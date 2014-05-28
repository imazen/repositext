class Repositext
  class Validation
    class Validator
      class KramdownSyntaxAt < KramdownSyntax

        def self.whitelisted_kramdown_features
          KramdownSyntaxPt.whitelisted_kramdown_features + \
          [
            :gap_mark,
            :record_mark,
            :subtitle_mark,
          ]
        end

        def self.whitelisted_class_names
          KramdownSyntaxPt.whitelisted_class_names
        end

        # Returns an array of regexes that will detect invalid characters.
        def self.invalid_character_detectors
          # '%' and '@' are allowed in AT files, so we don't add them to list
          # of invalid characters
          Repositext::Validation::Config::INVALID_CHARACTER_REGEXES
        end

        def run
          document_to_validate = ::File.read(@file_to_validate)
          errors, warnings = [], []

          catch (:abandon) do
            outcome = valid_kramdown_syntax?(document_to_validate)
            if outcome.fail?
              errors += outcome.errors
              warnings += outcome.warnings
              #throw :abandon
            end
            outcome = valid_syntax_at?(document_to_validate)
            if outcome.fail?
              errors += outcome.errors
              warnings += outcome.warnings
              #throw :abandon
            end
          end

          log_and_report_validation_step(errors, warnings)
        end

        # AT specific syntax validation
        # @param[String] source the at document to validate
        # @return[Outcome]
        def valid_syntax_at?(source)
          errors = []
          warnings = []

          validate_record_mark_syntax(source, errors, warnings)
          validate_escaped_character_syntax(source, errors, warnings)

          Outcome.new(errors.empty?, nil, [], errors, warnings)
        end

        # Implement AT specific validation callback when walking the tree.
        # @param[Kramdown::Element] el
        # @param[Array] errors collector for errors
        # @param[Array] warnings collector for warnings
        def validation_hook_on_element(el, errors, warnings)
          if(:root == el.type)
            if @options['run_options'].include?('kramdown_syntax_at-all_elements_are_inside_record_mark')
              # Validates that every element is contained inside a record_mark.
              # In other words, the root element may only contain elements of type :record_mark
              el.children.each do |child|
                if(:record_mark != child.type)
                  warnings << ::Repositext::Validation::Reportable.warning(
                    [
                      @file_to_validate,
                      (lo = el.options[:location]) && sprintf("line %5s", lo)
                    ].compact,
                    [
                      'Element outside of :record_mark',
                      "Element is not contained in a :record_mark",
                      "Type: #{ el.type }, Value: #{ el.value }"
                    ]
                  )
                end
              end
            end
          elsif(:record_mark == el.type)
            # Validates that kpns are monotonically increasing and consecutive
            if el.attr['kpn']
              l_kpn = el.attr['kpn'].to_i
              if @kpn_tracker.nil?
                # First kpn, initialize tracker
                @kpn_tracker = l_kpn
              else
                # Subsequent KPN
                if(l_kpn != @kpn_tracker + 1)
                  warnings << ::Repositext::Validation::Reportable.warning(
                    [
                      @file_to_validate,
                      (lo = el.options[:location]) && sprintf("line %5s", lo)
                    ].compact,
                    [
                      'Invalid KPN',
                      "KPN has unexpected value: #{ l_kpn.inspect }",
                      "Previous KPN: #{ @kpn_tracker.inspect }, Current KPN: #{ l_kpn.inspect }"
                    ]
                  )
                end
                @kpn_tracker = l_kpn
              end
            end
          elsif(
            :text == el.type &&
            @options['run_options'].include?('kramdown_syntax_at-no_underscore_or_caret')
          )
            # No underscores or carets allowed in idml imported AT (inner texts)
            # We have to check this here where we have access to the inner text,
            # rather than in #validate_character_inventory, since e.g.,
            # class attrs may contain legitimate underscores.
            if(el.value =~ /[\_\^]/)
              warnings << ::Repositext::Validation::Reportable.warning(
                [
                  @file_to_validate,
                  (lo = el.options[:location]) && sprintf("line %5s", lo)
                ].compact,
                [
                  'Invalid underscore or caret',
                  "In text: #{ el.value.inspect }"
                ]
              )
            end
          end
        end

      protected

        # @param[String] source the kramdown source string
        # @param[Array] errors collector for errors
        # @param[Array] warnings collector for warnings
        def validate_record_mark_syntax(source, errors, warnings)
          # Record_marks_have to be preceded by a blank line
          str_sc = Kramdown::Utils::StringScanner.new(source)
          while !str_sc.eos? do
            # NOTE: This regex won't match the first record_mark at beginning
            # of file (which isn't preceded by anything). This is ok since we
            # don't expect it to be preceded by a blank line.
            if (match = str_sc.scan_until(/[^\n]{2}\^\^\^/))
              errors << Reportable.error(
                [
                  @file_to_validate,
                  sprintf("line %5s", str_sc.current_line_number)
                ],
                [':record_mark not preceded by blank line', match[-40..-1].inspect]
              )
            else
              break
            end
          end

          # Make sure we have no :record_marks with no text between them
          str_sc = Kramdown::Utils::StringScanner.new(source)
          while !str_sc.eos? do
            if (match = str_sc.scan_until(/\^\^\^[^\n\^]+\s*\^\^\^/))
              position_of_previous_record_mark = match.rindex('^^^', -4) || 0
              relevant_match_fragment = match[position_of_previous_record_mark..-1].inspect
                                            .gsub(/^\"/, '') # Remove leading double quotes (from inspect)
                                            .gsub(/\"$/, '') # Remove trailing double quotes (from inspect)
              errors << Reportable.error(
                [
                  @file_to_validate,
                  sprintf("line %5s", str_sc.current_line_number)
                ],
                ['Consecutive :record_marks with no text inbetween', relevant_match_fragment]
              )
            else
              break
            end
          end

        end

      end
    end
  end
end