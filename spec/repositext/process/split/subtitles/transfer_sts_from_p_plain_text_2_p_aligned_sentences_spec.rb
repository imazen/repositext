# encoding UTF-8
require_relative '../../../../helper'

class Repositext
  class Process
    class Split
      class Subtitles

        describe TransferStsFromPrimaryPlainText2PrimaryAlignedSentences do

          let(:default_split_instance) { Split::Subtitles.new('_', '_') }

          describe '#transfer_sts_from_plain_text_2_sentences' do
            [
              [
                'Simple case',
                '@primary sentence 1.',
                ['primary sentence 1.'],
                ['@primary sentence 1.'],
              ],
              [
                'Multiple sentences',
                '@primary sentence 1. @primary sentence 2.',
                [
                  'primary sentence 1.',
                  'primary sentence 2.',
                ],
                [
                  '@primary sentence 1.',
                  '@primary sentence 2.',
                ],
              ],
              [
                'Subtitles that are not aligned with sentences',
                '@primary sentence 1 word1 @word2 word3.',
                [
                  'primary sentence 1 word1 word2 word3.',
                ],
                [
                  '@primary sentence 1 word1 @word2 word3.',
                ],
              ],
            ].each do |(desc, p_pt, p_ss, xpect)|
              it "handles #{ desc }" do
                default_split_instance.transfer_sts_from_plain_text_2_sentences(
                  p_pt, p_ss
                ).must_equal(xpect)
              end
            end

            # TODO: Simulate error conditions and make sure they get handled correctly!

          end
        end
      end
    end
  end
end
