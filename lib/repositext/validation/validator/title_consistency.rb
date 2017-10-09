class Repositext
  class Validation
    class Validator
      # Validates a content AT file's title.
      class TitleConsistency < Validator

        # Validates that titles from content, ID, and ERP in @file_to_validate
        # are consistent in the following ways:
        #
        # Comparison                                | English    | Foreign
        # ------------------------------------------|------------|------------
        # Title from ID and from content            | Formatted  | Formatted
        # Title from ERP and from content           | Plain text | Plain text
        # Primary title from ID and from ERP        | No         | Plain text
        # Date code from ID and from filename       | Yes        | Yes
        # Date code from ERP and from filename      | Yes        | Yes
        # Language code from ID and from filename   | No         | Yes
        # Language code from ERP and from filename  | No         | Yes
        #
        # The following validator_exceptions are available (can be combined):
        #
        # * 'ignore_end_diff_starting_at_pound_sign_erp': Endings of titles are
        #       different.
        #       Remove everything starting with pound sign from erp. Resulting
        #       ERP title must be contained in main title.
        # * 'ignore_short_word_capitalization': File is expected to capitalize
        #       small words differently between the 3 titles.
        # * 'multi_level_title': The file contains level 1 and level 2 headers
        #       that need to be combined to get the main title. The two titles
        #       will be joined with ", " and will be compared in plain text
        #       format only.
        # * 'remove_pound_sign_and_digits_erp': ERP title has extra pound sign
        #       and digits that will be removed before comparison.
        # * 'remove_pound_sign_erp': ERP title has extra pound sign that will be
        #       removed before comparison.
        # * 'remove_trailing_digits_content': Content title has extra trailing
        #       digits that will be removed before comparison.
        #
        # Notes:
        # * We always ignore differences in line breaks.
        # * We skip the `id` related parts of the validation if the file has no
        #   id parts at all. If it has some ID parts, but not id_title1 or
        #   id_title2 then we raise an error.
        def run
          content_at_file = @file_to_validate
          errors, warnings = [], []
          val_attrs = {
            exceptions: @options['validator_exceptions'],
            has_erp_data: nil,
            has_id_parts: nil,
            is_primary: content_at_file.is_primary?,
            raw: {
              content: {
                header_1_kd: nil,
                header_2_kd: nil,
                header_1_pt: nil,
                header_2_pt: nil,
              },
              erp: {
                date_code: nil,
                language_code: nil,
                primary_title: nil,
                title: nil,
              },
              filename: {
                date_code: nil,
                language_code: nil,
              },
              id: {
                id_title1: nil,
                id_title2: nil,
              },
            },
            prepared: {
              content: {},
              erp: {},
              filename: {},
              id: {},
            },
          }

          outcome = titles_consistent?(content_at_file, val_attrs, @options['erp_data'])
          errors += outcome.errors
          warnings += outcome.warnings

if errors.any?
  ap val_attrs
