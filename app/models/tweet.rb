class Tweet
  CLIENT = Twitter::REST::Client.new do |config|
    config.consumer_key = ENV['TWITTER_CONSUMER_KEY']
    config.consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
    config.access_token = ENV['TWITTER_ACCESS_TOKEN']
    config.access_token_secret = ENV['TWITTER_ACCESS_SECRET']
  end

  LIMIT = 140

  attr_accessor :message, :date

  class << self
    def create!(message:, date:)
      new(message: message, date: date).yap!
    end
  end

  def initialize(**args)
    args.each_pair do |key, value|
      send("#{key}=", value)
    end
  end

  def yap!
    Tweet::CLIENT.update!(tweet)
  end

  private

  def enough?
    raise DateRequired if date.blank?
    raise MessageRequired if message.blank?
    true
  end

  def tweet
    message[0..(chop_length - 1)] + pretty_date if enough?
  end

  def chop_length
    Tweet::LIMIT - pretty_date.length
  end

  def pretty_date
    @stored_pretty_date ||= date.strftime(' %Y/%m/%d %H:%M')
  end

  class DateRequired < StandardError
  end

  class MessageRequired < StandardError
  end
end