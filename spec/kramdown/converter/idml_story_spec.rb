require_relative '../../helper'

module Kramdown
  module Converter
    describe IdmlStory do

      # Generates a ParagraphStyleRange node.
      # @param[Hash] attrs
      #     * :ps Paragraph style name
      #     * :cs Character style name
      #     * :content Content element inner text
      def psr_node(attrs)
        attrs = {
          :ps => 'Normal',
          :cs => 'Regular',
          :content => 'the text'
        }.merge(attrs)
        %(
          <ParagraphStyleRange AppliedParagraphStyle="ParagraphStyle/#{ attrs[:ps] }">
            <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/#{ attrs[:cs] }">
              <Content>#{ attrs[:content] }</Content>
            </CharacterStyleRange>
          </ParagraphStyleRange>
        ).strip.gsub(/          /, '') + "\n"
      end

      it "wraps text in paragraph and character style ranges" do
        doc = Document.new("the text", :input => 'KramdownRepositext')
        doc.to_idml_story.must_equal psr_node({})
      end

      describe '#convert_header' do

        [
          ['Converts level 1', '# the text', { :ps => 'Header' }],
          ['Converts level 2', '## the text', { :ps => 'Header' }],
          ['Converts level 3', '### the text', { :ps => 'Header' }],
        ].each do |test_attrs|
          desc, test_string, expect = *test_attrs
          it desc do
            doc = Document.new(test_string, :input => 'KramdownRepositext')
            doc.to_idml_story.must_equal psr_node(expect)
          end
        end

      end

      describe '#convert_p' do

        [
          ['Handles without class', "the text", { :ps => 'Normal', :content => "the text" }],
          ['Handles class .normal', "the text\n{:.normal}", { :ps => 'Normal', :content => "the text" }],
        ].each do |test_attrs|
          desc, test_string, expect = *test_attrs
          it desc do
            doc = Document.new(test_string, :input => 'KramdownRepositext')
            doc.to_idml_story.must_equal psr_node(expect)
          end
        end

      end

      [
        "the text\n\n***",
        "the text\n\n* * *"
      ].each do |source_kramdown|
        it "converts :hr" do
          doc = Document.new(source_kramdown, :input => 'KramdownRepositext')
          doc.to_idml_story.must_equal %(
            <ParagraphStyleRange AppliedParagraphStyle="ParagraphStyle/Normal">
              <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Regular">
                <Content>the text</Content>
                <Br />
              </CharacterStyleRange>
            </ParagraphStyleRange>
            <ParagraphStyleRange AppliedParagraphStyle="ParagraphStyle/Horizontal rule">
              <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Regular">
                <Content>* * *</Content>
              </CharacterStyleRange>
            </ParagraphStyleRange>
          ).strip.gsub(/            /, '') + "\n"
        end
      end

      it "converts :br" do
        doc = Document.new("first  \nsecond", :input => 'KramdownRepositext')
        doc.to_idml_story.must_equal %(
          <ParagraphStyleRange AppliedParagraphStyle="ParagraphStyle/Normal">
            <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Regular">
              <Content>first</Content>
              <Content>\u2028</Content>
              <Content> second</Content>
            </CharacterStyleRange>
          </ParagraphStyleRange>
        ).strip.gsub(/          /, '') + "\n"
      end

      describe '#paragraph_style_range_tag' do

        it "handles adjacent paragraphs with different attrs" do
          doc = Document.new("para 1\n{:.style1}\n\npara 2\n{:.test_class}", :input => 'KramdownRepositext')
          doc.to_idml_story.must_equal %(
            <ParagraphStyleRange AppliedParagraphStyle=\"ParagraphStyle/Normal\">
              <CharacterStyleRange AppliedCharacterStyle=\"CharacterStyle/Regular\">
                <Content>para 1</Content>
                <Br />
              </CharacterStyleRange>
            </ParagraphStyleRange>
            <ParagraphStyleRange AppliedParagraphStyle=\"ParagraphStyle/NormalTest\">
              <CharacterStyleRange AppliedCharacterStyle=\"CharacterStyle/Regular\">
                <Content>para 2</Content>
              </CharacterStyleRange>
            </ParagraphStyleRange>
          ).strip.gsub(/            /, '') + "\n"
        end

        it "merges text from adjacent paragraphs with identical attrs" do
          doc = Document.new("para 1\n{:.style1}\n\npara 2\n{:.style1}", :input => 'KramdownRepositext')
          # NOTE: because we insert leading tabs before we merge paras, there are two tabs here.
          # I consider this a pretty edge case, however it may be an issue that
          # needs to be addressed.
          doc.to_idml_story.must_equal %(
            <ParagraphStyleRange AppliedParagraphStyle=\"ParagraphStyle/Normal\">
              <CharacterStyleRange AppliedCharacterStyle=\"CharacterStyle/Regular\">
                <Content>para 1</Content>
                <Br />
                <Content>para 2</Content>
              </CharacterStyleRange>
            </ParagraphStyleRange>
          ).strip.gsub(/            /, '') + "\n"
        end

      end

      describe '#character_style_range_tag_for_el' do

        it 'Handles :em inside :strong' do
          doc = Document.new('**strong *em* strong**', :input => 'KramdownRepositext')
          doc.to_idml_story.must_equal %(
            <ParagraphStyleRange AppliedParagraphStyle="ParagraphStyle/Normal">
              <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Bold">
                <Content>strong </Content>
              </CharacterStyleRange>
              <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Bold Italic">
                <Content>em</Content>
              </CharacterStyleRange>
              <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Bold">
                <Content> strong</Content>
              </CharacterStyleRange>
            </ParagraphStyleRange>
          ).strip.gsub(/            /, '') + "\n"
        end

        it 'Handles :strong inside :em' do
          doc = Document.new('*em **strong** em*', :input => 'KramdownRepositext')
          doc.to_idml_story.must_equal %(
            <ParagraphStyleRange AppliedParagraphStyle="ParagraphStyle/Normal">
              <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Italic">
                <Content>em </Content>
              </CharacterStyleRange>
              <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Bold Italic">
                <Content>strong</Content>
              </CharacterStyleRange>
              <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Italic">
                <Content> em</Content>
              </CharacterStyleRange>
            </ParagraphStyleRange>
          ).strip.gsub(/            /, '') + "\n"
        end

        it 'Handles :strong' do
          doc = Document.new('**the text**', :input => 'KramdownRepositext')
          doc.to_idml_story.must_equal psr_node(:cs => 'Bold')
        end

        describe ':em' do

          [
            ['Handles no class', '*the text*', { :cs => 'Italic' }],
            ['Handles .else', '*the text*{:.else}', { :cs => 'Regular' }]
          ].each do |test_attrs|
            desc, test_string, expect = *test_attrs
            it desc do
              doc = Document.new(test_string, :input => 'KramdownRepositext')
              doc.to_idml_story.must_equal psr_node(expect)
            end
          end

          it 'Handles .bold' do
            doc = Document.new('*the text*{:.bold}', :input => 'KramdownRepositext')
            doc.to_idml_story.must_equal %(
              <ParagraphStyleRange AppliedParagraphStyle="ParagraphStyle/Normal">
                <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Bold">
                  <Content>the text</Content>
                </CharacterStyleRange>
              </ParagraphStyleRange>
            ).strip.gsub(/              /, '') + "\n"
          end

          it 'Handles .bold.italic' do
            doc = Document.new('*the text*{:.bold.italic}', :input => 'KramdownRepositext')
            doc.to_idml_story.must_equal %(
              <ParagraphStyleRange AppliedParagraphStyle="ParagraphStyle/Normal">
                <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Bold Italic">
                  <Content>the text</Content>
                </CharacterStyleRange>
              </ParagraphStyleRange>
            ).strip.gsub(/              /, '') + "\n"
          end

          it 'Handles .italic' do
            doc = Document.new('*the text*{:.italic}', :input => 'KramdownRepositext')
            doc.to_idml_story.must_equal %(
              <ParagraphStyleRange AppliedParagraphStyle="ParagraphStyle/Normal">
                <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Italic">
                  <Content>the text</Content>
                </CharacterStyleRange>
              </ParagraphStyleRange>
            ).strip.gsub(/              /, '') + "\n"
          end

          it 'Handles .pn' do
            doc = Document.new('*142*{: .pn} and more text', :input => 'KramdownRepositext')
            doc.to_idml_story.must_equal %(
              <ParagraphStyleRange AppliedParagraphStyle="ParagraphStyle/Normal">
                <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Paragraph Number">
                  <Content>142</Content>
                </CharacterStyleRange>
                <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Regular">
                  <Content> and more text</Content>
                </CharacterStyleRange>
              </ParagraphStyleRange>
            ).strip.gsub(/              /, '') + "\n"
          end

          it 'Handles .smcaps' do
            doc = Document.new('*the text*{:.smcaps}', :input => 'KramdownRepositext')
            doc.to_idml_story.must_equal %(
              <ParagraphStyleRange AppliedParagraphStyle="ParagraphStyle/Normal">
                <CharacterStyleRange Capitalization="SmallCaps" AppliedCharacterStyle="CharacterStyle/Regular">
                  <Content>the text</Content>
                </CharacterStyleRange>
              </ParagraphStyleRange>
            ).strip.gsub(/              /, '') + "\n"
          end

          it 'Handles .subscript' do
            doc = Document.new('normal text*subscript*{: .subscript}more normal text', :input => 'KramdownRepositext')
            doc.to_idml_story.must_equal %(
              <ParagraphStyleRange AppliedParagraphStyle="ParagraphStyle/Normal">
                <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Regular">
                  <Content>normal text</Content>
                </CharacterStyleRange>
                <CharacterStyleRange Position="Subscript" AppliedCharacterStyle="CharacterStyle/Regular">
                  <Content>subscript</Content>
                </CharacterStyleRange>
                <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Regular">
                  <Content>more normal text</Content>
                </CharacterStyleRange>
              </ParagraphStyleRange>
            ).strip.gsub(/              /, '') + "\n"
          end

          it 'Handles .superscript' do
            doc = Document.new('normal text*superscript*{: .superscript}more normal text', :input => 'KramdownRepositext')
            doc.to_idml_story.must_equal %(
              <ParagraphStyleRange AppliedParagraphStyle="ParagraphStyle/Normal">
                <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Regular">
                  <Content>normal text</Content>
                </CharacterStyleRange>
                <CharacterStyleRange Position="Superscript" AppliedCharacterStyle="CharacterStyle/Regular">
                  <Content>superscript</Content>
                </CharacterStyleRange>
                <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Regular">
                  <Content>more normal text</Content>
                </CharacterStyleRange>
              </ParagraphStyleRange>
            ).strip.gsub(/              /, '') + "\n"
          end

          it 'Handles .underline' do
            doc = Document.new('*the text*{:.underline}', :input => 'KramdownRepositext')
            doc.to_idml_story.must_equal %(
              <ParagraphStyleRange AppliedParagraphStyle="ParagraphStyle/Normal">
                <CharacterStyleRange Underline="true" AppliedCharacterStyle="CharacterStyle/Regular">
                  <Content>the text</Content>
                </CharacterStyleRange>
              </ParagraphStyleRange>
            ).strip.gsub(/              /, '') + "\n"
          end
        end

      end

      describe 'escaped chars' do

        it "doesn't escape brackets" do
          doc = Document.new("some text with \\[escaped brackets\\]", :input => 'KramdownRepositext')
          doc.to_idml_story.must_equal psr_node({ :content => 'some text with [escaped brackets]' })
        end

      end

    end
  end
end
