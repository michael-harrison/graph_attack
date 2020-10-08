# frozen_string_literal: true

RSpec.describe GraphAttack::RateLimiter do
  let(:schema) { DefaultSchema }
  let(:redis) { Redis.current }
  let(:ip) { '99.99.99.99' }
  let(:context) { { ip: ip } }

  context 'when using the GraphQL::Ruby DSL' do
    context 'for mutations' do
      describe 'fields without rate limiting' do
        let(:result) { schema.execute(query, context: context) }
        let(:query) do
          <<-GRAPHQL
            mutation {
              logout {
                success
              }
            }
          GRAPHQL
        end
        let(:expected_data) do
          {
            'logout' => {
              'success' => true
            }
          }
        end

        it 'returns data' do
          expect(result['errors']).to be nil
          expect(result['data']).to eq expected_data
        end

        it 'does not insert rate limits in redis' do
          expect(result['errors']).to be nil
          expect(redis.scan_each(match: 'ratelimit:*').count).to eq 0
        end
      end

      describe 'fields with rate limiting' do
        let(:result) { schema.execute(query, context: context, variables: { email: 'john.citizen@example.com', password: 'something secret' }) }
        let(:query) do
          <<-GRAPHQL
            mutation($email: String!, $password: String!) {
              login(email: $email, password: $password) {
                user {
                  id
                  firstName
                  lastName
                  email
                }
              }
            }
          GRAPHQL
        end
        let(:key) { "ratelimit:#{ip}:graphql-query-login" }
        let(:expected_data) do
          {
            'login' => {
              'user' => {
                'id' => '1',
                'firstName' => 'John',
                'lastName' => 'Citizen',
                'email' => 'john.citizen@example.com'
              }
            }
          }
        end


        it 'inserts rate limits in redis' do
          expect(result['errors']).to be nil
          expect(redis.scan_each(match: key).count).to eq 1
        end

        it 'returns data until rate limit is exceeded' do
          4.times do
            result = schema.execute(query, context: context, variables: { email: 'john.citizen@example.com', password: 'something secret' })
            expect(result['data']).to eq expected_data
          end
        end

        context 'when rate limit is exceeded' do
          before do
            4.times do
              schema.execute(query, context: context, variables: { email: 'john.citizen@example.com', password: 'something secret' })
            end
          end

          let(:expected_message) { 'Query rate limit exceeded on login' }

          it 'returns an error' do
            expect(result['errors']).to eq([{ 'message' => expected_message }])
            expect(result).not_to have_key('data')
          end

          context 'when on a different IP' do
            let(:other_context) { { ip: '203.0.113.43' } }

            it 'does not return an error' do
              result = schema.execute(query, context: other_context, variables: { email: 'john.citizen@example.com', password: 'something secret' })
              expect(result['errors']).to be nil
              expect(result['data']).to eq expected_data
            end
          end
        end
      end
    end
  end
end
