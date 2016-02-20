require_relative '../../../helper'

class Repositext
  class Validation
    class Validator

      describe ContentAtFilesStartWithRecordMark do

        before do
          # Redirect console output for clean test logs
          # NOTE: use STDOUT.puts if you want to print something to the test output
          @stderr = $stderr = StringIO.new
          @stdout = $stdout = StringIO.new
        end

        let(:logger) { LoggerTest.new(nil, nil, nil, nil, nil) }
        let(:reporter) { ReporterTest.new(nil, nil, nil, nil) }

        [
          'starts_with_record_mark.txt'
        ].each do |file_name|
          it "passes a valid file: #{ file_name }" do
            ContentAtFilesStartWithRecordMark.new(
              File.open(get_test_data_path_for("/repositext/validation/validator/content_at_files_start_with_record_mark/valid/" + file_name)),
              logger,
              reporter,
              {}
            ).run
            reporter.errors.must_equal []
          end
        end

        [
          'does_not_start_with_record_mark.txt',
        ].each do |file_name|
          it "flags invalid file #{ file_name }" do
            ContentAtFilesStartWithRecordMark.new(
              File.open(get_test_data_path_for("/repositext/validation/validator/content_at_files_start_with_record_mark/invalid/" + file_name)),
              logger,
              reporter,
              {}
            ).run
            reporter.errors.size.must_equal 1
            reporter.errors.all? { |e|
              e.location.first.index(file_name) && "Content AT file doesn't start with record_mark" == e.details.first
            }.must_equal true
          end
        end

      end

    end
  end
end
