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

    #そのメッセージの子は、かならずscoreの小数点以下を切り捨てた値に-1のscoreにおさまる
    #<=での取得になるので、次の親メッセージを含む場合と含まない場合がある
    def children_of(id)
      my_score = message_store[id]
      prev_score = my_score.to_i - 1

      #自分と次の親メッセージを含みうる結果
      result = message_store.rangebyscore(prev_score, my_score)

      #自分を除去
      result.pop if message_store[result.last] == my_score
      #次の親メッセージなら除去
      result.shift if message_store[result.first] == prev_score

      result
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
      if message.reply_to.present?
        message_store[message.id] = score_for_reply_to(message.reply_to)
      else
        children = children_of(message.id)

        if children.present?
          old_score = message_store[message.id]
          new_score = message_store[message.id] = generate_score!
          plus = new_score - old_score
          children.each do |id|
            message_store.increment(id, plus)
          end
        else
          message_store[message.id] = generate_score!
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
