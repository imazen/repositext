class Repositext
  class Validation
    class Validator
      # This validator makes sure that validated text files are UTF8 encoded.
      #
      # Resources:
      #
      # * https://github.com/rkh/coder
      # * http://www.cl.cam.ac.uk/~mgk25/ucs/examples/UTF-8-test.txt
      # * http://www.cl.cam.ac.uk/~mgk25/ucs/examples/quickbrown.txt
      # * http://www.columbia.edu/~fdc/utf8/
      # * http://stackoverflow.com/a/1319229/130830
      #
      # List of character strings in many languages: http://en.wikipedia.org/wiki/List_of_pangrams
      class Utf8Encoding < Validator

        def run
          text_file = @file_to_validate
          outcome = utf8_encoded?(text_file)
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

        # @param file_to_validate [RFile]
        def utf8_encoded?(file_to_validate)
          begin
            # TODO: is this a good UTF8 encoding test?
            # github uses this: https://github.com/brianmario/charlock_holmes
            # TODO: Explain what we're doing here with the encode method.
            # Are we using UTF-16 to force a change in encoding if it is already
            # UTF8 encoded?
            _r = file_to_validate.contents.encode('UTF-16','UTF-8')
          rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError => e
            Outcome.new(
              false, nil, [],
              [
                Reportable.error(
                  { filename: @file_to_validate.filename },
                  [
                    'Invalid encoding',
                    "Document is not UTF8 encoded: #{ e.class.to_s } - #{ e.message }"
                  ]
                )
              ]
            )
          rescue Exception => e
            logger.info e.inspect
          else
            # Make sure file doesn't contain UTF8 BOM
            if(file_to_validate.contents =~ /\A\xEF\xBB\xBF/m)
              # File contains BOM (Byte Order Mark), that's not valid
              Outcome.new(
                false, nil, [],
                [
                  Reportable.error(
                    { filename: @file_to_validate.filename },
                    [
                      'Unexpected BOM',
                      "Document is UTF8 encoded, however it contains a UTF8 BOM. Repositext expects NO BOM."
                    ]
                  )
                ]
              )
            else
              Outcome.new(true, nil)
            end
          end
        end

      end
    end
  end
end
