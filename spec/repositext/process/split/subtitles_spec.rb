# encoding UTF-8
require_relative '../../../helper'

class Repositext
  class Process
    class Split

      describe Subtitles do

        let(:foreign_language) { Language::Spanish.new }
        let(:primary_language) { Language::English.new }
        let(:foreign_lines) {
          [
            '1 palabra1 palabra2 palabra3 palabra4',
            '2 palabra1 palabra2. palabra3 palabra4',
            '3 palabra1. palabra2 palabra3. palabra4',
          ]
        }
        let(:primary_lines) {
          [
            '@1 word1 word2 word3 word4',
            '@2 word1 word2. @word3 word4',
            '@3 word1. @word2 word3. @word4',
          ]
        }
        let(:foreign_contents) { (foreign_lines.map { |e| "#{ e }\n{: .normal}" }.join("\n\n")) + "\n" }
        let(:primary_contents) { (primary_lines.map { |e| "#{ e }\n{: .normal}" }.join("\n\n")) + "\n" }
        let(:foreign_filename) { 'path/to/foreign_file' }
        let(:primary_filename) { 'path/to/primary_file' }
        let(:foreign_file) { RFile.new(foreign_contents, foreign_language, foreign_filename) }
        let(:primary_file) { RFile.new(primary_contents, primary_language, primary_filename) }
        let(:subtitle_splitter) { Subtitles.new(foreign_file, primary_file) }

        describe '#split' do

          it 'handles default data' do
            subtitle_splitter.split.result.must_equal(
              [
                '@1 palabra1 palabra2 palabra3 palabra4',
                '{: .normal}',
                '',
                '@2 palabra1 palabra2. @palabra3 palabra4',
                '{: .normal}',
                '',
                '@3 palabra1. @palabra2 palabra3. @palabra4',
                '{: .normal}',
                '',
              ].join("\n")
            )
          end

          describe 'Spanish' do

            let(:specific_foreign_language) { Language::Spanish.new }

            [
              [
                '53-0609a para 88 etc.',
                [
                  '*88*{: .pn} Él dijo, Dios dijo: “He conocido la integridad de tu corazón, y por esa razón te he guardado de no pecar contra Mí; ¡pero ese es Mi profeta!”. ¡Aleluya!',
                  '{: .normal_pn}',
                  '',
                ].join("\n"),
                [
                  '@*88*{: .pn} %He said, God said, “I knowed the integrity of your heart, @and that’s the reason I kept you from sinning against Me. @But that’s My prophet!” Hallelujah!',
                  '{: .normal_pn}',
                  '',
                ].join("\n"),
                [
                  '@*88*{: .pn} Él dijo, Dios dijo: “He conocido la integridad de tu corazón, @y por esa razón te he guardado de no pecar contra Mí; @¡pero ese es Mi profeta!”. ¡Aleluya!',
                  '{: .normal_pn}',
                  '',
                ].join("\n"),
              ],
            ].each do |desc, foreign_contents, primary_contents, xpect|
              it "handles #{ desc.inspect }" do
                foreign_file = RFile.new(foreign_contents, specific_foreign_language, foreign_filename)
                primary_file = RFile.new(primary_contents, primary_language, primary_filename)
                subtitle_splitter = Subtitles.new(foreign_file, primary_file)
                subtitle_splitter.split.result.must_equal(xpect)
              end
            end

          end

        end

        describe '#compute_primary_sequence' do

          it 'handles default data' do
            r = subtitle_splitter.send(:compute_primary_sequence, primary_contents, primary_language)
            r.paragraphs.first.language.must_equal(primary_language)
            r.paragraphs.map { |paragraph| paragraph.contents }.must_equal(primary_lines)
          end

          [
            [
              '53-0609a para 88 etc.',
              [
                '@*88*{: .pn} %He said, God said, “I knowed the integrity of your heart, @and that’s the reason I kept you from sinning against Me. @But that’s My prophet!” Hallelujah!',
                '{: .normal_pn}',
                '',
              ].join("\n"),
              [
                '@88 He said, God said, “I knowed the integrity of your heart, @and that’s the reason I kept you from sinning against Me. @But that’s My prophet!” Hallelujah!',
              ]
            ],
          ].each do |desc, primary_contents, xpect|

            it "handles #{ desc.inspect }" do
              r = subtitle_splitter.send(:compute_primary_sequence, primary_contents, primary_language)
              r.paragraphs.map { |para| para.contents }.must_equal(xpect)
            end

          end

        end

        describe '#compute_foreign_sequence' do

          it 'handles default data' do
            r = subtitle_splitter.send(:compute_foreign_sequence, foreign_contents, foreign_language)
            r.paragraphs.first.language.must_equal(foreign_language)
            r.paragraphs.map { |paragraph| paragraph.contents }.must_equal(foreign_lines)
          end

          describe 'Spanish' do

            let(:specific_foreign_language) { Language::Spanish.new }

            [
              [
                '53-0609a para 88 etc.',
                [
                  '*88*{: .pn} Él dijo, Dios dijo: “He conocido la integridad de tu corazón, y por esa razón te he guardado de no pecar contra Mí; ¡pero ese es Mi profeta!”. ¡Aleluya!',
                  '{: .normal_pn}',
                  '',
                ].join("\n"),
                [
                  '88 Él dijo, Dios dijo: “He conocido la integridad de tu corazón, y por esa razón te he guardado de no pecar contra Mí; ¡pero ese es Mi profeta!”. ¡Aleluya!',
                ]
              ],
            ].each do |desc, foreign_contents, xpect|
              it "handles #{ desc.inspect }" do
                r = subtitle_splitter.send(:compute_foreign_sequence, foreign_contents, specific_foreign_language)
                r.paragraphs.map { |para| para.contents }.must_equal(xpect)
              end
            end

          end

        end

        describe '#compute_aligned_paragraph_pairs' do

          it 'handles default data' do
            foreign_sequence = subtitle_splitter.send(:compute_foreign_sequence, foreign_contents, foreign_language)
            primary_sequence = subtitle_splitter.send(:compute_primary_sequence, primary_contents, primary_language)
            r = subtitle_splitter.send(:compute_aligned_paragraph_pairs, primary_sequence, foreign_sequence)
            r.map { |bilingual_paragraph_pair|
              bilingual_paragraph_pair.bilingual_text_pairs.map { |bilingual_text_pair|
                [bilingual_text_pair.primary_text.contents, bilingual_text_pair.foreign_text.contents]
              }
            }.must_equal(
              [
                [["@1 word1 word2 word3 word4", "1 palabra1 palabra2 palabra3 palabra4"]],
                [["@2 word1 word2.", "2 palabra1 palabra2."], ["@word3 word4", "palabra3 palabra4"]],
                [["@3 word1.", "3 palabra1."], ["@word2 word3.", "palabra2 palabra3."], ["@word4", "palabra4"]]
              ]
            )
          end

          describe 'Spanish' do

            let(:specific_foreign_language) { Language::Spanish.new }

            [
              [
                '53-0609a para 88 etc.',
                [
                  '*88*{: .pn} Él dijo, Dios dijo: “He conocido la integridad de tu corazón, y por esa razón te he guardado de no pecar contra Mí; ¡pero ese es Mi profeta!”. ¡Aleluya!',
                  '{: .normal_pn}',
                  '',
                ].join("\n"),
                [
                  '@*88*{: .pn} %He said, God said, “I knowed the integrity of your heart, @and that’s the reason I kept you from sinning against Me. @But that’s My prophet!” Hallelujah!',
                  '{: .normal_pn}',
                  '',
                ].join("\n"),
                [
                  [
                    [
                      "@88 He said, God said, “I knowed the integrity of your heart, @and that’s the reason I kept you from sinning against Me. @But that’s My prophet!” Hallelujah!",
                      "88 Él dijo, Dios dijo: “He conocido la integridad de tu corazón, y por esa razón te he guardado de no pecar contra Mí; ¡pero ese es Mi profeta!”. ¡Aleluya!"
                    ]
                  ]
                ],
              ],
            ].each do |desc, foreign_contents, primary_contents, xpect|

              it "handles #{ desc.inspect }" do
                foreign_sequence = subtitle_splitter.send(:compute_foreign_sequence, foreign_contents, specific_foreign_language)
                primary_sequence = subtitle_splitter.send(:compute_primary_sequence, primary_contents, primary_language)
                r = subtitle_splitter.send(:compute_aligned_paragraph_pairs, primary_sequence, foreign_sequence)
                r.map { |bilingual_paragraph_pair|
                  bilingual_paragraph_pair.bilingual_text_pairs.map { |bilingual_text_pair|
                    [bilingual_text_pair.primary_text.contents, bilingual_text_pair.foreign_text.contents]
                  }
                }.must_equal(xpect)
              end

            end

          end

        end

        describe '#compute_sanitized_aligned_text_pairs' do

          it 'handles default data' do
            primary_paragraph = Subtitles::Paragraph.new(primary_lines.first, primary_language)
            foreign_paragraph = Subtitles::Paragraph.new(foreign_lines.first, foreign_language)
            r = subtitle_splitter.send(
              :compute_sanitized_aligned_text_pairs,
              primary_paragraph,
              foreign_paragraph
            )
            r.map { |bilingual_text_pair|
              [bilingual_text_pair.primary_contents, bilingual_text_pair.foreign_contents]
            }.must_equal([["@1 word1 word2 word3 word4", "1 palabra1 palabra2 palabra3 palabra4"]])
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
                r = subtitle_splitter.send(
                  :compute_sanitized_aligned_text_pairs,
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

          it 'handles default data' do
            primary_paragraph = Subtitles::Paragraph.new(primary_lines.first, primary_language)
            foreign_paragraph = Subtitles::Paragraph.new(foreign_lines.first, foreign_language)
            r = subtitle_splitter.send(
              :compute_raw_aligned_text_pairs,
              primary_paragraph,
              foreign_paragraph
            )
            r.map { |bilingual_text_pair|
              [bilingual_text_pair.primary_contents, bilingual_text_pair.foreign_contents]
            }.must_equal([["@1 word1 word2 word3 word4", "1 palabra1 palabra2 palabra3 palabra4"]])
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
                r = subtitle_splitter.send(
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

        end

        describe '#merge_text_pairs_with_gaps' do

          it 'handles default data' do
            primary_paragraph = Subtitles::Paragraph.new(primary_lines.first, primary_language)
            foreign_paragraph = Subtitles::Paragraph.new(foreign_lines.first, foreign_language)
            bilingual_text_pairs = subtitle_splitter.send(
              :compute_raw_aligned_text_pairs,
              primary_paragraph,
              foreign_paragraph
            )
            r = subtitle_splitter.send(:merge_text_pairs_with_gaps, bilingual_text_pairs)
            r.map { |bilingual_text_pair|
              [bilingual_text_pair.primary_contents, bilingual_text_pair.foreign_contents]
            }.must_equal([["@1 word1 word2 word3 word4", "1 palabra1 palabra2 palabra3 palabra4"]])
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
              r = subtitle_splitter.send(:merge_text_pairs_with_gaps, bilingual_text_pairs)
              r.map { |bilingual_text_pair|
                [bilingual_text_pair.primary_contents, bilingual_text_pair.foreign_contents]
              }.must_equal(xpect)
            end
          end

        end

        describe '#merge_low_confidence_text_pairs' do

          it 'handles default data' do
            primary_paragraph = Subtitles::Paragraph.new(primary_lines.first, primary_language)
            foreign_paragraph = Subtitles::Paragraph.new(foreign_lines.first, foreign_language)
            bilingual_text_pairs = subtitle_splitter.send(
              :compute_raw_aligned_text_pairs,
              primary_paragraph,
              foreign_paragraph
            )
            r = subtitle_splitter.send(:merge_low_confidence_text_pairs, bilingual_text_pairs)
            r.map { |bilingual_text_pair|
              [bilingual_text_pair.primary_contents, bilingual_text_pair.foreign_contents]
            }.must_equal([["@1 word1 word2 word3 word4", "1 palabra1 palabra2 palabra3 palabra4"]])
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
              r = subtitle_splitter.send(:merge_low_confidence_text_pairs, bilingual_text_pairs)
              r.map { |bilingual_text_pair|
                [bilingual_text_pair.primary_contents, bilingual_text_pair.foreign_contents]
              }.must_equal(xpect)
            end
          end

        end

        describe '#merge_lacking_confidence_adjacent_pairs' do

          it 'handles default data' do
            primary_paragraph = Subtitles::Paragraph.new(primary_lines.first, primary_language)
            foreign_paragraph = Subtitles::Paragraph.new(foreign_lines.first, foreign_language)
            bilingual_text_pairs = subtitle_splitter.send(
              :compute_raw_aligned_text_pairs,
              primary_paragraph,
              foreign_paragraph
            )
            r = subtitle_splitter.send(:merge_lacking_confidence_adjacent_pairs, bilingual_text_pairs)
            r.map { |bilingual_text_pair|
              [bilingual_text_pair.primary_contents, bilingual_text_pair.foreign_contents]
            }.must_equal([["@1 word1 word2 word3 word4", "1 palabra1 palabra2 palabra3 palabra4"]])
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
              r = subtitle_splitter.send(:merge_lacking_confidence_adjacent_pairs, bilingual_text_pairs)
              r.map { |bilingual_text_pair|
                [bilingual_text_pair.primary_contents, bilingual_text_pair.foreign_contents]
              }.must_equal(xpect)
            end
          end

        end

        describe '#copy_subtitles_to_foreign_plain_text' do

          it 'handles default data' do
            primary_sequence = subtitle_splitter.send(:compute_primary_sequence, primary_contents, primary_language)
            foreign_sequence = subtitle_splitter.send(:compute_foreign_sequence, foreign_contents, foreign_language)
            bilingual_paragraph_pairs = subtitle_splitter.send(:compute_aligned_paragraph_pairs, primary_sequence, foreign_sequence)
            r = subtitle_splitter.send(:copy_subtitles_to_foreign_plain_text, bilingual_paragraph_pairs)
            r.must_equal([
              "@1 palabra1 palabra2 palabra3 palabra4",
              "@2 palabra1 palabra2. @palabra3 palabra4",
              "@3 palabra1. @palabra2 palabra3. @palabra4",
            ].join("\n"))
          end

        end

        describe '#insert_subtitles_into_foreign_text' do

          it 'handles default data' do
            primary_text = primary_lines.first
            foreign_text = foreign_lines.first
            r = subtitle_splitter.send(:insert_subtitles_into_foreign_text, primary_text, foreign_text)
            r.must_equal("@1 palabra1 palabra2 palabra3 palabra4")
          end

        end

        describe '#interpolate_multiple_subtitles' do

          it 'handles default data' do
            primary_text = primary_lines.last
            foreign_text = foreign_lines.last
            r = subtitle_splitter.send(:interpolate_multiple_subtitles, primary_text, foreign_text)
            r.must_equal("@3 palabra1. @palabra2 palabra3. @palabra4")
          end

        end

        describe '#encode_document_for_paragraph_splitting' do

          it 'handles default data' do
            r = subtitle_splitter.send(
              :encode_document_for_paragraph_splitting,
              "# word\n\n"
            )
            r.must_equal("# word\n")
          end

        end

        describe '#decode_document_after_paragraph_splitting' do

          it 'handles default data' do
            r = subtitle_splitter.send(
              :decode_document_after_paragraph_splitting,
              "# word\n"
            )
            r.must_equal("# word\n\n")
          end

        end

      end

    end
  end
end

