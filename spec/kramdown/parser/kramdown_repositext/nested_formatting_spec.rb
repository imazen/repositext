require_relative '../../../helper'

module Kramdown
  module Parser
    class KramdownRepositext
      describe 'Nested formatting' do

        it "handles nested formatting" do
          doc = Document.new(
            "*this is italic and **this is bold italic** and this is italic*",
            { :input => 'KramdownRepositext' }
          )
          doc.root.inspect_tree.must_equal(
            %( - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}
                 - :p - {:location=>1}
                   - :em - {:location=>1}
                     - :text - {:location=>1} - \"this is italic and \"
                     - :strong - {:location=>1}
                       - :text - {:location=>1} - \"this is bold italic\"
                     - :text - {:location=>1} - \" and this is italic\"
              ).gsub(/\n              /, "\n")
          )
        end

      end
    end
  end
end
