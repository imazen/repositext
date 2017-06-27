require_relative '../../helper'

module Kramdown
  module Converter
    describe LatexRepositext do

      language = Repositext::Language::English

      describe "#convert_entity" do

        [
          ["word &amp; word\n{: .normal}", "\\begin{RtNormal}\nword \\&{} word\n\\end{RtNormal}\n\n"],
          ["word &#x2011; word\n{: .normal}", "\\begin{RtNormal}\nword \u2011 word\n\\end{RtNormal}\n\n"],
          ["word &#x2028; word\n{: .normal}", "\\begin{RtNormal}\nword \u2028 word\n\\end{RtNormal}\n\n"],
          ["word &#x202F; word\n{: .normal}", "\\begin{RtNormal}\nword \u202f word\n\\end{RtNormal}\n\n"],
          ["word &#xFEFF; word\n{: .normal}", "\\begin{RtNormal}\nword \uFEFF word\n\\end{RtNormal}\n\n"],
        ].each do |test_string, xpect|
          it "decodes valid encoded entity #{ test_string.inspect }" do
            doc = Document.new(test_string, input: 'KramdownRepositext', language: language)
            doc.to_latex_repositext.must_equal(xpect)
          end
        end

        [
          ["word &#x2012; word\n{: .normal}", "\\begin{RtNormal}\nword  word\n\\end{RtNormal}\n\n"],
        ].each do |test_string, xpect|
          it "doesn't decode invalid encoded entity #{ test_string.inspect }" do
            doc = Document.new(test_string, input: 'KramdownRepositext', language: language)
            doc.to_latex_repositext.must_equal(xpect)
          end
        end

        [
          ["word &#x391; word\n{: .normal}", "\\begin{RtNormal}\nword $A${} word\n\\end{RtNormal}\n\n"], # decimal 913
        ].each do |test_string, xpect|
          it "decodes kramdown built in entity #{ test_string.inspect }" do
            doc = Document.new(test_string, input: 'KramdownRepositext', language: language)
            doc.to_latex_repositext.must_equal(xpect)
          end
        end

      end

      describe "#convert_header" do

        [
          [
            "level 1 header",
            "# header level 1\n\n",
            "\\begin{RtTitle}%\nheader level 1%\n\\end{RtTitle}\n"
          ],
          [
            "level 2 header (must be preceded by level 1)",
            "# header level 1\n\n## header level 2\n\n",
            "\\begin{RtTitle}%\nheader level 1%\n\\end{RtTitle}\n\\begin{RtTitle2}%\nheader level 2%\n\\end{RtTitle2}\n"
          ],
        ].each do |desc, test_string, xpect|
          it "handles #{ desc }" do
            doc = Document.new(test_string, input: 'KramdownRepositext', language: language)
            doc.to_latex_repositext.must_equal(xpect)
          end
        end

        it "captures level 1 header text into i_var" do
          c = LatexRepositext.send(:new, '_', { header_offset: 0 })
          txt_el = Element.new(:text, "header level 1")
          header_el = Element.new(:header, nil, nil, level: 1)
          header_el.children << txt_el
          c.send(
            :convert_header,
            header_el,
            {}
          )
          c.instance_variable_get(:@document_title_latex).must_equal('header level 1')
          c.instance_variable_get(:@document_title_plain_text).must_equal("header level 1")
        end

        it "captures level 1 and level 2 header text into i_var" do
          c = LatexRepositext.send(:new, '_', { header_offset: 0, language: language })
          txt_el_1 = Element.new(:text, "header level 1")
          header_el_1 = Element.new(:header, nil, nil, level: 1)
          header_el_1.children << txt_el_1
          txt_el_2 = Element.new(:text, "header level 2")
          header_el_2 = Element.new(:header, nil, nil, level: 2)
          header_el_2.children << txt_el_2
          c.send(:convert_header, header_el_1, {})
          c.send(:convert_header, header_el_2, {})
          c.instance_variable_get(:@document_title_latex).must_equal('header level 1 — header level 2')
          c.instance_variable_get(:@document_title_plain_text).must_equal("header level 1 — header level 2\n")
        end

      end

      describe "#convert_hr" do

        it "uses setting to render horizontal rules" do
          doc = Document.new(
            "word\n{: .normal}\n\n* * *",
            input: 'KramdownRepositext',
            language: language,
            hrule_latex: 'hrule-latex'
          )
          doc.to_latex_repositext.must_equal(
            "\\begin{RtNormal}\nword\n\\end{RtNormal}\n\nhrule-latex"
          )
        end

      end

      describe "#convert_p" do

        [
          [
            "multiple nested environments around single paragraph",
            "word word word\n{: .normal .indent_for_eagle}\n",
            "\\begin{RtIndentForEagle}\n\\begin{RtNormal}\nword word word\n\\end{RtNormal}\n\\end{RtIndentForEagle}\n\n"
          ],
        ].each do |desc, test_string, xpect|
          it "handles #{ desc }" do
            doc = Document.new(test_string, input: 'KramdownRepositext', language: language)
            doc.to_latex_repositext.must_equal(xpect)
          end
        end

      end

      describe "#escape_latex_text" do

        [
          ["word & word", "word \\& word"],
          ["word % word", "word \\% word"],
          ["word $ word", "word \\$ word"],
          ["word # word", "word \\# word"],
          ["word _ word", "word \\_ word"],
          ["word { word", "word \\{ word"],
          ["word } word", "word \\} word"],
          ["word ~ word", "word \\textasciitilde word"],
          ["word ^ word", "word \\textasciicircum word"],
          ["word \\n word", "word \\textbackslashn word"],
        ].each do |test_string, xpect|
          it "escapes #{ test_string.inspect }" do
            c = LatexRepositext.send(:new, '_', {})
            c.send(:escape_latex_text, test_string).must_equal(xpect)
          end
        end

        [
          ["word \\& word", "word \\& word"],
          ["word \\% word", "word \\% word"],
          ["word \\$ word", "word \\$ word"],
          ["word \\# word", "word \\# word"],
          ["word \\_ word", "word \\_ word"],
          ["word \\{ word", "word \\{ word"],
          ["word \\} word", "word \\} word"],
        ].each do |test_string, xpect|
          it "does not escape already escaped character #{ test_string.inspect }" do
            c = LatexRepositext.send(:new, '_', {})
            c.send(:escape_latex_text, test_string).must_equal(xpect)
          end
        end

      end

    end
  end
end
