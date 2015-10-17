require './requirement'
require 'mail'

namespace :sweeper do
  desc 'Send all messages to your address, then Sweep all messages.'
  task :send_and_sweep! do
    send_mail
    Redis.current.flushall
  end

  desc 'Sweep all messages.'
  task :sweep! do
    Redis.current.flushall
  end

  desc 'Send all messages to your address.'
  task :send do
    send_mail
  end

  def send_mail
    mailer.delivery_method(:smtp, mailer_config)
    mailer.body
    mailer.deliver!
  end

  def mailer
    @stored_mailer ||= Mail.new do
      from from_address
      to to_address
      subject title
      body rendered
    end
  end

  def rendered
    messages.select { |message|
      message.reply_to.blank?
    }.inject([]) { |a, parent|
      a << parent
      a + Message.replies(parent.id)
    }.map { |message|
      [
        message.reply_to.present? ? "## ▲ #{message.written_at}\n\n" : "# #{message.written_at}\n\n",
        message.message
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
    "メモ#{message_size}枚（#{messages.first.written_at}～#{messages.last.written_at}）まとめ"
  end

  def from_address
    ENV['FROM_ADDRESS']
  end

  def to_address
    [ENV['TO_ADDRESS'], ENV['FROM_ADDRESS']]
  end
end