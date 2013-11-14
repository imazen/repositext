# -*- encoding: utf-8 -*-
require 'kramdown/options'

# We need to define options since Kramdown currently discards any unknown options
# in Kramdown::Options.merge.
# This may change in the future.
module Kramdown::Options
  define(:disable_subtitle_mark, Boolean, false, "Some documentation for the option")
  define(:disable_gap_mark, Boolean, false, "Some documentation for the option")
  define(:disable_record_mark, Boolean, false, "Some documentation for the option")
  define(:output_file_name, String, '', "Some documentation for the option")
  define(:validation_errors, Object, nil, "Some documentation for the option") { |v| v }
  define(:validation_file_descriptor, String, '', "Some documentation for the option")
  define(:validation_instance, Object, nil, "Some documentation for the option") { |v| v }
  define(:validation_warnings, Object, nil, "Some documentation for the option") { |v| v }
end
