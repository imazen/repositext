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

        describe '#paragraph_styles_consistent?' do
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
              validator.paragraph_styles_consistent?(
                RFile::ContentAt.new(test_string_f, language, filename),
                RFile::ContentAt.new(test_string_p, language, filename)
              ).success.must_equal(xpect)
            end
          end
        end

        describe '#extract_paragraph_styles' do
          [
            ["simple para\n{: .normal}", ['', '.normal']],
            ["ignores any lines that aren't paragraph classes in block IAL .normal", ['']],
            ["ignores class names inside *inline IALs*{: .normal} word", ['']],

            ["para with .omit first\n{: .omit .song}", ['', '.song']],
            ["para with .omit last\n{: .first_par .omit}", ['', '.first_par']],
            ["para with .omit in the middle\n{: .first_par .omit .song}", ['', '.first_par .song']],

            ["removes .decreased_word_space class\n{: .decreased_word_space}", ['', '']],
            ["removes .id_title3 class\n{: .id_title3}", ['', '']],
            ["removes .increased_word_space class\n{: .increased_word_space}", ['', '']],
            ["removes .indent_for_eagle class\n{: .indent_for_eagle}", ['', '']],

            ["changes .song_break class to .song\n{: .song_break}", ['', '.song']],

            ["does not modify .first_par\n{: .first_par}", ['', '.first_par']],
            ["does not modify .id_paragraph\n{: .id_paragraph}", ['', '.id_paragraph']],
            ["does not modify .id_title1\n{: .id_title1}", ['', '.id_title1']],
            ["does not modify .id_title2\n{: .id_title2}", ['', '.id_title2']],
            ["does not modify .normal\n{: .normal}", ['', '.normal']],
            ["does not modify .normal_pn\n{: .normal_pn}", ['', '.normal_pn']],
            ["does not modify .q\n{: .q}", ['', '.q']],
            ["does not modify .reading\n{: .reading}", ['', '.reading']],
            ["does not modify .scr\n{: .scr}", ['', '.scr']],
            ["does not modify .song\n{: .song}", ['', '.song']],
            ["does not modify .stanza\n{: .stanza}", ['', '.stanza']],
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
                :extract_paragraph_styles, test_string
              ).must_equal(xpect)
            end
          end
        end

        describe '#compute_paragraph_style_diff' do
          [
            [['{: .normal}'], ['{: .normal}'], true, []],
            [['{: .normal1}'], ['{: .normal2}'], true, [:different_style_in_foreign]],
            [['', ''], ['', '{: .normal}', ''], true, [:missing_style_in_foreign]],
            [['', '{: .normal}', ''], ['', ''], true, [:extra_style_in_foreign]],
            [['{: .normal}'], ['{: .normal_pn}'], true, [:different_style_in_foreign]],
            [['{: .normal}'], ['{: .normal_pn}'], false, []],
          ].each do |test_styles_f, test_styles_p, distinguish_between_normal_and_normal_pn, xpect|
            it "handles #{ test_styles_f.inspect }" do
              validator, _logger, _reporter = build_validator_logger_and_reporter(
                ParagraphStyleConsistency,
                [
                  RFile::ContentAt.new("_", language, filename),
                  RFile::ContentAt.new("_", language, filename),
                ]
              )
              validator.distinguish_between_normal_and_normal_pn = distinguish_between_normal_and_normal_pn
              validator.send(
                :compute_paragraph_style_diff, test_styles_f, test_styles_p
              ).map { |e| e[:type] }.must_equal(xpect)
            end
          end
        end

        describe '#foreign_has_paragraph_numbers?' do
          [
            ["1 para 1\n\n2 para 2", true],
            ["para 1\n\npara 2", false],
            ["1 para 1\n\n2 para 2\n\npara 3", true],
            ["1 para 1\n\npara 2\n\npara 3", true],
            ["1 para 1\n\npara 2\n\npara 3\n\npara 4", false],
          ].each do |foreign_test_doc, xpect|
            it "handles #{ foreign_test_doc.inspect }" do
              validator, _logger, _reporter = build_validator_logger_and_reporter(
                ParagraphStyleConsistency,
                [
                  RFile::ContentAt.new("_", language, filename),
                  RFile::ContentAt.new("_", language, filename),
                ]
              )
              validator.send(
                :foreign_has_paragraph_numbers?, foreign_test_doc
              ).must_equal(xpect)
            end
          end
        end

      end

    end
  end
end
