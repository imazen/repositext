require_relative '../helper.rb'

module Kramdown
  describe TreeStructureExtractor do

    let(:tree_structure_extractor) {
      Kramdown::TreeStructureExtractor.new(nil)
    }

    KRAMDOWN_TEST_STRING = %(^^^ {: .rid #rid-1}

# *Heading*

^^^ {: .rid #rid-2}

@word word word @word word word
{: .normal}

@*2*{: .pn} @word word *word* @word word word
{: .normal_pn}

@word word word
{: .normal}

^^^ {: .rid #rid-3}

@*3*{: .pn} @word word word @word word word
{: .normal_pn}

@*4*{: .pn} @word word word @word word word
{: .normal_pn}

)

    describe '#compute_character_count' do

      [
        ["some simple text with 37 characters\n\n", 37],
        ["text with multibyte char\n\n", 26],
        [KRAMDOWN_TEST_STRING, 335],
      ].each do |test_string, xpect|

        it "computes #{ test_string.inspect }" do
          kramdown_doc = Kramdown::Document.new(
            test_string,
            input: 'KramdownRepositext'
          )
          tree_structure_extractor.send(
            :compute_character_count, kramdown_doc
          ).must_equal(xpect)
        end

      end

    end

    describe '#compute_paragraph_count' do

      [
        ["a doc with 3 paragraphs\n\npara 2\n\npara 3\n\n", 3],
        [KRAMDOWN_TEST_STRING, 5]
      ].each do |test_string, xpect|

        it "computes #{ test_string.inspect }" do
          kramdown_doc = Kramdown::Document.new(
            test_string,
            input: 'KramdownRepositext'
          )
          tree_structure_extractor.send(
            :compute_paragraph_count, kramdown_doc
          ).must_equal(xpect)
        end

      end

    end

    describe '#compute_paragraph_numbers' do

      [
        [
          "*1*{: .pn} para 1\n{: .normal_pn}\n\n*2*{: .pn} para 2\n{: .normal_pn}\n\n",
          [{:paragraph_number=>"1", :line=>1}, {:paragraph_number=>"2", :line=>4}]
        ],
        [
          KRAMDOWN_TEST_STRING,
          [{:paragraph_number=>"header", :line=>3}, {:paragraph_number=>"no_number", :line=>7}, {:paragraph_number=>"2", :line=>10}, {:paragraph_number=>"no_number", :line=>13}, {:paragraph_number=>"3", :line=>18}, {:paragraph_number=>"4", :line=>21}]
        ],
        [
          "*1*{: .pn} para 1 with song class\n{: .song}\n\n",
          [{:paragraph_number=>"1", :line=>1}]
        ],
      ].each do |test_string, xpect|

        it "computes #{ test_string.inspect }" do
          kramdown_doc = Kramdown::Document.new(
            test_string,
            input: 'KramdownRepositext'
          )
          tree_structure_extractor.send(
            :compute_paragraph_numbers, kramdown_doc
          ).must_equal(xpect)
        end

      end

    end

    describe '#compute_subtitle_count' do

      [
        ["@some @simple @text @with @6 @subtitle_marks", 6],
        [KRAMDOWN_TEST_STRING, 12]
      ].each do |test_string, xpect|

        it "computes #{ test_string.inspect }" do
          kramdown_doc = Kramdown::Document.new(
            test_string,
            input: 'KramdownRepositext'
          )
          tree_structure_extractor.send(
            :compute_subtitle_count, kramdown_doc
          ).must_equal(xpect)
        end

      end

    end

  end
end
