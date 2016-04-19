class Repositext
  class Validation
    class Validator

      # Validates consistency of spot corrections:
      #
      # * sanitizes corrections text whitespace
      #
      # Validates that:
      #
      # * Correction numbers are consecutive.
      # * `reads` and `submitted` fragments are not identical.
      # * `reads` fragments are unambiguous in given file and paragraph.
      # * `reads` is consistent with content AT (ignoring subtitle and gap_marks).
      class SpotSheet < Validator

        class InvalidCorrectionsFile < StandardError; end
        class InvalidCorrection < StandardError; end

        # Runs all validations for self
        def run
          outcome = spot_sheet_valid?(@file_to_validate)
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

      protected

        # @param submitted_corrections_file_name [String] absolute path to the corrections file
        # @return [Outcome]
        def spot_sheet_valid?(submitted_corrections_file_name)
          repository = @options['repository']
          language = repository.language
          submitted_corrections_file = Repositext::RFile::Text.new(
            File.read(submitted_corrections_file_name),
            language,
            submitted_corrections_file_name,
            repository
          )

          sanitized_corrections_txt = sanitize_corrections_txt(
            submitted_corrections_file.contents
          )
          corrections = Process::Extract::SubmittedSpotCorrections.extract(
            sanitized_corrections_txt
          )
          corresponding_content_at_file = submitted_corrections_file.corresponding_content_at_file

          if corresponding_content_at_file.nil?
            raise "\nCould not find corresponding content AT file: #{ submitted_corrections_file.corresponding_content_at_filename.inspect }"
          end

          content_at = corresponding_content_at_file.contents

          errors = []
          warnings = []

          validate_corrections_file(
            sanitized_corrections_txt, errors, warnings
          )
          validate_corrections(
            corrections, errors, warnings
          )
          if 'validate' == @options['validate_or_merge']
            # Only in 'validate' mode do we compare corrections and content_at.
            # In 'merge' mode we leave it up to the merge command to detect
            # no match or multiple matches found and open the file in editor
            # for manual review.
            validate_corrections_and_content_at(
              corrections, content_at, errors, warnings
            )
          end

          Outcome.new(errors.empty?, nil, [], errors, warnings)
        end

        # Validates the corrections file in its entirety
        # @param corrections_file_contents [String]
        # @param [Array] errors collector for errors
        # @param [Array] warnings collector for warnings
        def validate_corrections_file(corrections_file_contents, errors, warnings)
          # Validate that no invalid characters are in correction file
          # NOTE: straight double quotes are allowed inside kramdown IALs, so we
          # convert them to a placeholder string ('<sdq>') for validation purposes.
          txt = corrections_file_contents.gsub(/(?<=\{)[^\{\}]*(?=\})/) { |inside_ial|
            inside_ial.gsub(/"/, '<sdq>')
          }

          invalid_chars = []
          [
            [/–/, 'EN DASH'],
            [/"/, 'Straight double quote'],
            [/'/, 'Straight single quote'],
            [/\r/, 'Carriage return'],
          ].each do |(regex, description)|
            s = StringScanner.new(txt)
            while !s.eos? do
              inv_char = s.scan_until(/.{,5}#{ regex }/) # match up to 5 chars before invalid char for reporting context
              if inv_char
                previous_text = txt[0..(s.pos - 1)]
                line_num = previous_text.count("\n") + 1
                context = s.matched[(-[10, s.matched.length].min)..-1] + s.rest[0,10]
                invalid_chars << " - #{ description } on line #{ line_num }: #{ context }"
              else
                s.terminate
              end
            end
          end
          if invalid_chars.any?
            loc = [@file_to_validate]
            desc = ['Contains invalid characters:'] + invalid_chars
            case @options['validate_or_merge']
            when 'merge'
              # This is part of `merge` command, raise an exception if we find error
              raise(InvalidCorrectionsFile.new((loc + desc).join("\n")))
            when 'validate'
              errors << Reportable.error(loc, desc)
            else
              raise "Handle this: #{ @options['validate_or_merge'].inspect }"
            end
          end
        end

        # Validates just the corrections for internal consistency.
        # @param corrections [Array<Hash>]
        # @param [Array] errors collector for errors
        # @param [Array] warnings collector for warnings
        def validate_corrections(corrections, errors, warnings)
          # Validate that each correction has the required attrs
          required_attrs_groups = [
            case @options['validate_or_merge']
            when 'merge'
              [:becomes, :no_change]
            when 'validate'
              [:submitted]
            else
              raise "Handle this: #{ @options['validate_or_merge'].inspect }"
            end,
            [:reads],
            [:correction_number],
            [:first_line],
            [:paragraph_number],
          ].compact
          corrections.each { |corr|
            if(mag =required_attrs_groups.detect { |attrs_group|
              # Are there any groups that have none of their attrs present in correction?
              attrs_group.none? { |attr| corr[attr] }
            })
              loc = [@file_to_validate, "Correction ##{ corr[:correction_number] }"]
              desc = ['Missing attributes', "One of `#{ mag.to_s }` is missing:", corr.inspect]
              case @options['validate_or_merge']
              when 'merge'
                # This is part of `merge` command, raise an exception if we find error
                raise(InvalidCorrection.new((loc + desc).join("\n")))
              when 'validate'
                errors << Reportable.error(loc, desc)
              else
                raise "Handle this: #{ @options['validate_or_merge'].inspect }"
              end
            end
          }

          # Validate that before and after are not identical
          corrections.each { |corr|
            if !corr[:no_change] && corr[:reads] == (corr[:becomes] || corr[:submitted])
              loc = [@file_to_validate, "Correction ##{ corr[:correction_number] }"]
              desc = [
                'Identical `Reads` and (`Becomes` or `Submitted`):',
                "`Reads`: `#{ corr[:reads].to_s }`, (`Becomes` or `Submitted`): `#{ (corr[:becomes] || corr[:submitted]).to_s }`",
              ]
              case @options['validate_or_merge']
              when 'merge'
                # This is part of `merge` command, raise an exception if we find error
                raise(InvalidCorrection.new((loc + desc).join("\n")))
              when 'validate'
                errors << Reportable.error(loc, desc)
              else
                raise "Handle this: #{ @options['validate_or_merge'].inspect }"
              end
            end
          }

          # Validate that we get consecutive correction_numbers
          # Valid scenarios:
          # '1', '2', '3'
          # '1', '2', '2a', '2b', '3'
          correction_numbers = corrections.map { |e| e[:correction_number] }
          correction_numbers.each_cons(2) { |x,y|
            valid = case [x,y].join('_')
            when /^(\d+_\d+)$/
              # Both are digits only: increment x by one
              x.to_i + 1 == y.to_i
            when /^(\d+_\d+[a-z])$/
              # From digits only to digits with letter: same digits, letter 'a'
              x.to_i == y.to_i && y =~ /a$/
            when /^(\d+[a-z]_\d+[a-z])$/
              # Both are digits with letter: same digits, next letter
              x.succ == y
            when /^(\d+[a-z]_\d+)$/
              # From digits with letter to digits only: increment digits, ignore letter
              x.to_i + 1 == y.to_i
            else
              raise "Handle this: #{ [x,y].inspect }"
            end
            if !valid
              loc = [@file_to_validate, "Correction ##{ y }"]
              desc = [
                'Non consecutive correction numbers:',
                "#{ x } was followed by #{ y }",
              ]
              case @options['validate_or_merge']
              when 'merge'
                # This is part of `merge` command, raise an exception if we find error
                raise(InvalidCorrection.new((loc + desc).join("\n")))
              when 'validate'
                errors << Reportable.error(loc, desc)
              else
                raise "Handle this: #{ @options['validate_or_merge'].inspect }"
              end
            end
          }
        end

        # Validates corrections as they relate to content at
        # @param corrections [Array<Hash>]
        # @param content_at [String]
        # @param [Array] errors collector for errors
        # @param [Array] warnings collector for warnings
        def validate_corrections_and_content_at(corrections, content_at, errors, warnings)
          corrections.each do |corr|
            content_at_relevant_paragraphs = Process::Extract::SpotCorrectionRelevantParagraphs.extract(
              corr,
              content_at
            )
            # Remove subtitle_marks and gap_marks from both
            corr_reads_txt = corr[:reads].gsub(/[@%]/, '')
            content_at_rel_para_txt = content_at_relevant_paragraphs[:relevant_paragraphs].gsub(/[@%]/, '')

            # Number of `Reads` occurrences
            num_reads_occurrences = content_at_rel_para_txt.scan(
              corr_reads_txt
            ).length
            # Validate that `reads` fragments are unambiguous in given file and paragraph.
            case num_reads_occurrences
            when 1
              # Found unambiguously, no errors to report.
              # This validates that `Reads` is specified unambiguously and matches
              # content at.
            when 0
              # Found none, report error
              loc = [@file_to_validate, "Correction ##{ corr[:correction_number] }"]
              desc = [
                'Corresponding content AT not found:',
                "`Reads`: #{ corr_reads_txt }",
              ]
              errors << Reportable.error(loc, desc)
            else
              # Found more than one, report error
              loc = [@file_to_validate, "Correction ##{ corr[:correction_number] }"]
              desc = [
                'Multiple instances of `Reads` found:',
                "Found #{ num_reads_occurrences } instances of `#{ corr_reads_txt }`",
              ]
              errors << Reportable.error(loc, desc)
            end

          end
        end

        def sanitize_corrections_txt(raw_corrections_txt)
          r = raw_corrections_txt.dup
          # Replace all \r with \n
          r.gsub!("\r", "\n")
          # Convert all tabs to spaces
          r.gsub!(/\t/, ' ')
          # Convert multiple consecutive spaces to single space
          r.gsub!(/ +/, ' ')
          # Remove all leading whitespace per line
          r.gsub!(/^ +/, '')
          r
        end

      end
    end
  end
end
