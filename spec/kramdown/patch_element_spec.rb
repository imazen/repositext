require_relative '../helper'

describe Kramdown::Element do

  describe "#inspect_tree" do
    it "prints a representation of element's tree" do
      doc = Kramdown::Document.new("para *one*{: .klass}\n\npara _two_", { :input => 'KramdownRepositext' })
      doc.root.inspect_tree.must_equal %( - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}
   - :p - {:location=>1}
     - :text - {:location=>1} - \"para \"
     - :em - {\"class\"=>\"klass\"} - {:location=>1, :ial=>{:refs=>[nil], \"class\"=>\"klass\"}}
       - :text - {:location=>1} - \"one\"
   - :blank - {:location=>3} - \"\\n\"
   - :p - {:location=>3}
     - :text - {:location=>3} - \"para \"
     - :em - {:location=>3}
       - :text - {:location=>3} - \"two\"
)
    end
  end

  describe '#is_of_same_type_as?' do
    [
      [[:em], [:em], true],
      [[:em], [:strong], false],
      [[:em, nil, { 'id' => 'id1' }], [:em, nil, { 'id' => 'id1' }], true],
      [[:em, nil, { 'id' => 'id1' }], [:em, nil, { 'id' => 'id2' }], true],
      [[:em, nil, { 'class' => 'class1' }], [:em, nil, { 'class' => 'class1' }], true],
      [[:em, nil, { 'class' => 'class1' }], [:em, nil, { 'class' => 'class2' }], false],
      [[:em, nil, nil, { :location => 'loc1' }], [:em, nil, nil, { :location => 'loc2' }], true],
      [[:em, nil, nil, { :input => 'in1' }], [:em, nil, nil, { :input => 'in2' }], false],
      [[:text, 'text1'], [:text, 'text2'], true]
    ].each_with_index do |(first_params, second_params, xpect), i|
      it "handles scenario #{ i + 1 }" do
        ke1 = Kramdown::Element.new(*first_params)
        ke2 = Kramdown::Element.new(*second_params)
        ke1.is_of_same_type_as?(ke2).must_equal xpect
        ke2.is_of_same_type_as?(ke1).must_equal xpect
      end
    end
  end

end
