# dependencies
require 'rubygems'
require 'fakefs/safe'
require 'minitest'
require 'minitest/autorun'

# Gem under test
require 'repositext-kramdown'

include FakeFS
# NOTE: Use these two callbacks in your specs to activate FakeFS:
# before do
#   FakeFS.activate!
#   FileSystem.clear
# end
# after do
#   FakeFS.deactivate!
# end
