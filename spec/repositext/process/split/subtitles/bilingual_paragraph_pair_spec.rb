# encoding UTF-8
require_relative '../../../../helper'

class Repositext
  class Process
    class Split
      class Subtitles

        describe BilingualParagraphPair do

          let(:foreign_contents) { 'palabra1 palabra2 palabra3' }
          let(:primary_contents) { 'word1 word2 word3' }
          let(:foreign_language) { Language::Spanish.new }
          let(:primary_language) { Language::English.new }
          let(:foreign_paragraph) { Paragraph.new(foreign_contents, foreign_language) }
          let(:primary_paragraph) { Paragraph.new(primary_contents, primary_language) }
          let(:bilingual_paragraph_pair) { BilingualParagraphPair.new(primary_paragraph, foreign_paragraph) }

          describe '#aligned_text_pairs' do

            it "handles default data" do
              bilingual_paragraph_pair.aligned_text_pairs.map { |btp|
                [btp.primary_contents, btp.foreign_contents]
              }.must_equal([[primary_contents, foreign_contents]])
            end

          end

          describe '#confidence_stats' do

            it "handles default data" do
              bilingual_paragraph_pair.confidence_stats.must_equal(
                { max: 1.0, min: 1.0, mean: 1.0, median: 1.0, count: 1 }
              )
            end

          end

          describe '#compute_aligned_text_pairs' do

            it "handles default data" do
              bilingual_paragraph_pair.send(
                :compute_aligned_text_pairs,
                primary_paragraph,
                foreign_paragraph
              ).map { |btp|
                [btp.primary_contents, btp.foreign_contents]
              }.must_equal([[primary_contents, foreign_contents]])
            end

            describe 'Spanish' do

              let(:specific_foreign_language) { Language::Spanish.new }

              [
                [
                  '53-0609a para 88 etc.',
                  '88 Él dijo, Dios dijo: “He conocido la integridad de tu corazón, y por esa razón te he guardado de no pecar contra Mí; ¡pero ese es Mi profeta!”. ¡Aleluya!',
                  '@88 He said, God said, “I knowed the integrity of your heart, @and that’s the reason I kept you from sinning against Me. @But that’s My prophet!” Hallelujah!',
                  [
                    [
                      "@88 He said, God said, “I knowed the integrity of your heart, @and that’s the reason I kept you from sinning against Me. @But that’s My prophet!” Hallelujah!",
                      "88 Él dijo, Dios dijo: “He conocido la integridad de tu corazón, y por esa razón te he guardado de no pecar contra Mí; ¡pero ese es Mi profeta!”. ¡Aleluya!"
                    ],
                  ],
                ],
              ].each do |desc, foreign_contents, primary_contents, xpect|

                it "handles #{ desc.inspect }" do
                  primary_paragraph = Subtitles::Paragraph.new(primary_contents, primary_language)
                  foreign_paragraph = Subtitles::Paragraph.new(foreign_contents, specific_foreign_language)

                  r = bilingual_paragraph_pair.send(
                    :compute_aligned_text_pairs,
                    primary_paragraph,
                    foreign_paragraph
                  )
                  r.map { |bilingual_text_pair|
                    [bilingual_text_pair.primary_contents, bilingual_text_pair.foreign_contents]
                  }.must_equal(xpect)
                end

              end

            end

          end

          describe '#compute_raw_aligned_text_pairs' do

            it "handles default data" do
              bilingual_paragraph_pair.send(
                :compute_raw_aligned_text_pairs,
                primary_paragraph,
                foreign_paragraph
              ).map { |btp|
                [btp.primary_contents, btp.foreign_contents]
              }.must_equal([[primary_contents, foreign_contents]])
            end

            describe 'Spanish' do

              let(:specific_foreign_language) { Language::Spanish.new }

              [
                [
                  '53-0609a para 88 etc.',
                  '88 Él dijo, Dios dijo: “He conocido la integridad de tu corazón, y por esa razón te he guardado de no pecar contra Mí; ¡pero ese es Mi profeta!”. ¡Aleluya!',
                  '@88 He said, God said, “I knowed the integrity of your heart, @and that’s the reason I kept you from sinning against Me. @But that’s My prophet!” Hallelujah!',
                  [
                    [
                      "@88 He said, God said, “I knowed the integrity of your heart, @and that’s the reason I kept you from sinning against Me.",
                      "88 Él dijo, Dios dijo: “He conocido la integridad de tu corazón, y por esa razón te he guardado de no pecar contra Mí; ¡pero ese es Mi profeta!”."
                    ],
                    [
                      "@But that’s My prophet!” Hallelujah!",
                      "¡Aleluya!"
                    ]
                  ],
                ],
              ].each do |desc, foreign_contents, primary_contents, xpect|
                it "handles #{ desc.inspect }" do
                  primary_paragraph = Subtitles::Paragraph.new(primary_contents, primary_language)
                  foreign_paragraph = Subtitles::Paragraph.new(foreign_contents, specific_foreign_language)

                  r = bilingual_paragraph_pair.send(
                    :compute_raw_aligned_text_pairs,
                    primary_paragraph,
                    foreign_paragraph
                  )
                  r.map { |bilingual_text_pair|
                    [bilingual_text_pair.primary_contents, bilingual_text_pair.foreign_contents]
                  }.must_equal(xpect)
                end

              end

            end

            [
              [
                'word1 word2 word3 word4',
                'palabra1 palabra2 palabra3 palabra4',
                [
                  ["word1 word2 word3 word4", "palabra1 palabra2 palabra3 palabra4"]
                ],
                [1.0],
              ],
              [
                'word1 word2. word3 word4. word5 word6.',
                'palabra1 palabra2. palabra3 palabra4. palabra5 palabra6.',
                [
                  ["word1 word2.", "palabra1 palabra2."],
                  ["word3 word4.", "palabra3 palabra4."],
                  ["word5 word6.", "palabra5 palabra6."]
                ],
                [1.0, 1.0, 1.0],
              ],
              [
                'word1 word2. word3 word4. word5 word6.',
                'palabra1 palabra2. palabra3 palabra4.',
                [
                  ["word1 word2. word3 word4.", "palabra1 palabra2."],
                  ["word5 word6.", "palabra3 palabra4."]
                ],
                [0.5, 1.0],
              ],
            ].each { |(primary_contents, foreign_contents, xpect_contents, xpect_confidences)|
              it "handles #{ primary_contents.inspect }" do
                r = bilingual_paragraph_pair.send(
                  :compute_raw_aligned_text_pairs,
                  Paragraph.new(primary_contents, primary_language),
                  Paragraph.new(foreign_contents, foreign_language)
                )
                r.map { |btp|
                  [btp.primary_contents, btp.foreign_contents]
                }.must_equal(xpect_contents)
                r.map { |btp| btp.confidence }.must_equal(xpect_confidences)
              end
            }

          end

          describe '#merge_text_pairs_with_gaps' do

            it 'handles default data' do
              r = bilingual_paragraph_pair.send(
                :merge_text_pairs_with_gaps,
                bilingual_paragraph_pair.aligned_text_pairs
              )
              r.map { |bilingual_text_pair|
                [bilingual_text_pair.primary_contents, bilingual_text_pair.foreign_contents]
              }.must_equal([["word1 word2 word3", "palabra1 palabra2 palabra3"]])
            end

            [
              [
                'All text pairs have full confidence, return as is',
                [
                  ['word1 word2 word3', 'palabra1 palabra2 palabra3'],
                  ['word4 word5 word6', 'palabra4 palabra5 palabra6'],
                ],
                [
                  ['word1 word2 word3', 'palabra1 palabra2 palabra3'],
                  ['word4 word5 word6', 'palabra4 palabra5 palabra6'],
                ],
              ],
              [
                'Single btp with gap in first position, merge into second',
                [
                  ['word1 word2 word3 word4', ''],
                  ['word5 word6 word7 word8', 'palabra1 palabra2 palabra3 palabra4'],
                ],
                [['word1 word2 word3 word4 word5 word6 word7 word8', 'palabra1 palabra2 palabra3 palabra4']]
              ],
              [
                'Single btp with gap bookended by btps without gaps, merge into last',
                [
                  ['word1 word2 word3 word4', 'palabra1 palabra2 palabra3 palabra4'],
                  ['word5 word6 word7 word8', ''],
                  ['word9 word10 word11 word12', 'palabra9 palabra10 palabra11 palabra12'],
                ],
                [
                  ['word1 word2 word3 word4', 'palabra1 palabra2 palabra3 palabra4'],
                  ['word5 word6 word7 word8 word9 word10 word11 word12', 'palabra9 palabra10 palabra11 palabra12']
                ]
              ],
              [
                'Single btp in last position, merge into first',
                [
                  ['word1 word2 word3 word4', 'palabra1 palabra2 palabra3 palabra4'],
                  ['word5 word6 word7 word8', ''],
                ],
                [['word1 word2 word3 word4 word5 word6 word7 word8', 'palabra1 palabra2 palabra3 palabra4']]
              ],
              [
                'Two adjacent btps with gaps in first positions, merge into third',
                [
                  ['word1 word2 word3 word4', ''],
                  ['word5 word6 word7 word8', ''],
                  ['word9 word10 word11 word12', 'palabra1 palabra2 palabra3 palabra4'],
                ],
                [['word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12', 'palabra1 palabra2 palabra3 palabra4']]
              ],
              [
                'Two adjacent btps with gaps bookended by btps without gaps, merge into last',
                [
                  ['word1 word2 word3 word4', 'palabra1 palabra2 palabra3 palabra4'],
                  ['word5 word6 word7 word8', ''],
                  ['word9 word10 word11 word12', ''],
                  ['word13 word14 word15 word16', 'palabra13 palabra14 palabra15 palabra16'],
                ],
                [
                  ['word1 word2 word3 word4',  'palabra1 palabra2 palabra3 palabra4'],
                  ['word5 word6 word7 word8 word9 word10 word11 word12 word13 word14 word15 word16', 'palabra13 palabra14 palabra15 palabra16']
                ]
              ],
              [
                'Two adjacent btps in last positions, merge into first',
                [
                  ['word1 word2 word3 word4', 'palabra1 palabra2 palabra3 palabra4'],
                  ['word5 word6 word7 word8', ''],
                  ['word9 word10 word11 word12', ''],
                ],
                [['word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12', 'palabra1 palabra2 palabra3 palabra4']]
              ],
              [
                'Two adjacent btps (pri and for) with gaps followed by btps without gaps, merge into last',
                [
                  ['word1 word2 word3 word4', ''],
                  ['', 'palabra1 palabra2 palabra3 palabra4'],
                  ['word5 word6 word7 word8', 'palabra5 palabra6 palabra7 palabra8'],
                ],
                [['word1 word2 word3 word4 word5 word6 word7 word8', 'palabra1 palabra2 palabra3 palabra4 palabra5 palabra6 palabra7 palabra8']]
              ],
              [
                'All btps (pri and for) have gaps, merge all together',
                [
                  ['word1 word2 word3 word4', ''],
                  ['', 'palabra1 palabra2 palabra3 palabra4'],
                  ['word5 word6 word7 word8', ''],
                ],
                [['word1 word2 word3 word4 word5 word6 word7 word8', 'palabra1 palabra2 palabra3 palabra4']]
              ],
            ].each do |description, text_pair_contents, xpect|
              it "handles #{ description.inspect }" do
                bilingual_text_pairs = text_pair_contents.map { |text_pair_content|
                  Subtitles::BilingualTextPair.new(
                    Repositext::Text.new(text_pair_content.first, primary_language),
                    Repositext::Text.new(text_pair_content.last, foreign_language)
                  )
                }
                r = bilingual_paragraph_pair.send(:merge_text_pairs_with_gaps, bilingual_text_pairs)
                r.map { |bilingual_text_pair|
                  [bilingual_text_pair.primary_contents, bilingual_text_pair.foreign_contents]
                }.must_equal(xpect)
              end
            end

          end

          describe '#merge_low_confidence_text_pairs' do

            it 'handles default data' do
              r = bilingual_paragraph_pair.send(
                :merge_low_confidence_text_pairs,
                bilingual_paragraph_pair.aligned_text_pairs
              )
              r.map { |bilingual_text_pair|
                [bilingual_text_pair.primary_contents, bilingual_text_pair.foreign_contents]
              }.must_equal([["word1 word2 word3", "palabra1 palabra2 palabra3"]])
            end

            [
              [
                'All text pairs have full confidence, return as is',
                [
                  ['word1 word2 word3', 'palabra1 palabra2 palabra3'],
                  ['word4 word5 word6', 'palabra4 palabra5 palabra6'],
                ],
                [
                  ['word1 word2 word3', 'palabra1 palabra2 palabra3'],
                  ['word4 word5 word6', 'palabra4 palabra5 palabra6'],
                ],
              ],
              [
                'Only full and medium confidence, no adjacent pairs with medium, return as is',
                [
                  ['word1 word2 word3', 'palabra1 palabra2 palabra3'],
                  ['word4 word5 word6', 'palabra4'],
                  ['word7 word8 word9', 'palabra7 palabra8 palabra9'],
                ],
                [
                  ['word1 word2 word3', 'palabra1 palabra2 palabra3'],
                  ['word4 word5 word6', 'palabra4'],
                  ['word7 word8 word9', 'palabra7 palabra8 palabra9'],
                ],
              ],
              [
                'All lacking confidence pairs are adjacent, merge them',
                [
                  ['word1 word2 word3', 'palabra1 palabra2 palabra3'],
                  ['word4 word5 word6', 'palabra4'],
                  ['word7 word8 word9', ''],
                  ['word10 word11 word12', 'palabra10 palabra11 palabra12'],
                ],
                [
                  ['word1 word2 word3', 'palabra1 palabra2 palabra3'],
                  ['word4 word5 word6 word7 word8 word9', 'palabra4'],
                  ['word10 word11 word12', 'palabra10 palabra11 palabra12'],
                ],
              ],
              [
                'No full confidence btps, merge entire para',
                [
                  ['word1 word2 word3', 'palabra1'],
                  ['word4', 'palabra4 palabra5 palabra6'],
                ],
                [
                  ['word1 word2 word3 word4', 'palabra1 palabra4 palabra5 palabra6'],
                ],
              ],
              [
                'Mix of adjacent and non-adjacent lacking confidence btps, merge entire para',
                [
                  ['word1 word2 word3', 'palabra1'],
                  ['word4 word5 word6', 'palabra4 palabra5 palabra6'],
                  ['word7', 'palabra7 palabra8 palabra9'],
                  ['word10 word11 word12', 'palabra10'],
                  ['word13 word14 word15', 'palabra13 palabra14 palabra15'],
                ],
                [
                  [
                    'word1 word2 word3 word4 word5 word6 word7 word10 word11 word12 word13 word14 word15',
                    'palabra1 palabra4 palabra5 palabra6 palabra7 palabra8 palabra9 palabra10 palabra13 palabra14 palabra15'
                  ],
                ],
              ],
            ].each do |description, text_pair_contents, xpect|
              it "handles #{ description.inspect }" do
                bilingual_text_pairs = text_pair_contents.map { |text_pair_content|
                  Subtitles::BilingualTextPair.new(
                    Repositext::Text.new(text_pair_content.first, primary_language),
                    Repositext::Text.new(text_pair_content.last, foreign_language)
                  )
                }
                r = bilingual_paragraph_pair.send(:merge_low_confidence_text_pairs, bilingual_text_pairs)
                r.map { |bilingual_text_pair|
                  [bilingual_text_pair.primary_contents, bilingual_text_pair.foreign_contents]
                }.must_equal(xpect)
              end
            end

          end

          describe '#merge_lacking_confidence_adjacent_pairs' do

            it 'handles default data' do
              r = bilingual_paragraph_pair.send(
                :merge_lacking_confidence_adjacent_pairs,
                bilingual_paragraph_pair.aligned_text_pairs
              )
              r.map { |bilingual_text_pair|
                [bilingual_text_pair.primary_contents, bilingual_text_pair.foreign_contents]
              }.must_equal([["word1 word2 word3", "palabra1 palabra2 palabra3"]])
            end

            [
              [
                'Two adjacent lacking confidence pairs in the middle, bookended by full confidence pairs',
                [
                  ['word1 word2 word3', 'palabra1 palabra2 palabra3'],
                  ['word4 word5 word6', 'palabra4'],
                  ['word7 word8 word9', ''],
                  ['word10 word11 word12', 'palabra10 palabra11 palabra12'],
                ],
                [
                  ['word1 word2 word3', 'palabra1 palabra2 palabra3'],
                  ['word4 word5 word6 word7 word8 word9', 'palabra4'],
                  ['word10 word11 word12', 'palabra10 palabra11 palabra12'],
                ],
              ],
            ].each do |description, text_pair_contents, xpect|
              it "handles #{ description.inspect }" do
                bilingual_text_pairs = text_pair_contents.map { |text_pair_content|
                  Subtitles::BilingualTextPair.new(
                    Repositext::Text.new(text_pair_content.first, primary_language),
                    Repositext::Text.new(text_pair_content.last, foreign_language)
                  )
                }
                r = bilingual_paragraph_pair.send(
                  :merge_lacking_confidence_adjacent_pairs,
                  bilingual_text_pairs
                )
                r.map { |bilingual_text_pair|
                  [bilingual_text_pair.primary_contents, bilingual_text_pair.foreign_contents]
                }.must_equal(xpect)
              end
            end

          end

        end

      end
    end
  end
end

