require_relative '../helper'

describe Kramdown::Element do

  describe "inspect_tree" do
    it "prints a representation of element's tree" do
      doc = Kramdown::Document.new("para *one*\n\npara _two_", { :input => 'KramdownRepositext' })
      doc.root.inspect_tree.must_equal %( - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}
   - :p - {:location=>1}
     - :text - {:location=>1} - \"para \"
     - :em - {:location=>1}
       - :text - {:location=>1} - \"one\"
   - :blank - {:location=>3} - \"\\n\"
   - :p - {:location=>3}
     - :text - {:location=>3} - \"para \"
     - :em - {:location=>3}
       - :text - {:location=>3} - \"two\"
)
    end
  end

end
