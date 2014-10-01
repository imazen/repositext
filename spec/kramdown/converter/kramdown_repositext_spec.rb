require_relative '../../helper'

module Kramdown
  module Converter
    describe KramdownRepositext do

      describe '#convert_text' do

        [
          ['Does not escape colons 1', "look at this: here it is", "look at this: here it is\n\n"],
          ['Does not escape colons 2 (in text node after em, which is beginning of line for regex, as used for definition lists)', "look at *this*: here it is", "look at *this*: here it is\n\n"],
          ['Does not escape brackets', "this is [in brackets]", "this is [in brackets]\n\n"],
          ['Does not escape backticks', "this is `in backticks`", "this is `in backticks`\n\n"],
          ['Does not escape single quotes', "this is 'in single quotes'", "this is 'in single quotes'\n\n"],
          ['Does not escape double quotes', "this is \"in double quotes\"", "this is \"in double quotes\"\n\n"],
          ['Escapes double dollars', "this has $$ double dollars", "this has \\$$ double dollars\n\n"],
          ['Escapes backslash', "this has \\ backslash", "this has \\\\ backslash\n\n"],
          ['Escapes asterisk', "this has * asterisk", "this has \\* asterisk\n\n"],
          ['Escapes underscore', "this has _ underscore", "this has \\_ underscore\n\n"],
          ['Escapes curly brace', "this has { curly brace", "this has \\{ curly brace\n\n"],
        ].each do |(desc, test_string, xpect)|
          it desc do
            doc = Document.new(test_string, :input => 'KramdownRepositext')
            doc.to_kramdown_repositext.must_equal xpect
          end
        end

      end

    end
  end
end
