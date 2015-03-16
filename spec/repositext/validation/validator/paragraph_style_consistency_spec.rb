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
            ["para\n{: .normal}", ['', '{: .normal}']],
            ["para with .omit\n{: .normal .omit}", ['', '{: .normal}']],
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
            [['{: .normal}'], ['{: .normal}'], []],
            [['{: .normal1}'], ['{: .normal2}'], [:different_style_in_foreign]],
            [['', ''], ['', '{: .normal}', ''], [:missing_style_in_foreign]],
            [['', '{: .normal}', ''], ['', ''], [:extra_style_in_foreign]],
            [['{: .normal}', '{: .normal}', '{: .normal}'], ['{: .normal_pn}', '{: .normal}', '{: .normal}'], []],
          ].each do |test_styles_f, test_styles_p, xpect|
            it "handles #{ test_styles_f.inspect }" do
              validator, logger, reporter = build_validator_logger_and_reporter(
                ParagraphStyleConsistency,
                [
                  FileLikeStringIO.new('_path', '_txt'),
                  FileLikeStringIO.new('_path', '_txt'),
                ]
              )
              validator.send(
                :compute_paragraph_style_diff, test_styles_f, test_styles_p
              ).map { |e| e[:type] }.must_equal(xpect)
            end
          end
        end

      end

    end
  end
end
