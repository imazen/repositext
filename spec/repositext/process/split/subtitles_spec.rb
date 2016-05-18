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
            '*1*{: pn} palabra1 palabra2 palabra3 palabra4',
            '*2*{: pn} palabra1 palabra2. palabra3 palabra4',
            '*3*{: pn} palabra1. palabra2 palabra3. palabra4',
          ]
        }
        let(:primary_lines) {
          [
            '@*1*{: pn} word1 word2 word3 word4',
            '@*2*{: pn} word1 word2. @word3 word4',
            '@*3*{: pn} word1. @word2 word3. @word4',
          ]
        }
        let(:foreign_contents) { (foreign_lines.map { |e| "#{ e }\n{: .normal}" }.join("\n\n")) + "\n" }
        let(:primary_contents) { (primary_lines.map { |e| "#{ e }\n{: .normal}" }.join("\n\n")) + "\n" }
        let(:foreign_filename) { 'path/to/foreign_file' }
        let(:primary_filename) { 'path/to/primary_file' }
        let(:foreign_file) { RFile::ContentAt.new(foreign_contents, foreign_language, foreign_filename) }
        let(:primary_file) { RFile::ContentAt.new(primary_contents, primary_language, primary_filename) }
        let(:subtitle_splitter) { Subtitles.new(foreign_file, primary_file) }

        describe '#split' do

          it 'handles default data' do
            subtitle_splitter.split.result.must_equal(
              [
                '@*1*{: pn} palabra1 palabra2 palabra3 palabra4',
                '{: .normal}',
                '',
                '@*2*{: pn} palabra1 palabra2. @palabra3 palabra4',
                '{: .normal}',
                '',
                '@*3*{: pn} palabra1. @palabra2 palabra3. @palabra4',
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
                  '*88*{: .pn} palabra palabra, Palabra palabra: “Palabra palabra palabra palabra palabra palabra palabra, palabra palabra palabra palabra palabra palabra palabra palabra palabra palabra palabra PaLABRA; ¡palabra palabra palabra Palabra palabra!”. ¡Palabra!',
                  '{: .normal_pn}',
                  '',
                ].join("\n"),
                [
                  '@*88*{: .pn} %Word word, Word word, “WORD word word word word word word, @word word’word word word WORD word word word word word Word. @Word word’word Word word!” Word!',
                  '{: .normal_pn}',
                  '',
                ].join("\n"),
                [
                  '@*88*{: .pn} palabra palabra, Palabra palabra: “Palabra palabra palabra palabra palabra palabra palabra, @palabra palabra palabra palabra palabra palabra palabra palabra palabra palabra palabra PaLABRA; @¡palabra palabra palabra Palabra palabra!”. ¡Palabra!',
                  '{: .normal_pn}',
                  '',
                ].join("\n"),
              ],
            ].each do |desc, foreign_contents, primary_contents, xpect|
              it "handles #{ desc.inspect }" do
                foreign_file = RFile::ContentAt.new(foreign_contents, specific_foreign_language, foreign_filename)
                primary_file = RFile::ContentAt.new(primary_contents, primary_language, primary_filename)
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
            r.paragraphs.map { |paragraph| paragraph.contents }.must_equal(
              ["@1 word1 word2 word3 word4", "@2 word1 word2. @word3 word4", "@3 word1. @word2 word3. @word4"]
            )
          end

          [
            [
              '53-0609a para 88 etc.',
              [
                '@*88*{: .pn} %Word word, Word word, “WORD word word word word word word, @word word’word word word WORD word word word word word Word. @Word word’word Word word!” Word!',
                '{: .normal_pn}',
                '',
              ].join("\n"),
              [
                '@88 Word word, Word word, “WORD word word word word word word, @word word’word word word WORD word word word word word Word. @Word word’word Word word!” Word!',
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
            r.paragraphs.map { |paragraph| paragraph.contents }.must_equal(
              ["1 palabra1 palabra2 palabra3 palabra4", "2 palabra1 palabra2. palabra3 palabra4", "3 palabra1. palabra2 palabra3. palabra4"]
            )
          end

          describe 'Spanish' do

            let(:specific_foreign_language) { Language::Spanish.new }

            [
              [
                '53-0609a para 88 etc.',
                [
                  '*88*{: .pn} palabra palabra, Palabra palabra: “Palabra palabra palabra palabra palabra palabra palabra, palabra palabra palabra palabra palabra palabra palabra palabra palabra palabra palabra PaLABRA; ¡palabra palabra palabra Palabra palabra!”. ¡Palabra!',
                  '{: .normal_pn}',
                  '',
                ].join("\n"),
                [
                  '88 palabra palabra, Palabra palabra: “Palabra palabra palabra palabra palabra palabra palabra, palabra palabra palabra palabra palabra palabra palabra palabra palabra palabra palabra PaLABRA; ¡palabra palabra palabra Palabra palabra!”. ¡Palabra!',
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

        describe '#encode_merged_paragraph_contents' do

          it 'handles default data' do
            primary_sequence = subtitle_splitter.send(:compute_primary_sequence, primary_contents, primary_language)
            foreign_sequence = subtitle_splitter.send(:compute_foreign_sequence, foreign_contents, foreign_language)
            bilingual_sequence_pair = Subtitles::BilingualSequencePair.new(primary_sequence, foreign_sequence)
            r = subtitle_splitter.send(
              :encode_merged_paragraph_contents,
              bilingual_sequence_pair.aligned_paragraph_pairs
            )
            r.map { |bpp| [bpp.primary_contents, bpp.foreign_contents] }.must_equal([
              ["@1 word1 word2 word3 word4", "1 palabra1 palabra2 palabra3 palabra4"],
              ["@2 word1 word2. @word3 word4", "2 palabra1 palabra2. palabra3 palabra4"],
              ["@3 word1. @word2 word3. @word4", "3 palabra1. palabra2 palabra3. palabra4"],
            ])
          end

          # [
          #   [
          #     '53-0609a para 88 etc.',
          #     [
          #       '*88*{: .pn} palabra palabra, Palabra palabra: “Palabra palabra palabra palabra palabra palabra palabra, palabra palabra palabra palabra palabra palabra palabra palabra palabra palabra palabra PaLABRA; ¡palabra palabra palabra Palabra palabra!”. ¡Palabra!',
          #       '{: .normal_pn}',
          #       '',
          #     ].join("\n"),
          #     [
          #       '88 palabra palabra, Palabra palabra: “Palabra palabra palabra palabra palabra palabra palabra, palabra palabra palabra palabra palabra palabra palabra palabra palabra palabra palabra PaLABRA; ¡palabra palabra palabra Palabra palabra!”. ¡Palabra!',
          #     ]
          #   ],
          # ].each do |desc, foreign_contents, xpect|
          #   it "handles #{ desc.inspect }" do
          #     r = subtitle_splitter.send(:compute_foreign_sequence, foreign_contents, specific_foreign_language)
          #     r.paragraphs.map { |para| para.contents }.must_equal(xpect)
          #   end
          # end

        end

        describe '#sanitize_aligned_paragraph_pairs' do

          it 'handles default data' do
            primary_sequence = subtitle_splitter.send(:compute_primary_sequence, primary_contents, primary_language)
            foreign_sequence = subtitle_splitter.send(:compute_foreign_sequence, foreign_contents, foreign_language)
            bilingual_sequence_pair = Subtitles::BilingualSequencePair.new(primary_sequence, foreign_sequence)
            r = subtitle_splitter.send(
              :sanitize_aligned_paragraph_pairs,
              bilingual_sequence_pair.aligned_paragraph_pairs
            )
            r.map { |bpp| [bpp.primary_contents, bpp.foreign_contents] }.must_equal([
              ["@1 word1 word2 word3 word4", "1 palabra1 palabra2 palabra3 palabra4"],
              ["@2 word1 word2. @word3 word4", "2 palabra1 palabra2. palabra3 palabra4"],
              ["@3 word1. @word2 word3. @word4", "3 palabra1. palabra2 palabra3. palabra4"],
            ])
          end

          [
            [
              'One gap in the middle of foreign paras',
              [
                [
                  "@1 word1 word2. @word3 word4.\n\n",
                  "1 palabra1 palabra2. palabra3 palabra4. palabra5 palabra6. palabra7 palabra8.\n\n",
                  1.0
                ],
                [
                  "@word5 word6. @word7 word8.\n\n",
                  "",
                  0.0
                ],
                [
                  "@2 word9 word10. @word11 word12.\n\n",
                  "2 palabra9 palabra10. palabra11 palabra12.\n\n",
                  1.0
                ],
              ],
              [
                [
                  "@1 word1 word2. @word3 word4.\n\n@word5 word6. @word7 word8.\n\n",
                  "1 palabra1 palabra2. palabra3 palabra4. palabra5 palabra6. palabra7 palabra8.\n\n",
                  0.5
                ],
                [
                  "@2 word9 word10. @word11 word12.\n\n",
                  "2 palabra9 palabra10. palabra11 palabra12.\n\n",
                  1.0
                ],
              ]
            ],
            [
              'Header followed by gap',
              [
                [
                  "# header1\n\n",
                  "# header1\n\n",
                  1.0
                ],
                [
                  "@1 word1 word2. @word3 word4.\n\n",
                  "",
                  0.0
                ],
                [
                  "@2 word5 word6. @word7 word8.\n\n",
                  "2 palabra5 palabra6. palabra7 palabra8.\n\n",
                  1.0
                ],
              ],
              [
                [
                  "# header1\n\n",
                  "# header1\n\n",
                  1.0
                ],
                [
                  "@1 word1 word2. @word3 word4.\n\n@2 word5 word6. @word7 word8.\n\n",
                  "2 palabra5 palabra6. palabra7 palabra8.\n\n",
                  0.5
                ],
              ]
            ],
          ].each do |desc, bpps_attrs, xpect|
            it "handles #{ desc.inspect }" do
              bpps = bpps_attrs.map { |(primary_contents, foreign_contents, confidence)|
                Subtitles::BilingualParagraphPair.new(
                  Subtitles::Paragraph.new(primary_contents, primary_language),
                  Subtitles::Paragraph.new(foreign_contents, foreign_language),
                  confidence
                )
              }
              r = subtitle_splitter.send(:sanitize_aligned_paragraph_pairs, bpps)
              r.map { |bpp|
                [bpp.primary_contents, bpp.foreign_contents, bpp.confidence]
              }.must_equal(xpect)
            end
          end

        end

        describe '#copy_subtitles_to_foreign_plain_text' do

          it 'handles default data' do
            primary_sequence = subtitle_splitter.send(:compute_primary_sequence, primary_contents, primary_language)
            foreign_sequence = subtitle_splitter.send(:compute_foreign_sequence, foreign_contents, foreign_language)
            bilingual_sequence_pair = Subtitles::BilingualSequencePair.new(primary_sequence, foreign_sequence)
            r = subtitle_splitter.send(
              :copy_subtitles_to_foreign_plain_text,
              bilingual_sequence_pair.aligned_paragraph_pairs
            )
            r.must_equal([
              "@1 palabra1 palabra2 palabra3 palabra4",
              "@2 palabra1 palabra2. @palabra3 palabra4",
              "@3 palabra1. @palabra2 palabra3. @palabra4",
            ].join("\n"))
          end

          [
            [
              'One paragraph with merged gap and lower confidence',
              [
                [
                  "@1 word1 word2. @word3 word4.\n\n@word5 word6. @word7 word8.\n\n",
                  "1 palabra1 palabra2. palabra3 palabra4. palabra5 palabra6. palabra7 palabra8.\n\n",
                  0.5
                ],
                [
                  "@2 word9 word10. @word11 word12.\n\n",
                  "2 palabra9 palabra10. palabra11 palabra12.\n\n",
                  1.0
                ],
              ],
              "@1 palabra1 palabra2. @palabra3 palabra4. @palabra5 palabra6. @palabra7 palabra8.\n@2 palabra9 palabra10. @palabra11 palabra12."
            ],
            [
              'Multiple paragraphs with merged gaps and lower confidence at the end',
              [
                [
                  "@1 word1 word2. @word3 word4.\n\n@word5 word6. @word7 word8.\n\n",
                  "1 palabra1 palabra2. palabra3 palabra4. palabra5 palabra6. palabra7 palabra8.\n\n",
                  0.5
                ],
                [
                  "@2 word9 word10. @word11 word12.\n\n",
                  "2 palabra9 palabra10. palabra11 palabra12.\n\n",
                  1.0
                ],
              ],
              "@1 palabra1 palabra2. @palabra3 palabra4. @palabra5 palabra6. @palabra7 palabra8.\n@2 palabra9 palabra10. @palabra11 palabra12."
            ],
          ].each do |desc, bpps_attrs, xpect|
            it "handles #{ desc.inspect }" do
              bpps = bpps_attrs.map { |(primary_contents, foreign_contents, confidence)|
                Subtitles::BilingualParagraphPair.new(
                  Subtitles::Paragraph.new(primary_contents, primary_language),
                  Subtitles::Paragraph.new(foreign_contents, foreign_language),
                  confidence
                )
              }
              r = subtitle_splitter.send(:copy_subtitles_to_foreign_plain_text, bpps)
              r.must_equal(xpect)
            end
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

        describe '#insert_subtitles_into_foreign_text' do

          it 'handles default data' do
            primary_text = primary_lines.first
            foreign_text = foreign_lines.first
            r = subtitle_splitter.send(:insert_subtitles_into_foreign_text, primary_text, foreign_text)
            r.must_equal("@*1*{: pn} palabra1 palabra2 palabra3 palabra4")
          end

        end

        describe '#adjust_subtitles' do

          it 'handles default data' do
            foreign_text = Text.new("@1 palabra1 @palabra2. palabra3 palabra4", foreign_language)
            r = subtitle_splitter.send(:adjust_subtitles, foreign_text)
            r.must_equal("@1 palabra1 palabra2. @palabra3 palabra4")
          end

        end

        describe '#interpolate_multiple_subtitles' do

          it 'handles default data' do
            primary_text = primary_lines.last
            foreign_text = foreign_lines.last
            r = subtitle_splitter.send(:interpolate_multiple_subtitles, primary_text, foreign_text)
            r.must_equal("@*3*{: pn} palabra1. @palabra2 palabra3. @palabra4")
          end

        end

      end

    end
  end
end

