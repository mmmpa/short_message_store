class Message
  include Redis::Objects

  ATTRIBUTES = [:message, :written_at, :reply_to, :length]

  attr_accessor *ATTRIBUTES
  hash_key :message_set

  class << self

    #
    # return instance
    #
    # 取得用の引数はidで統一
    #

    def create!(**args)
      new(**args).save!
    end

    def all
      message_store.members.map(&method(:find))
    end

    #idの主から次の親までを取得
    def between_next_parent_and(id)
      score = at(id)
      message_store.rangebyscore(score.to_i - 1, score).reverse
    end

    def find(id)
      Message.new.restore_from(id) if exist?(id)
    end

    # idの主を含まない
    def after(id)
      ids_from(id).tap { |result|
        result.delete(id)
      }.map(&method(:find))
    end

    # idの主を含む
    def from(id)
      ids_from(id).map(&method(:find))
    end

    def replies(id)
      reply_ids(id).map(&method(:find))
    end

    #
    # return id
    #

    def id_by_score(score)
      message_store.rangebyscore(score, score).first
    end

    def ids_from(id)
      message_store.rangebyscore(at(id), last_at + 1)
    end

    def next_parent_id(id)
      id_by_score(next_parent_score(id))
    end

    def reply_ids(id)
      parent = find(id)
      base = message_store[id]
      edge = message_store[id] - parent.length.to_f
      message_store.rangebyscore("(#{edge}", "(#{base}")
    rescue NotFound
      []
    end

    #
    # return score
    #

    def at(id)
      message_store[id]
    end

    def first_at
      message_store[message_store.first]
    end

    def last_at
      message_store[message_store.last]
    end

    def next_parent_score(id)
      message_store[id].ceil - 1
    end

    def next_score(id)
      rank = message_store.rank(id)
      next_id = if rank == 0
                  0
                else
                  message_store[rank - 1, 1].first
                end
      message_store[next_id]
    end

    def score_for_reply_to(id)
      #左端
      base = message_store[id]
      #右端
      edge = message_store[id] - find(id).length.to_f

      #右端か右端より左にあるスコア
      next_score = [edge, next_score(id)].max

      (base + next_score) / 2
    end

    #
    # for persistence
    #

    def generate_id!
      id_generator.increment.to_s
    end

    def generate_score!
      score_generator.increment
    end

    def store(message)
      if message.reply_to.present? && reply_target_exist?(message.reply_to)
        message_store[message.id] = score_for_reply_to(message.reply_to)
        message.length = (message_store[message.id] - next_score(message.id))
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
          message.length = 1
        else
          message_store[message.id] = generate_score!
          message.length = 1
        end
      end
    end

    def destroy!(id)
      message_store.delete(id) || (raise CannotDestroy)
    end

    def destroy_all!
      message_store.members.map(&method(:destroy!))
    end

    #
    # checker
    #

    def exist?(id)
      raise NotFound unless message_store.member?(id)

      true
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

    #
    # redis management
    #

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

  #
  # instance method
  #

  def initialize(**args)
    args.each_pair do |key, value|
      send("#{key}=", value)
    end

    adjust_time!
  end

  def destroy!
    Message.destroy!(id)
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

  def score
    Message.at(id)
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

  def update!(**args)
    args.each_pair do |key, value|
      send("#{key}=", value)
    end

    self.written_at = nil
    adjust_time!

    save!
  end

  private

  def adjust_time!
    self.written_at = case
                        when written_at.is_a?(Time)
                          written_at.strftime('%Y/%m/%d %H:%M')
                        else
                          Time.now.strftime('%Y/%m/%d %H:%M')
                      end
  end

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

  class CannotDestroy < StandardError

  end
end
