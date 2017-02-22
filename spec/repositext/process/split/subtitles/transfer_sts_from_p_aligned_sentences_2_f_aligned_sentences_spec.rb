# encoding UTF-8
require_relative '../../../../helper'

class Repositext
  class Process
    class Split
      class Subtitles

        describe TransferStsFromPAlignedSentences2FAlignedSentences do

          let(:default_split_instance) { Split::Subtitles.new('_', '_') }

          describe '#interpolate_subtitle_positions' do
            [
              [
                'Simple case',
                '@word word @word word',
                'ward ward ward ward',
                '@ward ward @ward ward',
              ],
              [
                'Double length',
                '@word word @word word',
                'wardward wardward wardward wardward',
                '@wardward wardward @wardward wardward',
              ],
              [
                'Moves subtitles to beginning of word',
                '@word word @word word',
                'ward wardwardward ward',
                '@ward @wardwardward ward',
              ],
            ].each do |(desc, p_s, f_s, xpect)|
              it "handles #{ desc }" do
                default_split_instance.interpolate_subtitle_positions(
                  p_s, f_s
                ).must_equal(xpect)
              end
            end
          end

          describe '#snap_subtitles_to_punctuation' do
            [
              [
                'Simple case',
                '@word word, @word word',
                '@ward ward, ward @ward',
                ['@ward ward, @ward ward', 0.8],
              ],
              [
                'Snaps to closest punctuation if both are the same',
                '@word word word, @word word word, word word word',
                '@ward ward ward, ward ward @ward, ward ward ward',
                ['@ward ward ward, ward ward ward, @ward ward ward', 0.8],
              ],
              [
                'Correct punctuation type is further away',
                '@word word word, @word word word; word word word',
                '@ward ward ward, ward ward @ward; ward ward ward',
                ['@ward ward ward, @ward ward ward; ward ward ward', 0.8],
              ],
            ].each do |(desc, p_s, f_s, xpect)|
              it "handles #{ desc }" do
                default_split_instance.snap_subtitles_to_punctuation(
                  p_s, f_s
                ).result.must_equal(xpect)
              end
            end
          end

        end
      end
    end
  end
end
