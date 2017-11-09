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
# @param [String] test_data_sub_path
# @return [String] absolute path based on test_data_sub_path.
def get_test_data_path_for(test_data_sub_path)
  File.expand_path("../test_data/#{ test_data_sub_path }", __dir__)
end

# Initializes a validation for test purposes with some common options set.
# @param [String] validation_class_name the class name of the validation
# @param [String] file_specs the file specs required for validation as hash
#     * keys: name of file_spec
#     * val: Array of base_dir, file_selector and file_extension as strings
# @param [Hash] options with symbolized keys
def initialize_test_validation(validation_class_name, file_specs, options)
  options = { :logger => 'LoggerTest' }.merge(options)
  Object.const_get("Repositext::Validation::#{ validation_class_name }").new(file_specs, options)
end

# Returns an Instance of RFile::ContentAt
# @param attr_overrides [Hash]
#   :contents
#   :filename
#   :language
#   :content_type provide a ContentType, or set to `true` to have default ct assigned
#   :sub_class Provide RFile subclass name as string. Defaults to `ContentAt`
def get_r_file(attr_overrides={})
  content_type = case attr_overrides[:content_type]
  when true
    # Create test content_type
    path_to_repo = Repositext::Repository::Test.create!('rt-english').first
    Repositext::ContentType.new(File.join(path_to_repo, 'ct-general'))
  when Repositext::ContentType
    # Use as is
    attr_overrides[:content_type]
  else
    # No content_type given
    nil
  end
  r_file_class_name = "Repositext::RFile::#{ attr_overrides[:sub_class] || 'ContentAt' }"
  attrs = [
    attr_overrides[:contents] || "# Title\n\nParagraph 1",
    attr_overrides[:language] || Repositext::Language::English.new,
    attr_overrides[:filename] || '/path-to/rt-english/ct-general/content/57/eng57-0103_1234.at',
    content_type,
  ].compact
  Object.const_get(r_file_class_name).new(*attrs)
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


# *********************************************
#
# StringIO that behaves like a file. Used to simulate files in specs
# Use like so:
#
#     FileLikeStringIO.new('/io/path', 'IO contents')
#
# or
#
#     FileLikeStringIO.new('/io/path', 'IO contents', 'w+')
#
# *********************************************

class FileLikeStringIO < StringIO

  attr_accessor :path

  # @param []
  def initialize(path, *args)
    super(*args)
    @path = path
  end

end
