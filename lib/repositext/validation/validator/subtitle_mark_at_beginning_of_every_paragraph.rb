class Repositext
  class Validation
    class Validator
      # Validates that there is a subtitle_mark at the beginning of every paragraph
      class SubtitleMarkAtBeginningOfEveryParagraph < Validator

        include BodyTextExtractor

        # Runs all validations for self
        def run
          errors, warnings = [], []

          catch (:abandon)  do
            outcome = subtitle_mark_at_beginning_of_every_paragraph?(
              ::File.read(@file_to_validate)
            )
            if outcome.fail?
              errors += outcome.errors
              warnings += outcome.warnings
              #throw :abandon
            end
          end

          log_and_report_validation_step(errors, warnings)
        end

      end

    private

      # Checks that every paragraph begins with a subtitle_mark
      # @param[String] content
      # @return[Outcome]
      def subtitle_mark_at_beginning_of_every_paragraph?(content)
        paragraphs_without_subtitle_mark = case @options[:content_type]
        when :import
          check_import_file(content)
        when :content
          check_content_file(content)
        else
          raise ArgumentError.new("Invalid @options[:content_type]: #{ @options[:content_type].inspect }")
        end

        if paragraphs_without_subtitle_mark.empty?
          Outcome.new(true, nil)
        else
          Outcome.new(
            false, nil, [],
            [
              Reportable.error(
                [@file_to_validate], # content_at file
                [
                  "The following paragraphs don't start with a subtitle_mark:",
                  paragraphs_without_subtitle_mark.map { |e| e.inspect }.join("\n")
                ]
              )
            ]
          )
        end
      end

      # @param[String] content
      # @return[Array<String>] an array of paras that don't start with @
      def check_import_file(content)
        c = content.dup
        c.gsub!(/\A\[[^\]]+\]\n/, '') # remove title
        c.strip!
        get_paragraphs_that_dont_start_with_subtitle_mark(c)
      end

      # @param[String] content
      # @return[Array<String>] an array of paras that don't start with @
      def check_content_file(content)
        content_with_subtitle_marks_only = extract_body_text_with_subtitle_marks(content)
        get_paragraphs_that_dont_start_with_subtitle_mark(content_with_subtitle_marks_only)
      end

      def get_paragraphs_that_dont_start_with_subtitle_mark(content)
        # split on para boundaries and find those that don't start with subtitle_mark
        content.strip.split(/\n+/).find_all { |para|
          '@' != para.strip[0]
        }
      end

    end
  end
end
