require 'spec_helper'

RSpec.describe Message, type: :model do
  describe 'not real tweet' do

    before :each do
      allow_any_instance_of(Tweet).to receive(:yap!) do |this|
        this.send(:tweet)
        true
      end
    end

    describe 'Do create' do
      context 'with valid params' do
        let(:message) { SecureRandom.hex(18) }
        let(:date) { Time.now }

        it { expect(Tweet.create!(message: message, date: date)).to be_truthy }
      end

      context 'with invalid params' do
        let(:message) { SecureRandom.hex(18) }
        let(:date) { Time.now }

        it { expect { Tweet.create!(message: nil, date: nil) }.to raise_error(Tweet::DateRequired) }
        it { expect { Tweet.create!(message: message, date: nil) }.to raise_error(Tweet::DateRequired) }
        it { expect { Tweet.create!(message: nil, date: date) }.to raise_error(Tweet::MessageRequired) }
        it { expect { Tweet.create!(message: message, date: '') }.to raise_error(Tweet::DateRequired) }
        it { expect { Tweet.create!(message: '', date: date) }.to raise_error(Tweet::MessageRequired) }
      end
    end

    describe 'Do new' do
      context 'with valid params' do
        let(:message) { SecureRandom.hex(18) }
        let(:date) { Time.now }

        it { expect(Tweet.new(message: message, date: date).send(:tweet)).to be_truthy }
      end

      context 'with invalid params' do
        let(:message) { SecureRandom.hex(18) }
        let(:date) { Time.now }

        it { expect { Tweet.new.send(:tweet) }.to raise_error(Tweet::DateRequired) }
        it { expect { Tweet.new(message: message).send(:tweet) }.to raise_error(Tweet::DateRequired) }
        it { expect { Tweet.new(date: date).send(:tweet) }.to raise_error(Tweet::MessageRequired) }
        it { expect { Tweet.new(message: message, date: '').send(:tweet) }.to raise_error(Tweet::DateRequired) }
        it { expect { Tweet.new(message: '', date: date).send(:tweet) }.to raise_error(Tweet::MessageRequired) }
      end
    end

    describe 'trim too long message' do
      context 'when message + date length is over 140' do
        let(:message) { SecureRandom.hex(80) }
        let(:date) { Time.now }
        let(:tweet) { Tweet.new(message: message, date: date) }

        it { expect(tweet.send(:message)).to eq(message) }
        it { expect(tweet.send(:date)).to eq(date) }
        it { expect(tweet.send(:tweet)).not_to include(message) }
        #it { expect(tweet.yap!).to be_truthy }
      end

      context 'when message + date length is under 140' do
        let(:message) { SecureRandom.hex(18) }
        let(:date) { Time.now }
        let(:tweet) { Tweet.new(message: message, date: date) }

        it { expect(tweet.send(:message)).to eq(message) }
        it { expect(tweet.send(:date)).to eq(date) }
        it { expect(tweet.send(:tweet)).to include(message) }
        it { expect(tweet.yap!).to be_truthy }
      end
    end
  end

  describe 'real tweet' do
    let(:message) { SecureRandom.hex(18) }
    let(:date) { Time.now }
    skip { expect(Tweet.create!(message: message, date: date)).to be_truthy }
  end
end
