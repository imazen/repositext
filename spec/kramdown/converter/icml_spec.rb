require_relative '../../helper'

describe Kramdown::Converter::Icml do

  it 'computes the story xml and inserts it into the template' do
    template_io = StringIO.new("<Story>\n  <%= @story %>\n</Story>", 'r')
    output_io = StringIO.new('', 'w+')
    Kramdown::Document.new(
      "some text",
      {
        :input => :repositext,
        :output_file => output_io,
        :template_file => template_io
      }
    ).to_icml
    output_io.rewind
    output_io.read.must_equal %(
      <Story>
        <ParagraphStyleRange AppliedParagraphStyle="ParagraphStyle/Normal">
        <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Regular">
          <Content>some text</Content>
        </CharacterStyleRange>
      </ParagraphStyleRange>

      </Story>
    ).strip.gsub(/      /, '')
  end

end
