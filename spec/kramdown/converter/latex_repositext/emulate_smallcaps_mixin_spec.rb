require_relative '../../../helper'

module Kramdown
  module Converter
    class LatexRepositext
      describe EmulateSmallcapsMixin do

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
              "W\\RtNoLineBreak{}\\RtSmCapsEmulation{17em}{ATER}{none}",
            ],
            [
              "Two regular words",
              "Water Water",
              "W\\RtNoLineBreak{}\\RtSmCapsEmulation{17em}{ATER}{15em} W\\RtNoLineBreak{}\\RtSmCapsEmulation{17em}{ATER}{none}",
            ],
            [
              "Applies custom kerning between smallcaps and questionmark, doesn't scale down questionmark",
              "Water?",
              "W\\RtNoLineBreak{}\\RtSmCapsEmulation{17em}{ATER}{13em}\\RtNoLineBreak{}?",
            ],
            [
              "Applies custom kerning between smallcaps and exclamation point, doesn't scale down exclamation point",
              "Water!",
              "W\\RtNoLineBreak{}\\RtSmCapsEmulation{17em}{ATER}{10em}\\RtNoLineBreak{}!",
            ],
            [
              "Applies custom kerning between smallcaps and comma, doesn't scale down comma",
              "Water,",
              "W\\RtNoLineBreak{}\\RtSmCapsEmulation{17em}{ATER}{11em}\\RtNoLineBreak{},",
            ],
            [
              "Applies custom kerning between smallcaps and period, doesn't scale down period",
              "Water.",
              "W\\RtNoLineBreak{}\\RtSmCapsEmulation{17em}{ATER}{12em}\\RtNoLineBreak{}.",
            ],
            [
              "Two adjacent full caps",
              "WAter",
              "WA\\RtNoLineBreak{}\\RtSmCapsEmulation{3em}{TER}{none}",
            ],
            [
              "With accented character mapping",
              "Wáter Wáter",
              "W\\RtNoLineBreak{}\\RtSmCapsEmulation{17em}{ÁTER}{15em} W\\RtNoLineBreak{}\\RtSmCapsEmulation{17em}{ÁTER}{none}",
            ],
            [
              "Fullcaps inside a word",
              "WaterWater Word",
              "W\\RtNoLineBreak{}\\RtSmCapsEmulation{17em}{ATER}{15em}\\RtNoLineBreak{}W\\RtNoLineBreak{}\\RtSmCapsEmulation{17em}{ATER}{15em} W\\RtNoLineBreak{}\\RtSmCapsEmulation{18em}{ORD}{none}",
            ],
            [
              "Leading punctuation character",
              "¿Water",
              "¿W\\RtNoLineBreak{}\\RtSmCapsEmulation{17em}{ATER}{none}",
            ],
            [
              "Upper cases character after apostrophe",
              "Word#{ language.chars[:apostrophe] }s Word",
              "W\\RtNoLineBreak{}\\RtSmCapsEmulation{18em}{ORD}{8em}\\RtNoLineBreak{}#{ language.chars[:apostrophe] }\\RtNoLineBreak{}\\RtSmCapsEmulation{22em}{S}{16em} W\\RtNoLineBreak{}\\RtSmCapsEmulation{18em}{ORD}{none}",
            ],
            [
              "Upper cases A.D., not scaling down the periods inbetween",
              "a.d.",
              "\\RtSmCapsEmulation{none}{A}{2em}\\RtNoLineBreak{}.\\RtNoLineBreak{}\\RtSmCapsEmulation{1em}{D}{5em}\\RtNoLineBreak{}.",
            ],
            [
              "Standalone upper case chars",
              "Water A Water",
              "W\\RtNoLineBreak{}\\RtSmCapsEmulation{17em}{ATER}{14em} A\\RtSmCapsEmulation{none}{}{4em} W\\RtNoLineBreak{}\\RtSmCapsEmulation{17em}{ATER}{none}",
            ],
            [
              "Adjacent upper case chars",
              "Water AWater",
              "W\\RtNoLineBreak{}\\RtSmCapsEmulation{17em}{ATER}{14em} AW\\RtNoLineBreak{}\\RtSmCapsEmulation{17em}{ATER}{none}",
            ],
            [
              "Word that starts with lower case letter",
              "word Word",
              "\\RtSmCapsEmulation{none}{WORD}{6em} W\\RtNoLineBreak{}\\RtSmCapsEmulation{18em}{ORD}{none}",
            ],
            [
              "Cyrillic words",
              "Чтo пpивлекaет?",
              "Ч\\RtNoLineBreak{}\\RtSmCapsEmulation{21em}{ТO}{9em} \\RtSmCapsEmulation{none}{ПPИВЛЕКAЕТ}{20em}\\RtNoLineBreak{}?",
            ],
            [
              "Apostrophe inside word, followed by upper case char",
              "Word#{ language.chars[:apostrophe] }Word",
              "W\\RtNoLineBreak{}\\RtSmCapsEmulation{18em}{ORD}{8em}\\RtNoLineBreak{}#{ language.chars[:apostrophe] }W\\RtNoLineBreak{}\\RtSmCapsEmulation{18em}{ORD}{none}",
            ],
            [
              "Inter-word pairing of two lowercase chars",
              "Word word",
              "W\\RtNoLineBreak{}\\RtSmCapsEmulation{18em}{ORD}{7em} \\RtSmCapsEmulation{none}{WORD}{none}",
            ],
            [
              "Smallcaps with single fullcaps char (occurs in kerning samples PDF)",
              "waterWater",
              "\\RtSmCapsEmulation{none}{WATER}{15em}\\RtNoLineBreak{}W\\RtNoLineBreak{}\\RtSmCapsEmulation{17em}{ATER}{none}",
            ],
            [
              "Comma followed by lowercase char",
              "water, water",
              "\\RtSmCapsEmulation{none}{WATER}{11em}\\RtNoLineBreak{},\\RtSmCapsEmulation{none}{}{23em} \\RtSmCapsEmulation{none}{WATER}{none}",
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

      end
    end
  end
end
