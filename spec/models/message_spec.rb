require 'rails_helper'

RSpec.describe Message, type: :model do
  before :all do
    Redis.current.redis.flushdb
  end

  context 'with valid params' do
    context 'when save' do
      let(:raw_message) { SecureRandom.hex(8) }
      let(:raw_time) { Time.now }
      let(:message) { Message.new(message: raw_message, written_at: raw_time) }

      it { expect(message.save!).to be_a(Message) }
    end
  end

  context 'with invalid params' do
    context 'when save' do
      let(:raw_message) { SecureRandom.hex(8) }
      let(:raw_time) { Time.now }

      it { expect { Message.new(message: '', written_at: raw_time).save! }.to raise_error(Message::RecordInvalid) }
      it { expect { Message.new(message: nil, written_at: raw_time).save! }.to raise_error(Message::RecordInvalid) }

      it { expect(Message.new(message: raw_message, written_at: nil).save!).to be_a(Message) }
      it { expect(Message.new(message: raw_message, written_at: 'abc').save!).to be_a(Message) }
    end
  end

  context 'when find' do
    let(:raw_message) { SecureRandom.hex(8) }
    let(:raw_time) { Time.now }
    let(:message) { Message.new(message: raw_message, written_at: raw_time).save! }

    it { expect(Message.find(message.id)).to be_a(Message) }
    it { expect{Message.find('not exist')}.to raise_error(Message::NotFound) }
  end

  context 'when saved' do
    let(:raw_message) { SecureRandom.hex(8) }
    let(:raw_time) { Time.now }
    let(:message) { Message.new(message: raw_message, written_at: raw_time).save! }

    it { expect(Message.find(message.id).message).to eq(raw_message) }
    it { expect(Message.find(message.id).written_at).to eq(raw_time.strftime('%Y/%m/%d %H:%M')) }
  end
end
