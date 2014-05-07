require_relative '../../helper'

describe Kramdown::Converter::PlainText do

  # Specs that run with repositext because :
  # a) repositext can handle the element type OR
  # b) repositext's behavior is different from kramdown proper
  [
    [%(the body), %(the body)],
    [%(# the header), %(the header)],
    [%(*the em*), %(the em)],
    [%(**the strong**), %(the strong)],
    [%(para 1\n\npara 2), %(para 1\n\npara 2)],
    [
      %(# header 1\n\n## header 2 *with em*\n\npara 1\n\npara 2 **with strong**.),
      %(header 1\n\nheader 2 with em\n\npara 1\n\npara 2 with strong.)
    ],
    [%(some text with \\[escaped brackets\\]), %(some text with [escaped brackets])],
  ].each_with_index do |(kramdown, expected), idx|
    it "converts example #{ idx + 1 } to plain text" do
      doc = Kramdown::Document.new(
        kramdown, { :input => 'KramdownRepositext' }
      )
      doc.to_plain_text.must_equal expected
    end
  end

  # Specs that need to run with kramdown proper (because repositext
  # doesn't support these elements (yet).)
  [
    [%([the link](link.html)), %(the link)],
    [%(* list 1\n* list 2\n* list 3), %(list 1\nlist 2\nlist 3)],
    [
      %(# header 1\n\n## header 2 *with em*\n\npara 1\n\npara 2 **with strong** and [link](link.html).),
      %(header 1\n\nheader 2 with em\n\npara 1\n\npara 2 with strong and link.)
    ],
  ].each_with_index do |(kramdown, expected), idx|
    it "converts example #{ idx + 1 } to plain text" do
      doc = Kramdown::Document.new(
        kramdown, { :input => 'kramdown' }
      )
      doc.to_plain_text.must_equal expected
    end
  end

end