end
          log_and_report_validation_step(errors, warnings)
        end

        # @param content_at_file [RFile::ContentAt] the file to validate
        # @param val_attrs [Hash] data storage for all validation attributes
        # @param all_erp_data [Hash] ERP data for all files
        # @return [Outcome]
        def titles_consistent?(content_at_file, val_attrs, all_erp_data)
          errors = []
          warnings = []

          # Validate validator_exceptions
          valid_exceptions = %w[
            ignore_end_diff_starting_at_pound_sign_erp
            ignore_short_word_capitalization
            multi_level_title
            remove_pound_sign_and_digits_erp
            remove_pound_sign_erp
            remove_trailing_digits_content
          ]
          if(iv_ex = val_attrs[:exceptions] - valid_exceptions).any?
            errors << Reportable.error(
              [@file_to_validate.filename],
              [
                "Invalid validator_exceptions",
                "#{ iv_ex.inspect } is not one of #{ valid_exceptions.inspect }"
              ]
            )
            return Outcome.new(false, nil, [], errors, warnings)
          end

          # Early exit if we skip the validation
          if val_attrs[:exceptions].include?('skip')
            warnings << Reportable.warning(
              [content_at_file.filename],
              ['Skipped "TitleConsistency" validator']
            )
            return Outcome.new(true, nil, [], errors, warnings)
          end

          extract_raw_attrs!(content_at_file, val_attrs, all_erp_data)
          prepare_validation_attrs!(content_at_file, val_attrs)
          validate_attrs(content_at_file, val_attrs, errors, warnings)

          Outcome.new(errors.empty?, nil, [], errors, warnings)
        end

      protected

        # @param content_at_file [RFile::ContentAt] the file to validate
        # @param val_attrs [Hash] data storage for all validation attributes
        # @param all_erp_data [Hash] ERP data for all files
        # Mutates val_attrs in place.
        def extract_raw_attrs!(content_at_file, val_attrs, all_erp_data)
          extract_raw_attrs_content!(content_at_file, val_attrs)
          extract_raw_attrs_erp!(content_at_file, val_attrs, all_erp_data)
          extract_raw_attrs_filename!(content_at_file, val_attrs)
          extract_raw_attrs_id!(content_at_file, val_attrs)
        end

        def extract_raw_attrs_content!(content_at_file, val_attrs)
          content_at = content_at_file.contents
          if val_attrs[:exceptions].include?('multi_level_title')
            # Get both level 1 and level 2 headers as plain text
            titles_kd = Services::ExtractContentAtMainTitles.call(
              content_at, :content_at, true
            ).result
            titles_pt = Services::ExtractContentAtMainTitles.call(
              content_at, :plain_text, true
            ).result
            val_attrs[:raw][:content] = {
              header_1_kd: titles_kd[0],
              header_2_kd: titles_kd[1],
              header_1_pt: titles_pt[0],
              header_2_pt: titles_pt[1],
            }
          else
            val_attrs[:raw][:content] = {
              header_1_kd: Services::ExtractContentAtMainTitles.call(
                content_at, :content_at
              ).result,
              header_1_pt: Services::ExtractContentAtMainTitles.call(
                content_at, :plain_text
              ).result,
            }
          end
          true
        end

        def extract_raw_attrs_erp!(content_at_file, val_attrs, all_erp_data)
          pii = content_at_file.extract_product_identity_id(false).to_i
          file_erp_data = all_erp_data.detect { |e| e['productidentityid'] == pii }
          if file_erp_data
            val_attrs[:has_erp_data] = true
          else
            val_attrs[:has_erp_data] = false
            return true
          end
          val_attrs[:raw][:erp] = {
            title: file_erp_data['foreigntitle'],
            primary_title: file_erp_data['englishtitle'],
            date_code: file_erp_data['productid'],
            language_code: file_erp_data['languageid'],
          }
          true
        end

        def extract_raw_attrs_filename!(content_at_file, val_attrs)
          val_attrs[:raw][:filename] = {
            date_code: content_at_file.extract_date_code,
            language_code: content_at_file.language_code_3_chars,
          }
          true
        end

        def extract_raw_attrs_id!(content_at_file, val_attrs)
          id_parts = Services::ExtractContentAtIdParts.call(
            content_at_file.contents
          ).result
          if id_parts.any?
            val_attrs[:has_id_parts] = true
            val_attrs[:raw][:id] = {
              id_title1: id_parts['id_title1'],
              id_title2: id_parts['id_title2'],
            }
          else
            val_attrs[:has_id_parts] = false
          end
          true
        end

        def prepare_validation_attrs!(content_at_file, val_attrs)
          prepare_validation_attrs_content!(content_at_file, val_attrs)
          prepare_validation_attrs_erp!(content_at_file, val_attrs)
          prepare_validation_attrs_filename!(content_at_file, val_attrs)
          prepare_validation_attrs_id!(content_at_file, val_attrs)
        end

        def prepare_validation_attrs_content!(content_at_file, val_attrs)
          ra = val_attrs[:raw][:content]
          # For comparison with ERP we convert non-breaking hyphens to regular ones
          erp_title_sanitizer = ->(txt){ txt.gsub('&#x2011;', '-').gsub('‑', '-') }
          r = if val_attrs[:exceptions].include?('multi_level_title')
            # Join both level 1 and level 2 headers as plain text
            t = remove_linebreaks_plain_text(
              [ra[:header_1_pt].to_s.strip, ra[:header_2_pt].to_s.strip].join(", ")
            )
            {
              title_for_erp: erp_title_sanitizer.call(t),
              title_for_id: t,
            }
          else
            # Prepare both pt and kd from header 1
            {
              title_for_erp: remove_linebreaks_plain_text(
                erp_title_sanitizer.call(ra[:header_1_pt].to_s.strip)
              ),
              title_for_id: remove_linebreaks_kramdown(
                ra[:header_1_kd].to_s.strip
              ),
            }
          end
          r = apply_exceptions_content(r, val_attrs[:exceptions])
          val_attrs[:prepared][:content] = r
          true
        end

        def prepare_validation_attrs_erp!(content_at_file, val_attrs)
          ra = val_attrs[:raw][:erp]
          title_sanitizer = ->(raw_title) {
            # Replace straight apostrophes with typographic ones
            raw_title.to_s.strip.gsub("'", '’')
          }
          # NOTE: We upper case all language codes for comparison
          r = {
            title: title_sanitizer.call(ra[:title]),
            primary_title: title_sanitizer.call(ra[:primary_title]),
            date_code: ra[:date_code].to_s.strip.downcase,
            language_code: ra[:language_code].to_s.strip,
          }
          r = apply_exceptions_erp(r, val_attrs[:exceptions])
          val_attrs[:prepared][:erp] = r
        end

        def prepare_validation_attrs_filename!(content_at_file, val_attrs)
          ra = val_attrs[:raw][:filename]
          # NOTE: We upper case all language codes for comparison
          val_attrs[:prepared][:filename] = {
            date_code: ra[:date_code].to_s.strip,
            language_code: ra[:language_code].to_s.strip.upcase,
          }
          # Note: Currently there are no exceptions to be applied to filename attrs
        end

        def prepare_validation_attrs_id!(content_at_file, val_attrs)
          return true  if !val_attrs[:has_id_parts]
          ra = val_attrs[:raw][:id]
          r = {}
          if val_attrs[:is_primary]
            # Get kramdown title from id_title1
            raw_title = ra[:id_title1].first.to_s.strip
            if val_attrs[:exceptions].include?('multi_level_title')
              # Work with plain text titles
              r[:title] = remove_linebreaks_plain_text(
                Kramdown::Document.new(raw_title).to_plain_text.strip
              )
            else
              # Work with kramdown titles
              r[:title] = remove_linebreaks_kramdown(raw_title)
            end
            r[:primary_title] = ''
            # Get datecode from id_title2
            # Remove asterisks to address cases like `64-0304*e*{: .smcaps}`
            # ImplementationTag #date_code_regex
            r[:date_code] = ra[:id_title2].first
                                          .to_s
                                          .downcase
                                          .strip
                                          .gsub('*', '')[/\d{2}-\d{4}[a-z]?/]
          else
            # Extract title, language, and datecode from id_title1
            raw_title = ra[:id_title1].first.to_s.strip
            # We remove language and date code from kramdown title and we extract
            # and remove them from the plain text title.
            # ImplementationTag #date_code_regex
            t_kd = raw_title.sub(/[a-z]{3}\d{2}-\d{4}[a-z]?.*\z/i, '').strip
            t_pt_wldc = Kramdown::Document.new(raw_title).to_plain_text.strip
            t_pt = nil
            # ImplementationTag #date_code_regex
            if(md = t_pt_wldc.match(/([a-z]{3})(\d{2}-\d{4}[a-z]?)/i))
              # NOTE: Don't touch capitalization of language code. We expect them
              # to be upper case.
              r[:language_code] = md[1].to_s.strip
              r[:date_code] = md[2].to_s.strip
              t_pt = t_pt_wldc.sub(md.to_s, '').strip
            end
            if val_attrs[:exceptions].include?('multi_level_title')
              # Use plain text title
              r[:title] = t_pt
            else
              # Use kramdown title
              r[:title] = t_kd
            end
            # Get primary title from id_title2.
            # Remove surrounding parentheses and convert to plain text
            r[:primary_title] = if ra[:id_title2]
              p_t_kd = ra[:id_title2].first
                                     .to_s
                                     .strip
                                     .sub(/\A\(/, '')
                                     .sub(/\)\z/, '')
              Kramdown::Document.new(p_t_kd).to_plain_text.strip
            else
              ''
            end
          end
          r = apply_exceptions_id(r, val_attrs[:exceptions])
          val_attrs[:prepared][:id] = r
        end

        def apply_exceptions_content(attrs, exceptions)
          na = attrs.dup
          if exceptions.include?('ignore_end_diff_starting_at_pound_sign_erp')
            # N/A
          end
          if exceptions.include?('ignore_short_word_capitalization')
            na[:title_for_erp] = apply_exception_ignore_short_word_capitalization(
              na[:title_for_erp]
            )
            na[:title_for_id] = apply_exception_ignore_short_word_capitalization(
              na[:title_for_id]
            )
          end
          if exceptions.include?('multi_level_title')
            # Processing has already been done in prepare_validation_attrs_content
          end
          if exceptions.include?('remove_trailing_digits_content')
            na[:title_for_erp] = apply_exception_remove_trailing_digits(
              na[:title_for_erp]
            )
            na[:title_for_id] = apply_exception_remove_trailing_digits(
              na[:title_for_id]
            )
          end
          na
        end

        def apply_exceptions_erp(attrs, exceptions)
          na = attrs.dup
          if exceptions.include?('ignore_end_diff_starting_at_pound_sign_erp')
            na[:title] = apply_exception_ignore_end_diff_starting_at_pound_sign(
              na[:title]
            )
            na[:primary_title] = apply_exception_ignore_end_diff_starting_at_pound_sign(
              na[:primary_title]
            )
          end
          if exceptions.include?('ignore_short_word_capitalization')
            na[:title] = apply_exception_ignore_short_word_capitalization(
              na[:title]
            )
            na[:primary_title] = apply_exception_ignore_short_word_capitalization(
              na[:primary_title]
            )
          end
          if exceptions.include?('remove_pound_sign_and_digits_erp')
            na[:title] = apply_exception_remove_pound_sign_and_digits(
              na[:title]
            )
            na[:primary_title] = apply_exception_remove_pound_sign_and_digits(
              na[:primary_title]
            )
          end
          if exceptions.include?('remove_pound_sign_erp')
            na[:title] = apply_exception_remove_pound_sign(
              na[:title]
            )
            na[:primary_title] = apply_exception_remove_pound_sign(
              na[:primary_title]
            )
          end
          na
        end

        def apply_exceptions_id(attrs, exceptions)
          na = attrs.dup
          if exceptions.include?('ignore_short_word_capitalization')
            na[:title] = apply_exception_ignore_short_word_capitalization(
              na[:title]
            )
            na[:primary_title] = apply_exception_ignore_short_word_capitalization(
              na[:primary_title]
            )
          end
          if exceptions.include?('multi_level_title')
            # N/A
          end
          na
        end

        def apply_exception_ignore_end_diff_starting_at_pound_sign(title)
          # Remove everything from pound sign to the end
          # test if erp is contained in title from content
          title.sub(/\s#.*\z/, '')
        end

        def apply_exception_ignore_short_word_capitalization(title)
          nt = title.dup
          %w[and in of on the].each { |sw|
            nt.gsub!(/\b#{ sw }\b/i, sw)
          }
          nt
        end

        def apply_exception_remove_pound_sign_and_digits(title)
          # Remove pound signs followed by digits (and preceded by space)
          title.gsub(/\s?#\d+/, '')
        end

        def apply_exception_remove_pound_sign(title)
          # Remove pound signs
          title.gsub('#', '')
        end

        def apply_exception_remove_trailing_digits(title)
          # Remove trailing digits and preceding whitespace both in plain text
          # and kramdown
          title.gsub(/\s?\*\d+\*\{\:[^\}]+\}\z/, '')
               .gsub(/\s?\d+/, '')

        end

        def remove_linebreaks_kramdown(txt)
          txt.gsub("*{: .italic .smcaps} *.*{: .line_break}*", ' ')
        end

        def remove_linebreaks_plain_text(txt)
          txt.gsub(/ *\n+ */, ' ')
        end

        # @param content_at_file [RFile::ContentAt]
        # @param val_attrs [Hash]
        # @param errors [Array]
        # @param warnings [Array]
        # Mutates errors and warnings in place
        def validate_attrs(content_at_file, val_attrs, errors, warnings)
          compare_erp_with_content(content_at_file, val_attrs, errors, warnings)
          compare_erp_with_filename(content_at_file, val_attrs, errors, warnings)
          compare_id_with_content(content_at_file, val_attrs, errors, warnings)
          compare_id_with_erp(content_at_file, val_attrs, errors, warnings)
          compare_id_with_filename(content_at_file, val_attrs, errors, warnings)
        end

        def compare_erp_with_content(content_at_file, val_attrs, errors, warnings)
          pa_c = val_attrs[:prepared][:content]
          pa_erp = val_attrs[:prepared][:erp]

          if '' == pa_c[:title_for_erp]
            errors << Reportable.error(
              [@file_to_validate.filename],
              ["Title from content is missing"]
            )
          end
          if val_attrs[:has_erp_data]
            if '' == pa_erp[:title]
              errors << Reportable.error(
                [@file_to_validate.filename],
                ["Title from ERP is missing"]
              )
            elsif pa_erp[:title] != pa_c[:title_for_erp]
              record_error = true

              if val_attrs[:exceptions].include?('ignore_end_diff_starting_at_pound_sign_erp')
                # Check for plain text containment, not equality
                record_error = false  if pa_c[:title_for_erp][pa_erp[:title]]
              end

              if record_error
                errors << Reportable.error(
                  [@file_to_validate.filename],
                  [
                    "ERP title is different from content title",
                    "ERP title: #{ pa_erp[:title].inspect }, Content title: #{ pa_c[:title_for_erp].inspect }"
                  ]
                )
              end
            end
          else
            warnings << Reportable.warning(
              [@file_to_validate.filename],
              ["No ERP data present"]
            )
          end
        end

        def compare_erp_with_filename(content_at_file, val_attrs, errors, warnings)
          pa_fn = val_attrs[:prepared][:filename]
          pa_erp = val_attrs[:prepared][:erp]

          # Compare ERP datecode with filename (primary and foreign)
          if '' == pa_fn[:date_code]
            errors << Reportable.error(
              [@file_to_validate.filename],
              ["Date code from filename is missing"]
            )
          end
          if val_attrs[:has_erp_data]
            if '' == pa_erp[:date_code]
              errors << Reportable.error(
                [@file_to_validate.filename],
                ["Date code from ERP is missing"]
              )
            elsif pa_fn[:date_code] != pa_erp[:date_code]
              errors << Reportable.error(
                [@file_to_validate.filename],
                [
                  "ERP datecode is different from filename datecode",
                  "ERP datecode: #{ pa_erp[:date_code].inspect }, Filename datecode: #{ pa_fn[:date_code].inspect }"
                ]
              )
            end
          end

          # Compare ERP language code with filename (foreign only)
          if !val_attrs[:is_primary]
            if '' == pa_fn[:language_code]
              errors << Reportable.error(
                [@file_to_validate.filename],
                ["Language code from filename is missing"]
              )
            end
            if val_attrs[:has_erp_data]
              if '' == pa_erp[:language_code]
                errors << Reportable.error(
                  [@file_to_validate.filename],
                  ["Language code from ERP is missing"]
                )
              elsif pa_erp[:language_code] != pa_fn[:language_code]
                errors << Reportable.error(
                  [@file_to_validate.filename],
                  [
                    "ERP language code is different from filename language code",
                    "ERP language_code: #{ pa_erp[:language_code].inspect }, filename language code: #{ pa_fn[:language_code].inspect }"
                  ]
                )
              end
            end
          end
        end

        def compare_id_with_content(content_at_file, val_attrs, errors, warnings)
          pa_c = val_attrs[:prepared][:content]
          pa_id = val_attrs[:prepared][:id]

          # Compare ID title with content
          if val_attrs[:has_id_parts]
            if '' == pa_id[:title]
              errors << Reportable.error(
                [@file_to_validate.filename],
                ["Title from id is missing"]
              )
            elsif pa_id[:title] != pa_c[:title_for_id]
              errors << Reportable.error(
                [@file_to_validate.filename],
                [
                  "ID title is different from content title",
                  "ID title: #{ pa_id[:title].inspect }, Content title: #{ pa_c[:title_for_id].inspect }"
                ]
              )
            end
          end
        end

        def compare_id_with_erp(content_at_file, val_attrs, errors, warnings)
          pa_erp = val_attrs[:prepared][:erp]
          pa_id = val_attrs[:prepared][:id]

          # Compare primary ID title with ERP for foreign files only
          if !val_attrs[:is_primary] && val_attrs[:has_id_parts]
            if '' == pa_id[:primary_title]
              errors << Reportable.error(
                [@file_to_validate.filename],
                ["Primary title from ID is missing"]
              )
            end
            if val_attrs[:has_erp_data]
              if '' == pa_erp[:primary_title]
                errors << Reportable.error(
                  [@file_to_validate.filename],
                  ["Primary title from ERP is missing"]
                )
              elsif pa_id[:primary_title] != pa_erp[:primary_title]
                errors << Reportable.error(
                  [@file_to_validate.filename],
                  [
                    "ERP primary title is different from ID primary title",
                    "ERP primary title: #{ pa_erp[:primary_title].inspect }, ID primary title: #{ pa_id[:primary_title].inspect }"
                  ]
                )
              end
            end
          end

        end

        def compare_id_with_filename(content_at_file, val_attrs, errors, warnings)
          pa_fn = val_attrs[:prepared][:filename]
          pa_id = val_attrs[:prepared][:id]

          # Compare ID datecode with filename (primary and foreign)
          if val_attrs[:has_id_parts]
            if '' == pa_id[:date_code]
              errors << Reportable.error(
                [@file_to_validate.filename],
                ["Date code from ID is missing"]
              )
            elsif pa_id[:date_code] != pa_fn[:date_code]
              errors << Reportable.error(
                [@file_to_validate.filename],
                [
                  "ID datecode is different from filename datecode",
                  "ID datecode: #{ pa_id[:date_code].inspect }, Filename datecode: #{ pa_fn[:date_code].inspect }"
                ]
              )
            end
          end

          # Compare ID language code with filename (foreign only)
          if !val_attrs[:is_primary] && val_attrs[:has_id_parts]
            if '' == pa_id[:language_code]
              errors << Reportable.error(
                [@file_to_validate.filename],
                ["Language code from ID is missing"]
              )
            elsif pa_id[:language_code] != pa_fn[:language_code]
              errors << Reportable.error(
                [@file_to_validate.filename],
                [
                  "ID language code is different from filename language code",
                  "ID language_code: #{ pa_id[:language_code].inspect }, filename language code: #{ pa_fn[:language_code].inspect }"
                ]
              )
            end
          end
        end

      end
    end
  end
end
