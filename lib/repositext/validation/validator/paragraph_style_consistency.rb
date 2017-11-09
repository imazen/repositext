class Repositext
  class Validation
    class Validator
      # Validates that two files' paragraphs have identical classes and formatting
      # spans applied.
      class ParagraphStyleConsistency < Validator

        # Runs all validations for self
        def run
          f_content_at_file, p_content_at_file = @file_to_validate
          outcome = pclasses_and_fspans_consistent?(f_content_at_file, p_content_at_file)
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

        # Checks if f_content_at_file and p_content_at_file's paragraphs have
        # identical styles applied.
        # @param f_content_at_file [RFile::ContentAt]
        # @param p_content_at_file [RFile::ContentAt]
        # @return [Outcome]
        def pclasses_and_fspans_consistent?(f_content_at_file, p_content_at_file)
          f_pclasses_and_fspans = extract_pclasses_and_fspans(f_content_at_file.contents)
          p_pclasses_and_fspans = extract_pclasses_and_fspans(p_content_at_file.contents)
          pclass_and_fspan_mismatches = compute_pclass_and_fspan_mismatches(
            f_pclasses_and_fspans,
            p_pclasses_and_fspans
          )
          if pclass_and_fspan_mismatches.empty?
            Outcome.new(true, nil)
          else
            Outcome.new(
              false, nil, [],
              pclass_and_fspan_mismatches.map { |(mismatch_location_attrs, error_attrs)|
                Reportable.error(
                  {
                    filename: f_content_at_file.filename,
                    corr_filename: p_content_at_file.filename,
                  }.merge(mismatch_location_attrs),
                  error_attrs
                )
              }
            )
          end
        end

      private

        # Extracts paragraph classes and their formatting_spans from doc.
        # @param doc [String] kramdown document with paragraph classes
        # @return [Array<Hash>] one entry for each paragraph:
        #   {
        #     type: :p,
        #     paragraph_classes: ["normal", "first_par"],
        #     formatting_spans: [:italic, :smcaps],
        #     line: 3,
        #   }
        def extract_pclasses_and_fspans(doc)
          kramdown_doc = Kramdown::Document.new(doc, input: 'KramdownRepositext')
          psafsas = kramdown_doc.to_paragraph_style_and_formatting_span_attrs
          psafsas.each { |p_attrs|
            # Remove classes that are specific to primary
            p_attrs[:paragraph_classes] -= %w[
              decreased_word_space
              increased_word_space
              indent_for_eagle
              omit
            ]
            # Normalize .song_break to .song because we expect them to be different
            # between primary and foreign.
            p_attrs[:paragraph_classes].map! { |e|
              if 'song_break' == e
                'song'
              else
                e
              end
            }
          }
          psafsas
        end

        # Computes mismatches between primary and foreign paragraph classes and
        # formatting spans inside of each paragraph.
        # Checks only for presence of at least one formatting span. Does not
        # expect exact same counts of spans between foreign and primary.
        # @param f_pclasses_and_fspans [Array<Hash>] one entry per foreign para.
        #   See #extract_pclasses_and_fspans for details
        # @param p_pclasses_and_fspans [Array<Hash>] one entry per primary para.
        #   See #extract_pclasses_and_fspans for details
        # @return [Array<Array<String>>] one entry for each mismatch. Entry contains
        #   array with location and array with generic error message and error details.
        def compute_pclass_and_fspan_mismatches(f_pclasses_and_fspans, p_pclasses_and_fspans)
          mismatches = []
          # First we compute paragraph level diffs. With the diff info, we can then
          # compare the formatting_span diffs whithin each paragraph. The diff
          # info will help us align paragraphs.
          paragraph_class_diffs = Repositext::Utils::ArrayDiffer.diff(
            *(
              [p_pclasses_and_fspans, f_pclasses_and_fspans].map { |psafsas|
                psafsas.map { |p_attrs|
                  # Extract paragraph style only
                  p_attrs[:paragraph_classes]
                }
              }
            )
          )
          report_paragraph_class_differences(
            f_pclasses_and_fspans,
            p_pclasses_and_fspans,
            paragraph_class_diffs,
            mismatches
          )
          # Align paragraphs using diff data
          aligned_paragraph_pairs = align_foreign_and_primary_paragraphs(
            f_pclasses_and_fspans,
            p_pclasses_and_fspans,
            paragraph_class_diffs
          )
          # Compare formatting_span attrs in each paragraph pair
          f_language = @file_to_validate.first.language
          validation_rules = f_language.paragraph_style_consistency_validation_rules
          aligned_paragraph_pairs.each { |(f_attrs, p_attrs)|
            # Skip any gaps. They are already reported as paragraph class mismatches.
            next  if f_attrs.nil? || p_attrs.nil?
            compute_formatting_span_mismatches(
              f_attrs,
              p_attrs,
              validation_rules,
              mismatches
            )
          }
          mismatches
        end

        # Computes formatting_span mismatches for a paragraph pair. Considers
        # language specific validation rules.
        # @param f_attrs [Array<Hash>] see #extract_pclasses_and_fspans
        # @param p_attrs [Array<Hash>] see #extract_pclasses_and_fspans
        # @param validation_rules [Hash] see Language#paragraph_style_consistency_validation_rules
        # @param mismatches [Array] collector for any mismatches to report.
        # @return Appends to mismatches in place.
        def compute_formatting_span_mismatches(f_attrs, p_attrs, validation_rules, mismatches)
          # Prepare foreign formatting_spans by transforming them according to
          # language's validation rules.
          prepared_f_fspans = prepare_formatting_spans(f_attrs, validation_rules)
          if prepared_f_fspans != p_attrs[:formatting_spans]
            # formatting_spans are different, collect the details.
            fspan_diffs = Repositext::Utils::ArrayDiffer.diff(
              p_attrs[:formatting_spans],
              prepared_f_fspans
            )
            missing_foreign_fspans = []
            extra_foreign_fspans = []
            fspan_diffs.each { |diff|
              # diff = ["-", [0, :italic], [0, nil]]
              # Cast Diff::LCS::ContextChange to array!
              type, p_diff_attrs, f_diff_attrs = diff.to_a
              case type
              when '='
                next # skip equals
              when '+'
                # Extra in foreign
                extra_foreign_fspans << f_diff_attrs.last
              when '-'
                # Missing in foreign
                missing_foreign_fspans << p_diff_attrs.last
              when '!'
                # Different, report as both missing and extra
                extra_foreign_fspans << f_diff_attrs.last
                missing_foreign_fspans << p_diff_attrs.last
              else
                raise "Handle this: #{ diff.inspect }"
              end
            }

            # Check differences agains validation_rules and report any that
            # match the rules.
            missing_foreign_fspans.each { |formatting_span|
              validation_rule = compute_formatting_span_validation_rule(
                f_attrs,
                formatting_span,
                validation_rules
              )
              if [:strict, :report_missing].include?(validation_rule)
                # Report error
                mismatches << [
                  {
                    line: f_attrs[:line_number],
                    corr_line: p_attrs[:line_number],
                  },
                  [
                    "Span formatting mismatch",
                    [
                      "Foreign is missing formatting span #{ formatting_span.inspect }",
                    ].join,
                  ],
                ]
              else
                # Ignore
                puts "Ignoring missing foreign #{ formatting_span.inspect } given validation_rule #{ validation_rule.inspect }"
              end
            }
            extra_foreign_fspans.each { |formatting_span|
              validation_rule = compute_formatting_span_validation_rule(
                f_attrs,
                formatting_span,
                validation_rules
              )
              if [:strict, :report_extra].include?(validation_rule)
                # Report error
                mismatches << [
                  {
                    line: f_attrs[:line_number],
                    corr_line: p_attrs[:line_number],
                  },
                  [
                    "Span formatting mismatch",
                    [
                      "Foreign has extra formatting span #{ formatting_span.inspect }",
                    ].join,
                  ],
                ]
              else
                # Ignore
                puts "Ignoring extra foreign #{ formatting_span.inspect } given validation_rule #{ validation_rule.inspect }"
              end
            }
          end
        end

        # Transforms foreign formatting_spans according to language's validation
        # rules.
        # @param f_attrs [Hash] see #extract_pclasses_and_fspans
        # @param validation_rules [Hash] see Language#paragraph_style_consistency_validation_rules
        # @return [Array] transformed formatting_spans
        def prepare_formatting_spans(f_attrs, validation_rules)
          validation_rules[:map_foreign_to_primary_formatting_spans].call(f_attrs)
        end

        # Given foreign pclasses and fspan, finds the language specific validation
        # rule to be applied to the fspan.
        # @param p_attrs [Hash] see #extract_pclasses_and_fspans
        # @param fspan [Symbol]
        # @param validation_rules [Hash] see Language#paragraph_style_consistency_validation_rules
        # @return [Symbol]
        def compute_formatting_span_validation_rule(p_attrs, fspan, validation_rules)
          # Start with most specific (based on :element_type, :paragraph_class, and fspan type)
          r = case p_attrs[:type]
          when :header
            # No classes to consider
            validation_rules.dig(:paragraph_class, :header, fspan)
          when :hr
            # Nothing to do
            :none
          when :p
            # Look for paragraph classes, then fspan type
            para_level_rules = p_attrs[:paragraph_classes].map { |p_class|
              validation_rules.dig(:paragraph_class, :p, p_class.to_sym)
            }.compact.first
            case para_level_rules
            when Symbol
              # Return symbol as is
              para_level_rules
            when Hash
              # Look for fspan type
              para_level_rules[fspan]
            when nil
              # Not found, return nil
              nil
            else
              raise "Handle this: #{ para_level_rules.inspect }"
            end
          else
            raise "Handle this: #{ p_attrs.inspect }"
          end
          # Then try fspan type
          r ||= validation_rules.dig(:formatting_span_type, fspan)
          # Then try language default
          r ||= validation_rules[:language]
          if r.nil?
            raise "No language default validation rule given! #{ validation_rules.inspect }"
          end
          r
        end

        # @param f_pclasses_and_fspans [Array<Hash>] one entry per foreign para.
        #   See #extract_pclasses_and_fspans for details
        # @param p_pclasses_and_fspans [Array<Hash>] one entry per primary para.
        #   See #extract_pclasses_and_fspans for details
        # @param paragraph_class_diffs [Array<Array>]
        # @param mismatches [Array] collector for mismatches.
        # Appends to mismatches in place.
        def report_paragraph_class_differences(f_pclasses_and_fspans, p_pclasses_and_fspans, paragraph_class_diffs, mismatches)
          error_type = "Paragraph class mismatch"
          paragraph_class_diffs.each { |diff|
            # diff = ["=", [1, ["first_par", "normal"]], [1, ["first_par", "normal_pn"]]]
            # Cast Diff::LCS::ContextChange to array!
            type, p_attrs, f_attrs = diff.to_a
            # Get detailed paragraph attrs for reporting
            f_p_style_and_spans = f_pclasses_and_fspans[f_attrs.first] || {}
            p_p_style_and_spans = p_pclasses_and_fspans[p_attrs.first] || {}
            # Skip any that are equal
            if '=' == type || ('' == f_attrs.last.to_s && '' == p_attrs.last.to_s)
              next
            end
            case type
            when '!'
              # change
              mismatches << [
                {
                  line: f_p_style_and_spans[:line_number],
                  corr_line: p_p_style_and_spans[:line_number],
                },
                [
                  error_type,
                  [
                    "Foreign paragraph class #{ f_attrs.last.inspect } ",
                    "is different from primary #{ p_attrs.last.inspect }",
                  ].join,
                ],
              ]
            when '+'
              # insertion
              # Ignore extra id_title3 in foreign
              next  if f_attrs.last.include?('id_title3')
              mismatches << [
                {
                  line: f_p_style_and_spans[:line_number],
                  corr_line: p_p_style_and_spans[:line_number],
                },
                [
                  error_type,
                  [
                    "Foreign has extra paragraph ##{ f_attrs.first } ",
                    "with class #{ f_attrs.last.inspect }",
                  ].join,
                ],
              ]
            when '-'
              # deletion
              mismatches << [
                {
                  line: f_p_style_and_spans[:line_number],
                  corr_line: p_p_style_and_spans[:line_number],
                },
                [
                  error_type,
                  [
                    "Foreign is missing primary paragraph ##{ p_attrs.first } ",
                    "with class #{ p_attrs.last.inspect }",
                  ].join,
                ],
              ]
            when '='
              # Nothing to do
            else
              raise "Invalid type: #{ type.inspect }"
            end
          }
        end

        # @param f_pclasses_and_fspans [Array<Hash>] one entry per foreign para.
        #   See #extract_pclasses_and_fspans for details
        # @param p_pclasses_and_fspans [Array<Hash>] one entry per primary para.
        #   See #extract_pclasses_and_fspans for details
        # @param paragraph_class_diffs [Array<Array>]
        # @return [Array<Array>] the paragraph airs aligned based on diffs.
        def align_foreign_and_primary_paragraphs(f_pclasses_and_fspans, p_pclasses_and_fspans, paragraph_class_diffs)
          aligned_pairs = []
          p_pos = 0
          f_pos = 0
          diff_pos = 0
          iteration_count = 0
          while(
            p_pos < p_pclasses_and_fspans.length ||
            f_pos < f_pclasses_and_fspans.length
          ) do
            # diff = ["=", [1, ["first_par", "normal"]], [1, ["first_par", "normal_pn"]]]
            # Cast Diff::LCS::ContextChange to array!
            diff_type, _diff_f_attrs, _diff_p_attrs = paragraph_class_diffs[diff_pos].to_a
            case diff_type
            when '-'
              # Missing foreign paragraph, use primary only
              aligned_pairs << [nil, p_pclasses_and_fspans[p_pos]]
              p_pos += 1
              diff_pos += 1
            when '+'
              # Extra foreign paragraph, use foreign only
              aligned_pairs << [f_pclasses_and_fspans[f_pos], nil]
              f_pos += 1
              diff_pos += 1
            when '!', '='
              # Paragraph pair, use both
              aligned_pairs << [f_pclasses_and_fspans[f_pos], p_pclasses_and_fspans[p_pos]]
              f_pos += 1
              p_pos += 1
              diff_pos += 1
            else
              raise "Handle this: #{ diff_type.inspect }"
            end

            if (iteration_count += 1) > 10_000
              puts "p_pos: #{ p_pos.inspect }"
              puts "f_pos: #{ f_pos.inspect }"
              puts "diff_pos: #{ diff_pos.inspect }"
              ap p_pclasses_and_fspans
              ap f_pclasses_and_fspans
              raise "Infinite loop"
            end
          end
          aligned_pairs
        end

      end
    end
  end
end
