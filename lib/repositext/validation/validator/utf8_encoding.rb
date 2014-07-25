# https://github.com/rkh/coder
# http://www.cl.cam.ac.uk/~mgk25/ucs/examples/UTF-8-test.txt
# http://www.cl.cam.ac.uk/~mgk25/ucs/examples/quickbrown.txt
# http://www.columbia.edu/~fdc/utf8/
# http://stackoverflow.com/a/1319229/130830

# List of character strings in many languages: http://en.wikipedia.org/wiki/List_of_pangrams

class Repositext
  class Validation
    class Validator
      # This validator makes sure that validated text files are UTF8 encoded.
      class Utf8Encoding < Validator

        def run
          document_to_validate = ::File.read(@file_to_validate)
          errors, warnings = [], []

          catch(:abandon) do
            outcome = utf8_encoded?(document_to_validate)
            if outcome.fail?
              errors += outcome.errors
              warnings += outcome.warnings
              #throw :abandon
            end
          end

          log_and_report_validation_step(errors, warnings)
        end

        def utf8_encoded?(a_string)
          begin
            # TODO: is this a good UTF8 encoding test?
            # github uses this: https://github.com/brianmario/charlock_holmes
            # TODO: Explain what we're doing here with the encode method.
            # Are we using UTF-16 to force a change in encoding if it is already
            # UTF8 encoded?
            _r = a_string.encode('UTF-16','UTF-8')
          rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError => e
            Outcome.new(
              false, nil, [],
              [
                Reportable.error(
                  [@file_to_validate],
                  ['Invalid encoding', "Document is not UTF8 encoded: #{ e.class.to_s } - #{ e.message }"]
                )
              ]
            )
          rescue Exception => e
            logger.info e.inspect
          else
            Outcome.new(true, nil)
          end
        end

      end
    end
  end
end
