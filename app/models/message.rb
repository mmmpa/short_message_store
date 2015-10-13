class Message
  include Redis::Objects

  ATTRIBUTES = [:message, :fail_message, :written_at]

  attr_accessor *ATTRIBUTES
  ATTRIBUTES.each { |name| value "redis_#{name}" }

  class << self

    def find(id)
      raise NotFound unless message_store.member?(id)
      Message.new.restore_from(id)
    end

    def generate_id
      begin
        id = SecureRandom.hex(16)
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

  def initialize(message: nil, fail_message: nil, written_at: nil)
    @id = id
    self.message = message
    self.fail_message = fail_message
    self.written_at = written_at || Time.now.strftime('%Y/%m/%d %H:%M')
  end

  def save
    @id ||= self.class.generate_id
    self_to_redis!
    Message.store(self)
    self
  end

  def id
    @id
  end

  def restore_from(id)
    @id = id
    redis_to_self!
    self
  end

  private

  def self_to_redis!
    ATTRIBUTES.each do |name|
      send("redis_#{name}=", send("#{name}"))
    end
  end

  def redis_to_self!
    ATTRIBUTES.each do |name|
      send("#{name}=", send("redis_#{name}").value)
    end
  end

  class NotFound < StandardError

  end
end
