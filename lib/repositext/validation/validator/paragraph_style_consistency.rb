class Repositext
  class Validation
    class Validator
      # Validates that two files' paragraphs have identical styles applied.
      class ParagraphStyleConsistency < Validator

        attr_accessor :distinguish_between_normal_and_normal_pn # for testing

        # Runs all validations for self
        def run
          f_content_at_file, p_content_at_file = @file_to_validate
          outcome = paragraph_styles_consistent?(f_content_at_file, p_content_at_file)
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

        # Checks if f_content_at_file and p_content_at_file's paragraphs have
        # identical styles applied.
        # @param f_content_at_file [RFile::ContentAt]
        # @param p_content_at_file [RFile::ContentAt]
        # @return [Outcome]
        def paragraph_styles_consistent?(f_content_at_file, p_content_at_file)
          # If the foreign file has no paragraph numbers, then we make no distinction
          # between .normal and .normal_pn. This is true for some legacy files.
          # We detect the presence of paragraph numbers in the foreign file,
          # and if the foreign file appears to have paragraph numbers, then
          # we distinguish between .normal and .normal_pn.
          @distinguish_between_normal_and_normal_pn = foreign_has_paragraph_numbers?(f_content_at_file.contents)

          f_paragraph_styles = extract_paragraph_styles(f_content_at_file.contents)
          p_paragraph_styles = extract_paragraph_styles(p_content_at_file.contents)
          mismatching_paragraph_styles = compute_paragraph_style_diff(
            f_paragraph_styles,
            p_paragraph_styles
          )

          if mismatching_paragraph_styles.empty?
            Outcome.new(true, nil)
          else
            Outcome.new(
              false, nil, [],
              mismatching_paragraph_styles.map { |diff|
                Reportable.error(
                  [@file_to_validate.first.filename],
                  ['Difference in paragraph style between foreign and its corresponding primary file', diff]
                )
              }
            )
          end
        end

      private

        PARAGRAPH_STYLE_REGEX = /^\{:/

        # Extracts paragraph styles from doc.
        # @param doc [String] kramdown document with paragraph styles
        # @return [String] one line for each doc line. Lines with paragraph style
        # contain the style, all other lines are empty.
        def extract_paragraph_styles(doc)
          doc.strip.split(/\n+/).map { |line|
            line =~ PARAGRAPH_STYLE_REGEX ? line : ''
          }.inject([]) { |m,e|
            # Remove a number of classes that are different between primary and
            # foreign:
            r = e.dup
            %w[
              decreased_word_space
              id_title3
              increased_word_space
              indent_for_eagle
              omit
            ].each { |class_name|
              r.gsub!(/\s*\.#{ class_name }\s*/, ' ')
            }
            # Normalize .song_break to .song because we expect them to be different
            # between primary and foreign languages.
            r.gsub!(/\s*\.song_break\s*/, ' .song ')
            # Remove everything but paragraph class names
            r = r.scan(/\.\w+/)
            m << r.join(' ')
          }
        end

        # Computes diffs between foreign and primary paragraph styles.
        # @param styles_f [Array<String>] one entry per line in foreign file.
        #     Only paragraph style lines contain text. All others are empty.
        # @param styles_p [Array<String>] one entry per line in primary file.
        # @return [Array<Hash>] one entry for each diff.
        def compute_paragraph_style_diff(styles_f, styles_p)
          if !@distinguish_between_normal_and_normal_pn
            # Foreign doesn't contain any paragraph numbers. In that case,
            # .normal and .normal_pn should be treated as equal.
            styles_p.each { |e|
              next  if [nil, ''].include?(e)
              e.gsub!('.normal_pn', '.normal')
            }
          end
          diffs = Repositext::Utils::ArrayDiffer.diff(styles_f, styles_p)
          diffs.inject([]) { |m, diff|
            # diff = ["=", [25, ""], [27, ""]], ["+", [26, nil], [28, ""]]]
            type, f_attrs, p_attrs = *diff
            if '=' == type || ('' == f_attrs.last.to_s && '' == p_attrs.last.to_s)
              next m
            end
            case type
            when '!'
              # change
              m << {
                type: :different_style_in_foreign,
                line: f_attrs.first,
                details: "foreign: #{ f_attrs.last }, primary: #{ p_attrs.last }"
              }
            when '+'
              # insertion
              m << {
                type: :missing_style_in_foreign,
                line: f_attrs.first,
                details: p_attrs.last
              }
            when '-'
              # deletion
              m << {
                type: :extra_style_in_foreign,
                line: f_attrs.first,
                details: f_attrs.last
              }
            when '='
              # Nothing to do
            else
              raise "Invalid type: #{ type.inspect }"
            end
            m
          }
        end

        def foreign_has_paragraph_numbers?(foreign_doc)
          paragraph_number_count = foreign_doc.scan(/^[^[:digit:]\n]{0,2}[[:digit:]]+(?![[:digit:]\.])/).size
          block_level_elements_count = foreign_doc.split("\n\n").length

          return false  if 0 == block_level_elements_count
          # return true if more than 30% of block level elements contain a para number
          (paragraph_number_count / block_level_elements_count.to_f) > 0.3
        end

      end
    end
  end
end
