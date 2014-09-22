class Repositext
  class Validation
    class Validator
      # Validates that there is a subtitle_mark at the beginning of every paragraph
      class SubtitleMarkAtBeginningOfEveryParagraph < Validator

        class NoSubtitleMarkAtBeginningOfParagraph < StandardError; end

        # Runs all validations for self
        def run
          document_to_validate = @file_to_validate.read
          errors, warnings = [], []

          catch(:abandon) do
            outcome = subtitle_mark_at_beginning_of_every_paragraph?(
              document_to_validate
            )
            if outcome.fail?
              errors += outcome.errors
              warnings += outcome.warnings
              #throw :abandon
            end
          end

          log_and_report_validation_step(errors, warnings)
        end

      private

        # Checks that every paragraph begins with a subtitle_mark
        # @param[String] content
        # @return[Outcome]
        def subtitle_mark_at_beginning_of_every_paragraph?(content)
          # Early return if content doesn't contain any subtitle_marks
          return Outcome.new(true, nil)  if !content.index('@')
          # We only look at text after the first subtitle_mark. Replace all lines
          # before the first subtitle_mark with empty lines (to keep line location
          # in error reports accurate)
          content_from_first_subtitle_mark = remove_all_text_content_before_first_subtitle_mark(content)
          case @options[:content_type]
          when :import
            paragraphs_without_subtitle_mark = check_import_file(content_from_first_subtitle_mark)
            if paragraphs_without_subtitle_mark.empty?
              Outcome.new(true, nil)
            else
              # We want to terminate an import if there isn't a subtitle_mark
              # at the beginning of every paragraph.
              # Normally we'd return a negative outcome (see :content), but in this
              # case we raise an exception.
              raise NoSubtitleMarkAtBeginningOfParagraph.new(
                [
                  "The following paragraphs don't start with a subtitle_mark:",
                  paragraphs_without_subtitle_mark.map { |e| e.inspect }.join("\n")
                ].join("\n")
              )
            end
          when :content
            paragraphs_without_subtitle_mark = check_content_file(content_from_first_subtitle_mark)
            if paragraphs_without_subtitle_mark.empty?
              Outcome.new(true, nil)
            else
              Outcome.new(
                false, nil, [],
                [
                  Reportable.error(
                    [@file_to_validate.path], # content_at file
                    [
                      "The following paragraphs don't start with a subtitle_mark:",
                      paragraphs_without_subtitle_mark.map { |e| e.inspect }.join("\n")
                    ]
                  )
                ]
              )
            end
          else
            raise ArgumentError.new("Invalid @options[:content_type]: #{ @options[:content_type].inspect }")
          end
        end

        # @param[String] content
        # @return[Array<String>] an array of paras that don't start with @
        def check_import_file(content)
          c = content.dup
          c.strip!
          get_paragraphs_that_dont_start_with_subtitle_mark(c)
        end

        # @param[String] content
        # @return[Array<String>] an array of paras that don't start with @
        def check_content_file(content)
          content_with_subtitle_marks_only = Repositext::Utils::SubtitleMarkTools.extract_body_text_with_subtitle_marks_only(content)
          get_paragraphs_that_dont_start_with_subtitle_mark(content_with_subtitle_marks_only)
        end

        def get_paragraphs_that_dont_start_with_subtitle_mark(content)
          # split on para boundaries and find those that don't start with subtitle_mark
          content.strip.split(/\n+/).find_all { |para|
            '@' != para.strip[0]
          }
        end

        # Keeps only newlines of lines before the first subtitle_mark in txt
        # @param[String]
        # @return[String]
        def remove_all_text_content_before_first_subtitle_mark(txt)
          substring_to_first_subtitle_mark = txt.match(/\A[^@]*(?=(@|\z))/).to_s
          only_newlines_preserved = substring_to_first_subtitle_mark.gsub(/[^\n]/, '')
          txt.sub(substring_to_first_subtitle_mark, only_newlines_preserved)
        end

      end
    end
  end
end
