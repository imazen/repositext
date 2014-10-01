require_relative '../../../helper'
require_relative 'shared_spec_behaviors'

class Repositext
  class Validation
    class Validator

      describe KramdownSyntaxAt do

        include SharedSpecBehaviors

        describe '#run' do

          it 'reports no errors for valid kramdown AT' do
            validator, logger, reporter = build_validator_logger_and_reporter(
              KramdownSyntaxAt,
              FileLikeStringIO.new('_path', 'valid kramdown AT')
            )
            validator.run
            reporter.errors.must_be(:empty?)
          end

          it 'reports errors for invalid kramdown AT' do
            validator, logger, reporter = build_validator_logger_and_reporter(
              KramdownSyntaxAt,
              FileLikeStringIO.new('_path', 'invalid kramdown AT with gap_mark in%side a word')
            )
            validator.run
            reporter.errors.wont_be(:empty?)
          end

        end

        describe '#valid_syntax_at?' do
          [
            ["valid kramdown AT", true],
            ["record_mark not preceded by blank line\n^^^", false],
            ["escaped bracket \\[", false],
          ].each do |test_string, xpect|
            it "handles #{ test_string.inspect }" do
              validator, logger, reporter = build_validator_logger_and_reporter(
                KramdownSyntaxAt,
                FileLikeStringIO.new('_path', '_txt')
              )
              validator.valid_syntax_at?(test_string).success.must_equal(xpect)
            end
          end
        end

        describe '#validate_record_mark_syntax' do
          [
            ["valid kramdown AT", 0],
            ["record_mark preceded by blank line\n\n^^^\n\nnext line", 0],
            ["^^^\n\nfirst record_mark doesn't need to be preceded by blank line", 0],
            ["record_mark not preceded by blank line\n^^^\n\nnext line", 1],
            ["^^^\n\nrecord_marks with text between them\n\n^^^\n\nnext line", 0],
            ["record_marks with no text between them\n\n^^^\n\n^^^\n\nnext line", 1],
            ["record_marks with no text between them\n\n^^^\n\n  \n\n^^^\n\nnext line", 1],
            ["record_mark followed by two newlines\n\n^^^\n\nnext line", 0],
            ["record_mark followed by one newline\n\n^^^\nnext line", 1],
            ["record_mark followed by three newlines\n\n^^^\n\n\nnext line", 1],
          ].each do |test_string, xpect|
            it "handles #{ test_string.inspect }" do
              validator, logger, reporter = build_validator_logger_and_reporter(
                KramdownSyntaxAt,
                FileLikeStringIO.new('_path', '_txt')
              )
              errors = []
              warnings = []
              validator.send(
                :validate_record_mark_syntax, test_string, errors, warnings
              )
              errors.size.must_equal(xpect)
            end
          end
        end


      end

    end
  end
end
