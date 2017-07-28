class Repositext
  class Validation
    class Validator
      # Validates that two files' paragraphs have identical styles applied.
      class ParagraphStyleConsistency < Validator

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
          f_p_styles_and_spans = extract_paragraph_styles_and_formatting_spans(f_content_at_file.contents)
          p_p_styles_and_spans = extract_paragraph_styles_and_formatting_spans(p_content_at_file.contents)
          p_style_and_span_mismatches = compute_p_style_and_span_mismatches(
            f_p_styles_and_spans,
            p_p_styles_and_spans
          )

          if p_style_and_span_mismatches.empty?
            Outcome.new(true, nil)
          else
            Outcome.new(
              false, nil, [],
              p_style_and_span_mismatches.map { |mismatch|
                Reportable.error([@file_to_validate.first.filename], mismatch)
              }
            )
          end
        end

      private

        # Extracts paragraph styles from doc.
        # @param doc [String] kramdown document with paragraph styles
        # @return [Array<Hash>] one entry for each paragraph:
        #   {
        #     type: :p,
        #     paragraph_styles: ["normal", "first_par"],
        #     formatting_spans: [:italic, :smcaps],
        #     index: 3,
        #     plain_text_contents: "asdf (40 chars max)"
        #   }
        def extract_paragraph_styles_and_formatting_spans(doc)
          kramdown_doc = Kramdown::Document.new(doc, input: 'KramdownRepositext')
          psafsas = kramdown_doc.to_paragraph_style_and_formatting_span_attrs
          psafsas.each { |p_attrs|
            # Remove classes that are specific to primary
            p_attrs[:paragraph_styles] -= %w[
              decreased_word_space
              id_title3
              increased_word_space
              indent_for_eagle
              omit
            ]
            # Normalize .song_break to .song because we expect them to be different
            # between primary and foreign.
            p_attrs[:paragraph_styles].map! { |e|
              if 'song_break' == e
                'song'
              else
                e
              end
            }
          }
          psafsas
        end

        # Computes mismatches between primary and foreign paragraph styles and
        # formatting spans inside of each paragraph.
        # Checks only for presence of at least one formatting span. Does not
        # expect exact same counts of spans between foreign and primary.
        # @param f_p_styles_and_spans [Array<Hash>] one entry per foreign para.
        #   See #extract_paragraph_styles_and_formatting_spans for details
        # @param p_p_styles_and_spans [Array<Hash>] one entry per primary para.
        #   See #extract_paragraph_styles_and_formatting_spans for details
        # @return [Array<Array<String>>] one entry for each mismatch. Entry contains
        #   generic error message and error details.
        def compute_p_style_and_span_mismatches(f_p_styles_and_spans, p_p_styles_and_spans)
          mismatches = []
          # First we compute paragraph level diffs. With the diff info, we can then
          # compare the formatting_span diffs whithin each paragraph. The diff
          # info will help us align paragraphs.
          paragraph_style_diffs = Repositext::Utils::ArrayDiffer.diff(
            *(
              [p_p_styles_and_spans, f_p_styles_and_spans].map { |psafsas|
                psafsas.map { |p_attrs|
                  # Extract paragraph style only
                  p_attrs[:paragraph_styles]
                }
              }
            )
          )
          # Report paragraph_style_differences
          report_paragraph_style_differences(
            f_p_styles_and_spans,
            p_p_styles_and_spans,
            paragraph_style_diffs,
            mismatches
          )
          # Align paragraphs using diff data
          aligned_paragraph_pairs = align_foreign_and_primary_paragraphs(
            f_p_styles_and_spans,
            p_p_styles_and_spans,
            paragraph_style_diffs
          )
          # Compare formatting_span attrs in each paragraph pair
          aligned_paragraph_pairs.each { |(f_attrs, p_attrs)|
            # skip gaps. They are already reported as paragraph mismatches.
            next  if f_attrs.nil? || p_attrs.nil?
            if f_attrs[:formatting_spans] != p_attrs[:formatting_spans]
              mismatches << [
                "Span formatting mismatch",
                [
                  "Foreign span formatting #{ f_attrs[:formatting_spans].inspect } is different from ",
                  "primary #{ p_attrs[:formatting_spans].inspect } ",
                  "in foreign paragraph ##{ f_attrs[:index] } starting with #{ f_attrs[:plain_text_contents].inspect }",
                ].join
              ]
            end
          }
          mismatches
        end

        # @param f_p_styles_and_spans [Array<Hash>] one entry per foreign para.
        #   See #extract_paragraph_styles_and_formatting_spans for details
        # @param p_p_styles_and_spans [Array<Hash>] one entry per primary para.
        #   See #extract_paragraph_styles_and_formatting_spans for details
        # @param paragraph_style_diffs [Array<Array>]
        # @param mismatches [Array] collector for mismatches.
        # Appends to mismatches in place.
        def report_paragraph_style_differences(f_p_styles_and_spans, p_p_styles_and_spans, paragraph_style_diffs, mismatches)
          error_type = "Paragraph class mismatch"
          paragraph_style_diffs.each { |diff|
            # Cast Diff::LCS::ContextChange to array
            # diff = ["=", [25, ""], [27, ""]], ["+", [26, nil], [28, ""]]]
            type, p_attrs, f_attrs = diff.to_a
            # Get detailed paragraph attrs for reporting
            f_p_style_and_spans = f_p_styles_and_spans[f_attrs.first]
            p_p_style_and_spans = p_p_styles_and_spans[p_attrs.first]
            # Skip any that are equal
            if '=' == type || ('' == f_attrs.last.to_s && '' == p_attrs.last.to_s)
              next
            end
            case type
            when '!'
              # change
              mismatches << [
                error_type,
                [
                  "Foreign paragraph class #{ f_attrs.last.inspect } is different from ",
                  "primary #{ p_attrs.last.inspect } ",
                  "in foreign paragraph ##{ f_attrs.first } starting with ",
                  f_p_style_and_spans[:plain_text_contents].inspect,
                ].join
              ]
            when '+'
              # insertion
              mismatches << [
                error_type,
                [
                  "Foreign has extra paragraph ##{ f_attrs.first } ",
                  "with class #{ f_attrs.last.inspect } starting with ",
                  f_p_style_and_spans[:plain_text_contents].inspect,
                ].join
              ]
            when '-'
              # deletion
              mismatches << [
                error_type,
                [
                  "Foreign is missing primary paragraph ##{ p_attrs.first } ",
                  "with class #{ p_attrs.last.inspect } starting with ",
                  p_p_style_and_spans[:plain_text_contents].inspect,
                ].join
              ]
            when '='
              # Nothing to do
            else
              raise "Invalid type: #{ type.inspect }"
            end
          }
        end

        # @param f_p_styles_and_spans [Array<Hash>] one entry per foreign para.
        #   See #extract_paragraph_styles_and_formatting_spans for details
        # @param p_p_styles_and_spans [Array<Hash>] one entry per primary para.
        #   See #extract_paragraph_styles_and_formatting_spans for details
        # @param paragraph_style_diffs [Array<Array>]
        # @return [Array<Array>] the paragraph airs aligned based on diffs.
        def align_foreign_and_primary_paragraphs(f_p_styles_and_spans, p_p_styles_and_spans, paragraph_style_diffs)
          aligned_pairs = []
          p_pos = 0
          f_pos = 0
          diff_pos = 0
          iteration_count = 0
          while(
            p_pos < p_p_styles_and_spans.length ||
            f_pos < f_p_styles_and_spans.length
          ) do
            # diff = ["=", [25, ""], [27, ""]], ["+", [26, nil], [28, ""]]]
            diff_type, diff_f_attrs, diff_p_attrs = paragraph_style_diffs[diff_pos]
            if('-' == diff_type && f_pos == diff_f_attrs.first)
              # Missing foreign paragraph, use primary only
              aligned_pairs << [nil, p_p_styles_and_spans[p_pos]]
              p_pos += 1
              diff_pos += 1
            elsif('+' == diff_type && p_pos == diff_p_attrs.first)
              # Extra foreign paragraph, use foreign only
              aligned_pairs << [f_p_styles_and_spans[f_pos], nil]
              f_pos += 1
              diff_pos += 1
            else
              # No diff for current paragraph pair, use both
              aligned_pairs << [f_p_styles_and_spans[f_pos], p_p_styles_and_spans[p_pos]]
              f_pos += 1
              p_pos += 1
            end
            if (iteration_count += 1) > 10_000
              puts "p_pos: #{ p_pos.inspect }"
              puts "f_pos: #{ f_pos.inspect }"
              puts "diff_pos: #{ diff_pos.inspect }"
              ap p_p_styles_and_spans
              ap f_p_styles_and_spans
              raise "Infinite loop"
            end
          end
          aligned_pairs
        end

      end
    end
  end
end
