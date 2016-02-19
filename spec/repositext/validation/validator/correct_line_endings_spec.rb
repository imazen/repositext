require_relative '../../../helper'

class Repositext
  class Validation
    class Validator

      describe CorrectLineEndings do

        before do
          # Redirect console output for clean test logs
          # NOTE: use STDOUT.puts if you want to print something to the test output
          @stderr = $stderr = StringIO.new
          @stdout = $stdout = StringIO.new
        end

        let(:logger) { LoggerTest.new(nil, nil, nil, nil, nil) }
        let(:reporter) { ReporterTest.new(nil, nil, nil, nil) }

        [
          'valid-line-endings.txt'
        ].each do |file_name|
          it "passes a valid file: #{ file_name }" do
            CorrectLineEndings.new(
              File.open(get_test_data_path_for("/repositext/validation/validator/correct_line_endings/valid/" + file_name)),
              logger,
              reporter,
              {}
            ).run
            reporter.errors.must_equal []
          end
        end

        [
          'cr-lf-line-endings.txt',
        ].each do |file_name|
          it "flags invalid file #{ file_name }" do
            CorrectLineEndings.new(
              File.open(get_test_data_path_for("/repositext/validation/validator/correct_line_endings/invalid/" + file_name)),
              logger,
              reporter,
              {}
            ).run
            reporter.errors.size.must_equal 1
            reporter.errors.all? { |e|
              e.location.first.index(file_name) && 'Invalid line endings' == e.details.first
            }.must_equal true
          end
        end

      end

    end
  end
end
