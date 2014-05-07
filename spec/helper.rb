# dependencies
require 'rubygems'
require 'fakefs/safe'
require 'minitest'
require 'minitest/autorun'

# Gem under test
require 'repositext'

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
# repositext/test_data
# @param[String] test_data_sub_path
# @return[String] absolute path based on test_data_sub_path.
def get_test_data_path_for(test_data_sub_path)
  File.expand_path(File.dirname(__FILE__) + "/../test_data/#{ test_data_sub_path }")
end

# Initializes a validation for test purposes with some common options set.
# @param[String] validation_class_name the class name of the validation
# @param[String] file_specs the file specs required for validation as hash
#     * keys: name of file_spec
#     * val: Array of base_dir and file_pattern as strings
# @param[Hash] options with symbolized keys
def initialize_test_validation(validation_class_name, file_specs, options)
  options = { :logger => 'LoggerTest' }.merge(options)
  Object.const_get("Repositext::Validation::#{ validation_class_name }").new(file_specs, options)
end
