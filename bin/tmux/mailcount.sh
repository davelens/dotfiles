#!/usr/bin/ruby
load '~/.bin/tmux/netrc.rb'
require 'net/imap'

# You can add multiple servers here as you see fit.
servers = {
  'imap.telenet.be' => { port: 993, ssl: true },
}

netrc = Netrc.read("#{`echo ${HOME}`.gsub(/\n/, '')}/.netrc")
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
