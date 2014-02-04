require_relative '../helper'

describe Kramdown::ElementRt do

  describe "#parent" do
    it "responds to #parent" do
      e = Kramdown::ElementRt.new(:text)
      e.parent = 'parent'
      e.parent.must_equal 'parent'
    end
  end

  describe "#add_children" do
    # def add_children(the_children)
    #   the_children.each { |e| e.parent = self }
    #   self.children += the_children
    # end
    # # @param[Kramdown::Element] the_child
    # def add_child(the_child); add_children([the_child]); end
  end

  describe "#has_class?" do
    it "returns true if it has class" do
      e = Kramdown::ElementRt.new(:text, nil, 'class' => 'class1 class2')
      e.has_class?('class2').must_equal true
    end
    it "returns false if it doesn't have class" do
      e = Kramdown::ElementRt.new(:text, nil, 'class' => 'class1 class2')
      e.has_class?('class3').must_equal false
    end
  end

  describe "#add_class" do
    it "adds a new class" do
      e = Kramdown::ElementRt.new(:text, nil, 'class' => 'class1 class2')
      e.add_class('class3')
      e.has_class?('class3').must_equal true
    end
    it "doesn't add an existing class" do
      e = Kramdown::ElementRt.new(:text, nil, 'class' => 'class1 class2')
      e.add_class('class1')
      e.attr['class'].must_equal 'class1 class2'
    end
    it "adds class to element that has no classes yet" do
      e = Kramdown::ElementRt.new(:text)
      e.add_class('class1')
      e.attr['class'].must_equal 'class1'
    end
  end

  describe "#remove_class" do
    it "removes an existing class" do
      e = Kramdown::ElementRt.new(:text, nil, 'class' => 'class1 class2')
      e.remove_class('class2')
      e.has_class?('class2').must_equal false
    end
    it "doesn't remove a non-existing class" do
      e = Kramdown::ElementRt.new(:text, nil, 'class' => 'class1 class2')
      e.remove_class('class3')
      e.attr['class'].must_equal 'class1 class2'
    end
  end

end
