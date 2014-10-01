require_relative '../../helper'

module Kramdown
  module Converter
    describe Icml do

      it 'computes the story xml and inserts it into the template' do
        template_io = StringIO.new("<Story>\n  <%= @story %>\n</Story>", 'r')
        r = Document.new(
          "some text",
          {
            :input => 'KramdownRepositext',
            :template_file => template_io
          }
        ).to_icml
        r.must_equal %(
          <Story>
            <ParagraphStyleRange AppliedParagraphStyle="ParagraphStyle/Normal">
            <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Regular">
              <Content>some text</Content>
            </CharacterStyleRange>
          </ParagraphStyleRange>
          </Story>
        ).strip.gsub(/          /, '')
      end

    end
  end
end
