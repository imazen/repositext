class Repositext
  class Validation
    class Validator
      # Validates that there are no standalone eagles. Eagles should always be
      # connected to a paragraph.
      class EaglesConnectedToParagraph < Validator

        # Runs all validations for self
        def run
          content_at_file = @file_to_validate
          outcome = eagles_connected_to_paragraph?(content_at_file)
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

      private

        # Checks that every eagle is connected to a paragraph
        def eagles_connected_to_paragraph?(content_at_file)
          # Early return if content doesn't contain any eagles
          return Outcome.new(true, nil)  if !content_at_file.contents.index('')
          disconnected_eagles = find_disconnected_eagles(content_at_file)
          if disconnected_eagles.empty?
            Outcome.new(true, nil)
          else
            Outcome.new(
              false, nil, [],
              disconnected_eagles.map { |(line, para)|
                Reportable.error(
                  {
                    filename: content_at_file.filename,
                    line: line,
                    context: para.inspect
                  },
                  ["Eagle is not connected to a paragraph"]
                )
              }
            )
          end
        end

        # @return [Array<Array<String>>] an array of arrays with line numbers and paras
        def find_disconnected_eagles(content_at_file)
          # split into lines and find disconnected eagles
          content_at_file.contents
                         .split(/\n/)
                         .each_with_index
                         .inject([]) { |m, (line, line_idx)|
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
