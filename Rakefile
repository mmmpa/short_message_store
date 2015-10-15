require './requirement'
require 'mail'

namespace :sweeper do

  desc 'Send all messages to hatena blog as a entry.'
  task :sweep! do
    mailer.delivery_method(:smtp, mailer_config)
    mailer.body
    mailer.deliver!
    Redis.current.flushall
  end

  def mailer
    @stored_mailer ||= Mail.new do
      from from_address
      to hatena_address
      subject title
      body rendered
    end
  end

  def rendered
    sorted = []
    messages.map do |message|
      if message[:reply_to]
        target_index = sorted.index { |target| target[:id] == message[:reply_to] }
        if target_index
          sorted = sorted[0..(target_index)] + [message] + sorted[(target_index + 1)..sorted.size]
        else
          sorted.push(message)
        end
      else
        sorted.push(message)
      end
    end
    "このエントリーはShort Message Storeから自動的に投稿される\n\n" +
    sorted.map { |message|
      pp message
      [
        message[:reply_to].present? ? "## ▲ #{message[:written_at]}\n\n" : "# #{message[:written_at]}\n\n",
        message[:message]
      ].join("\n")
    }.join("\n\n")
  end

  def messages
    @stored_messages ||= Message.all
  end

  def message_size
    messages.size
  end

  def mailer_config
    {
      user_name: ENV['SENDGRID_USER_NAME'],
      password: ENV['SENDGRID_USER_PASSWORD'],
      domain: ENV['SENDGRID_DOMAIN'],
      address: 'smtp.sendgrid.net',
      port: 587,
      authentication: :plain,
      enable_starttls_auto: true
    }
  end

  def title
    "メモ#{message_size}枚（#{messages.first[:written_at]}～#{messages.last[:written_at]}）まとめ"
  end

  def from_address
    ENV['FROM_ADDRESS']
  end

  def hatena_address
    ENV['HATENA_ADDRESS_FOR_ENTRY']
  end
end