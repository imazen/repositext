require_relative '../helper'

describe Kramdown::Options do

  describe "it handles these options" do
    [
      [:disable_subtitle_mark, true],
      [:disable_gap_mark, true],
      [:disable_record_mark, true],
      [:validation_errors, [1,2,3]],
      [:validation_file_descriptor, 'descriptor'],
      [:validation_instance, 'Validation instance'],
      [:validation_warnings, [1,2,3]],
    ].each do |test_attrs|
      option_name, option_value = test_attrs
      it "handles #{ option_name }" do
        doc = Kramdown::Document.new("text", { :input => 'KramdownRepositext', option_name => option_value })
        doc.options[option_name].must_equal option_value
      end
    end

  end

end
