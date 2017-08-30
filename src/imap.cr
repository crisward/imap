require "./imap/*"
require "openssl"
require "logger"

module Imap
  class Client
    @socket : TCPSocket | OpenSSL::SSL::Socket::Client | Nil = nil
    @logger : Logger
    @mailbox : String?

    def initialize(host = "imap.gmail.com", port = 993, username = "", password = "", loglevel = Logger::ERROR)
      @logger = Logger.new(STDOUT)
      @logger.level = loglevel
      @mailboxes = [] of String
      @mailbox = nil

      @command_history = [] of String
      @socket = TCPSocket.new(host, port)
      tls_socket = OpenSSL::SSL::Socket::Client.new(@socket.as(TCPSocket), sync_close: true, hostname: host)
      tls_socket.sync = false
      @socket = tls_socket
      login(username, password)
      # list headers
      # process_mail_headers(command("tag FETCH 1:#{count} (BODY[HEADER])"))
    end

    private def socket
      if _socket = @socket
        _socket
      else
        raise "Client socket not opened."
      end
    end

    private def command(command : String, *parameters)
      command_and_parameter = "tag #{command}"
      params = parameters.join(" ")
      command_and_parameter += " #{params}" if params && params.size > 0
      @command_history << command_and_parameter
      @logger.info "=====> #{command_and_parameter}"
      socket << command_and_parameter << "\r\n"
      socket.flush
      response
    end

    private def login(username, password)
      command("login", username, password)
    end

    # Sends a SELECT command to select a +mailbox+ so that messages
    # in the +mailbox+ can be accessed.
    def select(mailbox)
      @mailbox = mailbox
      command("SELECT", mailbox)
    end

    # Sends a EXAMINE command to select a +mailbox+ so that messages
    # in the +mailbox+ can be accessed.  Behaves the same as #select(),
    # except that the selected +mailbox+ is identified as read-only.
    def examine(mailbox)
      @mailbox = mailbox
      command("EXAMINE", mailbox)
    end

    # Sends a DELETE command to remove the +mailbox+.
    def delete(mailbox)
      command("DELETE", mailbox)
    end

    # Sends a RENAME command to change the name of the +mailbox+ to
    # +newname+.
    def rename(mailbox, newname)
      command("RENAME", mailbox, newname)
    end

    # Returns an array of mailbox names
    def get_mailboxes : Array(String)
      mailboxes = [] of String
      res = command(%{LIST "" "*"})
      res.each do |line|
        if line =~ /HasNoChildren/
          name = line.match(/"([^"]+)"$/)
          mailboxes << name[1].to_s if name
        end
      end
      return mailboxes
    end

    # Returns the number of messages in the current mailbox
    def get_message_count
      mailbox = @mailbox
      if !mailbox
        raise "No Mailbox set"
      end
      res = command("STATUS #{mailbox} (MESSAGES)")
      # eg (MESSAGES 3)
      res.each do |line|
        if line =~ /MESSAGES/
          match = line.match(/MESSAGES ([0-9]+)/)
          if match
            return match[1].to_i
          end
        end
      end
      return 0
    end

    # Sends a STATUS command, and returns the status of the indicated
    # `mailbox`. `attr` is a list of one or more attributes whose
    # statuses are to be requested.  Supported attributes include:
    #
    #   * MESSAGES:: the number of messages in the mailbox.
    #   * RECENT:: the number of recent messages in the mailbox.
    #   * UNSEEN:: the number of unseen messages in the mailbox.
    #
    # The return value is a hash of attributes. For example:
    # ```
    #   p imap.status("inbox", ["MESSAGES", "RECENT"])
    #   #=> {"RECENT"=>0, "MESSAGES"=>44}
    #```
    def status(mailbox, attr : Array(String))
      param = "(#{attr.join(" ")})"
      res = command("STATUS", mailbox, param)
      vals = Hash(String, Int32).new
      counts = res[0].match(/\(([^)]+)\)/)
      if counts && counts[1]
        counts[1].scan(/\w+ \d+/) do |match|
          key, value = match[0].to_s.split(" ", 2)
          vals[key] = value.to_i
        end
      end
      return vals
    end

    private def process_mail_headers(res)
      ip = nil
      from = nil
      res.each do |line|
        if line =~ /^From:/
          from = line.sub(/^From: /, "")
        end
        if line =~ /^Received:/
          ips = line.match(/\[(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\]/)
          if ips
            ip = ips[1].to_s
          end
        end
        if ip && from
          @logger.info "from: #{from} ip: #{ip}"
          from = nil
          ip = nil
        end
      end
    end

    private def response
      status_messages = [] of String
      while (line = socket.gets)
        @command_history << line
        if line =~ /^\*/
          status_messages << line
        elsif line =~ /^tag OK/
          status_messages << line
          break
        elsif line =~ /^tag (BAD|NO)/
          raise "Invalid responce \"#{line}\" received."
        else
          status_messages << line
        end
      end
      status_messages
    end

    # Closes the imap connection
    def close
      command("LOGOUT")
    end
  end
end
