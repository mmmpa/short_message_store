class Message
  include Redis::Objects

  ATTRIBUTES = [:message, :fail_message, :written_at, :reply_to]

  attr_accessor *ATTRIBUTES
  hash_key :message_set

  class << self
    def all
      message_store.members.map(&method(:find))
    end

    def list_after(score)
      id_list_from(score).tap { |result|
        result.delete(id_by_score(score))
      }.map(&method(:find))
    end

    def list_from(score)
      id_list_from(score).map(&method(:find))
    end

    def replies(id)
      score = at(id)
      result = message_store.rangebyscore(score.to_i - 1, score).reverse
      result.delete(id_by_score(score))
      result.delete(id_by_score(score.to_i - 1))

      parents = Set.new([id_by_score(score)])
      result.map { |result_id|
        target = find(result_id)
        if parents.include?(target.reply_to)
          parents << target.id
          target
        else
          nil
        end
      }.compact
    end

    def reply_ids(id)
      replies(id).map(&:id)
    end

    def id_by_score(score)
      message_store.rangebyscore(score, score).first
    end

    def id_list_from(score)
      message_store.rangebyscore(score, last_at + 1)
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

    def exist?(id)
      raise NotFound unless message_store.member?(id)

      true
    end

    def find(id)
      Message.new.restore_from(id) if exist?(id)
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

    def next_parent_score(score)
      score.ceil - 1
    end

    def score_for_reply_to(id)
      base = message_store[id]
      my_rank = message_store.rank(id)
      #最大でも1に抑える
      next_score = if my_rank == 0
                     next_parent_score(base)
                   else
                     next_id = message_store[my_rank - 1, 1].first
                     [next_parent_score(base), message_store[next_id]].max
                   end

      (base + next_score) / 2
    end

    def store(message)
      if message.reply_to.present? && reply_target_exist?(message.reply_to)
        children = replies(message.id)
        message_store[message.id] = score_for_reply_to(message.reply_to)

        children.each do |target|
          message_store[target.id] = score_for_reply_to(target.reply_to)
        end
      else
        message.reply_to = nil
        children = replies(message.id)

        if children.present?
          old_score = message_store[message.id]
          new_score = message_store[message.id] = generate_score!
          plus = new_score - old_score
          children.each do |reply|
            message_store.increment(reply.id, plus)
          end
        else
          message_store[message.id] = generate_score!
        end
      end
    end

    def reply_target_exist?(id)
      return true if id.blank?
      begin
        exist?(id)
      rescue NotFound
        false
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
      score: score,
      message: message,
      written_at: written_at,
      reply_to: reply_to
    }
  end

  def score
    Message.at(id)
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
