require './requirement'
require 'mail'

namespace :sweeper do

  desc 'Send all messages to hatena blog as a entry.'
  task :sweep! do
    mailer.delivery_method(:smtp, mailer_config)
    mailer.deliver!
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
    "このエントリーはShort Message Storeから自動的に投稿される\n\n"
    messages.map { |message|
      [
        "# #{message[:written_at]}\n\n",
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