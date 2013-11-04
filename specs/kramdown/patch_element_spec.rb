require_relative '../helper'

describe Kramdown::Element do

  describe "inspect_tree" do
    it "prints a representation of element's tree" do
      doc = Kramdown::Document.new("para *one*\n\npara _two_", { :input => :repositext })
      lambda { doc.root.inspect_tree }.must_output %( - :root - {:encoding=>#<Encoding:UTF-8>, :abbrev_defs=>{}}
   - :p
     - :text - "para "
     - :em
       - :text - "one"
   - :blank - "\\n"
   - :p
     - :text - "para "
     - :em
       - :text - "two"
)
    end
  end

end
