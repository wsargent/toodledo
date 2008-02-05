# -*- ruby -*-

require 'rubygems'
require 'hoe'
$:.unshift(File.dirname(__FILE__) + "/lib")
require 'toodledo'

Hoe.new('toodledo', Toodledo::VERSION) do |p|
  p.rubyforge_name = 'toodledo'
  p.author = 'Will Sargent'
  p.email = 'will@tersesystems.com'
  p.summary = 'A command line client and API to Toodledo'
  p.description = p.paragraphs_of('README.txt', 2..5).join("\n\n")
  p.url = p.paragraphs_of('README.txt', 0).first.split(/\n/)[1..-1]
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
  p.remote_rdoc_dir = '' # Release to root
  p.test_globs = 'test/**/*_test.rb'
  p.rsync_args << ' --exclude=statsvn/'
end

# vim: syntax=Ruby
