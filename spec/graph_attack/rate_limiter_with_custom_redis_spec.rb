# frozen_string_literal: true

RSpec.describe GraphAttack::RateLimiter do
  let(:context) { { ip: '99.99.99.99' } }

  context 'when using the GraphQL::Ruby DSL' do
    context 'with custom redis client' do
      let(:schema) { CustomSchema }
      let(:redis) { CUSTOM_REDIS_CLIENT }

      describe 'fields with rate limiting' do
        it 'inserts rate limits in the custom redis client' do
          schema.execute('{ expensiveField }', context: context)

          key = 'ratelimit:99.99.99.99:graphql-query-expensiveField'
          expect(redis.scan_each(match: key).count).to eq(1)
        end
      end
    end
  end
end
