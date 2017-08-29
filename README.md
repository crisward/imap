# imap

A very much WIP imap library for crystal.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  imap:
    github: crisward/imap
```

## Usage

```crystal
require "imap"

imap = Imap::Client.new(host: "imap.gmail.com", port: 993, username: "email@gmail.com", password: "*******")
mailboxes = imap.get_mailboxes
if mailboxes.size > 0
  mailbox = mailboxes[0]
  imap.set_mailbox(mailbox)
  message_count = imap.get_message_count
  puts "There are #{message_count} message in #{mailbox}"
end
imap.close
```

## Contributing

1. Fork it ( https://github.com/crisward/imap/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [crisward](https://github.com/crisward) Cris Ward - creator, maintainer
