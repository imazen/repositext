require_relative '../../../helper'
require_relative 'shared_spec_behaviors'

class Repositext
  class Validation
    class Validator

      describe ParagraphStyleConsistency do

        include SharedSpecBehaviors

        let(:language) { Language::English.new }
        let(:filename) { '/content/16/eng16_0403-1234.at' }

        describe '#run' do

          it 'reports no errors for consistent paragraph styles' do
            validator, _logger, reporter = build_validator_logger_and_reporter(
              ParagraphStyleConsistency,
              [
                RFile::ContentAt.new("foreign para\n{: .normal}\n", language, filename),
                RFile::ContentAt.new("primary para\n{: .normal}\n", language, filename),
              ]
            )
            validator.run
            reporter.errors.must_be(:empty?)
          end

          it 'reports errors for inconsistent paragraph styles' do
            validator, _logger, reporter = build_validator_logger_and_reporter(
              ParagraphStyleConsistency,
              [
                RFile::ContentAt.new("foreign para\n{: .normal1}\n", language, filename),
                RFile::ContentAt.new("primary para\n{: .normal2}\n", language, filename),
              ]
            )
            validator.run
            reporter.errors.wont_be(:empty?)
          end

        end

        describe '#pclasses_and_fspans_consistent?' do
          [
            [
              "foreign para\n{: .normal}",
              "foreign para\n{: .normal}",
              true
            ],
            [
              "foreign para\n{: .normal1}",
              "foreign para\n{: .normal2}",
              false
            ],
          ].each do |test_string_f, test_string_p, xpect|
            it "handles #{ test_string_f.inspect }" do
              validator, _logger, _reporter = build_validator_logger_and_reporter(
                ParagraphStyleConsistency,
                [
                  RFile::ContentAt.new(test_string_f, language, filename),
                  RFile::ContentAt.new(test_string_p, language, filename),
                ]
              )
              validator.pclasses_and_fspans_consistent?(
                RFile::ContentAt.new(test_string_f, language, filename),
                RFile::ContentAt.new(test_string_p, language, filename)
              ).success.must_equal(xpect)
            end
          end
        end

        describe '#extract_pclasses_and_fspans' do
          [
            [
              "simple para\n{: .normal}",
              [
                {
                  :formatting_spans=>[],
                  :paragraph_classes=>["normal"],
                  :type=>:p,
                  :line_number=>1
                }
              ]
            ],
            [
              "ignores any lines that aren't paragraph classes in block IAL .normal",
              [
                {
                  :formatting_spans=>[],
                  :paragraph_classes=>[],
                  :type=>:p,
                  :line_number=>1
                }
              ]
            ],
            [
              "para with .omit first\n{: .omit .song}",
              [
                {
                  :formatting_spans=>[],
                  :paragraph_classes=>['song'],
                  :type=>:p,
                  :line_number=>1
                }
              ]
            ],
            [
              "para with .omit last\n{: .first_par .omit}",
              [
                {
                  :formatting_spans=>[],
                  :paragraph_classes=>['first_par'],
                  :type=>:p,
                  :line_number=>1
                }
              ]
            ],
            [
              "para with .omit in the middle\n{: .first_par .omit .song}",
              [
                {
                  :formatting_spans=>[],
                  :paragraph_classes=>['first_par', 'song'],
                  :type=>:p,
                  :line_number=>1
                }
              ]
            ],

            [
              "removes .decreased_word_space class\n{: .decreased_word_space}",
              [
                {
                  :formatting_spans=>[],
                  :paragraph_classes=>[],
                  :type=>:p,
                  :line_number=>1
                }
              ]
            ],
            [
              "removes .id_title3 class\n{: .id_title3}",
              [
                {
                  :formatting_spans=>[],
                  :paragraph_classes=>[],
                  :type=>:p,
                  :line_number=>1
                }
              ]
            ],
            [
              "removes .increased_word_space class\n{: .increased_word_space}",
              [
                {
                  :formatting_spans=>[],
                  :paragraph_classes=>[],
                  :type=>:p,
                  :line_number=>1
                }
              ]
            ],
            [
              "removes .indent_for_eagle class\n{: .indent_for_eagle}",
              [
                {
                  :formatting_spans=>[],
                  :paragraph_classes=>[],
                  :type=>:p,
                  :line_number=>1
                }
              ]
            ],

            [
              "changes .song_break class to .song\n{: .song_break}",
              [
                {
                  :formatting_spans=>[],
                  :paragraph_classes=>['song'],
                  :type=>:p,
                  :line_number=>1
                }
              ]
            ],

            [
              "does not modify .first_par\n{: .first_par}",
              [
                {
                  :formatting_spans=>[],
                  :paragraph_classes=>['first_par'],
                  :type=>:p,
                  :line_number=>1
                }
              ]
            ],
            [
              "does not modify .id_paragraph\n{: .id_paragraph}",
              [
                {
                  :formatting_spans=>[],
                  :paragraph_classes=>['id_paragraph'],
                  :type=>:p,
                  :line_number=>1
                }
              ]
            ],
            [
              "does not modify .id_title1\n{: .id_title1}",
              [
                {
                  :formatting_spans=>[],
                  :paragraph_classes=>['id_title1'],
                  :type=>:p,
                  :line_number=>1
                }
              ]
            ],
            [
              "does not modify .id_title2\n{: .id_title2}",
              [
                {
                  :formatting_spans=>[],
                  :paragraph_classes=>['id_title2'],
                  :type=>:p,
                  :line_number=>1
                }
              ]
            ],
            [
              "does not modify .normal\n{: .normal}",
              [
                {
                  :formatting_spans=>[],
                  :paragraph_classes=>['normal'],
                  :type=>:p,
                  :line_number=>1
                }
              ]
            ],
            [
              "does not modify .normal_pn\n{: .normal_pn}",
              [
                {
                  :formatting_spans=>[],
                  :paragraph_classes=>['normal_pn'],
                  :type=>:p,
                  :line_number=>1
                }
              ]
            ],
            [
              "does not modify .q\n{: .q}",
              [
                {
                  :formatting_spans=>[],
                  :paragraph_classes=>['q'],
                  :type=>:p,
                  :line_number=>1
                }
              ]
            ],
            [
              "does not modify .reading\n{: .reading}",
              [
                {
                  :formatting_spans=>[],
                  :paragraph_classes=>['reading'],
                  :type=>:p,
                  :line_number=>1
                }
              ]
            ],
            [
              "does not modify .scr\n{: .scr}",
              [
                {
                  :formatting_spans=>[],
                  :paragraph_classes=>['scr'],
                  :type=>:p,
                  :line_number=>1
                }
              ]
            ],
            [
              "does not modify .song\n{: .song}",
              [
                {
                  :formatting_spans=>[],
                  :paragraph_classes=>['song'],
                  :type=>:p,
                  :line_number=>1
                }
              ]
            ],
            [
              "does not modify .stanza\n{: .stanza}",
              [
                {
                  :formatting_spans=>[],
                  :paragraph_classes=>['stanza'],
                  :type=>:p,
                  :line_number=>1
                }
              ]
            ],
            [
              "extracts formatting_span type italic from blank em *word*\n{: .normal}",
              [
                {
                  :formatting_spans=>[:italic],
                  :paragraph_classes=>['normal'],
                  :type=>:p,
                  :line_number=>1
                }
              ]
            ],
            [
              "extracts formatting_span type italic from em with class *word*{: .italic}\n{: .normal}",
              [
                {
                  :formatting_spans=>[:italic],
                  :paragraph_classes=>['normal'],
                  :type=>:p,
                  :line_number=>1
                }
              ]
            ],
            [
              "extracts formatting_span type bold from strong **word**\n{: .normal}",
              [
                {
                  :formatting_spans=>[:bold],
                  :paragraph_classes=>['normal'],
                  :type=>:p,
                  :line_number=>1
                }
              ]
            ],
            [
              "extracts formatting_span types from multiple ems *word*{: .smcaps} and *word*{: .superscript}\n{: .normal}",
              [
                {
                  :formatting_spans=>[:smcaps, :superscript],
                  :paragraph_classes=>['normal'],
                  :type=>:p,
                  :line_number=>1
                }
              ]
            ],
            [
              "extracts formatting_span type bold *word*{: .bold}\n{: .normal}",
              [
                {
                  :formatting_spans=>[:bold],
                  :paragraph_classes=>['normal'],
                  :type=>:p,
                  :line_number=>1
                }
              ]
            ],
            [
              "ignores formatting_span type line_break *.*{: .line_break}\n{: .normal}",
              [
                {
                  :formatting_spans=>[],
                  :paragraph_classes=>['normal'],
                  :type=>:p,
                  :line_number=>1
                }
              ]
            ],
            [
              "ignores formatting_span type pn *.*{: .pn}\n{: .normal}",
              [
                {
                  :formatting_spans=>[],
                  :paragraph_classes=>['normal'],
                  :type=>:p,
                  :line_number=>1
                }
              ]
            ],
            [
              "extracts formatting_span type smcaps *word*{: .smcaps}\n{: .normal}",
              [
                {
                  :formatting_spans=>[:smcaps],
                  :paragraph_classes=>['normal'],
                  :type=>:p,
                  :line_number=>1
                }
              ]
            ],
            [
              "extracts formatting_span type subscript *word*{: .subscript}\n{: .normal}",
              [
                {
                  :formatting_spans=>[:subscript],
                  :paragraph_classes=>['normal'],
                  :type=>:p,
                  :line_number=>1
                }
              ]
            ],
            [
              "extracts formatting_span type superscript *word*{: .superscript}\n{: .normal}",
              [
                {
                  :formatting_spans=>[:superscript],
                  :paragraph_classes=>['normal'],
                  :type=>:p,
                  :line_number=>1
                }
              ]
            ],
            [
              "extracts formatting_span type underline *word*{: .underline}\n{: .normal}",
              [
                {
                  :formatting_spans=>[:underline],
                  :paragraph_classes=>['normal'],
                  :type=>:p,
                  :line_number=>1
                }
              ]
            ],
          ].each do |test_string, xpect|
            it "handles #{ test_string.inspect }" do
              validator, _logger, _reporter = build_validator_logger_and_reporter(
                ParagraphStyleConsistency,
                [
                  RFile::ContentAt.new("_", language, filename),
                  RFile::ContentAt.new("_", language, filename),
                ]
              )
              validator.send(
                :extract_pclasses_and_fspans, test_string
              ).must_equal(xpect)
            end
          end
        end

        describe '#compute_pclass_and_fspan_mismatches' do
          [
            [
              "Finds no mismatches for identical docs",
              [
                {
                  :formatting_spans=>[:italic],
                  :paragraph_classes=>['normal'],
                  :type=>:p,
                  :line_number=>1
                }
              ],
              [
                {
                  :formatting_spans=>[:italic],
                  :paragraph_classes=>['normal'],
                  :type=>:p,
                  :line_number=>1
                }
              ],
              []
            ],
            [
              "Finds mismatches for different docs",
              [
                {
                  :formatting_spans=>[:bold],
                  :paragraph_classes=>['normal_pn'],
                  :type=>:p,
                  :line_number=>1
                }
              ],
              [
                {
                  :formatting_spans=>[],
                  :paragraph_classes=>['normal'],
                  :type=>:p,
                  :line_number=>1
                }
              ],
              [
                "Paragraph class mismatch",
                "Span formatting mismatch",
              ]
            ],
          ].each do |description, f_classes_and_fspans, p_classes_and_fspans, xpect|
            it description do
              validator, _logger, _reporter = build_validator_logger_and_reporter(
                ParagraphStyleConsistency,
                [
                  RFile::ContentAt.new("_", language, filename),
                  RFile::ContentAt.new("_", language, filename),
                ]
              )
              validator.send(
                :compute_pclass_and_fspan_mismatches, f_classes_and_fspans, p_classes_and_fspans
              ).map { |e| e.first }.must_equal(xpect)
            end
          end
        end

        describe '#compute_formatting_span_mismatches' do
          [
            [
              "Finds no mismatches for identical fspans",
              {
                :formatting_spans=>[:italic],
                :paragraph_classes=>['normal'],
                :type=>:p,
                :line_number=>1
              },
              {
                :formatting_spans=>[:italic],
                :paragraph_classes=>['normal'],
                :type=>:p,
                :line_number=>1
              },
              []
            ],
            [
              "Finds mismatches default case",
              {
                :formatting_spans=>[:italic],
                :paragraph_classes=>['normal'],
                :type=>:p,
                :line_number=>1
              },
              {
                :formatting_spans=>[:bold],
                :paragraph_classes=>['normal'],
                :type=>:p,
                :line_number=>1
              },
              [
                "Foreign is missing formatting span :bold on line 1",
                "Foreign has extra formatting span :italic on line 1",
              ]
            ],
          ].each do |description, f_classes_and_fspans, p_classes_and_fspans, xpect|
            it description do
              validator, _logger, _reporter = build_validator_logger_and_reporter(
                ParagraphStyleConsistency,
                [
                  RFile::ContentAt.new("_", language, filename),
                  RFile::ContentAt.new("_", language, filename),
                ]
              )
              validation_rules = language.paragraph_style_consistency_validation_rules
              mismatches = []
              validator.send(
                :compute_formatting_span_mismatches,
                f_classes_and_fspans,
                p_classes_and_fspans,
                validation_rules,
                mismatches
              )
              mismatches.map { |e| e.last }.must_equal(xpect)
            end
          end
        end

        describe '#prepare_formatting_spans' do
          [
            [
              "Returns formatting_spans as is by default",
              {
                :formatting_spans=>[:italic],
                :paragraph_classes=>['normal'],
                :type=>:p,
                :line_number=>1
              },
              ->(paragraph_attrs) {
                paragraph_attrs[:formatting_spans]
              },
              [:italic]
            ],
            [
              "Replaces [:bold, :underline] with [:bold]",
              {
                :formatting_spans=>[:bold, :underline],
                :paragraph_classes=>['normal'],
                :type=>:p,
                :line_number=>1
              },
              ->(paragraph_attrs) {
                formatting_spans = paragraph_attrs[:formatting_spans]
                if ([:bold, :underline] - formatting_spans).empty?
                  # formatting_spans contains both bold and underline
                  # change to :bold
                  (formatting_spans - [:bold, :underline]).push(:bold).uniq
                else
                  # No change
                  formatting_spans
                end
              },
              [:bold]
            ],
          ].each do |description, f_class_and_fspans, mftpfs, xpect|
            it description do
              validator, _logger, _reporter = build_validator_logger_and_reporter(
                ParagraphStyleConsistency,
                [
                  RFile::ContentAt.new("_", language, filename),
                  RFile::ContentAt.new("_", language, filename),
                ]
              )
              validator.send(
                :prepare_formatting_spans,
                f_class_and_fspans,
                { map_foreign_to_primary_formatting_spans: mftpfs },
              ).must_equal(xpect)
            end
          end
        end

        describe '#compute_formatting_span_validation_rule' do
          [
            [
              "Uses language default",
              {
                :formatting_spans=>[:italic],
                :paragraph_classes=>['normal'],
                :type=>:p,
                :line_number=>1
              },
              :italic,
              :strict
            ],
            [
              "Uses formatting_span type default",
              {
                :formatting_spans=>[:smcaps],
                :paragraph_classes=>['normal'],
                :type=>:p,
                :line_number=>1
              },
              :smcaps,
              :report_extra
            ],
            [
              "Uses paragraph class default 1",
              {
                :formatting_spans=>[:smcaps],
                :paragraph_classes=>['scr'],
                :type=>:p,
                :line_number=>1
              },
              :smcaps,
              :strict
            ],
            [
              "Uses paragraph class default 2",
              {
                :formatting_spans=>[:underline],
                :paragraph_classes=>['id_title1'],
                :type=>:p,
                :line_number=>1
              },
              :underline,
              :none
            ],
            [
              "Uses header rules",
              {
                :formatting_spans=>[:smcaps],
                :paragraph_classes=>[],
                :type=>:header,
                :line_number=>1
              },
              :smcaps,
              :strict
            ],
          ].each do |description, p_attrs, fspan, xpect|

            # Uses standard validation rule:
            # {
            #   map_foreign_to_primary_formatting_spans: ->(paragraph_attrs) {
            #     paragraph_attrs[:formatting_spans]
            #   },
            #   language: :strict,
            #   formatting_span_type: {
            #     smcaps: :report_extra,
            #   },
            #   paragraph_class: {
            #     p: {
            #       id_paragraph: :none,
            #       id_title1: :none,
            #       id_title2: :none,
            #       scr: { smcaps: :strict },
            #     },
            #     header: {
            #       smcaps: :strict
            #     }
            #   }
            # }
            it description do
              validator, _logger, _reporter = build_validator_logger_and_reporter(
                ParagraphStyleConsistency,
                [
                  RFile::ContentAt.new("_", language, filename),
                  RFile::ContentAt.new("_", language, filename),
                ]
              )
              validation_rules = language.paragraph_style_consistency_validation_rules
              validator.send(
                :compute_formatting_span_validation_rule,
                p_attrs,
                fspan,
                validation_rules,
              ).must_equal(xpect)
            end
          end
        end

        # describe '#report_paragraph_class_differences' do
        # end

        # describe '#align_foreign_and_primary_paragraphs' do
        # end

      end

    end
  end
end
