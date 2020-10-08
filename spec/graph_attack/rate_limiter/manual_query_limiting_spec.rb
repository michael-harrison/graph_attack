# frozen_string_literal: true

RSpec.describe GraphAttack::RateLimiter do
  let(:schema) { DefaultSchema }
  let(:redis) { Redis.current }
  let(:context) { { ip: '99.99.99.99' } }

  context '.manual_count_increment' do
    context 'for queries' do
      it 'inserts rate limits in redis' do
        schema.execute('{ sometimesExpensiveField }', context: context)

        key = 'ratelimit:99.99.99.99:graphql-query-sometimesExpensiveField'
        expect(redis.scan_each(match: key).count).to eq(1)
      end

      it 'returns data until rate limit is exceeded' do
        4.times do
          result = schema.execute('{ sometimesExpensiveField }', context: context)

          expect(result).not_to have_key('errors')
          expect(result['data']).to eq('sometimesExpensiveField' => 'result')
        end
      end

      context 'when rate limit is exceeded' do
        let(:expected_message) { 'This field has been expensive to run too many times' }

        before do
          4.times do
            schema.execute('{ sometimesExpensiveField }', context: context)
          end
        end

        it 'returns an error' do
          result = schema.execute('{ sometimesExpensiveField }', context: context)

          expect(result['errors'].first['message']).to eq expected_message
          expect(result['data']).to be nil
        end

        context 'when on a different IP' do
          let(:context2) { { ip: '203.0.113.43' } }

          it 'does not return an error' do
            result = schema.execute('{ sometimesExpensiveField }', context: context2)

            expect(result).not_to have_key('errors')
            expect(result['data']).to eq('sometimesExpensiveField' => 'result')
          end
        end
      end
    end
  end
end
