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

    private def command(command : String, parameter : String? = nil)
      command_and_parameter = command
      command_and_parameter += " " + parameter if parameter
      @command_history << command_and_parameter
      @logger.info "=====> #{command_and_parameter}"
      socket << command_and_parameter << "\r\n"
      socket.flush
      response
    end

    private def login(username, password)
      command("tag login #{username} #{password}")
    end

    # sets the current mailbox
    def set_mailbox(mailbox)
      @mailbox = mailbox
      command("tag SELECT #{mailbox}")
    end

    # Returns an array of mailbox names
    def get_mailboxes : Array(String)
      mailboxes = [] of String
      res = command(%{tag LIST "" "*"})
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
      res = command("tag STATUS #{mailbox} (MESSAGES)")
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
      command("tag LOGOUT")
    end
  end
end
