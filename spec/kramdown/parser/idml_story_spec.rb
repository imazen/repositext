require_relative '../../helper'

module Kramdown
  module Parser
    describe IdmlStory do

      # Wraps plain_text so that it is a valid IdmlStory that can be parsed.
      # @param[String] plain_text
      # @param[Hash, optional] options: :aps, :acs
      def plain_text_as_idml_story(plain_text, options = {})
        options = {:acs => 'CharacterStyle/Regular'}.merge(options)
        data =  '<Content>'
        data <<   plain_text
        data << '</Content>'
        content_as_idml_story(data, options)
      end

      # Wraps a_content so that it is a valid IdmlStory that can be parsed.
      # @param[String] a_content
      # @param[Hash, optional] options: :aps, :acs
      def content_as_idml_story(a_content, options = {})
        options = {:acs => 'CharacterStyle/Regular'}.merge(options)
        data =  %(<CharacterStyleRange AppliedCharacterStyle="#{options[:acs]}" CharacterDirection="LeftToRightDirection">)
        data <<   a_content
        data << '</CharacterStyleRange>'
        char_as_idml_story(data, options)
      end

      # Wraps a_character_style_range so that it is a valid IdmlStory that can be parsed.
      # @param[String] a_character_style_range
      # @param[Hash, optional] options: :aps
      def char_as_idml_story(a_character_style_range, options = {})
        options = {:aps => 'ParagraphStyle/Normal'}.merge(options)
        data =  %(<ParagraphStyleRange AppliedParagraphStyle="#{options[:aps]}" HyphenateCapitalizedWords="false">)
        data <<   a_character_style_range
        data << '</ParagraphStyleRange>'
        para_as_idml_story(data)
      end

      # Wraps a_paragraph_style_range so that it is a valid IdmlStory that can be parsed.
      # @param[String] a_paragraph_style_range
      def para_as_idml_story(a_paragraph_style_range)
        data = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        data << '<idPkg:Story xmlns:idPkg="http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging" DOMVersion="8.0">'
        data << '  <Story Self="test" AppliedTOCStyle="n" TrackChanges="false" StoryTitle="$ID/" AppliedNamedGrid="n">'
        data << '    <StoryPreference OpticalMarginAlignment="false" OpticalMarginSize="12" FrameType="TextFrameType" StoryOrientation="Horizontal" StoryDirection="LeftToRightDirection"/>'
        data << '    <InCopyExportOption IncludeGraphicProxies="true" IncludeAllResources="false"/>'
        data <<      a_paragraph_style_range
        data << '  </Story>'
        data << '</idPkg:Story>'
        data
      end

      describe 'plain_text' do
        [
          ['a', {}, %(a\n{: .normal}\n\n)]
        ].each do |attrs|
          plain_text, options, expected = attrs
          it "parses plain_text #{plain_text}" do
            doc = Document.new(
              plain_text_as_idml_story(plain_text, options), { :input => 'IdmlStory' }
            )
            doc.to_kramdown_repositext.must_equal expected
          end
        end
      end

      # describe 'empty content elements' do
      # end

      describe 'character_style_range' do
        [
          [
            "handles SmallCaps nested inside Italic",
            %(
              <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Italic">
                <Content> should be italic, </Content>
              </CharacterStyleRange>
              <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Italic" Capitalization="SmallCaps">
                <Content>smallcaps</Content>
              </CharacterStyleRange>
              <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Italic">
                <Content>, italic again!</Content>
                <Br/>
              </CharacterStyleRange>
            ),
            {},
            %(*should be italic,* *smallcaps*{: .italic .smcaps}*, italic again!*\n{: .normal}\n\n)
          ],
          [
            "removes styling from Content nodes that contain whitespace only.",
            %(
              <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Regular" FontStyle="Italic">
                <Content>Para 1.</Content>
                <Br/>
                <Content>        </Content>
              </CharacterStyleRange>
              <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Regular">
                <Content>Para 2.</Content>
              </CharacterStyleRange>
            ),
            {},
            %(*Para 1.*\n{: .normal}\n\nPara 2.\n{: .normal}\n\n)
          ],
          [
            "moves leading and trailing whitespace outside of em elements",
            %(
              <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Italic" Capitalization="SmallCaps" CharacterDirection="LeftToRightDirection">
                <Content>Para 1</Content>
              </CharacterStyleRange>
              <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Italic" CharacterDirection="LeftToRightDirection">
                <Content> padded with whitespace </Content>
              </CharacterStyleRange>
              <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Italic" Capitalization="SmallCaps" CharacterDirection="LeftToRightDirection">
                <Content>Para 3</Content>
              </CharacterStyleRange>
            ),
            {},
            %(*Para 1*{: .italic .smcaps} *padded with whitespace* *Para 3*{: .italic\n.smcaps}\n{: .normal}\n\n)
          ],
          [
           "moves trailing whitespace outside of em elements",
            %(
              <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/$ID/[No character style]" CharacterDirection="LeftToRightDirection">
                <Content>Karon, kung ... nahimong panulondon, </Content>
              </CharacterStyleRange>
              <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/$ID/[No character style]" FontStyle="Italic" CharacterDirection="LeftToRightDirection">
                <Content>kita gibut-an nang daan sumala sa katuyoan sa nagpalihok sa tanang mga butang sumala sa laraw sa Iyang pagbuot</Content>
              </CharacterStyleRange>
            ),
            {},
            %(Karon, kung ... nahimong panulondon, *kita gibut-an nang daan sumala sa\nkatuyoan sa nagpalihok sa tanang mga butang sumala sa laraw sa Iyang\npagbuot*\n{: .normal}\n\n)
          ],
          [
            "uses two em elements for mid-word style changes (resulting in invalid kramdown, validation will catch this)",
            %(
              <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Italic" CharacterDirection="LeftToRightDirection">
                <Content>This is italic a</Content>
              </CharacterStyleRange>
              <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Italic" Capitalization="SmallCaps" CharacterDirection="LeftToRightDirection">
                <Content>nd this is italic with smallcaps.</Content>
              </CharacterStyleRange>
            ),
            {},
            %(*This is italic a*{::}*nd this is italic with smallcaps.*{: .italic\n.smcaps}\n{: .normal}\n\n)
          ],
          [
            "removes Content nodes that contain whitespace only while preserving the unstyled whitespace",
            %(
              <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Regular">
                <Content>rfect is made</Content>
              </CharacterStyleRange>
              <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Italic">
                <Content> </Content>
              </CharacterStyleRange>
              <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Regular">
                <Content>known.”</Content>
                <Br/>
                <Content>        Now, I’ve got a question</Content>
              </CharacterStyleRange>
            ),
            {},
            %(rfect is made known.”\n{: .normal}\n\nNow, I’ve got a question\n{: .normal}\n\n)
          ],
          [
            "merges two sibling Content nodes of same type, with same attrs and same options (except :location)",
            %(
              <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Italic">
                <Content>first node </Content>
              </CharacterStyleRange>
              <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Italic">
                <Content>second node</Content>
              </CharacterStyleRange>
            ),
            {},
            %(*first node second node*\n{: .normal}\n\n)
          ],
          [
            "converts U+2028 to :br element (kramdown inserts two spaces before \\n)",
            %(
              <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Regular">
                <Content>before\u2028after</Content>
              </CharacterStyleRange>
            ),
            {},
            %(before  \nafter\n{: .normal}\n\n)
          ],
        ].each do |attrs|
          description, character_style_range, options, expected = attrs
          it description do
            doc = Document.new(
              char_as_idml_story(character_style_range, options), { :input => 'IdmlStory' }
            )
            doc.to_kramdown_repositext.must_equal expected
          end
        end
      end

      describe 'parapgraph_style_range' do
      end

    end
  end
end
