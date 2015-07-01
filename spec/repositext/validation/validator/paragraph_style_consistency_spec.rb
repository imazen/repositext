require_relative '../../../helper'
require_relative 'shared_spec_behaviors'

class Repositext
  class Validation
    class Validator

      describe ParagraphStyleConsistency do

        include SharedSpecBehaviors

        describe '#run' do

          it 'reports no errors for consistent paragraph styles' do
            validator, logger, reporter = build_validator_logger_and_reporter(
              ParagraphStyleConsistency,
              [
                FileLikeStringIO.new('_path_f', "foreign para\n{: .normal}"),
                FileLikeStringIO.new('_path_p', "primary para\n{: .normal}"),
              ]
            )
            validator.run
            reporter.errors.must_be(:empty?)
          end

          it 'reports errors for inconsistent paragraph styles' do
            validator, logger, reporter = build_validator_logger_and_reporter(
              ParagraphStyleConsistency,
              [
                FileLikeStringIO.new('_path_f', "foreign para\n{: .normal1}\n"),
                FileLikeStringIO.new('_path_p', "primary para\n{: .normal2}\n"),
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
              validator, logger, reporter = build_validator_logger_and_reporter(
                ParagraphStyleConsistency,
                [
                  FileLikeStringIO.new('_path', '_txt'),
                  FileLikeStringIO.new('_path', '_txt'),
                ]
              )
              validator.paragraph_styles_consistent?(
                test_string_f,
                test_string_p
              ).success.must_equal(xpect)
            end
          end
        end

        describe '#extract_paragraph_styles' do
          [
            ["para\n{: .normal}", ['', '.normal']],
            ["para with .omit last\n{: .normal .omit}", ['', '.normal']],
            ["para with .omit first\n{: .omit .stanza}", ['', '.stanza']],
          ].each do |test_string, xpect|
            it "handles #{ test_string.inspect }" do
              validator, logger, reporter = build_validator_logger_and_reporter(
                ParagraphStyleConsistency,
                [
                  FileLikeStringIO.new('_path', '_txt'),
                  FileLikeStringIO.new('_path', '_txt'),
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
              validator, logger, reporter = build_validator_logger_and_reporter(
                ParagraphStyleConsistency,
                [
                  FileLikeStringIO.new('_path', '_txt'),
                  FileLikeStringIO.new('_path', '_txt'),
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
              validator, logger, reporter = build_validator_logger_and_reporter(
                ParagraphStyleConsistency,
                [
                  FileLikeStringIO.new('_path', '_txt'),
                  FileLikeStringIO.new('_path', '_txt'),
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
