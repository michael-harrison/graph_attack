# frozen_string_literal: true

RSpec.describe GraphAttack::RateLimiter do
  let(:schema) { DefaultSchema }
  let(:redis) { Redis.current }
  let(:ip) { '99.99.99.99' }
  let(:context) { { ip: ip } }

  context '.manual_count_increment' do
    context 'for mutations' do
      let(:result) { schema.execute(query, context: context, variables: { email: 'john.citizen@example.com', password: password }) }
      let(:query) do
        <<-GRAPHQL
            mutation($email: String!, $password: String!) {
              limitedLogin(email: $email, password: $password) {
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
      let(:key) { "ratelimit:#{ip}:graphql-query-loginFailure" }
      let(:expected_data) do
        {
          'limitedLogin' => {
            'user' => {
              'id' => '1',
              'firstName' => 'John',
              'lastName' => 'Citizen',
              'email' => 'john.citizen@example.com'
            }
          }
        }
      end

      context 'when a correct password is provided' do
        let(:password) { 'something secret' }

        it 'will not insert rate limits in redis' do
          expect(result['errors']).to be nil
          expect(redis.scan_each(match: key).count).to eq 0
        end

        context 'when rate limit is exceeded' do
          before do
            4.times do
              schema.execute(query, context: context, variables: { email: 'john.citizen@example.com', password: password })
            end
          end

          it 'will not return an error' do
            expect(result['errors']).to be nil
            expect(result['data']).to eq expected_data
          end

          context 'when on a different IP' do
            let(:other_context) { { ip: '203.0.113.43' } }

            it 'does not return an error' do
              result = schema.execute(query, context: other_context, variables: { email: 'john.citizen@example.com', password: password })
              expect(result['errors']).to be nil
              expect(result['data']).to eq expected_data
            end
          end
        end
      end

      context 'when an incorrect password is provided' do
        let(:password) { 'something incorrect' }
        let(:expected_data) do
          {
            'limitedLogin' => {
              'user' => nil
            }
          }
        end

        it 'will insert rate limits in redis' do
          expect(result['errors']).to be nil
          expect(redis.scan_each(match: key).count).to eq 1
        end

        it 'returns data until rate limit is exceeded' do
          4.times do
            result = schema.execute(query, context: context, variables: { email: 'john.citizen@example.com', password: password })
            expect(result['data']).to eq expected_data
          end
        end

        context 'when rate limit is exceeded' do
          let(:expected_message) { 'This field has been expensive to run too many times' }

          before do
            4.times do
              schema.execute(query, context: context, variables: { email: 'john.citizen@example.com', password: password })
            end
          end

          it 'will return an error' do
            result = schema.execute(query, context: context, variables: { email: 'john.citizen@example.com', password: password })

            expect(result['errors'].first['message']).to eq expected_message
          end

          context 'when on a different IP' do
            let(:other_context) { { ip: '203.0.113.43' } }

            it 'will not return an error' do
              result = schema.execute(query, context: other_context, variables: { email: 'john.citizen@example.com', password: password })
              expect(result['errors']).to be nil
              expect(result['data']).to eq expected_data
            end
          end
        end
      end
    end
  end
end
