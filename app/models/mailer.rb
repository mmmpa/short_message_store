class Mailer
  def initialize(letter:)
    @body = letter
  end

  def send_mail
    new_mailer = mailer
    new_mailer.delivery_method(:smtp, mailer_config)
    new_mailer.deliver!
  end

  def mailer
    new_mailer = Mail.new
    new_mailer.from = from_address
    new_mailer.to = to_address
    new_mailer.subject = title
    new_mailer.body = @body
    new_mailer
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
    'メモまとめ'
  end

  def from_address
    ENV['FROM_ADDRESS']
  end

  def to_address
    [ENV['TO_ADDRESS'], ENV['FROM_ADDRESS']]
  end
end