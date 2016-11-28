class Repositext
  class Validation
    class Validator
      # Validates a kramdown string's valid syntax.
      class KramdownSyntax < Validator

        # Returns true if source is valid kramdown
        # @param [String] source the kramdown source string
        # @param [Hash, optional] options
        #
        # * parse document using repositext-kramdown
        # * walk the element tree
        #     * check each element against kramdown feature whitelist
        #     * concatenate inner texts into Array of Hashes with strings and corresponding location
        #     * detect any potential ambiguities
        #     * check each IAL against class names whitelist
        # * check inner text string for unprocessed kramdown
        def valid_kramdown_syntax?(source, options = {})
          inner_texts = []
          errors = []
          warnings = []
          classes_histogram = Hash.new(0)

          validate_character_inventory(source, errors, warnings)
          validate_source(source, errors, warnings)
          validate_escaped_character_syntax(source, errors, warnings)

          validate_parse_tree(source, inner_texts, classes_histogram, errors, warnings)
          validate_inner_texts(inner_texts, errors, warnings)

          Outcome.new(errors.empty?, nil, [], errors, warnings)
        end

        # @param [String] source the kramdown source string
        # @param [Array] errors collector for errors
        # @param [Array] warnings collector for warnings
        def validate_source(source, errors, warnings)
          # Detect disconnected IAL
          str_sc = Kramdown::Utils::StringScanner.new(source)
          while !str_sc.eos? do
            if (match = str_sc.scan_until(/\n\s*?\n(\{:[^\}]+\})\s*?\n\s*?\n/))
              errors << Reportable.error(
                [
                  @file_to_validate.path,
                  sprintf("line %5s", str_sc.current_line_number)
                ],
                ['Disconnected IAL', match[-40..-1].inspect]
              )
            else
              break
            end
          end
          # Detect gap_marks (%) and subtitle_marks (@) inside of words,
          # asterisks, quotes (straight or typographic), parentheses, or brackets.
          # NOTE: We allow subtitle_marks to immediately follow words if the
          # subtitle mark is followed by `…?…`.
          str_sc.reset
          while !str_sc.eos? do
            if (match = str_sc.scan_until(/(?<=[[:alpha:]\*\"\“\”\'\‘\’\(\[])(%|@(?!…?…))/))
              next  if "…*@" == match[-3..-1] # allow subtitle marks after ellipsis and asterisk
              msg = case match[-1]
              when '%'
                next  if @options['skip_invalid_gap_mark_validation']
                ':gap_mark (%) at invalid position'
              when '@'
                ':subtitle_mark (@) at invalid position'
              else
                raise "Unhandled match: #{ match.inspect }"
              end
              errors << Reportable.error(
                [
                  @file_to_validate.path,
                  sprintf("line %5s", str_sc.current_line_number)
                ],
                [msg, match[-40..-1].inspect]
              )
            else
              break
            end
          end
          # Detect paragraphs that are not followed by two newlines.
          str_sc.reset
          while !str_sc.eos? do
            if (match = str_sc.scan_until(/
              \n\{:[^}]*\} # block IAL
              (?=( # followed by one of
                \n[^\n] # single newline
                | # OR
                \n{3,} # 3 or more newlines
              ))
            /x))
              errors << Reportable.error(
                [
                  @file_to_validate.path,
                  sprintf("line %5s", str_sc.current_line_number)
                ],
                ['Paragraph not followed by exactly 2 newlines']
              )
            else
              break
            end
          end
          # Detect unexpected line breaks
          str_sc.reset
          while !str_sc.eos? do
            if (match = str_sc.scan_until(/[^\n]\n(?!(\n|\{:|\z))/))
              errors << Reportable.error(
                [
                  @file_to_validate.path,
                  sprintf("line %5s", str_sc.current_line_number)
                ],
                ['Unexpected line break']
              )
            else
              break
            end
          end
          # Detect multiple adjacent spaces
          str_sc.reset
          while !str_sc.eos? do
            if (match = str_sc.scan_until(/ {2,}/))
              errors << Reportable.error(
                [
                  @file_to_validate.path,
                  sprintf("line %5s", str_sc.current_line_number)
                ],
                ['More than one adjacent space character']
              )
            else
              break
            end
          end
          # # TODO: Detect adjacent periods (instead of elipses)
          # str_sc.reset
          # while !str_sc.eos? do
          #   if (match = str_sc.scan_until(/\.{2,}/))
          #     errors << Reportable.error(
          #       [
          #         @file_to_validate.path,
          #         sprintf("line %5s", str_sc.current_line_number)
          #       ],
          #       ['Adjacent periods. Should this be an elipsis instead?']
          #     )
          #   else
          #     break
          #   end
          # end
        end

        # @param [String] source the kramdown source string
        # @param [Array<Hash>] inner_texts collector for inner texts
        # @param [Hash] classes_histogram collector for histogram of used classes
        # @param [Array] errors collector for errors
        # @param [Array] warnings collector for warnings
        def validate_parse_tree(source, inner_texts, classes_histogram, errors, warnings)
          kd_root = @options['kramdown_validation_parser_class'].parse(source).first
          validate_element(kd_root, inner_texts, classes_histogram, errors, warnings)
          if 'debug' == @logger.level
            # capture classes histogram
            classes_histogram = classes_histogram.sort_by { |k,v|
              k
            }.map { |(classes, count)|
              sprintf("%-15s %5d", classes.join(', '), count)
            }
            reporter.add_stat(
              Reportable.stat([@file_to_validate.path], ['Classes Histogram', classes_histogram])
            )
          end
        end

        # @param [Kramdown::Element] el
        # @param [Array<Hash>] inner_texts collector for inner texts
        # @param [Hash] classes_histogram collector for histogram of used classes
        # @param [Array] errors collector for errors
        # @param [Array] warnings collector for warnings
        def validate_element(el, inner_texts, classes_histogram, errors, warnings)
          validation_hook_on_element(el, errors, warnings)
          # check if element's type is whitelisted
          if !whitelisted_kramdown_features.include?(el.type)
            errors << Reportable.error(
              [
                @file_to_validate.path,
                (lo = el.options[:location]) && sprintf("line %5s", lo)
              ].compact,
              [
                'Invalid kramdown feature',
                ":#{ el.type }"
              ]
            )
          end
          if (
            ial = el.options[:ial]) &&
            (klasses = ial['class']) &&
            (klasses = klasses.split(' ')
          )
            # check if element has classes and if so whether all classes are
            # whitelisted.
            if klasses.any? { |k|
              !whitelisted_class_names.map{ |e| e[:name] }.include?(k)
            }
              errors << Reportable.error(
                [
                  @file_to_validate.path,
                  (lo = el.options[:location]) && sprintf("line %5s", lo)
                ].compact,
                [
                  'Invalid class name',
                  "'#{ klasses }'",
                  "on element #{ el.type}"
                ]
              )
            end
            # Build classes inventory
            if 'debug' == @logger.level
              classes_histogram[klasses.sort] += 1
            end
          end
          # collect inner_texts of :text elements
          if :text == el.type && (t = el.value) && ![" ", "\n", nil].include?(t)
            inner_texts << { :text => t, :location => el.options[:location] }
          end
          # then iterate over children
          el.children.each { |child|
            validate_element(child, inner_texts, classes_histogram, errors, warnings)
          }
        end

        # Use this callback to implement custom validations for subclasses.
        # Called once for each element when walking the tree.
        # @param [Kramdown::Element] el
        # @param [Array] errors collector for errors
        # @param [Array] warnings collector for warnings
        def validation_hook_on_element(el, errors, warnings)
          # NOTE: Implement in sub-classes
        end

        # Validates the inner_texts we collected during validate_parse_tree
        # to check if any unprocessed kramdown remains, indicating kramdown
        # syntax errors. Currently we check for '*' and '_'.
        # @param [Array<Hash>] inner_texts where we check for kramdown leftovers
        # @param [Array] errors collector for errors
        # @param [Array] warnings collector for warnings
        def validate_inner_texts(inner_texts, errors, warnings)
          inner_texts.each do |it|
            match_data = it[:text].to_enum(
              :scan,
              /
                .{0,10} # capture up to 10 preceding characters on same line
                [\*\_]  # detect any asterisks or underscores
                .{0,10} # capture up to 10 following characters on same line
              /x
            ).map { Regexp.last_match }
            match_data.each do |e|
              errors << Reportable.error(
                [
                  @file_to_validate.path,
                  (lo = it[:location]) && sprintf("line %5s", lo)
                ].compact,
                ['Leftover kramdown character', e[0]]
              )
            end
          end
        end

        # @param [String] source the kramdown source string
        # @param [Array] errors collector for errors
        # @param [Array] warnings collector for warnings
        def validate_character_inventory(source, errors, warnings)
          # Detect invalid characters
          str_sc = Kramdown::Utils::StringScanner.new(source)
          soft_hyphen_context_window = 10 # how much context to show around soft hyphens
          while !str_sc.eos? do
            if (match = str_sc.scan_until(
              Regexp.union(self.class.invalid_character_detectors)
            ))
              context = if "\u00AD" == match[-1]
                # Print context around soft hyphens, replace soft with hard hyphen
                " inside '#{ match[-soft_hyphen_context_window..-2] }-#{ str_sc.rest[0..soft_hyphen_context_window] }'"
              else
                ''
              end
              errors << Reportable.error(
                [
                  @file_to_validate.path,
                  sprintf("line %5s", str_sc.current_line_number)
                ],
                ['Invalid character', sprintf('U+%04X', match[-1].codepoints.first) + context]
              )
            else
              break
            end
          end
          # Build character inventory
          if 'debug' == @logger.level
            chars = Hash.new(0)
            ignored_chars = [0x30..0x39, 0x41..0x5A, 0x61..0x7A]
            source.codepoints.each { |cp|
              chars[cp] += 1  unless ignored_chars.any? { |r| r.include?(cp) }
            }
            chars = chars.sort_by { |k,v|
              k
            }.map { |(code,count)|
              sprintf("U+%04x  #{ code.chr('UTF-8') }  %5d", code, count)
            }
            reporter.add_stat(
              Reportable.stat([@file_to_validate.path], ['Character Histogram', chars])
            )
          end
        end

        def whitelisted_kramdown_features
          self.class.whitelisted_kramdown_features
        end

        def whitelisted_class_names
          self.class.whitelisted_class_names
        end

        # TODO: add validation that doesn't allow more than one class on any paragraph
        # e.g., "{: .normal_pn .q}" is not valid. This applies ot both PT and AT.

        # @param [String] source the kramdown source string
        # @param [Array] errors collector for errors
        # @param [Array] warnings collector for warnings
        def validate_escaped_character_syntax(source, errors, warnings)
          # Unlike kramdown, in repositext the following characters are not
          # escaped: `:`, `[`, `]`, `'`
          str_sc = Kramdown::Utils::StringScanner.new(source)
          while !str_sc.eos? do
            if (match = str_sc.scan_until(/\\[\:\[\]\`]/))
              errors << Reportable.error(
                [
                  @file_to_validate.path,
                  sprintf("line %5s", str_sc.current_line_number)
                ],
                ['Character that should not be escaped is escaped:', match[-10..-1].inspect]
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
