require_relative '../../../helper'

class Repositext
  class Validation
    class Validator

      describe DocxImportWorkflow do

        before do
          # Redirect console output for clean test logs
          # NOTE: use STDOUT.puts if you want to print something to the test output
          @stderr = $stderr = StringIO.new
          @stdout = $stdout = StringIO.new
        end

        let(:logger) { LoggerTest.new(nil, nil, nil, nil, nil) }
        let(:reporter) { ReporterTest.new(nil, nil, nil, nil) }

        describe '#validate_correct_file_name' do
          [
            ["eng56-0101_0297.docx", true],
            ["norcab_01_-_title_1386.docx", true],
            ["some_other_name.docx", false],
          ].each do |file_name, xpect_valid|
            it "validates #{ file_name.inspect }" do
              validator = DocxImportWorkflow.new(
                FileLikeStringIO.new('/_', '_'),
                logger,
                reporter,
                {}
              )
              if xpect_valid
                validator.send(:validate_correct_file_name, file_name, [], [])
                1.must_equal 1
              else
                lambda {
                  validator.send(
                    :validate_correct_file_name,
                    file_name,
                    [],
                    []
                  )
                }.must_raise(DocxImportWorkflow::InvalidFileNameError)
              end
            end
          end
        end

      end

    end
  end
end
