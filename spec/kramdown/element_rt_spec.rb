require_relative '../helper'

module Kramdown
  describe ElementRt do

    describe "#parent" do
      it "responds to #parent" do
        e = ElementRt.new(:text)
        e.parent = 'parent'
        e.parent.must_equal 'parent'
      end
    end

    describe '#add_child' do
      it "adds a single ke as child" do
        r = ElementRt.new(:root)
        t = ElementRt.new(:text, 'text')
        r.add_child(t)
        r.children.must_equal [t]
      end
      it "adds an array of kes as children" do
        r = ElementRt.new(:root)
        t1 = ElementRt.new(:text, 'text1')
        t2 = ElementRt.new(:text, 'text2')
        r.add_child([t1, t2])
        r.children.must_equal [t1, t2]
      end
      it "adds a single child at_index" do
        r = ElementRt.new(:root)
        t1 = ElementRt.new(:text, 'text1')
        t2 = ElementRt.new(:text, 'text2')
        t3 = ElementRt.new(:text, 'text3')
        r.add_child([t1, t3])
        r.add_child(t2, 1)
        r.children.must_equal [t1, t2, t3]
      end
      it "adds an array of kes at_index" do
        r = ElementRt.new(:root)
        t1 = ElementRt.new(:text, 'text1')
        t2 = ElementRt.new(:text, 'text2')
        t3 = ElementRt.new(:text, 'text3')
        t4 = ElementRt.new(:text, 'text4')
        r.add_child([t1, t4])
        r.add_child([t2, t3], 1)
        r.children.must_equal [t1, t2, t3, t4]
      end
      it "raises if you try to add self as child" do
        r = ElementRt.new(:root)
        t1 = ElementRt.new(:text, 'text1')
        lambda { r.add_child([t1, r]) }.must_raise ArgumentError
      end
    end

    describe '#add_child_or_reuse_if_same' do
      it "uses other if different" do
        p = ElementRt.new(:em)
        c = ElementRt.new(:strong)
        r = p.add_child_or_reuse_if_same(c)
        r.must_equal c
      end
      it "adds other as child to self if different" do
        p = ElementRt.new(:em)
        c = ElementRt.new(:strong)
        p.add_child_or_reuse_if_same(c)
        c.parent.must_equal p
        p.children.must_equal [c]
      end
      it "reuses self is same" do
        em1 = ElementRt.new(:em)
        em2 = ElementRt.new(:em)
        r = em1.add_child_or_reuse_if_same(em2)
        r.must_equal em1
      end
    end

    describe '#detach_from_parent' do
      it "returns nil if ke has no parent" do
        r = ElementRt.new(:root)
        r.detach_from_parent.must_be(:nil?)
      end
      it "sets parent to nil" do
        r = ElementRt.new(:root)
        t1 = ElementRt.new(:text, 'text1')
        r.add_child(t1)
        t1.parent.must_equal r
        t1.detach_from_parent
        t1.parent.must_be(:nil?)
      end
      it "removes ke from parent's children collection" do
        r = ElementRt.new(:root)
        t1 = ElementRt.new(:text, 'text1')
        t2 = ElementRt.new(:text, 'text2')
        r.add_child([t1, t2])
        r.children.must_equal [t1, t2]
        t1.detach_from_parent
        r.children.must_equal [t2]
      end
      it "returns child index" do
        r = ElementRt.new(:root)
        t1 = ElementRt.new(:text, 'text1')
        t2 = ElementRt.new(:text, 'text2')
        r.add_child([t1, t2])
        t2.detach_from_parent.must_equal 1
        t1.detach_from_parent.must_equal 0
      end
    end

    describe '#following_sibling' do
      it "returns the following sibling" do
        r = ElementRt.new(:root)
        t1 = ElementRt.new(:text, 'text1')
        t2 = ElementRt.new(:text, 'text2')
        r.add_child([t1, t2])
        t1.following_sibling.must_equal t2
      end
      it "returns nil if ke has no parent" do
        r = ElementRt.new(:root)
        r.following_sibling.must_be(:nil?)
      end
      it "returns nil if ke is only child" do
        r = ElementRt.new(:root)
        t1 = ElementRt.new(:text, 'text1')
        r.add_child(t1)
        t1.following_sibling.must_be(:nil?)
      end
      it "returns nil if ke is the last child" do
        r = ElementRt.new(:root)
        t1 = ElementRt.new(:text, 'text1')
        t2 = ElementRt.new(:text, 'text2')
        r.add_child([t1, t2])
        t2.following_sibling.must_be(:nil?)
      end
    end

    describe '#insert_sibling_after' do
      it "inserts a sibling after ke" do
        r = ElementRt.new(:root)
        t1 = ElementRt.new(:text, 'text1')
        t2 = ElementRt.new(:text, 'text2')
        r.add_child(t1)
        t1.insert_sibling_after(t2)
        r.children.must_equal [t1, t2]
      end
      it "doesn't insert a sibling if ke has no parent" do
        r = ElementRt.new(:root)
        t1 = ElementRt.new(:text, 'text1')
        r.insert_sibling_after(t1).must_be(:nil?)
      end
      it "raises if you try to insert self as sibling after" do
        t1 = ElementRt.new(:text, 'text1')
        lambda { t1.insert_sibling_after(t1) }.must_raise ArgumentError
      end
    end

    describe '#insert_sibling_before' do
      it "inserts a sibling before ke" do
        r = ElementRt.new(:root)
        t1 = ElementRt.new(:text, 'text1')
        t2 = ElementRt.new(:text, 'text2')
        r.add_child(t2)
        t2.insert_sibling_before(t1)
        r.children.must_equal [t1, t2]
      end
      it "doesn't insert a sibling if ke has no parent" do
        r = ElementRt.new(:root)
        t1 = ElementRt.new(:text, 'text1')
        r.insert_sibling_before(t1).must_be(:nil?)
      end
      it "raises if you try to insert self as sibling after" do
        t1 = ElementRt.new(:text, 'text1')
        lambda { t1.insert_sibling_before(t1) }.must_raise ArgumentError
      end
    end

    describe '#is_only_child?' do
      it "returns true if ke is only child" do
        r = ElementRt.new(:root)
        t1 = ElementRt.new(:text, 'text1')
        r.add_child(t1)
        t1.is_only_child?.must_equal true
      end
      it "returns false if ke is not the only child" do
        r = ElementRt.new(:root)
        t1 = ElementRt.new(:text, 'text1')
        t2 = ElementRt.new(:text, 'text2')
        r.add_child([t1, t2])
        t1.is_only_child?.must_equal false
      end
      it "returns false if ke has no parent" do
        r = ElementRt.new(:root)
        r.is_only_child?.must_equal false
      end
    end

    describe '#own_child_index' do
      it "returns oci for children" do
        r = ElementRt.new(:root)
        t1 = ElementRt.new(:text, 'text1')
        t2 = ElementRt.new(:text, 'text2')
        t3 = ElementRt.new(:text, 'text3')
        r.add_child([t1, t2, t3])
        t1.own_child_index.must_equal 0
        t2.own_child_index.must_equal 1
        t3.own_child_index.must_equal 2
      end
    end

    describe '#previous_sibling' do
      it "returns the previous sibling" do
        r = ElementRt.new(:root)
        t1 = ElementRt.new(:text, 'text1')
        t2 = ElementRt.new(:text, 'text2')
        r.add_child([t1, t2])
        t2.previous_sibling.must_equal t1
      end
      it "returns nil if ke has no parent" do
        r = ElementRt.new(:root)
        r.previous_sibling.must_be(:nil?)
      end
      it "returns nil if ke is only child" do
        r = ElementRt.new(:root)
        t1 = ElementRt.new(:text, 'text1')
        r.add_child(t1)
        t1.previous_sibling.must_be(:nil?)
      end
      it "returns nil if ke is the first child" do
        r = ElementRt.new(:root)
        t1 = ElementRt.new(:text, 'text1')
        t2 = ElementRt.new(:text, 'text2')
        r.add_child([t1, t2])
        t1.previous_sibling.must_be(:nil?)
      end
    end

    describe '#replace_with' do
      it "replaces self with other" do
        r = ElementRt.new(:root)
        t1 = ElementRt.new(:text, 'text1')
        t2 = ElementRt.new(:text, 'text2')
        r.add_child(t1)
        t1.replace_with(t2)
        r.children.first.must_equal t2
        t1.parent.must_be(:nil?)
      end
      it "raises if you try to replace self with self" do
        r = ElementRt.new(:root)
        t1 = ElementRt.new(:text, 'text1')
        r.add_child(t1)
        lambda { t1.replace_with(t1) }.must_raise ArgumentError
      end
    end

  end
end
