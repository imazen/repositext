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
            ].each do |(desc, f_ss, f_pt, f_s_confs, xpect)|
              it "handles #{ desc }" do
                default_split_instance.transfer_sts_from_sentences_to_plain_text(
                  f_ss, f_pt, f_s_confs
                ).result.must_equal(xpect)
              end
            end

          end
        end
      end
    end
  end
end
