class Repositext
  class Validation
    class Validator
      # Validates that paragraph numbers
      # * are in consecutive order
      # * have no gaps
      # * have no duplicates
      # * start with 1 or 2
      class ParagraphNumberSequencing < Validator

        # Runs all validations for self
        def run
          content_at_file = @file_to_validate
          outcome = paragraph_numbers_in_sequence?(content_at_file)
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

      private

        # @param content_at_file [RFile::ContentAt]
        # @return [Outcome]
        def paragraph_numbers_in_sequence?(content_at_file)
          paragraph_numbers_out_of_sequence = find_paragraph_numbers_out_of_sequence(
            content_at_file
          )
          if paragraph_numbers_out_of_sequence.empty?
            Outcome.new(true, nil)
          else
            Outcome.new(
              false, nil, [],
              paragraph_numbers_out_of_sequence.map { |(line, issue_desc)|
                Reportable.error(
                  {
                    filename: content_at_file.filename,
                    line: line,
                  },
                  [
                    "Paragraph number is out of sequence",
                    issue_desc.inspect
                  ]
                )
              }
            )
          end
        end

        # @param content_at_file [RFile::ContentAt]
        # @return [Array<Array<String>>] an array of arrays with line numbers and paras
        def find_paragraph_numbers_out_of_sequence(content_at_file)
          kramdown_doc = Kramdown::Document.new(
            content_at_file.contents,
            input: 'KramdownRepositext'
          )
          tree_structure = Kramdown::TreeStructureExtractor.new(kramdown_doc).extract
          actual_paragraph_numbers = tree_structure[:paragraph_numbers].find_all { |e|
            e[:paragraph_number] =~ /\A\d/
          }
          return []  if actual_paragraph_numbers.empty?
          prev_num = nil
          pns_oos = []
          actual_paragraph_numbers.each_with_index do |cur_attrs, idx|
            cur_num = cur_attrs[:paragraph_number]
            cur_line = cur_attrs[:line]
            if prev_num.nil?
              # check first para num
              next  if allow_unexpected_start_number?(content_at_file.filename)
              pns_oos << [cur_line, "Invalid start number: #{ cur_num }"]  if cur_num !~ /\A(1|2)(?!\d)/
            elsif !(vsn = valid_subsequent_numbers(prev_num)).include?(cur_num)
              # find invalid subsequent numbers
              if content_at_file.filename.index('62-0318') && '2' == cur_num
                # this is an expected exception. Paragraph numbering in this
                # file is reset to '2' half way down the file.
                # Nothing to do
              elsif prev_num == cur_num
                pns_oos << [cur_line, "Duplicate number: #{ cur_num }"]
              elsif cur_num == prev_num.succ.succ
                pns_oos << [cur_line, "Gap in numbers: Previous was #{ prev_num }, expected #{ prev_num.succ }, got #{ cur_num }"]
              else
                pns_oos << [cur_line, "Unexpected number: Previous was #{ prev_num }, expected one of [#{ vsn.join(',') }], got #{ cur_num }"]
              end
            end
            prev_num = cur_num
          end
          pns_oos
        end

        # Returns an array of all valid subsequent_numbers for num
        # @param num [String]
        # @return [Array<String>]
        def valid_subsequent_numbers(num)
          case num
          when /\A\d+\z/
            # Digits only:
            # Allow subsequent digit, or same digit with 'a' suffix
            [num.succ, "#{ num }a"]
          when /\A\d+[a-z]\z/
            # Digits and letters:
            # Allow valid subsequent letters, or just digit (same or subsequent)
            [
              valid_subsequent_letters(num.gsub(/\d+/, '')).map { |e| num.to_i.to_s + e },
              num.to_i.to_s,
              (num.to_i + 1).to_s,
            ].flatten
          else
            # unexpected para num format
            raise "Unexpected number: #{ num.inspect }"
          end
        end

        # Returns array of all valid subsequent_letters for letter
        def valid_subsequent_letters(letter)
          case letter
          when 'h'
            # i and j may or may not be skipped
            %w[i j k]
          when 'i'
            # j may or may not be skipped
            %w[j k]
          when 'k'
            # always skip l
            %w[m]
          when 'n'
            # always skip o
            %w[p]
          else
            [letter.succ]
          end
        end

        def allow_unexpected_start_number?(filename)
          files_that_start_with_unexpected_numbers.any? { |e| filename.index(e) }
        end

        def files_that_start_with_unexpected_numbers
          %w[].freeze
        end

      end
    end
  end
end
