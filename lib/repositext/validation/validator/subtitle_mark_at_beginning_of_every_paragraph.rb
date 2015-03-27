class Repositext
  class Validation
    class Validator
      # Validates that there is a subtitle_mark at the beginning of every paragraph
      # after the second record_id. We assume that every document has at least
      # two record_ids. This is a fair assumption since this validation is only
      # run on the primary repository.
      class SubtitleMarkAtBeginningOfEveryParagraph < Validator

        class NoSubtitleMarkAtBeginningOfParagraphError < StandardError; end

        # Runs all validations for self
        def run
          document_to_validate = @file_to_validate.read
          outcome = subtitle_mark_at_beginning_of_every_paragraph?(
            document_to_validate
          )
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

      private

        # Checks that every paragraph in content begins with a subtitle_mark
        # @param content [String]
        # @return [Outcome]
        def subtitle_mark_at_beginning_of_every_paragraph?(content)
          # Early return if content doesn't contain any subtitle_marks
          return Outcome.new(true, nil)  if !content.index('@')
          # We only look at text after the second record_id. Replace all lines
          # before the second record_id with empty lines (to keep line location
          # in error reports accurate)
          content_from_second_record_id = remove_all_text_content_before_second_record_id(content)
          case @options[:content_type]
          when :import
            # In this mode we raise an exception if we find any paragraphs
            paragraphs_without_subtitle_mark = check_import_file(content_from_second_record_id)
            if paragraphs_without_subtitle_mark.empty?
              Outcome.new(true, nil)
            else
              # We want to terminate an import if there isn't a subtitle_mark
              # at the beginning of every paragraph.
              # Normally we'd return a negative outcome (see :content), but in this
              # case we raise an exception.
              raise NoSubtitleMarkAtBeginningOfParagraphError.new(
                [
                  "The following paragraphs don't start with a subtitle_mark:",
                  paragraphs_without_subtitle_mark.map { |e| e.inspect }.join("\n")
                ].join("\n")
              )
            end
          when :content
            # In this mode we only report errors if we find any paragraphs
            paragraphs_without_subtitle_mark = check_content_file(content_from_second_record_id)
            if paragraphs_without_subtitle_mark.empty?
              Outcome.new(true, nil)
            else
              Outcome.new(
                false, nil, [],
                paragraphs_without_subtitle_mark.map { |(line, para)|
                  Reportable.error(
                    [@file_to_validate.path, line], # content_at file
                    [
                      "Paragraph doesn't start with a subtitle_mark:",
                      para.inspect
                    ]
                  )
                }
              )
            end
          else
            raise ArgumentError.new("Invalid @options[:content_type]: #{ @options[:content_type].inspect }")
          end
        end

        # @param content [String]
        # @return (see #get_paragraphs_that_dont_start_with_subtitle_mark)
        def check_import_file(content)
          # No need to strip other tokens since the subtitle import files have them stripped already
          get_paragraphs_that_dont_start_with_subtitle_mark(content)
        end

        # @param[String] content
        # @return (see #get_paragraphs_that_dont_start_with_subtitle_mark)
        def check_content_file(content)
          content_with_subtitle_marks_only = Repositext::Utils::SubtitleMarkTools.extract_body_text_with_subtitle_marks_only(content)
          get_paragraphs_that_dont_start_with_subtitle_mark(content_with_subtitle_marks_only)
        end

        # @return [Array<Array<String>>] an array of arrays with line numbers and paras that don't start with @
        def get_paragraphs_that_dont_start_with_subtitle_mark(content)
          # split on para boundaries and find those that don't start with subtitle_mark
          content.split(/\n/).each_with_index.inject([]) { |m, (para, line_idx)|
            if '' != para && '@' != para.strip[0]
              m << ["line #{ line_idx + 1}", para]
            end
            m
          }
        end

        # Empties all lines up to the second record_id
        # @param[String]
        # @return[String]
        def remove_all_text_content_before_second_record_id(txt)
          # split text into lines
          lines = txt.split("\n")
          # empty all lines up to second record_id
          record_id_counter = 0
          lines.each_with_index do |line, idx|
            record_id_counter += 1  if /\A\^\^\^/ =~ line
            lines[idx] = ''
            break  if record_id_counter >= 2
          end
          if record_id_counter < 2
            # No second record_id found, return original text
            puts 'Warning: Could not find second record_id'
            txt
          else
            # return modified text
            lines.join("\n")
          end
        end

      end
    end
  end
end
