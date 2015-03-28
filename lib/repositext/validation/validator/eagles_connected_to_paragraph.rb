class Repositext
  class Validation
    class Validator
      # Validates that there are no standalone eagles. Eagles should always be
      # connected to a paragraph.
      class EaglesConnectedToParagraph < Validator

        # Runs all validations for self
        def run
          document_to_validate = @file_to_validate.read
          outcome = eagles_connected_to_paragraph?(
            document_to_validate
          )
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

      private

        # Checks that every eagle is connected to a paragraph
        # @param content [String]
        # @return [Outcome]
        def eagles_connected_to_paragraph?(content)
          # Early return if content doesn't contain any eagles
          return Outcome.new(true, nil)  if !content.index('')
          disconnected_eagles = find_disconnected_eagles(content)
          if disconnected_eagles.empty?
            Outcome.new(true, nil)
          else
            Outcome.new(
              false, nil, [],
              disconnected_eagles.map { |(line, para)|
                Reportable.error(
                  [@file_to_validate.path, line], # content_at file
                  [
                    "Eagle that is not connected to a paragraph:",
                    para.inspect
                  ]
                )
              }
            )
          end
        end

        # @return [Array<Array<String>>] an array of arrays with line numbers and paras
        def find_disconnected_eagles(content)
          # split into lines and find disconnected eagles
          content.split(/\n/).each_with_index.inject([]) { |m, (line, line_idx)|
            if line.index('')
              if line =~ /\A[^]{0,3}[^]{0,3}\z/
                # 3 or less chars on both sides of eagle, considered standalone
                m << ["line #{ line_idx + 1}", line]
              end
            end
            m
          }
        end

      end
    end
  end
end
