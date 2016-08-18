#!/usr/bin/ruby
load '~/.bin/tmux/netrc.rb'
require 'net/imap'

servers = {
  #'mail.openminds.be' => { port: 143, ssl: false },
  'imap.telenet.be' => { port: 993, ssl: true },
}

netrc = Netrc.read("#{`echo $HOME`.gsub(/\n/, '')}/.netrc")
count = 0

servers.each { |server, options|
  user, pass = netrc[server]

  imap = Net::IMAP.new(server, options)
  imap.login(user, pass)
  imap.examine('Inbox')
  count += imap.search(['UNSEEN']).size
  imap.disconnect
}

puts count

#imap = Net::IMAP.new('imap.telenet.be')
#imap.login(user, pass)
#imap.examine('Inbox')
#imap.search(['NEW']).each do |message_id|
  #envelope = imap.fetch(message_id, "ENVELOPE")[0].attr["ENVELOPE"]
  #puts "#{envelope.from[0].name}: \t#{envelope.subject}"
#end
#imap.disconnect
