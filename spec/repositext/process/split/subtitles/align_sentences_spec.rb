# encoding UTF-8
require_relative '../../../../helper'

class Repositext
  class Process
    class Split
      class Subtitles

        describe AlignSentences do

          let(:default_split_instance) { Split::Subtitles.new('_', '_') }

          describe '#align_sentences' do
            [
              [
                'Simple case',
                '@primary sentence 1.',
                ['primary sentence 1.'],
                ['@primary sentence 1.'],
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
