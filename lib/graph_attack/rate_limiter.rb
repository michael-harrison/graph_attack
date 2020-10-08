# frozen_string_literal: true

module GraphAttack
  # == GraphAttack::RateLimiter
  # Query analyser you can add to your GraphQL schema to limit calls by IP.
  #
  #     ApplicationSchema = GraphQL::Schema.define do
  #       query_analyzer GraphAttack::RateLimiter.new
  #     end
  #
  class RateLimiter
    class Error < StandardError; end

    class RateLimited < GraphQL::AnalysisError; end

    # @param [Redis] redis_client specific redis client (defaults to the current Redis)
    def initialize(redis_client: Redis.new)
      @redis_client = redis_client
    end

    def initial_value(query)
      {
        ip: query.context[:ip],
        query_rate_limits: [],
      }
    end

    # Extracts the rate limit details and increases the rate limit counter when the `rate_limit` node is passed in
    #
    # @param [Hash] memo hash containing the ip address
    # @param [Symbol] visit_type
    # @param [GraphQL::InternalRepresentation::Node] irep_node the node containing the rate limit details
    # @return [Hash] updated memo with rate limits extracted associated with the queries / mutations
    def call(memo, visit_type, irep_node)
      if rate_limited_node?(visit_type, irep_node)
        data = rate_limit_data(irep_node)

        memo[:query_rate_limits].push(data)

        increment_rate_limit(memo[:ip], data[:key])
      end

      memo
    end

    # Finalises the analysis by checking the rate limit.  If it has been exceeded then it will return an analysis error
    # otherwise nil
    #
    # @param [Hash] memo hash containing the ip address and rate_limits associated with the queries / mutations
    # @return [GraphAttack::RateLimiter::RateLimited, nil]
    def final_value(memo)
      handle_exceeded_calls_on_queries(memo)
    end


    # Allows for the manual increment of the rate counter for one field.  This is particularly useful when business
    # logic in the calling application is required to increment the counter.  For example, the query field becomes
    # expensive under a certain set of circumstances or the counter only needs to be incremented when a mutation fails
    # (e.g failed logins)
    #
    # The method returns the limit status, if the limit is exceeded then return returned status will be `:exceeded`
    # otherwise `:ok`.
    #
    # @param [String] ip the ip address of the client calling the GraphQL API
    # @param [String] name field name for the query / mutation
    # @param [Int] threshold number of counts per interval
    # @param [Int] interval time in seconds
    # @return [Symbol] limit status after increment
    def manual_count_increment(ip:, name:, threshold:, interval:)
      key = "graphql-query-#{name}"
      memo = {
        ip: ip,
        query_rate_limits: [
          {
            threshold: threshold,
            interval: interval,
            key: key,
            query_name: name
          }
        ]
      }

      increment_rate_limit(ip, key)
      identify_exceeded_calls(memo).any? ? :exceeded : :ok
    end

    private

    attr_reader :redis_client

    def increment_rate_limit(ip, key)
      raise Error, 'Missing :ip value on the GraphQL context' unless ip

      rate_limit(ip).add(key)
    end

    def rate_limit_data(node)
      data = node.definition.metadata[:rate_limit]

      data.merge(
        key: "graphql-query-#{node.name}",
        query_name: node.name,
      )
    end

    # @param [Hash] memo hash containing the ip address and rate_limits associated with the queries / mutations
    def handle_exceeded_calls_on_queries(memo)
      queries = identify_exceeded_calls(memo)
      return unless queries.any?

      RateLimited.new("Query rate limit exceeded on #{queries.join(', ')}")
    end

    # Identifies the fields that have exceeded their rate limits
    #
    # @param [Hash] memo hash containing the ip address and rate_limits associated with the queries / mutations
    def identify_exceeded_calls(memo)
      memo[:query_rate_limits].map do |limit_data|
        next unless calls_exceeded_on_query?(memo[:ip], limit_data)

        limit_data[:query_name]
      end.compact
    end

    def calls_exceeded_on_query?(ip, query_limit_data)
      rate_limit(ip).exceeded?(
        query_limit_data[:key],
        threshold: query_limit_data[:threshold],
        interval: query_limit_data[:interval],
      )
    end

    def rate_limit(ip)
      @rate_limit ||= {}
      @rate_limit[ip] ||= Ratelimit.new(ip, redis: redis_client)
    end

    def rate_limited_node?(visit_type, node)
      valid_field_node?(node) &&
        visit_type == :enter &&
        node.definition.metadata[:rate_limit]
    end

    def valid_field_node?(node)
      %w(Query Mutation).include?(node.owner_type.name) &&
        node.ast_node.is_a?(GraphQL::Language::Nodes::Field)
    end
  end
end
