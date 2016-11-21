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
              "W\\nolinebreak[4]\\RtSmCapsEmulation{17em}{ATER}{none}",
            ],
            [
              "Two regular words",
              "Water Water",
              "W\\nolinebreak[4]\\RtSmCapsEmulation{17em}{ATER}{15em} W\\nolinebreak[4]\\RtSmCapsEmulation{17em}{ATER}{none}",
            ],
            [
              "Applies custom kerning between smallcaps and questionmark, doesn't scale down questionmark",
              "Water?",
              "W\\nolinebreak[4]\\RtSmCapsEmulation{17em}{ATER}{13em}\\nolinebreak[4]?",
            ],
            [
              "Applies custom kerning between smallcaps and exclamation point, doesn't scale down exclamation point",
              "Water!",
              "W\\nolinebreak[4]\\RtSmCapsEmulation{17em}{ATER}{10em}\\nolinebreak[4]!",
            ],
            [
              "Applies custom kerning between smallcaps and comma, doesn't scale down comma",
              "Water,",
              "W\\nolinebreak[4]\\RtSmCapsEmulation{17em}{ATER}{11em}\\nolinebreak[4],",
            ],
            [
              "Applies custom kerning between smallcaps and period, doesn't scale down period",
              "Water.",
              "W\\nolinebreak[4]\\RtSmCapsEmulation{17em}{ATER}{12em}\\nolinebreak[4].",
            ],
            [
              "Two adjacent full caps",
              "WAter",
              "WA\\nolinebreak[4]\\RtSmCapsEmulation{3em}{TER}{none}",
            ],
            [
              "With accented character mapping",
              "Wáter Wáter",
              "W\\nolinebreak[4]\\RtSmCapsEmulation{17em}{ÁTER}{15em} W\\nolinebreak[4]\\RtSmCapsEmulation{17em}{ÁTER}{none}",
            ],
            [
              "Fullcaps inside a word",
              "WaterWater Word",
              "W\\nolinebreak[4]\\RtSmCapsEmulation{17em}{ATER}{15em}\\nolinebreak[4]W\\nolinebreak[4]\\RtSmCapsEmulation{17em}{ATER}{15em} W\\nolinebreak[4]\\RtSmCapsEmulation{18em}{ORD}{none}",
            ],
            [
              "Leading punctuation character",
              "¿Water",
              "¿W\\nolinebreak[4]\\RtSmCapsEmulation{17em}{ATER}{none}",
            ],
            [
              "Upper cases character after apostrophe",
              "Word#{ language.chars[:apostrophe] }s Word",
              "W\\nolinebreak[4]\\RtSmCapsEmulation{18em}{ORD}{8em}\\nolinebreak[4]#{ language.chars[:apostrophe] }\\nolinebreak[4]\\RtSmCapsEmulation{22em}{S}{16em} W\\nolinebreak[4]\\RtSmCapsEmulation{18em}{ORD}{none}",
            ],
            [
              "Upper cases A.D., not scaling down the periods inbetween",
              "a.d.",
              "\\RtSmCapsEmulation{none}{A}{2em}\\nolinebreak[4].\\nolinebreak[4]\\RtSmCapsEmulation{1em}{D}{5em}\\nolinebreak[4].",
            ],
            [
              "Standalone upper case chars",
              "Water A Water",
              "W\\nolinebreak[4]\\RtSmCapsEmulation{17em}{ATER}{14em} A\\RtSmCapsEmulation{none}{}{4em} W\\nolinebreak[4]\\RtSmCapsEmulation{17em}{ATER}{none}",
            ],
            [
              "Adjacent upper case chars",
              "Water AWater",
              "W\\nolinebreak[4]\\RtSmCapsEmulation{17em}{ATER}{14em} AW\\nolinebreak[4]\\RtSmCapsEmulation{17em}{ATER}{none}",
            ],
            [
              "Word that starts with lower case letter",
              "word Word",
              "\\RtSmCapsEmulation{none}{WORD}{6em} W\\nolinebreak[4]\\RtSmCapsEmulation{18em}{ORD}{none}",
            ],
            [
              "Cyrillic words",
              "Чтo пpивлекaет?",
              "Ч\\nolinebreak[4]\\RtSmCapsEmulation{21em}{ТO}{9em} \\RtSmCapsEmulation{none}{ПPИВЛЕКAЕТ}{20em}\\nolinebreak[4]?",
            ],
            [
              "Apostrophe inside word, followed by upper case char",
              "Word#{ language.chars[:apostrophe] }Word",
              "W\\nolinebreak[4]\\RtSmCapsEmulation{18em}{ORD}{8em}\\nolinebreak[4]#{ language.chars[:apostrophe] }W\\nolinebreak[4]\\RtSmCapsEmulation{18em}{ORD}{none}",
            ],
            [
              "Inter-word pairing of two lowercase chars",
              "Word word",
              "W\\nolinebreak[4]\\RtSmCapsEmulation{18em}{ORD}{7em} \\RtSmCapsEmulation{none}{WORD}{none}",
            ],
            [
              "Smallcaps with single fullcaps char (occurs in kerning samples PDF)",
              "waterWater",
              "\\RtSmCapsEmulation{none}{WATER}{15em}\\nolinebreak[4]W\\nolinebreak[4]\\RtSmCapsEmulation{17em}{ATER}{none}",
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
