# encoding UTF-8
require_relative '../../../../helper'

class Repositext
  class Process
    class Split
      class Subtitles

        describe BilingualTextPair do

          let(:foreign_contents) { 'palabra1 palabra2 palabra3' }
          let(:primary_contents) { 'word1 word2 word3' }
          let(:foreign_language) { Language::Spanish.new }
          let(:primary_language) { Language::English.new }
          let(:foreign_text) { Text.new(foreign_contents, foreign_language) }
          let(:primary_text) { Text.new(primary_contents, primary_language) }
          let(:bilingual_text_pair) { BilingualTextPair.new(primary_text, foreign_text) }

          describe '.merge' do

            [
              [
                'Single text pair, return as is',
                [['word1 word2 word3 word4', 'palabra1 palabra2 palabra3 palabra4']],
                ['word1 word2 word3 word4', 'palabra1 palabra2 palabra3 palabra4']
              ],
              [
                'One btp with gap, one without, merge together',
                [
                  ['word1 word2 word3 word4', ''],
                  ['word5 word6 word7 word8', 'palabra1 palabra2 palabra3 palabra4'],
                ],
                ['word1 word2 word3 word4 word5 word6 word7 word8', 'palabra1 palabra2 palabra3 palabra4']
              ],
              [
                'Single btp with gap bookended by btps without gaps, merge together',
                [
                  ['word1 word2 word3 word4', 'palabra1 palabra2 palabra3 palabra4'],
                  ['word5 word6 word7 word8', ''],
                  ['word9 word10 word11 word12', 'palabra9 palabra10 palabra11 palabra12'],
                ],
                ['word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12', 'palabra1 palabra2 palabra3 palabra4 palabra9 palabra10 palabra11 palabra12']
              ],
              [
                'One btp without gap, one with gap, merge together',
                [
                  ['word1 word2 word3 word4', 'palabra1 palabra2 palabra3 palabra4'],
                  ['word5 word6 word7 word8', ''],
                ],
                ['word1 word2 word3 word4 word5 word6 word7 word8', 'palabra1 palabra2 palabra3 palabra4']
              ],
              [
                'Two adjacent btps (pri and for) with gaps followed by btp without gaps, merge together',
                [
                  ['word1 word2 word3 word4', ''],
                  ['', 'palabra1 palabra2 palabra3 palabra4'],
                  ['word5 word6 word7 word8', 'palabra5 palabra6 palabra7 palabra8'],
                ],
                ['word1 word2 word3 word4 word5 word6 word7 word8', 'palabra1 palabra2 palabra3 palabra4 palabra5 palabra6 palabra7 palabra8']
              ],
              [
                'All btps (pri and for) have gaps, merge all together',
                [
                  ['word1 word2 word3 word4', ''],
                  ['', 'palabra1 palabra2 palabra3 palabra4'],
                  ['word5 word6 word7 word8', ''],
                ],
                ['word1 word2 word3 word4 word5 word6 word7 word8', 'palabra1 palabra2 palabra3 palabra4']
              ],
            ].each { |(description, text_pairs, xpect)|
              it "handles #{ description }" do
                input_btps = text_pairs.map { |(pri_con, for_con)|
                  BilingualTextPair.new(
                    Text.new(pri_con, primary_language),
                    Text.new(for_con, foreign_language)
                  )
                }
                merged_btp = BilingualTextPair.merge(input_btps)
                merged_btp.primary_contents.must_equal(xpect.first)
                merged_btp.foreign_contents.must_equal(xpect.last)
              end
            }

          end

          describe 'Initializing' do

            it "initializes primary_text" do
              bilingual_text_pair.primary_text.must_equal(primary_text)
            end

            it "initializes foreign_text" do
              bilingual_text_pair.foreign_text.must_equal(foreign_text)
            end

          end

          describe '#confidence' do

            it "computes correct confidence" do
              bilingual_text_pair.confidence.must_equal(1.0)
            end

            [
              ['word1 word2 word3 word4', 'palabra1 palabra2 palabra3 palabra4', 1.0],
              ['word1 word2 word3 word4', 'palabra1 palabra2 palabra3', 1.0],
              ['word1 word2 word3 word4', 'palabra1 palabra2', 0.5],
              ['word1 word2 word3 word4', 'palabra1', 0.25],
              ['word1 word2 word3 word4', '', 0.0],
              ['word1 word2 word3 word4', 'palabra1 palabra2 palabra3 palabra4', 1.0],
              ['word1 word2 word3', 'palabra1 palabra2 palabra3 palabra4', 1.0],
              ['word1 word2', 'palabra1 palabra2 palabra3 palabra4', 0.5],
              ['word1', 'palabra1 palabra2 palabra3 palabra4', 0.25],
              ['', 'palabra1 palabra2 palabra3 palabra4', 0.0],
            ].each { |(primary_contents, foreign_contents, xpect)|
              it "handles #{ primary_contents.inspect }" do
                BilingualTextPair.new(
                  Text.new(primary_contents, primary_language),
                  Text.new(foreign_contents, foreign_language)
                ).confidence.must_equal(xpect)
              end
            }

          end

          describe '#confidence_boundaries' do

            it "computes correct confidence_boundaries" do
              bilingual_text_pair.confidence_boundaries.must_equal([0.48, 1.85]) # for 3 words
            end

            [
              [1, [0.4, 2.0]],
              [2, [0.45, 1.9]],
              [3, [0.48, 1.85]],
              [4, [0.52, 1.8]],
              [5, [0.55, 1.75]],
              [6, [0.58, 1.7]],
              [7, [0.62, 1.65]],
              [8, [0.63, 1.6]],
              [9, [0.68, 1.58]],
              [10, [0.7, 1.52]],
              [15, [0.75, 1.4]],
              [20, [0.8, 1.3]],
              [30, [0.85, 1.2]],
              [40, [0.9, 1.12]],
              [50, [0.95, 1.1]],
              [60, [0.97, 1.08]],
            ].each { |max_word_count, xpect|
              it "handles #{ max_word_count.inspect }" do
                BilingualTextPair.new(
                  Text.new('word ' * max_word_count, primary_language),
                  Text.new('palabra', foreign_language)
                ).confidence_boundaries.must_equal(xpect)
              end
            }

          end

          describe '#foreign_contents' do
            it "returns foreign_contents" do
              bilingual_text_pair.foreign_contents.must_equal(foreign_contents)
            end
          end

          describe '#foreign_language' do
            it "returns foreign_language" do
              bilingual_text_pair.foreign_language.must_equal(foreign_language)
            end
          end

          describe '#length_ratio_in_words' do

            it "returns length_ratio_in_words" do
              bilingual_text_pair.length_ratio_in_words.must_equal(1.0)
            end

            [
              ['word word word', 'palabra palabra palabra', 1.0],
              ['', 'palabra palabra palabra', 0.0],
              ['word word word', '', 0.0],
              ['word word', 'palabra palabra palabra', 3/2.0],
              ['word word word', 'palabra palabra', 2/3.0],
              [('word ' * 100), 'palabra palabra palabra', 3/100.0],
            ].each { |primary_contents, foreign_contents, xpect|
              it "handles #{ primary_contents.inspect }" do
                BilingualTextPair.new(
                  Text.new(primary_contents, primary_language),
                  Text.new(foreign_contents, foreign_language)
                ).length_ratio_in_words.must_equal(xpect)
              end
            }

          end

          describe '#length_ratio_in_words_is_within_bounds' do
            it "returns length_ratio_in_words" do
              bilingual_text_pair.length_ratio_in_words_is_within_bounds.must_equal(true)
            end
          end

          describe '#max_word_length' do
            it "returns max_word_length" do
              bilingual_text_pair.max_word_length.must_equal(3)
            end
          end

          describe '#min_word_length' do
            it "returns min_word_length" do
              bilingual_text_pair.min_word_length.must_equal(3)
            end
          end

          describe '#primary_contents' do
            it "returns primary_contents" do
              bilingual_text_pair.primary_contents.must_equal(primary_contents)
            end
          end

          describe '#primary_language' do
            it "returns primary_language" do
              bilingual_text_pair.primary_language.must_equal(primary_language)
            end
          end

        end

      end
    end
  end
end
