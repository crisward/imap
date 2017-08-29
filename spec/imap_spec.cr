require "./spec_helper"

describe Imap do
  # TODO: Write tests

  it "should count emails in mailbox" do
    imap = Imap::Client.new(host: "imap.gmail.com", port: 993, username: "***", password: "***")
    mailboxes = imap.get_mailboxes
    if mailboxes.size > 0
      mailbox = mailboxes[0]
      imap.set_mailbox(mailbox)
      message_count = imap.get_message_count
      puts "There are #{message_count} message in #{mailbox}"
    end
    imap.close
  end
end
