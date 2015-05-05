require_relative '../helper'

module Kramdown
  describe Element do

    describe "#add_class" do
      it "adds a new class" do
        e = Element.new(:text, nil, 'class' => 'class1 class2')
        e.add_class('class3')
        e.has_class?('class3').must_equal true
      end
      it "doesn't add an existing class" do
        e = Element.new(:text, nil, 'class' => 'class1 class2')
        e.add_class('class1')
        e.attr['class'].must_equal 'class1 class2'
      end
      it "adds class to element that has no classes yet" do
        e = Element.new(:text)
        e.add_class('class1')
        e.attr['class'].must_equal 'class1'
      end
      it "strips whitespace from new class" do
        e = Element.new(:text)
        e.add_class('class1 ')
        e.attr['class'].must_equal 'class1'
      end
      it "orders classes alphabetically" do
        e = Element.new(:text, nil, 'class' => 'class2 class1')
        e.add_class('class3')
        e.attr['class'].must_equal 'class1 class2 class3'
      end
      it "ignores an empty added class" do
        e = Element.new(:text, nil, 'class' => 'class1')
        e.add_class(' ')
        e.attr['class'].must_equal 'class1'
      end
    end

    describe "#descendants" do
      it "returns children" do
        p = Element.new(:p)
        children = 5.times.map { Element.new(:text) }
        p.children = children
        p.descendants.must_equal children
      end

      it "returns grand children" do
        p = Element.new(:p)
        child = Element.new(:em)
        grand_children = 5.times.map { Element.new(:text) }
        p.children = [child]
        child.children = grand_children
        p.descendants.must_equal [child, grand_children].flatten
      end
    end

    describe "#has_class?" do
      it "returns true if it has class" do
        e = Element.new(:text, nil, 'class' => 'class1 class2')
        e.has_class?('class2').must_equal true
      end
      it "returns false if it doesn't have class" do
        e = Element.new(:text, nil, 'class' => 'class1 class2')
        e.has_class?('class3').must_equal false
      end
      it "strips whitepace from test class" do
        e = Element.new(:text, nil, 'class' => 'class1 class2')
        e.has_class?(' class1 ').must_equal true
      end
      it "handles multiple classes as argument (pos)" do
        e = Element.new(:text, nil, 'class' => 'class1')
        e.has_class?('class1 class2').must_equal true
      end
      it "handles multiple classes as argument (neg)" do
        e = Element.new(:text, nil, 'class' => 'class1')
        e.has_class?(' class2 class3').must_equal false
      end
    end

    describe "#inspect_tree" do
      it "prints a representation of element's tree" do
        doc = Document.new("para *one*{: .klass}\n\npara _two_", { :input => 'KramdownRepositext' })
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
          ke1 = Element.new(*first_params)
          ke2 = Element.new(*second_params)
          ke1.is_of_same_type_as?(ke2).must_equal xpect
          ke2.is_of_same_type_as?(ke1).must_equal xpect
        end
      end
    end

    describe "#remove_class" do
      it "removes an existing class" do
        e = Element.new(:text, nil, 'class' => 'class1 class2')
        e.remove_class('class2')
        e.has_class?('class2').must_equal false
      end
      it "doesn't remove a non-existing class" do
        e = Element.new(:text, nil, 'class' => 'class1 class2')
        e.remove_class('class3')
        e.attr['class'].must_equal 'class1 class2'
      end
      it "works with elements that have no classes" do
        e = Element.new(:text, nil)
        e.remove_class('class')
        e.attr['class'].must_equal ''
      end
      it "strips whitespace from removed class" do
        e = Element.new(:text, nil, 'class' => 'class1 class2')
        e.remove_class(' class2 ')
        e.has_class?('class2').must_equal false
      end
      it "doesn't remove partial class names" do
        e = Element.new(:text, nil, 'class' => 'normal_pn')
        e.remove_class('normal')
        e.has_class?('normal_pn').must_equal true
      end
    end

    describe "#to_plain_text" do
      it "converts an element and its descendants to plain text" do
        p = Element.new(:p)
        child = Element.new(:em)
        p.children = [child]
        grand_children = [
          Element.new(:text, 'word1 '),
          Element.new(:text, 'word2'),
        ]
        child.children = grand_children
        p.to_plain_text.must_equal("word1 word2\n")
      end
    end

  end
end
