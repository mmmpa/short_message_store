require 'spec_helper'

describe 'Route' do
  def app
    Sinatra::Application
  end

  before :all do
    Message.destroy_all!
    @result = (1..100).to_a.map { |n|
      Message.create!(message: n.to_s)
    }
  end

  after :all do
    Message.destroy_all!
  end

  let(:samples) { 100 }
  let(:body) { last_response.body }
  let(:json_hash) { JSON.parse(body) }

  describe 'GET /' do
    before :each do
      get '/'
    end

    it { expect(last_response).to be_ok }
    skip { expect(last_response.body).to have_tag('h1', text: 'slim') }
  end

  describe 'GET /messages/index' do
    context 'with no query' do
      before :each do
        get '/messages/index'
      end

      it do
        expect(json_hash.size).to eq(100)
      end

      it do
        @result.each_with_index do |message, index|
          hash = json_hash[index].symbolize_keys!
          expect(message.message).to eq(hash[:message])
          expect(message.score).to eq(hash[:score])
          expect(message.id).to eq(hash[:id])
        end
      end
    end

    context 'with from query' do
      let(:sampled) { @result.sample }
      let(:this_id) { sampled.id }
      let(:sampled_number) { sampled.message.to_i }
      let(:sampled_after) { samples - sampled_number }

      context 'with no reply' do
        before :each do
          get "/messages/index?from=#{this_id}"
        end

        it do
          expect(json_hash.size).to eq(sampled_after)
        end

        it do
          after = @result[sampled_number..@result.size]
          after.each_with_index do |message, index|
            hash = json_hash[index].symbolize_keys!
            expect(message.id).to eq(hash[:id])
          end
        end

        it do
          before = @result[0..(sampled_number - 1)].inject(Set.new) do |a, message|
            a << message.id
          end

          json_hash.each do |hash|
            hash.symbolize_keys!
            expect(before.include?(hash[:id])).to be_falsey
          end
        end
      end

      context 'with some replies' do
        let(:replies_count) { rand(20) }

        after :each do
          @replies.each(&:destroy!)
        end

        it do
          added = []
          @replies = (1..replies_count).to_a.map do |n|
            target = @result.sample
            new_message = Message.create!(message: "rep::#{n}", reply_to: target.id)

            if target.message.to_i > sampled_number
              added << new_message
            end

            new_message
          end

          get "/messages/index?from=#{this_id}"
          expect(json_hash.size).to eq(sampled_after + added.size)
        end
      end
    end
  end
end