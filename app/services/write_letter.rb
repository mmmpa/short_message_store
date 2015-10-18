class WriteLetter
  class << self
    def call
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
  end
end