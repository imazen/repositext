# encoding UTF-8
require_relative '../../../../helper'

class Repositext
  class Process
    class Split
      class Subtitles

        describe TransferStsFromPAlignedSentences2FAlignedSentences do

          let(:default_split_instance) { Split::Subtitles.new('_', '_') }

          describe '#transfer_subtitles' do
            [
              [
                'Simple case',
                '@word word @word word',
                'ward ward ward ward',
                ['@ward ward @ward ward', 1.0]
              ],
            ].each do |(desc, p_s, f_s, xpect)|
              it "handles #{ desc }" do
                default_split_instance.transfer_subtitles(
                  p_s, f_s
                ).result.must_equal(xpect)
              end
            end
          end

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
              [
                'Moves subtitles to beginning of word with accented character',
                '@word word @word word',
                'ward ward wàrdward ward',
                '@ward ward @wàrdward ward',
              ],
              [
                'Moves subtitles to beginning of word with escaped character',
                '@word word @word word',
                'ward ward&#x00A0;ward&#x202F;ward',
                '@ward @ward&#x00A0;ward&#x202F;ward',
              ],
            ].each do |(desc, p_s, f_s, xpect)|
              it "handles #{ desc }" do
                default_split_instance.interpolate_subtitle_positions(
                  p_s, f_s
                ).must_equal(xpect)
              end
            end
          end

          describe '#snap_subtitles_to_punctuation_signature' do
            [
              [
                'Simple case',
                '@word word, @word word',
                '@ward ward, ward @ward',
                ['@ward ward, @ward ward', 1.0],
              ],
              [
                'Snaps to correct punctuation even if closer to wrong one.',
                '@word word word, @word word word, word word word',
                '@ward ward ward, ward ward @ward, ward ward ward',
                ['@ward ward ward, @ward ward ward, ward ward ward', 1.0],
              ],
              [
                'Correct punctuation type is further away',
                '@word word word, @word word word; word word word',
                '@ward ward ward, ward ward @ward; ward ward ward',
                ['@ward ward ward, @ward ward ward; ward ward ward', 1.0],
              ],
              [
                'Elipsis without trailing space',
                '@word word…@word word',
                '@ward ward…ward @ward',
                ['@ward ward…@ward ward', 1.0],
              ],
              [
                'Multiple adjacent punctuation chars',
                '@word word), @word word',
                '@ward ward), ward @ward',
                ['@ward ward), @ward ward', 1.0],
              ],
            ].each do |(desc, p_s, f_s, xpect)|
              it "handles #{ desc }" do
                default_split_instance.snap_subtitles_to_punctuation_signature(
                  p_s, f_s
                ).result.must_equal(xpect)
              end
            end

            # ImplementationTag #punctuation_characters
            punctuation_marks = ".,;:!?)]…”—".chars

            punctuation_marks.each do |p_punct|
              punctuation_marks.each do |f_punct|
                it "snaps primary #{ p_punct.inspect } to foreign #{ f_punct.inspect }" do
                  p_s = "@word word#{ p_punct } @word word"
                  f_s = "@ward ward#{ f_punct } ward @ward"
                  xpect = ["@ward ward#{ f_punct } @ward ward", 1.0]
                  default_split_instance.snap_subtitles_to_punctuation_signature(
                    p_s, f_s
                  ).result.must_equal(xpect)
                end
              end
            end
          end

          describe '#snap_subtitles_to_nearby_punctuation' do
            [
              [
                'Simple case',
                '@word word word, @word word word. @word word word:',
                '@ward ward ward, ward @ward ward; ward @ward ward:',
                ['@ward ward ward, @ward ward ward; @ward ward ward:', 0.6400000000000001]
              ],
              [
                'Complex punctuation signature, subtitles after sequences of punctuation.',
                "word…word, “word,” [word, “word,”— word.] @“word;” [“word;”] “word,” [“word,”] @“word.” [“word.”]",
                "ward…ward ward: “ward,” [ward: “ward,”— @ward.] “ward;” [“ward;”] “ward,” [“ward, @ward”] “ward.” [“ward.”]",
                [
                  "ward…ward ward: “ward,” [ward: “ward,”— ward.] @“ward;” [“ward;”] “ward,” [“ward, ward”] @“ward.” [“ward.”]",
                  0.6400000000000001
                ],
              ],
            ].each do |(desc, p_s, f_s, xpect)|
              it "handles #{ desc }" do
                default_split_instance.snap_subtitles_to_nearby_punctuation(
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
