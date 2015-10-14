require 'rails_helper'

RSpec.describe Message, type: :model do
  after :all do
    Message.destroy_all
  end

  describe 'Do save' do
    context 'with valid params' do
      let(:raw_message) { SecureRandom.hex(8) }
      let(:raw_time) { Time.now }
      let(:message) { Message.new(message: raw_message, written_at: raw_time) }

      it { expect(message.save!).to be_a(Message) }

      context 'then' do
        let(:message) { Message.new(message: raw_message, written_at: raw_time).save! }

        it { expect(Message.find(message.id).message).to eq(raw_message) }
        it { expect(Message.find(message.id).written_at).to eq(raw_time.strftime('%Y/%m/%d %H:%M')) }
      end
    end

    context 'with invalid params' do
      let(:raw_message) { SecureRandom.hex(8) }
      let(:raw_time) { Time.now }

      it { expect { Message.new(message: '', written_at: raw_time).save! }.to raise_error(Message::RecordInvalid) }
      it { expect { Message.new(message: nil, written_at: raw_time).save! }.to raise_error(Message::RecordInvalid) }

      it { expect(Message.new(message: raw_message, written_at: nil).save!).to be_a(Message) }
      it { expect(Message.new(message: raw_message, written_at: 'abc').save!).to be_a(Message) }
    end
  end


  describe 'Do find' do
    let(:raw_message) { SecureRandom.hex(8) }
    let(:raw_time) { Time.now }
    let(:message) { Message.new(message: raw_message, written_at: raw_time).save! }

    it { expect(Message.find(message.id)).to be_a(Message) }
    it { expect { Message.find('not exist') }.to raise_error(Message::NotFound) }
  end


  describe 'Do destroy' do
    let(:raw_message) { SecureRandom.hex(8) }
    let(:raw_time) { Time.now }
    let(:message) { Message.new(message: raw_message, written_at: raw_time).save! }

    context 'with valid id' do
      it { expect(Message.destroy(message.id)).to be_truthy }
      it { expect(message.destroy!).to be_truthy }

      context 'then' do
        it do
          id = message.id
          message.destroy!
          expect { Message.find(id) }.to raise_error(Message::NotFound)
        end
      end
    end

    context 'with invalid id' do
      it { expect(Message.destroy('not exist')).to be_falsey }
    end
  end
end
