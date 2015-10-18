require './requirement'
require 'mail'

namespace :sweeper do
  desc 'Send all messages to your address, then Sweep all messages.'
  task :send_and_sweep! do
    Mailer.new(letter: WriteLetter.()).send_mail
    Redis.current.flushall
  end

  desc 'Sweep all messages.'
  task :sweep! do
    Redis.current.flushall
  end

  desc 'Send all messages to your address.'
  task :send do
    Mailer.new(letter: WriteLetter.()).send_mail
  end
end