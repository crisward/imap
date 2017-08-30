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
  imap.select(mailbox)
  status = imap.status(mailbox, ["MESSAGES", "UNSEEN"])
  puts "There are #{status["MESSAGES"]} message in #{mailbox} #{status["UNSEEN"]} unread."
end
imap.close
```

## Testing

Need to start writing tests.
* https://github.com/ruby/ruby/tree/ruby_2_4/test/net/imap for inspiration

## Contributing

1. Fork it ( https://github.com/crisward/imap/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [crisward](https://github.com/crisward) Cris Ward - creator, maintainer
