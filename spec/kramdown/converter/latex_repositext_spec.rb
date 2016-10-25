require_relative '../../helper'

module Kramdown
  module Converter
    describe LatexRepositext do

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
            "W\\RtSmCapsEmulation{-0.1em}{ATER}{none}",
          ],
          [
            "Two regular words",
            "Water Water",
            "W\\RtSmCapsEmulation{-0.1em}{ATER}{none} W\\RtSmCapsEmulation{-0.1em}{ATER}{none}",
          ],
          [
            "Applies custom kerning between smallcaps and questionmark, doesn't scale down questionmark",
            "Water?",
            "W\\RtSmCapsEmulation{-0.1em}{ATER}{-0.3em}?",
          ],
          [
            "Applies custom kerning between smallcaps and exclamation point, doesn't scale down exclamation point",
            "Water!",
            "W\\RtSmCapsEmulation{-0.1em}{ATER}{none}!",
          ],
          [
            "Applies custom kerning between smallcaps and comma, doesn't scale down comma",
            "Water,",
            "W\\RtSmCapsEmulation{-0.1em}{ATER}{none},",
          ],
          [
            "Applies custom kerning between smallcaps and period, doesn't scale down period",
            "Water.",
            "W\\RtSmCapsEmulation{-0.1em}{ATER}{none}.",
          ],
          [
            "Handles two adjacent full caps",
            "WAter",
            "WA\\RtSmCapsEmulation{none}{TER}{none}",
          ],
          [
            "With accented character mapping",
            "Wáter Wáter",
            "W\\RtSmCapsEmulation{-0.1em}{ÁTER}{none} W\\RtSmCapsEmulation{-0.1em}{ÁTER}{none}",
          ],
          [
            "Handles fullcaps inside a word",
            "WaterWater Word",
            "W\\RtSmCapsEmulation{-0.1em}{ATER}{-0.4em}W\\RtSmCapsEmulation{-0.1em}{ATER}{none} W\\RtSmCapsEmulation{none}{ORD}{none}",
          ],
          [
            "Handles leading punctuation character",
            "¿Water",
            "¿W\\RtSmCapsEmulation{-0.1em}{ATER}{none}",
          ],
          [
            "Upper cases character after apostrophe",
            "Word’s Word",
            "W\\RtSmCapsEmulation{none}{ORD}{none}’\\RtSmCapsEmulation{none}{S}{none} W\\RtSmCapsEmulation{none}{ORD}{none}",
          ],
          [
            "Upper cases A.D., not scaling down the periods inbetween",
            "a.d.",
            "\\RtSmCapsEmulation{none}{A}{none}.\\RtSmCapsEmulation{none}{D}{none}.",
          ],
          [
            "Handles standalone upper case chars",
            "Word A Word",
            "W\\RtSmCapsEmulation{none}{ORD}{none} A W\\RtSmCapsEmulation{none}{ORD}{none}",
          ],
        ].each do |desc, test_string, xpect|
          it "handles #{ desc.inspect }" do
            c = LatexRepositext.send(:new, '_', {})
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
            doc = Document.new(test_string, :input => 'KramdownRepositext')
            doc.to_latex_repositext.must_equal(xpect)
          end
        end

        [
          ["word &#x2012; word", "word  word\n\n"],
        ].each do |test_string, xpect|
          it "doesn't decode invalid encoded entity #{ test_string.inspect }" do
            doc = Document.new(test_string, :input => 'KramdownRepositext')
            doc.to_latex_repositext.must_equal(xpect)
          end
        end

        [
          ["word &#x391; word", "word $A${} word\n\n"], # decimal 913
        ].each do |test_string, xpect|
          it "decodes kramdown built in entity #{ test_string.inspect }" do
            doc = Document.new(test_string, :input => 'KramdownRepositext')
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
