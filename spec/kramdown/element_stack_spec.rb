require_relative '../helper'

module Kramdown
  describe ElementStack do

    let(:element_stack){ ElementStack.new }
    let(:id_title1_paragraph){ Element.new(:p, nil, 'class' => 'id_title1') }
    let(:id_title2_paragraph){ Element.new(:p, nil, 'class' => 'id_title2') }
    let(:normal_paragraph){ Element.new(:p, nil, 'class' => 'normal') }
    let(:title_header){ Element.new(:header, nil) }

    describe "stack methods" do
      it "responds to #push" do
        element_stack.must_respond_to(:push)
      end

      it "responds to #pop" do
        element_stack.must_respond_to(:pop)
      end
    end

    describe "#inside_id_title1?" do
      it "detects positive" do
        element_stack.push(id_title1_paragraph)
        element_stack.inside_id_title1?.must_equal(id_title1_paragraph)
      end

      it "detects negative" do
        element_stack.push(normal_paragraph)
        element_stack.inside_id_title1?.must_equal(nil)
      end
    end

    describe "#inside_id_title2?" do
      it "detects positive" do
        element_stack.push(id_title2_paragraph)
        element_stack.inside_id_title2?.must_equal(id_title2_paragraph)
      end

      it "detects negative" do
        element_stack.push(normal_paragraph)
        element_stack.inside_id_title2?.must_equal(nil)
      end
    end

    describe "#inside_title?" do
      it "detects positive" do
        element_stack.push(title_header)
        element_stack.inside_title?.must_equal(title_header)
      end

      it "detects negative" do
        element_stack.push(normal_paragraph)
        element_stack.inside_title?.must_equal(nil)
      end
    end

  end
end
