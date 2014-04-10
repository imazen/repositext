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

# Returns an absolute path to test_data_sub_path. Base for the relative path is
# repositext-kramdown/test_data
# @param[String] test_data_sub_path
# @return[String] absolute path based on test_data_sub_path.
def get_test_data_path_for(test_data_sub_path)
  File.expand_path(File.dirname(__FILE__) + "/../test_data/#{ test_data_sub_path }")
end
