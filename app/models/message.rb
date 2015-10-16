class Message
  include Redis::Objects

  ATTRIBUTES = [:message, :fail_message, :written_at, :reply_to]

  attr_accessor *ATTRIBUTES
  hash_key :message_set

  class << self
    def all
      message_store.members.map(&method(:find)).map(&:to_hash)
    end

    def list_after(id)
      id_list_from(id).tap { |result|
        result.delete(id)
      }.map(&method(:find)).map(&:to_hash)
    end

    def list_from(id)
      id_list_from(id).map(&method(:find)).map(&:to_hash)
    end

    def id_list_from(id)
      message_store.rangebyscore(at(id).to_i, last_at.to_i + 1)
    end

    def at(id)
      message_store[id]
    end

    def last_at
      message_store[message_store.last]
    end

    def first_at
      message_store[message_store.first]
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

    def generate_id!
      id_generator.increment.to_s
    end

    def generate_score!
      score_generator.increment
    end

    def store(message)
      if message.reply_to.present?
        base = message_store[message.reply_to].to_f
        score_for_reply = base - ((base.to_i + 1).to_f - base) / 2
        message_store[message.id] = score_for_reply
      else
        old_score = message_store[message.id]
        new_score = message_store[message.id] = generate_score!

        prev_score = old_score - 1

        if (children = message_store.rangebyscore(prev_score, old_score)).present?
          plus = new_score - old_score
          if message_store[children.first] == prev_score
            children.shift
          end
          children.each do |id|
            message_store.increment(id, plus)
          end
        end
      end
    end

    private

    def message_store
      @stored_message_store ||= Redis::SortedSet.new('messages')
    end

    def id_generator
      @stored_id_generator ||= Redis::Counter.new('messages_id')
    end

    def score_generator
      @stored_score_generator ||= Redis::Counter.new('messages_score')
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

  def to_hash
    {
      id: id,
      score: Message.at(id),
      message: message,
      written_at: written_at,
      reply_to: reply_to
    }
  end

  def destroy!
    Message.destroy(id)
  end

  def id
    @id
  end

  def reply_target_exist?
    return true if reply_to.blank?
    begin
      !!Message.find(reply_to)
    rescue NotFound
      false
    end
  end

  def invalid?
    message.blank? || written_at.blank?
  end

  def restore_from(id)
    @id = id
    redis_to_self!
    self
  end

  def children
    Message.children_of(id)
  end

  def save!
    raise RecordInvalid.new(self) if invalid?

    unless reply_target_exist?
      self.reply_to = nil
    end

    @id ||= self.class.generate_id!
    Message.store(self)
    self_to_redis!
    self
  end

  def update!(**args)
    args.each_pair do |key, value|
      send("#{key}=", value)
    end

    self.written_at = nil
    adjust_time!

    save!
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
