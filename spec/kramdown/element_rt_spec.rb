require_relative '../helper'

describe Kramdown::ElementRt do

  describe "#parent" do
    it "responds to #parent" do
      e = Kramdown::ElementRt.new(:text)
      e.parent = 'parent'
      e.parent.must_equal 'parent'
    end
  end

  describe '#add_child' do
    it "adds a single ke as child" do
      r = Kramdown::ElementRt.new(:root)
      t = Kramdown::ElementRt.new(:text, 'text')
      r.add_child(t)
      r.children.must_equal [t]
    end
    it "adds an array of kes as children" do
      r = Kramdown::ElementRt.new(:root)
      t1 = Kramdown::ElementRt.new(:text, 'text1')
      t2 = Kramdown::ElementRt.new(:text, 'text2')
      r.add_child([t1, t2])
      r.children.must_equal [t1, t2]
    end
    it "adds a single child at_index" do
      r = Kramdown::ElementRt.new(:root)
      t1 = Kramdown::ElementRt.new(:text, 'text1')
      t2 = Kramdown::ElementRt.new(:text, 'text2')
      t3 = Kramdown::ElementRt.new(:text, 'text3')
      r.add_child([t1, t3])
      r.add_child(t2, 1)
      r.children.must_equal [t1, t2, t3]
    end
    it "adds an array of kes at_index" do
      r = Kramdown::ElementRt.new(:root)
      t1 = Kramdown::ElementRt.new(:text, 'text1')
      t2 = Kramdown::ElementRt.new(:text, 'text2')
      t3 = Kramdown::ElementRt.new(:text, 'text3')
      t4 = Kramdown::ElementRt.new(:text, 'text4')
      r.add_child([t1, t4])
      r.add_child([t2, t3], 1)
      r.children.must_equal [t1, t2, t3, t4]
    end
    it "raises if you try to add self as child" do
      r = Kramdown::ElementRt.new(:root)
      t1 = Kramdown::ElementRt.new(:text, 'text1')
      lambda { r.add_child([t1, r]) }.must_raise ArgumentError
    end
  end

  describe '#add_child_or_reuse_if_same' do
    it "uses other if different" do
      p = Kramdown::ElementRt.new(:em)
      c = Kramdown::ElementRt.new(:strong)
      r = p.add_child_or_reuse_if_same(c)
      r.must_equal c
    end
    it "adds other as child to self if different" do
      p = Kramdown::ElementRt.new(:em)
      c = Kramdown::ElementRt.new(:strong)
      r = p.add_child_or_reuse_if_same(c)
      c.parent.must_equal p
      p.children.must_equal [c]
    end
    it "reuses self is same" do
      em1 = Kramdown::ElementRt.new(:em)
      em2 = Kramdown::ElementRt.new(:em)
      r = em1.add_child_or_reuse_if_same(em2)
      r.must_equal em1
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

  describe '#detach_from_parent' do
    it "returns nil if ke has no parent" do
      r = Kramdown::ElementRt.new(:root)
      r.detach_from_parent.must_equal nil
    end
    it "sets parent to nil" do
      r = Kramdown::ElementRt.new(:root)
      t1 = Kramdown::ElementRt.new(:text, 'text1')
      r.add_child(t1)
      t1.parent.must_equal r
      t1.detach_from_parent
      t1.parent.must_equal nil
    end
    it "removes ke from parents children collection" do
      r = Kramdown::ElementRt.new(:root)
      t1 = Kramdown::ElementRt.new(:text, 'text1')
      t2 = Kramdown::ElementRt.new(:text, 'text2')
      r.add_child([t1, t2])
      r.children.must_equal [t1, t2]
      t1.detach_from_parent
      r.children.must_equal [t2]
    end
    it "returns child index" do
      r = Kramdown::ElementRt.new(:root)
      t1 = Kramdown::ElementRt.new(:text, 'text1')
      t2 = Kramdown::ElementRt.new(:text, 'text2')
      r.add_child([t1, t2])
      t2.detach_from_parent.must_equal 1
      t1.detach_from_parent.must_equal 0
    end
  end

  describe '#following_sibling' do
    it "returns the following sibling" do
      r = Kramdown::ElementRt.new(:root)
      t1 = Kramdown::ElementRt.new(:text, 'text1')
      t2 = Kramdown::ElementRt.new(:text, 'text2')
      r.add_child([t1, t2])
      t1.following_sibling.must_equal t2
    end
    it "returns nil if ke has no parent" do
      r = Kramdown::ElementRt.new(:root)
      r.following_sibling.must_equal nil
    end
    it "returns nil if ke is only child" do
      r = Kramdown::ElementRt.new(:root)
      t1 = Kramdown::ElementRt.new(:text, 'text1')
      r.add_child(t1)
      t1.following_sibling.must_equal nil
    end
    it "returns nil if ke is the last child" do
      r = Kramdown::ElementRt.new(:root)
      t1 = Kramdown::ElementRt.new(:text, 'text1')
      t2 = Kramdown::ElementRt.new(:text, 'text2')
      r.add_child([t1, t2])
      t2.following_sibling.must_equal nil
    end
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

  describe '#insert_sibling_after' do
    it "inserts a sibling after ke" do
      r = Kramdown::ElementRt.new(:root)
      t1 = Kramdown::ElementRt.new(:text, 'text1')
      t2 = Kramdown::ElementRt.new(:text, 'text2')
      r.add_child(t1)
      t1.insert_sibling_after(t2)
      r.children.must_equal [t1, t2]
    end
    it "doesn't insert a sibling if ke has no parent" do
      r = Kramdown::ElementRt.new(:root)
      t1 = Kramdown::ElementRt.new(:text, 'text1')
      r.insert_sibling_after(t1).must_equal nil
    end
    it "raises if you try to insert self as sibling after" do
      r = Kramdown::ElementRt.new(:root)
      t1 = Kramdown::ElementRt.new(:text, 'text1')
      lambda { t1.insert_sibling_after(t1) }.must_raise ArgumentError
    end
  end

  describe '#insert_sibling_before' do
    it "inserts a sibling before ke" do
      r = Kramdown::ElementRt.new(:root)
      t1 = Kramdown::ElementRt.new(:text, 'text1')
      t2 = Kramdown::ElementRt.new(:text, 'text2')
      r.add_child(t2)
      t2.insert_sibling_before(t1)
      r.children.must_equal [t1, t2]
    end
    it "doesn't insert a sibling if ke has no parent" do
      r = Kramdown::ElementRt.new(:root)
      t1 = Kramdown::ElementRt.new(:text, 'text1')
      r.insert_sibling_before(t1).must_equal nil
    end
    it "raises if you try to insert self as sibling after" do
      r = Kramdown::ElementRt.new(:root)
      t1 = Kramdown::ElementRt.new(:text, 'text1')
      lambda { t1.insert_sibling_before(t1) }.must_raise ArgumentError
    end
  end

  describe '#is_only_child?' do
    it "returns true if ke is only child" do
      r = Kramdown::ElementRt.new(:root)
      t1 = Kramdown::ElementRt.new(:text, 'text1')
      r.add_child(t1)
      t1.is_only_child?.must_equal true
    end
    it "returns false if ke is not the only child" do
      r = Kramdown::ElementRt.new(:root)
      t1 = Kramdown::ElementRt.new(:text, 'text1')
      t2 = Kramdown::ElementRt.new(:text, 'text2')
      r.add_child([t1, t2])
      t1.is_only_child?.must_equal false
    end
    it "returns false if ke has no parent" do
      r = Kramdown::ElementRt.new(:root)
      r.is_only_child?.must_equal false
    end
  end

  describe '#own_child_index' do
    it "returns oci for children" do
      r = Kramdown::ElementRt.new(:root)
      t1 = Kramdown::ElementRt.new(:text, 'text1')
      t2 = Kramdown::ElementRt.new(:text, 'text2')
      t3 = Kramdown::ElementRt.new(:text, 'text3')
      r.add_child([t1, t2, t3])
      t1.own_child_index.must_equal 0
      t2.own_child_index.must_equal 1
      t3.own_child_index.must_equal 2
    end
  end

  describe '#previous_sibling' do
    it "returns the previous sibling" do
      r = Kramdown::ElementRt.new(:root)
      t1 = Kramdown::ElementRt.new(:text, 'text1')
      t2 = Kramdown::ElementRt.new(:text, 'text2')
      r.add_child([t1, t2])
      t2.previous_sibling.must_equal t1
    end
    it "returns nil if ke has no parent" do
      r = Kramdown::ElementRt.new(:root)
      r.previous_sibling.must_equal nil
    end
    it "returns nil if ke is only child" do
      r = Kramdown::ElementRt.new(:root)
      t1 = Kramdown::ElementRt.new(:text, 'text1')
      r.add_child(t1)
      t1.previous_sibling.must_equal nil
    end
    it "returns nil if ke is the first child" do
      r = Kramdown::ElementRt.new(:root)
      t1 = Kramdown::ElementRt.new(:text, 'text1')
      t2 = Kramdown::ElementRt.new(:text, 'text2')
      r.add_child([t1, t2])
      t1.previous_sibling.must_equal nil
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

  describe '#replace_with' do
    it "replaces self with other" do
      r = Kramdown::ElementRt.new(:root)
      t1 = Kramdown::ElementRt.new(:text, 'text1')
      t2 = Kramdown::ElementRt.new(:text, 'text2')
      r.add_child(t1)
      t1.replace_with(t2)
      r.children.first.must_equal t2
      t1.parent.must_equal nil
    end
    it "raises if you try to replace self with self" do
      r = Kramdown::ElementRt.new(:root)
      t1 = Kramdown::ElementRt.new(:text, 'text1')
      r.add_child(t1)
      lambda { t1.replace_with(t1) }.must_raise ArgumentError
    end
  end

end
