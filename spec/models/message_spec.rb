require 'spec_helper'

RSpec.describe Message, type: :model do
  before :each do
    Message.destroy_all
  end

  let(:raw_message) { SecureRandom.hex(8) }
  let(:raw_time) { Time.now }

  describe 'Do save' do
    context 'with valid params' do
      let(:message) { Message.new(message: raw_message, written_at: raw_time) }

      it { expect(message.save!).to be_a(Message) }

      context 'then' do
        let(:message) { Message.new(message: raw_message, written_at: raw_time).save! }

        it { expect(Message.find(message.id).message).to eq(raw_message) }
        it { expect(Message.find(message.id).written_at).to eq(raw_time.strftime('%Y/%m/%d %H:%M')) }
      end
    end

    context 'with invalid params' do
      it { expect { Message.new(message: '', written_at: raw_time).save! }.to raise_error(Message::RecordInvalid) }
      it { expect { Message.new(message: nil, written_at: raw_time).save! }.to raise_error(Message::RecordInvalid) }

      it { expect(Message.new(message: raw_message, written_at: nil).save!).to be_a(Message) }
      it { expect(Message.new(message: raw_message, written_at: 'abc').save!).to be_a(Message) }

      context 'then' do
        it do
          begin
            Message.new(message: nil, written_at: raw_time).save!
          rescue Message::RecordInvalid => e
            expect(e.record).to be_a(Message)
          end
        end
      end
    end
  end


  describe 'Do find' do
    let(:message) { Message.new(message: raw_message, written_at: raw_time).save! }

    it { expect(Message.find(message.id)).to be_a(Message) }
    it { expect { Message.find('not exist') }.to raise_error(Message::NotFound) }
  end


  describe 'Do destroy' do
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

  describe 'Edit' do
    let!(:a) { Message.new(message: raw_message).save! }
    let!(:b) { Message.new(message: raw_message).save! }
    let!(:c) { Message.new(message: raw_message).save! }
    let!(:d) { Message.new(message: raw_message).save! }
    let!(:e) { Message.new(message: raw_message).save! }
    let!(:f) { Message.new(message: raw_message).save! }
    let!(:g) { Message.new(message: raw_message).save! }
    let!(:reply_to_c) { Message.new(message: raw_message, reply_to: c.id).save! }
    let!(:reply_to_reply_to_c) { Message.new(message: raw_message, reply_to: reply_to_c.id).save! }
    let!(:reply_to_a) { Message.new(message: raw_message, reply_to: a.id).save! }
    let!(:reply_to_a2) { Message.new(message: raw_message, reply_to: a.id).save! }

    context 'when no edit' do
      it { expect(ids).to eq([g.id, f.id, e.id, d.id, c.id, reply_to_c.id, reply_to_reply_to_c.id, b.id, a.id, reply_to_a2.id, reply_to_a.id]) }
    end

    context 'when edit' do
      it do
        b.update!
        expect(ids).to eq([b.id, g.id, f.id, e.id, d.id, c.id, reply_to_c.id, reply_to_reply_to_c.id, a.id, reply_to_a2.id, reply_to_a.id])
      end

      context 'has reply' do
        it do
          c.update!
          expect(ids).to eq([c.id, reply_to_c.id, reply_to_reply_to_c.id, g.id, f.id, e.id, d.id, b.id, a.id, reply_to_a2.id, reply_to_a.id])
        end

        it do
          a.update!
          expect(ids).to eq([a.id, reply_to_a2.id, reply_to_a.id, g.id, f.id, e.id, d.id, c.id, reply_to_c.id, reply_to_reply_to_c.id, b.id])
        end
      end

      context 'lost parent' do
        it do
          a.destroy!
          expect(ids).to eq([g.id, f.id, e.id, d.id, c.id, reply_to_c.id, reply_to_reply_to_c.id, b.id, reply_to_a2.id, reply_to_a.id])
          reply_to_a2.update!
          expect(ids).to eq([reply_to_a2.id, g.id, f.id, e.id, d.id, c.id, reply_to_c.id, reply_to_reply_to_c.id, b.id, reply_to_a.id])
        end

        it do
          c.destroy!
          expect(ids).to eq([g.id, f.id, e.id, d.id, reply_to_c.id, reply_to_reply_to_c.id, b.id, a.id, reply_to_a2.id, reply_to_a.id])
          reply_to_c.update!
          expect(ids).to eq([reply_to_c.id, reply_to_reply_to_c.id, g.id, f.id, e.id, d.id, b.id, a.id, reply_to_a2.id, reply_to_a.id])
        end

        it do
          c.destroy!
          expect(ids).to eq([g.id, f.id, e.id, d.id, reply_to_c.id, reply_to_reply_to_c.id, b.id, a.id, reply_to_a2.id, reply_to_a.id])
          reply_to_reply_to_c.update!
          expect(ids).to eq([g.id, f.id, e.id, d.id, reply_to_c.id, reply_to_reply_to_c.id, b.id, a.id, reply_to_a2.id, reply_to_a.id])
        end

        context 'has siblings' do
          let!(:reply_to_c2) { Message.new(message: raw_message, reply_to: c.id).save! }
          let!(:reply_to_reply_to_c2) { Message.new(message: raw_message, reply_to: reply_to_c2.id).save! }

          before :each do
            c.destroy!
          end

          context 'when no edit' do
            it do
              expect(ids).to eq([g.id, f.id, e.id, d.id, reply_to_c2.id, reply_to_reply_to_c2.id, reply_to_c.id, reply_to_reply_to_c.id, b.id, a.id, reply_to_a2.id, reply_to_a.id])
            end
          end

          context 'when edit' do
            it 'dont move' do
              reply_to_reply_to_c.update!
              expect(ids).to eq([g.id, f.id, e.id, d.id, reply_to_c2.id, reply_to_reply_to_c2.id, reply_to_c.id, reply_to_reply_to_c.id, b.id, a.id, reply_to_a2.id, reply_to_a.id])
            end

            it do
              reply_to_c.update!
              expect(ids).to eq([reply_to_c.id, reply_to_reply_to_c.id, g.id, f.id, e.id, d.id, reply_to_c2.id, reply_to_reply_to_c2.id, b.id, a.id, reply_to_a2.id, reply_to_a.id])
            end

            it do
              reply_to_c2.update!
              expect(ids).to eq([reply_to_c2.id, reply_to_reply_to_c2.id, g.id, f.id, e.id, d.id, reply_to_c.id, reply_to_reply_to_c.id, b.id, a.id, reply_to_a2.id, reply_to_a.id])
            end
          end
        end
      end

      context 'reply' do
        it do
          reply_to_c.update!
          expect(ids).to eq([g.id, f.id, e.id, d.id, c.id, reply_to_c.id, reply_to_reply_to_c.id, b.id, a.id, reply_to_a2.id, reply_to_a.id])
        end

        it do
          reply_to_a.update!
          expect(ids).to eq([g.id, f.id, e.id, d.id, c.id, reply_to_c.id, reply_to_reply_to_c.id, b.id, a.id, reply_to_a.id, reply_to_a2.id])
        end
      end
    end
  end

  describe 'Reply' do
    before :each do
      Message.destroy_all
    end

    let!(:a) { Message.new(message: raw_message).save! }
    let!(:b) { Message.new(message: raw_message).save! }
    let!(:c) { Message.new(message: raw_message).save! }
    let!(:d) { Message.new(message: raw_message).save! }

    context 'when no reply' do
      it { expect(ids).to eq([d.id, c.id, b.id, a.id]) }
    end

    context 'when added reply' do
      it do
        reply = Message.new(message: 'reply', reply_to: b.id).save!
        expect(ids).to eq([d.id, c.id, b.id, reply.id, a.id])
      end

      context 'to tail' do
        it do
          reply = Message.new(message: 'reply', reply_to: a.id).save!
          expect(ids).to eq([d.id, c.id, b.id, a.id, reply.id])
        end
      end

      context 'to head' do
        it do
          reply = Message.new(message: 'reply', reply_to: d.id).save!
          expect(ids).to eq([d.id, reply.id, c.id, b.id, a.id])
        end
      end


      context 'to reply' do
        it do
          reply = Message.new(message: 'reply', reply_to: d.id).save!
          reply_to_reply = Message.new(message: 'reply', reply_to: reply.id).save!
          expect(ids).to eq([d.id, reply.id, reply_to_reply.id, c.id, b.id, a.id])
        end
      end

      context 'to has reply' do
        it do
          reply = Message.new(message: 'reply', reply_to: d.id).save!
          reply_to_has_reply = Message.new(message: 'reply', reply_to: d.id).save!
          expect(ids).to eq([d.id, reply_to_has_reply.id, reply.id, c.id, b.id, a.id])
        end
      end
    end
  end
end

def ids
  Message.all.map { |message| message[:id] }.reverse
end