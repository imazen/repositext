require_relative '../../helper'

module Kramdown
  module Converter
    describe LatexRepositext do

      language = Repositext::Language::English

      describe "#emulate_small_caps" do

        [
          [
            "Single letter (part of date code, no custom kerning)",
            "m",
            "\\RtSmCapsEmulation{none}{M}{none}",
          ],
          [
            "Default case with single word",
            "Water",
            "W\\RtSmCapsEmulation{17em}{ATER}{none}",
          ],
          [
            "Two regular words",
            "Water Water",
            "W\\RtSmCapsEmulation{17em}{ATER}{15em} W\\RtSmCapsEmulation{17em}{ATER}{none}",
          ],
          [
            "Applies custom kerning between smallcaps and questionmark, doesn't scale down questionmark",
            "Water?",
            "W\\RtSmCapsEmulation{17em}{ATER}{13em}?",
          ],
          [
            "Applies custom kerning between smallcaps and exclamation point, doesn't scale down exclamation point",
            "Water!",
            "W\\RtSmCapsEmulation{17em}{ATER}{10em}!",
          ],
          [
            "Applies custom kerning between smallcaps and comma, doesn't scale down comma",
            "Water,",
            "W\\RtSmCapsEmulation{17em}{ATER}{11em},",
          ],
          [
            "Applies custom kerning between smallcaps and period, doesn't scale down period",
            "Water.",
            "W\\RtSmCapsEmulation{17em}{ATER}{12em}.",
          ],
          [
            "Handles two adjacent full caps",
            "WAter",
            "WA\\RtSmCapsEmulation{3em}{TER}{none}",
          ],
          [
            "With accented character mapping",
            "Wáter Wáter",
            "W\\RtSmCapsEmulation{17em}{ÁTER}{15em} W\\RtSmCapsEmulation{17em}{ÁTER}{none}",
          ],
          [
            "Handles fullcaps inside a word",
            "WaterWater Word",
            "W\\RtSmCapsEmulation{17em}{ATER}{15em}W\\RtSmCapsEmulation{17em}{ATER}{15em} W\\RtSmCapsEmulation{18em}{ORD}{none}",
          ],
          [
            "Handles leading punctuation character",
            "¿Water",
            "¿W\\RtSmCapsEmulation{17m}{ATER}{none}",
          ],
          [
            "Upper cases character after apostrophe",
            "Word#{ language.chars[:apostrophe] }s Word",
            "W\\RtSmCapsEmulation{18em}{ORD}{8em}#{ language.chars[:apostrophe] }\\RtSmCapsEmulation{22em}{S}{16em} W\\RtSmCapsEmulation{18em}{ORD}{none}",
          ],
          [
            "Upper cases A.D., not scaling down the periods inbetween",
            "a.d.",
            "\\RtSmCapsEmulation{none}{A}{2em}.\\RtSmCapsEmulation{1em}{D}{5em}.",
          ],
          [
            "Handles standalone upper case chars",
            "Water A Water",
            "W\\RtSmCapsEmulation{17em}{ATER}{14em} A\\RtSmCapsEmulation{none}{}{4em} W\\RtSmCapsEmulation{17em}{ATER}{none}",
          ],
          [
            "Handles adjacent upper case chars",
            "Water AWater",
            "W\\RtSmCapsEmulation{17em}{ATER}{14em} AW\\RtSmCapsEmulation{17em}{ATER}{none}",
          ],
          [
            "Handles a word that starts with lower case letter",
            "word Word",
            "\\RtSmCapsEmulation{none}{WORD}{6em} W\\RtSmCapsEmulation{18em}{ORD}{none}",
          ],
          [
            "Cyrillic words",
            "Чтo пpивлекaет?",
            "Ч\\RtSmCapsEmulation{21em}{ТO}{9em} \\RtSmCapsEmulation{none}{ПPИВЛЕКAЕТ}{20em}?",
          ],
          [
            "Apostrophe inside word, followed by upper case char",
            "Word#{ language.chars[:apostrophe] }Word",
            "W\\RtSmCapsEmulation{18em}{ORD}{8em}#{ language.chars[:apostrophe] }W\\RtSmCapsEmulation{18em}{ORD}{none}",
          ],
          [
            "Inter-word pairing of two lowercase chars",
            "Word word",
            "W\\RtSmCapsEmulation{18em}{ORD}{7em} \\RtSmCapsEmulation{none}{WORD}{none}",
          ],
          [
            "smallcaps with single fullcaps char (occurs in kerning samples PDF)",
            "waterWater",
            "\\RtSmCapsEmulation{none}{WATER}{15em}W\\RtSmCapsEmulation{17em}{ATER}{none}",
          ],
        ].each do |desc, test_string, xpect|
          it "handles #{ desc.inspect }" do
            c = LatexRepositext.send(:new, '_', { language: language })
            c.emulate_small_caps(
              test_string,
              'Arial',
              ['regular']
            ).must_equal(xpect)
          end
        end

      end

      describe "#convert_entity" do

        [
          ["word &amp; word", "word \\&{} word\n\n"],
          ["word &#x2011; word", "word \u2011 word\n\n"],
          ["word &#x2028; word", "word \u2028 word\n\n"],
          ["word &#x202F; word", "word \u202F word\n\n"],
          ["word &#xFEFF; word", "word \uFEFF word\n\n"],
        ].each do |test_string, xpect|
          it "decodes valid encoded entity #{ test_string.inspect }" do
            doc = Document.new(test_string, input: 'KramdownRepositext', language: language)
            doc.to_latex_repositext.must_equal(xpect)
          end
        end

        [
          ["word &#x2012; word", "word  word\n\n"],
        ].each do |test_string, xpect|
          it "doesn't decode invalid encoded entity #{ test_string.inspect }" do
            doc = Document.new(test_string, input: 'KramdownRepositext', language: language)
            doc.to_latex_repositext.must_equal(xpect)
          end
        end

        [
          ["word &#x391; word", "word $A${} word\n\n"], # decimal 913
        ].each do |test_string, xpect|
          it "decodes kramdown built in entity #{ test_string.inspect }" do
            doc = Document.new(test_string, input: 'KramdownRepositext', language: language)
            doc.to_latex_repositext.must_equal(xpect)
          end
        end

      end

      describe "#convert_p" do

        [
          [
            "multiple nested environments around single paragraph",
            "word word word\n{: .normal .indent_for_eagle}\n",
            "\\begin{RtNormal}\n\\begin{RtIndentForEagle}\nword word word\n\\end{RtIndentForEagle}\n\\end{RtNormal}\n\n"
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
