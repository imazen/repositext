require_relative '../../helper'

describe Kramdown::Converter::IdmlStory do

  # Generates a ParagraphStyleRange node.
  # @param[Hash] attrs
  #     * :ps Paragraph style name
  #     * :cs Character style name
  #     * :content Content element inner text
  def psr_node(attrs)
    attrs = {
      :ps => '',
      :cs => 'Regular',
      :content => 'the text'
    }.merge(attrs)
    %(
      <ParagraphStyleRange AppliedParagraphStyle="ParagraphStyle/#{ attrs[:ps] }">
        <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/#{ attrs[:cs] }">
          <Content>#{ attrs[:content] }</Content>
        </CharacterStyleRange>
      </ParagraphStyleRange>
    ).strip.gsub(/      /, '') + "\n"
  end

  it "wraps text in paragraph and character style ranges" do
    doc = Kramdown::Document.new("the text", :input => 'repositext')
    doc.to_idml_story.must_equal psr_node({})
  end

  describe '#convert_header' do

    [
      ['Converts level 1', '# the text', { :ps => 'Title of Sermon' }],
      ['Converts level 3', '### the text', { :ps => 'Sub-title' }],
    ].each do |test_attrs|
      desc, test_string, expect = *test_attrs
      it desc do
        doc = Kramdown::Document.new(test_string, :input => 'repositext')
        doc.to_idml_story.must_equal psr_node(expect)
      end
    end

    it "raises an exception when given a level 2 header" do
      doc = Kramdown::Document.new("## level 2 header", :input => 'repositext')
      proc { doc.to_idml_story }.must_raise(Kramdown::Converter::IdmlStory::InvalidElementException)
    end

  end

  describe '#convert_p' do

    [
      ['Handles class .normal', "the text\n{:.normal}", { :ps => 'Normal' }],
      ['Handles class .normal_pn', "the text\n{:.normal_pn}", { :ps => 'Normal' }],
      ['Handles class .scr', "the text\n{:.scr}", { :ps => 'Scripture' }],
      ['Handles class .stanza', "the text\n{:.stanza}", { :ps => 'Song stanza' }],
      ['Handles class .song', "the text\n{:.song}", { :ps => 'Song' }],
      ['Handles class .id_title1', "the text\n{:.id_title1}", { :ps => 'IDTitle1' }],
      ['Handles class .id_title2', "the text\n{:.id_title2}", { :ps => 'IDTitle2' }],
      ['Handles class .id_paragraph', "the text\n{:.id_paragraph}", { :ps => 'IDParagraph' }],
      ['Handles class .reading', "the text\n{:.reading}", { :ps => 'Reading' }],
    ].each do |test_attrs|
      desc, test_string, expect = *test_attrs
      it desc do
        doc = Kramdown::Document.new(test_string, :input => 'repositext')
        doc.to_idml_story.must_equal psr_node(expect)
      end
    end

    [
      ['Handles Question1', "", { :ps => 'Question1' }],
      ['Handles Question1', "1", { :ps => 'Question1' }],
      ['Handles Question2', "11", { :ps => 'Question2' }],
      ['Handles Question3', "111", { :ps => 'Question3' }],
    ].each do |test_attrs|
      desc, number, expect = *test_attrs
      test_string = "**#{ number }.** question body\n{: .q}"
      it desc do
        doc = Kramdown::Document.new(test_string, :input => 'repositext')
        doc.to_idml_story.must_equal %(
          <ParagraphStyleRange AppliedParagraphStyle="ParagraphStyle/#{ expect[:ps] }">
            <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Bold">
              <Content>#{ number }.</Content>
            </CharacterStyleRange>
            <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Regular">
              <Content> question body</Content>
            </CharacterStyleRange>
          </ParagraphStyleRange>
        ).strip.gsub(/          /, '') + "\n"
      end
    end

  end

  it "converts :hr" do
    doc = Kramdown::Document.new("the text\n\n***", :input => 'repositext')
    doc.to_idml_story.must_equal %(
      <ParagraphStyleRange AppliedParagraphStyle="ParagraphStyle/">
        <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Regular">
          <Content>the text</Content>
          <Br />
        </CharacterStyleRange>
      </ParagraphStyleRange>
      <ParagraphStyleRange AppliedParagraphStyle="ParagraphStyle/Horizontal rule">
        <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Regular">
          <Content>* * *</Content>
          <Br />
        </CharacterStyleRange>
      </ParagraphStyleRange>
    ).strip.gsub(/      /, '') + "\n"
  end

  it "converts :br" do
    doc = Kramdown::Document.new("first  \nsecond", :input => 'repositext')
    doc.to_idml_story.must_equal %(
      <ParagraphStyleRange AppliedParagraphStyle="ParagraphStyle/">
        <CharacterStyleRange AppliedCharacterStyle="CharacterStyle/Regular">
          <Content>first</Content>
          <Content>\u2028</Content>
          <Content> second</Content>
        </CharacterStyleRange>
      </ParagraphStyleRange>
    ).strip.gsub(/      /, '') + "\n"
  end

  describe '#paragraph_style_range_tag' do

    it "handles adjacent paragraphs with different attrs" do
      doc = Kramdown::Document.new("para 1\n{:.normal}\n\npara 2\n{:.scr}", :input => 'repositext')
      doc.to_idml_story.must_equal %(
        <ParagraphStyleRange AppliedParagraphStyle=\"ParagraphStyle/Normal\">
          <CharacterStyleRange AppliedCharacterStyle=\"CharacterStyle/Regular\">
            <Content>para 1</Content>
            <Br />
          </CharacterStyleRange>
        </ParagraphStyleRange>
        <ParagraphStyleRange AppliedParagraphStyle=\"ParagraphStyle/Scripture\">
          <CharacterStyleRange AppliedCharacterStyle=\"CharacterStyle/Regular\">
            <Content>para 2</Content>
          </CharacterStyleRange>
        </ParagraphStyleRange>
      ).strip.gsub(/        /, '') + "\n"
    end

    it "merges text from adjacent paragraphs with identical attrs" do
      doc = Kramdown::Document.new("para 1\n{:.normal}\n\npara 2\n{:.normal}", :input => 'repositext')
      doc.to_idml_story.must_equal %(
        <ParagraphStyleRange AppliedParagraphStyle=\"ParagraphStyle/Normal\">
          <CharacterStyleRange AppliedCharacterStyle=\"CharacterStyle/Regular\">
            <Content>para 1</Content>
            <Br />
            <Content>para 2</Content>
          </CharacterStyleRange>
        </ParagraphStyleRange>
      ).strip.gsub(/        /, '') + "\n"
    end

  end

  describe '#character_style_range_tag_for_el' do

    it 'Handles :em inside :strong' do
      doc = Kramdown::Document.new('**strong *em* strong**', :input => 'repositext')
      doc.to_idml_story.must_equal %(
        <ParagraphStyleRange AppliedParagraphStyle="ParagraphStyle/">
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
      ).strip.gsub(/        /, '') + "\n"
    end

    it 'Handles :strong inside :em' do
      doc = Kramdown::Document.new('*em **strong** em*', :input => 'repositext')
      doc.to_idml_story.must_equal %(
        <ParagraphStyleRange AppliedParagraphStyle="ParagraphStyle/">
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
      ).strip.gsub(/        /, '') + "\n"
    end

    it 'Handles :strong' do
      doc = Kramdown::Document.new('**the text**', :input => 'repositext')
      doc.to_idml_story.must_equal psr_node(:cs => 'Bold')
    end

    describe ':em' do

      [
        ['Handles .pn', '*the text*{:.pn}', { :cs => 'Paragraph number' }],
        ['Handles .bold.italic', '*the text*{:.bold.italic}', { :cs => 'Bold Italic' }],
        ['Handles .bold', '*the text*{:.bold}', { :cs => 'Bold' }],
        ['Handles .italic', '*the text*{:.italic}', { :cs => 'Italic' }],
        ['Handles .else', '*the text*{:.else}', { :cs => 'Regular' }]
      ].each do |test_attrs|
        desc, test_string, expect = *test_attrs
        it desc do
          doc = Kramdown::Document.new(test_string, :input => 'repositext')
          doc.to_idml_story.must_equal psr_node(expect)
        end
      end

      it 'Handles .underline' do
        doc = Kramdown::Document.new('*the text*{:.underline}', :input => 'repositext')
        doc.to_idml_story.must_equal %(
          <ParagraphStyleRange AppliedParagraphStyle="ParagraphStyle/">
            <CharacterStyleRange Underline="true" AppliedCharacterStyle="CharacterStyle/Regular">
              <Content>the text</Content>
            </CharacterStyleRange>
          </ParagraphStyleRange>
        ).strip.gsub(/          /, '') + "\n"
      end

      it 'Handles .smcaps' do
        doc = Kramdown::Document.new('*the text*{:.smcaps}', :input => 'repositext')
        doc.to_idml_story.must_equal %(
          <ParagraphStyleRange AppliedParagraphStyle="ParagraphStyle/">
            <CharacterStyleRange Capitalization="SmallCaps" AppliedCharacterStyle="CharacterStyle/Regular">
              <Content>the text</Content>
            </CharacterStyleRange>
          </ParagraphStyleRange>
        ).strip.gsub(/          /, '') + "\n"
      end

    end

  end

end
