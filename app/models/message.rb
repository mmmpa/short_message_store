class Message
  include Redis::Objects

  ATTRIBUTES = [:message, :fail_message, :written_at]

  attr_accessor *ATTRIBUTES
  hash_key :message_set

  class << self
    def all
      message_store.members.map(&method(:find))
    end

    def find(id)
      raise NotFound unless message_store.member?(id)
      Message.new.restore_from(id)
    end

    def destroy_all
      message_store.members.map(&method(:destroy))
    end

    def destroy(id)
      message_store.delete(id)
    end

    def generate_id
      begin
        # 100000回saveで1度当たる程度なので4でよい
        # 2だとよく当たる
        id = SecureRandom.hex(4)
      end while message_store.member?(id)
      id
    end

    def store(message)
      message_store[message.id] = message.written_at.gsub(/[^0-9]/, '').to_f
    end

    private

    def message_store
      @stored_message_store ||= Redis::SortedSet.new('messages')
    end
  end

  def initialize(**args)
    args.each_pair do |key, value|
      send("#{key}=", value)
    end

    adjust_time!
  end

  def adjust_time!
    self.written_at = case
                        when written_at.is_a?(Time)
                          written_at.strftime('%Y/%m/%d %H:%M')
                        else
                          Time.now.strftime('%Y/%m/%d %H:%M')
                      end
  end

  def destroy!
    Message.destroy(id)
  end

  def id
    @id
  end

  def invalid?
    message.blank? || written_at.blank?
  end

  def restore_from(id)
    @id = id
    redis_to_self!
    self
  end

  def save!
    raise RecordInvalid.new(self) if invalid?

    @id ||= self.class.generate_id
    Message.store(self)
    self_to_redis!
    self
  end

  private

  def redis_to_self!
    self.message_set.each do |key, value|
      send("#{key}=", value)
    end
  end

  def self_to_redis!
    ATTRIBUTES.each do |key|
      message_set[key] = send(key)
    end
  end

  class RecordInvalid < StandardError
    def initialize(record)
      @record = record
    end

    def record
      @record
    end
  end

  class NotFound < StandardError

  end
end
