# dependencies
require 'rubygems'
require 'minitest/autorun'
require 'fakefs/safe'

# Gem under test
require 'repositext'

include FakeFS
# NOTE: Use these two callbacks in your specs to activate FakeFS:
# before do
#   FakeFS.activate!
#   FakeFS::FileSystem.clear
# end
# after do
#   FakeFS.deactivate!
#   FakeFS::FileSystem.clear
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


# *********************************************
#
# Shared spec behaviors
#
# *********************************************

# Patch Module to implement 'it' (for shared behaviors)
class Module
  def it(description, &block)
    define_method "test_#{description}", &block
  end
end

# Require all shared behaviors
# `include` them in each spec file they apply to
require_relative 'shared_spec_behaviors/validators'
require_relative 'shared_spec_behaviors/validations'



# *********************************************
#
# StringIO that behaves like a file. Used to simulate files in specs
#
# *********************************************

class FileLikeStringIO < StringIO

  attr_accessor :path

  # @param[]
  def initialize(path, *args)
    super(*args)
    @path = path
  end

end
