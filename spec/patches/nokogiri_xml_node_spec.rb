require_relative '../helper'

module Nokogiri
  module XML
    describe Node do

      let(:default_div_node){
        n = Node.new('div', Document.new)
        n['type'] = 1 # ELEMENT_NODE
        n
      }

      describe '#add_class' do
        it 'adds initial class' do
          default_div_node.add_class('the_class')
          default_div_node.class_names.must_equal(['the_class'])
        end
        it 'adds subsequent classes' do
          default_div_node.add_class('the_class')
          default_div_node.add_class('the_other_class')
          default_div_node.class_names.must_equal(['the_class', 'the_other_class'])
        end
        it 'ignores duplicates' do
          default_div_node.add_class('the_class')
          default_div_node.add_class('the_class')
          default_div_node.class_names.must_equal(['the_class'])
        end
      end

      describe '#class_names' do
        it 'returns class names' do
          default_div_node.add_class('the_class')
          default_div_node.add_class('the_other_class')
          default_div_node.class_names.must_equal(['the_class', 'the_other_class'])
        end
      end

      describe '#duplicate_of?' do
        it 'returns true if two nodes have same name, class, and type' do
          default_div_node.add_class('the_class')
          n2 = Node.new('div', Document.new)
          n2.add_class('the_class')
          n2['type'] = 1
          default_div_node.duplicate_of?(n2).must_equal(true)
        end
        it 'returns false if two nodes have same name, class, but different type' do
          default_div_node.add_class('the_class')
          n2 = Node.new('div', Document.new)
          n2.add_class('the_class')
          n2['type'] = 2
          default_div_node.duplicate_of?(n2).must_equal(false)
        end
        it 'returns false if two nodes have same name, different class, same type' do
          default_div_node.add_class('the_class')
          n2 = Node.new('div', Document.new)
          n2.add_class('the_other_class')
          n2['type'] = 1
          default_div_node.duplicate_of?(n2).must_equal(false)
        end
        it 'returns false if two nodes have different name, same class, same type' do
          default_div_node.add_class('the_class')
          n2 = Node.new('p', Document.new)
          n2.add_class('the_class')
          n2['type'] = 1
          default_div_node.duplicate_of?(n2).must_equal(false)
        end
        it 'returns false if class or type are blank' do
          n2 = Node.new('div', Document.new)
          n2['type'] = 1
          default_div_node.duplicate_of?(n2).must_equal(false)
        end
      end

      describe '#has_class?' do
        it 'returns true if node has class' do
          default_div_node.add_class('the_class')
          default_div_node.has_class?('the_class').must_equal(true)
        end
        it 'returns false if node does not have class' do
          default_div_node.add_class('the_class')
          default_div_node.has_class?('the_other_class').must_equal(false)
        end
      end

      describe '#name_and_class_path' do
        it 'returns the name and class path' do
          default_div_node.add_class('the_class')
          default_div_node.name_and_class_path.must_equal('div.the_class')
        end
      end

      describe '#name_and_class' do
        it 'returns the name and class' do
          default_div_node.add_class('the_class')
          default_div_node.name_and_class_path.must_equal('div.the_class')
        end
      end

      describe '#remove_class' do
        it 'removes the existing class' do
          default_div_node.add_class('the_class')
          default_div_node.remove_class('the_class')
          default_div_node.class_names.must_equal([])
        end
        it 'ignores a non-existing class' do
          default_div_node.add_class('the_class')
          default_div_node.remove_class('the__other_class')
          default_div_node.class_names.must_equal(['the_class'])
        end
      end

      describe '#wrap_in' do
        it 'wraps self in other xn' do
          default_div_node.add_class('the_class')
          new_parent_node = Node.new('div', Document.new)
          new_parent_node.add_class('parent_class')
          default_div_node.wrap_in(new_parent_node)
          default_div_node.name_and_class_path.must_equal(
            'div.parent_class > div.the_class')
        end
      end

    end
  end
end
