# encoding UTF-8
require_relative '../../../../helper'

class Repositext
  class Process
    class Split
      class Subtitles

        describe TransferStsFromFAlignedSentences2FPlainText do

          let(:default_split_instance) { Split::Subtitles.new('_', '_') }

          describe '#transfer_sts_from_sentences_to_plain_text' do
            [
              [
                'Simple case',
                [
                  '@foreign sentence 1.',
                ],
                'foreign sentence 1.',
                [1],
                [
                  '@foreign sentence 1.',
                  [1],
                ],
              ],
              [
                'With subtitle at end from asp gap',
                [
                  '@foreign sentence 1. foreign sentence 2.@',
                ],
                'foreign sentence 1. foreign sentence 2.',
                [0],
                [
                  '@foreign sentence 1. foreign sentence 2.@',
                  [0,0],
                ],
              ],
              [
                'Without subtitles',
                [
                  'foreign sentence 1.',
                ],
                'foreign sentence 1.',
                [1],
                [
                  'foreign sentence 1.',
                  [],
                ],
              ],
              [
                'Paragraph numbers in pt (initially in invalid position after pn)',
                [
                  '@foreign sentence.',
                ],
                '123 foreign sentence.',
                [1],
                [
                  '123 @foreign sentence.',
                  [1],
                ],
              ],
              [
                'Partial matches (sentence aligner merged sentences from two paras)',
                [
                  '@foreign sentence para1. foreign sentence para2.',
                ],
                "foreign sentence para1.\nforeign sentence para2.",
                [1],
                [
                  "@foreign sentence para1.\nforeign sentence para2.",
                  [1],
                ],
              ],
              [
                'comma after closing parens',
                [
                  '@foreign sentence (para1), @foreign sentence para2.',
                ],
                "foreign sentence (para1), foreign sentence para2.",
                [1,1],
                [
                  "@foreign sentence (para1), @foreign sentence para2.",
                  [1,1],
                ],
              ],
              [
                'Subtitle mark at the end of previous sentence',
                [
                  "@word word, word word.@",
                  "“word!” word",
                ],
                "244 word word, word word. “word!” word",
                [1,1],
                [
                  "244 @word word, word word.@ “word!” word",
                  [1,1],
                ],
              ],
              [
                'Plain text contains no-break space that was removed from aligned sentences by aligner',
                [
                  "@word word.",
                ],
                "word\u00A0word.",
                [1],
                [
                  "@word\u00A0word.",
                  [1],
                ],
              ],
              [
                'Run of multiple stms at beginning of line',
                [
                  "@@@word word.",
                ],
                "word word.",
                [1,1,1],
                [
                  "@@@word word.",
                  [1,1,1],
                ],
              ],
              [
                'Run of multiple stms in the middle of line',
                [
                  "word @@@word.",
                ],
                "word word.",
                [1,1,1],
                [
                  "word @@@word.",
                  [1,1,1],
                ],
              ],
              [
                'Run of multiple stms at end of line',
                [
                  "word word.@@@",
                ],
                "word word.",
                [1,1,1],
                [
                  "word word.@@@",
                  [1,1,1],
                ],
              ],
            ].each do |(desc, f_ss, f_pt, f_s_confs, xpect)|
              it "handles #{ desc }" do
                default_split_instance.transfer_sts_from_sentences_to_plain_text(
                  f_ss, f_pt, f_s_confs
                ).result.must_equal(xpect)
              end
            end
          end

          describe '#post_process_f_plain_text' do
            [
              [
                'Simple case',
                "# Header\n@foreign sentence 1.",
                [1],
                [
                  "# Header\n@foreign sentence 1.",
                  [1],
                ],
              ],
              [
                'Move stm after pn to before pn',
                "# Header\n12 @foreign sentence 1.",
                [1],
                [
                  "# Header\n@12 foreign sentence 1.",
                  [1],
                ],
              ],
              [
                'Move stm from previous line',
                "# Header\n@line1 word word @word\nline2 word word word @word",
                [1],
                [
                  "# Header\n@line1 word word word\n@line2 word word word @word",
                  [1],
                ],
              ],
              [
                'Move stm from current line',
                "# Header\n@line1 word @word word\nline2 @word word word word",
                [1],
                [
                  "# Header\n@line1 word @word word\n@line2 word word word word",
                  [1],
                ],
              ],
              [
                'Move stm up to beginning of word',
                "# Header\n@line1 word.@ word word",
                [1],
                [
                  "# Header\n@line1 word. @word word",
                  [1],
                ],
              ],
              [
                'Move stm up to beginning of quote',
                "# Header\n@line1 word.@ “word word",
                [1],
                [
                  "# Header\n@line1 word. @“word word",
                  [1],
                ],
              ],
              [
                'Move spaces inside stm sequences to the left',
                "# Header\n@line1 word.@@@@@@ @word word",
                [1],
                [
                  "# Header\n@line1 word. @@@@@@@word word",
                  [1],
                ],
              ],
              [
                'Move stm to the outside of closing quotes',
                "# Header\n@line1 word.@” word word",
                [1],
                [
                  "# Header\n@line1 word.” @word word",
                  [1],
                ],
              ],
            ].each do |(desc, f_pt, f_s_confs, xpect)|
              it "handles #{ desc }" do
                default_split_instance.post_process_f_plain_text(
                  f_pt, f_s_confs
                ).result.must_equal(xpect)
              end
            end
          end

          describe '#validate_that_no_plain_text_content_was_changed' do
            it "doesn't raise if plain text hasn't changed" do
              default_split_instance.validate_that_no_plain_text_content_was_changed(
                "# Foreign plain text\n@with headers and subtitles.",
                "# Foreign plain text\n@with headers and subtitles.",
              )
              1.must_equal(1)
            end

            it "raises if plain text has changed" do
              lambda {
                default_split_instance.validate_that_no_plain_text_content_was_changed(
                  "# Foreign plain text\n@with headers and subtitles.",
                  "# Changed foreign plain text\n@with headers and subtitles.",
                )
              }.must_raise(RuntimeError)
            end
          end

          describe '#validate_same_number_of_sts_in_as_and_pt' do
            it "doesn't raise if they have same number of subtitles" do
              default_split_instance.validate_same_number_of_sts_in_as_and_pt(
                [
                  "@sentence 1.",
                  "@sentence 2.",
                ],
                "@sentence 1. @sentence 2."
              )
              1.must_equal(1)
            end

            it "raises if plain text has changed" do
              lambda {
                default_split_instance.validate_same_number_of_sts_in_as_and_pt(
                  [
                    "@@sentence 1.",
                    "@sentence 2.",
                  ],
                  "@sentence 1. @sentence 2."
                )
              }.must_raise(RuntimeError)
            end
          end

        end
      end
    end
  end
end
