class Repositext
  class Validation
    class Validator
      # Validates a content AT file's title.
      class TitleConsistency < Validator

        # Validates that title in @file_to_validate is consistent in the following
        # ways:
        # * id_title1 is consistent with main title (including formatting).
        # * Title stored in ERP is consistent with main title (plain text only).
        # * Foreign only: id_title2 is consistent with corresponding primary
        #   main title (plain text only).
        # * language and date code from id are consistent with file name.
        #
        # The following validator_exceptions are available (can be combined):
        # * 'ignore_end_diff_starting_at_pound_sign_erp': Endings of titles are
        #       different.
        #       Remove everything starting with pound sign from erp. Resulting
        #       ERP title must be contained in main title.
        # * 'ignore_pound_sign_and_number_diff_erp': File is expected to have a
        #       pound sign and number in one title but not in other. Pass
        #       validation if diff =~ /#\d+/.
        # * 'ignore_pound_sign_diff_erp': File is expected to have a pound sign
        #       in one title but not in other. Pass validation if diff == '#'.
        # * 'ignore_short_word_capitalization_erp': File is expected to capitalize
        #       small words differently between ERP and content.
        # * 'multi_level_title': The file contains level 1 and level 2 headers
        #       that need to be combined to get the main title. The two titles
        #       will be joined with ", " and will be compared in plain text
        #       format only.
        # * 'skip': This validation will be skipped and a warning will be
        #       printed to the console.
        #
        # Notes:
        # * We always ignore differences in line breaks.
        # * We skip the `id` related parts of the validation if the file has no
        #   id parts at all. If it some id parts, but not id_title1 or id_title2,
        #   we raise an error.
        #
        # Behavior                                                     | English          | Foreign
        # -------------------------------------------------------------|------------------|-------------------
        # Set main title to combination of level 1 and level 2 headers | multi_level_title| multi_level_title
        # Compare id_title1 with main title                            | Formatted        | Formatted
        # Compare ERP title with main title                            | Plain text       | Plain text
        # Compare id_title2 with corresponding English main title      | No               | Plain text
        # Remove id_title1 trailing date code                          | No               | Yes
        # Validate id_title1 trailing date + lang code with filename   | No               | Yes
        # Validate id_title2  date code with filename                  | Yes              | No
        #
        def run
          content_at_file = @file_to_validate
          errors, warnings = [], []
          val_attrs = {
            validator_exceptions: @options['validator_exceptions'],
            is_primary: content_at_file.is_primary?,
          }

          outcome = title_consistent?(content_at_file, val_attrs, @options['erp_data'])
          errors += outcome.errors
          warnings += outcome.warnings

if errors.any? || warnings.any?
  ap val_attrs
end
          log_and_report_validation_step(errors, warnings)
        end

        # AT specific syntax validation
        # @param content_at_file [RFile::ContentAt] the file to validate
        # @param val_attrs [Hash] data storage for all validation attributes
        # @param all_erp_data [Hash] ERP data for all files
        # @return [Outcome]
        def title_consistent?(content_at_file, val_attrs, all_erp_data)
          errors = []
          warnings = []

          # Validate validator_exceptions
          valid_exceptions = %w[
            ignore_end_diff_starting_at_pound_sign_erp
            ignore_pound_sign_and_number_diff_erp
            ignore_pound_sign_diff_erp
            ignore_short_word_capitalization_erp
            multi_level_title
            skip
          ]
          if(iv_ex = val_attrs[:validator_exceptions] - valid_exceptions).any?
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
          if val_attrs[:validator_exceptions].include?('skip')
            warnings << Reportable.warning(
              [content_at_file.filename],
              ['Skipped "TitleConsistency" validator']
            )
            return Outcome.new(true, nil, [], errors, warnings)
          end

          prepare_common_attrs!(content_at_file, val_attrs, all_erp_data)

          if val_attrs[:is_primary]
            prepare_primary_attrs!(content_at_file, val_attrs)
            validate_attrs_common(content_at_file, val_attrs, errors, warnings)
          else
            prepare_foreign_attrs!(content_at_file, val_attrs)
            validate_attrs_common(content_at_file, val_attrs, errors, warnings)
            validate_attrs_foreign(content_at_file, val_attrs, errors, warnings)
          end

          Outcome.new(errors.empty?, nil, [], errors, warnings)
        end

      protected

        # Adds common values to val_attrs.
        # @param content_at_file [RFile::ContentAt] the file to validate
        # @param val_attrs [Hash] data storage for all validation attributes
        # @param all_erp_data [Hash] ERP data for all files
        # Mutates val_attrs in place.
        def prepare_common_attrs!(content_at_file, val_attrs, all_erp_data)
          compute_title_from_content!(content_at_file, val_attrs)
          id_parts = Services::ExtractContentAtIdParts.call(
            content_at_file.contents
          ).result
          if id_parts.any?
            val_attrs[:id_parts] = {
              'id_title1' => id_parts['id_title1'],
              'id_title2' => id_parts['id_title2'],
            }
          else
            val_attrs[:id_parts] = {}
          end

          compute_attrs_from_filename!(content_at_file, val_attrs)
          compute_attrs_from_erp_data!(content_at_file, val_attrs, all_erp_data)

          true
        end

        def prepare_foreign_attrs!(content_at_file, val_attrs)

          if(idp = val_attrs[:id_parts]).any?
            # Extract title, language, and datecode from id_title1
            raw_title = remove_linebreaks_kramdown(idp['id_title1'].first.to_s.strip)
            # We remove language and date code from kramdown title and we extract
            # and remove them from the plain text title.
            # ImplementationTag #date_code_regex
            t_k_id = raw_title.sub(/[a-z]{3}\d{2}-\d{4}[a-z]?.*\z/i, '').strip
            t_pt_id_wldc = Kramdown::Document.new(raw_title).to_plain_text.strip
            # ImplementationTag #date_code_regex
            if(md = t_pt_id_wldc.match(/([a-z]{3})(\d{2}-\d{4}[a-z]?)/i))
              val_attrs[:language_code_from_id] = md[1].to_s.downcase.strip
              val_attrs[:date_code_from_id] = md[2].to_s.strip
              t_pt_id = t_pt_id_wldc.sub(md.to_s, '').strip
            end
            if val_attrs[:validator_exceptions].include?('multi_level_title')
              # Work with plain text titles
              # Remove language and date code from title
              val_attrs[:title_plain_text_from_id] = t_pt_id
            else
              # Work with kramdown titles
              # Remove language and date code from title
              val_attrs[:title_kramdown_from_id] = t_k_id
            end
            # Get primary title from id_title2. Remove surrounding parentheses
            # and convert to plain text
            if idp['id_title2']
              p_t_k_id = idp['id_title2'].first
                                          .to_s
                                          .strip
                                          .sub(/\A\(/, '')
                                          .sub(/\)\z/, '')
              val_attrs[:primary_title_plain_text_from_id] = Kramdown::Document.new(p_t_k_id).to_plain_text.strip
            else
              val_attrs[:primary_title_plain_text_from_id] = ''
            end
          end
          true
        end

        def prepare_primary_attrs!(content_at_file, val_attrs)
          if(idp = val_attrs[:id_parts]).any?
            # Get title from id_title1
            raw_title_from_id = idp['id_title1'].first.to_s.strip
            if val_attrs[:validator_exceptions].include?('multi_level_title')
              # Work with plain text titles
              # Remove language and date code from title
              val_attrs[:title_plain_text_from_id] = remove_linebreaks_plain_text(
                Kramdown::Document.new(raw_title_from_id).to_plain_text.strip
              )
            else
              # Work with kramdown titles
              # Remove language and date code from title
              val_attrs[:title_kramdown_from_id] = remove_linebreaks_kramdown(
                raw_title_from_id
              )
            end
            # Get datecode from id_title2
            raw_datecode = idp['id_title2'].first.to_s.downcase.strip
            # * `SPN64-0304`
            # *
            # ImplementationTag #date_code_regex
            # Remove asterisks to address cases like `64-0304*e*{: .smcaps}` and
            # `60-*0417s*{: .smcaps}`
            val_attrs[:date_code_from_id] = raw_datecode.gsub('*', '')[/\d{2}-\d{4}[a-z]?/]
          end
          true
        end

        # Computes both kramdown and plain text titles and adds them to val_attrs.
        def compute_title_from_content!(content_at_file, val_attrs)
          content_at = content_at_file.contents
          if val_attrs[:validator_exceptions].include?('multi_level_title')
            # Get both level 1 and level 2 headers
            titles = Services::ExtractContentAtMainTitles.call(
              content_at, :plain_text, true
            ).result
            # Only assign plain_text, not kramdown
            val_attrs[:title_plain_text_from_content] = remove_linebreaks_plain_text(
              titles.join(", ")
            ).to_s.strip
          else
            val_attrs[:title_kramdown_from_content] = remove_linebreaks_kramdown(
              Services::ExtractContentAtMainTitles.call(
                content_at, :content_at
              ).result.to_s.strip
            )
            val_attrs[:title_plain_text_from_content] = remove_linebreaks_plain_text(
              Services::ExtractContentAtMainTitles.call(
                content_at, :plain_text
              ).result.to_s.strip
            )
          end
          true
        end

        def compute_attrs_from_filename!(content_at_file, val_attrs)
          val_attrs[:date_code_from_filename] = content_at_file.extract_date_code.to_s.strip
          val_attrs[:language_code_from_filename] = content_at_file.language_code_3_chars.to_s.downcase.strip
          true
        end

        def compute_attrs_from_erp_data!(content_at_file, val_attrs, all_erp_data)
          pii = content_at_file.extract_product_identity_id(false).to_i
          file_erp_data = all_erp_data.detect { |e| e['productidentityid'] == pii }
          if file_erp_data
            val_attrs[:has_erp_data] = true
          else
            val_attrs[:has_erp_data] = false
            return true
          end
          title_sanitizer = ->(raw_title) {
            # Replace straight apostrophes with typographic ones
            raw_title.to_s.strip.gsub("'", '’')
          }
          val_attrs[:title_plain_text_from_erp] = title_sanitizer.call(
            file_erp_data['foreigntitle']
          )
          val_attrs[:primary_title_plain_text_from_erp] = title_sanitizer.call(
            file_erp_data['englishtitle']
          )
          val_attrs[:date_code_from_erp] = file_erp_data['productid'].to_s.strip.downcase
          val_attrs[:language_code_from_erp] = file_erp_data['languageid'].to_s.downcase.strip
          true
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
        def validate_attrs_common(content_at_file, val_attrs, errors, warnings)
          # Compare ERP title with content
          t_pt_c = val_attrs[:title_plain_text_from_content]
          if '' == t_pt_c
            errors << Reportable.error(
              [@file_to_validate.filename],
              ["Title (plain text) from content is missing"]
            )
          end
          if val_attrs[:has_erp_data]
            t_pt_erp = val_attrs[:title_plain_text_from_erp]
            if '' == t_pt_erp
              errors << Reportable.error(
                [@file_to_validate.filename],
                ["Title (plain text) from ERP is missing"]
              )
            elsif t_pt_erp != t_pt_c
              record_error = true
              ex_t_pt_erp = t_pt_erp
              ex_t_pt_c = t_pt_c
              ex_comparer = ->(t_from_erp, t_from_c) { t_from_erp == t_from_c }
              # Start with most specific exceptions
              if val_attrs[:validator_exceptions].include?('ignore_end_diff_starting_at_pound_sign_erp')
                # Remove everything from pound sign to the end in erp, then
                # test if erp is contained in title from content
                ex_t_pt_erp.sub!(/\s#.*\z/, '')
                ex_comparer = ->(t_from_erp, t_from_c) { t_from_c[t_from_erp] }
              end
              if val_attrs[:validator_exceptions].include?('ignore_pound_sign_and_number_diff_erp')
                # Remove pound signs followed by digits (and preceded by space) from erp
                ex_t_pt_erp.gsub!(/\s?#\d+/, '')
              end
              if val_attrs[:validator_exceptions].include?('ignore_pound_sign_diff_erp')
                # Remove pound signs from erp
                ex_t_pt_erp.gsub!('#', '')
              end
              if val_attrs[:validator_exceptions].include?('ignore_short_word_capitalization_erp')
                # Capitalize all small words in both and compare again
                sw_lower_caser = ->(txt) {
                  %w[and in of on the].each { |sw|
                    txt.gsub(/\b#{ sw.upcase }\b/, sw)
                  }
                }
                ex_t_pt_erp = sw_lower_caser.call(t_pt_erp)
                ex_t_pt_c = sw_lower_caser.call(t_pt_c)
              end
              record_error = false  if ex_comparer.call(ex_t_pt_erp, ex_t_pt_c)

              if record_error
                errors << Reportable.error(
                  [@file_to_validate.filename],
                  [
                    "ERP title is different from content title (plain text)",
                    "ERP title: #{ t_pt_erp.inspect }, Content title: #{ t_pt_c.inspect }"
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


          # Compare ID title with content
          if val_attrs[:id_parts].any?
            if val_attrs[:validator_exceptions].include?('multi_level_title')
              # Use plain text titles
              t_pt_id = val_attrs[:title_plain_text_from_id]
              if '' == t_pt_id
                errors << Reportable.error(
                  [@file_to_validate.filename],
                  ["Title (plain text) from id is missing"]
                )
              elsif t_pt_id != t_pt_c
                errors << Reportable.error(
                  [@file_to_validate.filename],
                  [
                    "ID title is different from content title (plain text)",
                    "ID title: #{ t_pt_id.inspect }, Content title: #{ t_pt_c.inspect }"
                  ]
                )
              end
            else
              # Use kramdown titles
              t_k_c = val_attrs[:title_kramdown_from_content]
              if '' == t_k_c
                errors << Reportable.error(
                  [@file_to_validate.filename],
                  ["Title (kramdown) from content is missing"]
                )
              end
              t_k_id = val_attrs[:title_kramdown_from_id]
              if '' == t_k_id
                errors << Reportable.error(
                  [@file_to_validate.filename],
                  ["Title (kramdown) from id is missing"]
                )
              elsif t_k_id != t_k_c
                errors << Reportable.error(
                  [@file_to_validate.filename],
                  [
                    "ID title is different from content title (kramdown)",
                    "ID title: #{ t_k_id.inspect }, Content title: #{ t_k_c.inspect }"
                  ]
                )
              end
            end
          end

          # Compare ERP datecode with filename
          dc_fn = val_attrs[:date_code_from_filename]
          if '' == dc_fn
            errors << Reportable.error(
              [@file_to_validate.filename],
              ["Date code from filename is missing"]
            )
          end
          if val_attrs[:has_erp_data]
            dc_erp = val_attrs[:date_code_from_erp]
            if '' == dc_erp
              errors << Reportable.error(
                [@file_to_validate.filename],
                ["Date code from ERP is missing"]
              )
            elsif dc_erp != dc_fn
              errors << Reportable.error(
                [@file_to_validate.filename],
                [
                  "ERP datecode is different from filename datecode",
                  "ERP datecode: #{ dc_erp.inspect }, Filename datecode: #{ dc_fn.inspect }"
                ]
              )
            end
          end

          # Compare ID datecode with filename
          if val_attrs[:id_parts].any?
            dc_id = val_attrs[:date_code_from_id]
            if '' == dc_id
              errors << Reportable.error(
                [@file_to_validate.filename],
                ["Date code from ID is missing"]
              )
            elsif dc_id != dc_fn
              errors << Reportable.error(
                [@file_to_validate.filename],
                [
                  "ID datecode is different from filename datecode",
                  "ID datecode: #{ dc_id.inspect }, Filename datecode: #{ dc_fn.inspect }"
                ]
              )
            end
          end

          true
        end

        # @param content_at_file [RFile::ContentAt]
        # @param val_attrs [Hash]
        # @param errors [Array]
        # @param warnings [Array]
        # Mutates errors and warnings in place
        def validate_attrs_foreign(content_at_file, val_attrs, errors, warnings)
          # Compare primary ID title with ERP
          if val_attrs[:id_parts].any?
            pr_t_pt_id = val_attrs[:primary_title_plain_text_from_id]
            if '' == pr_t_pt_id
              errors << Reportable.error(
                [@file_to_validate.filename],
                ["Primary title from ID is missing"]
              )
            end
            if val_attrs[:has_erp_data]
              pr_t_pt_erp = val_attrs[:primary_title_plain_text_from_erp]
              if '' == pr_t_pt_erp
                errors << Reportable.error(
                  [@file_to_validate.filename],
                  ["Primary title from ERP is missing"]
                )
              elsif pr_t_pt_id != pr_t_pt_erp
                record_error = true
                ex_pr_t_pt_id = pr_t_pt_id
                ex_pr_t_pt_id = pr_t_pt_id
                ex_comparer = ->(pr_t_from_erp, pr_t_from_id) { pr_t_from_erp == pr_t_from_id }
                # Start with most specific exceptions
                if val_attrs[:validator_exceptions].include?('ignore_end_diff_starting_at_pound_sign_erp')
                  # Remove everything from pound sign to the end in erp, then
                  # test if erp is contained in title from content
                  ex_pr_t_pt_id.sub!(/\s#.*\z/, '')
                  ex_comparer = ->(pr_t_from_erp, pr_t_from_id) { pr_t_from_id[pr_t_from_erp] }
                end
                if val_attrs[:validator_exceptions].include?('ignore_pound_sign_and_number_diff_erp')
                  # Remove pound signs followed by digits (and preceded by space) from erp
                  ex_pr_t_pt_id.gsub!(/\s?#\d+/, '')
                end
                if val_attrs[:validator_exceptions].include?('ignore_pound_sign_diff_erp')
                  # Remove pound signs from erp
                  ex_pr_t_pt_id.gsub!('#', '')
                end
                if val_attrs[:validator_exceptions].include?('ignore_short_word_capitalization_erp')
                  # Capitalize all small words in both and compare again
                  sw_lower_caser = ->(txt) {
                    %w[and in of on the].each { |sw|
                      txt.gsub(/\b#{ sw.upcase }\b/, sw)
                    }
                  }
                  ex_pr_t_pt_id = sw_lower_caser.call(pr_t_pt_id)
                  ex_pr_t_pt_id = sw_lower_caser.call(pr_t_pt_id)
                end
                record_error = false  if ex_comparer.call(ex_pr_t_pt_id, ex_pr_t_pt_id)

                if record_error
                  errors << Reportable.error(
                    [@file_to_validate.filename],
                    [
                      "ERP primary title is different from ID primary title",
                      "ERP primary title: #{ pr_t_pt_erp.inspect }, ID primary title: #{ pr_t_pt_id.inspect }"
                    ]
                  )
                end
              end
            end
          end

          # Compare ERP language code with filename
          lc_fn = val_attrs[:language_code_from_filename]
          if '' == lc_fn
            errors << Reportable.error(
              [@file_to_validate.filename],
              ["Language code from filename is missing"]
            )
          end
          if val_attrs[:has_erp_data]
            lc_erp = val_attrs[:language_code_from_erp]
            if '' == lc_erp
              errors << Reportable.error(
                [@file_to_validate.filename],
                ["Language code from ERP is missing"]
              )
            elsif lc_erp != lc_fn
              errors << Reportable.error(
                [@file_to_validate.filename],
                [
                  "ERP language code is different from filename language code",
                  "ERP language_code: #{ lc_erp.inspect }, filename language code: #{ lc_fn.inspect }"
                ]
              )
            end
          end

          # Compare ID language code with filename
          if val_attrs[:id_parts].any?
            lc_id = val_attrs[:language_code_from_id]
            if '' == lc_id
              errors << Reportable.error(
                [@file_to_validate.filename],
                ["Language code from ID is missing"]
              )
            elsif lc_id != lc_fn
              errors << Reportable.error(
                [@file_to_validate.filename],
                [
                  "ID language code is different from filename language code",
                  "ID language_code: #{ lc_id.inspect }, filename language code: #{ lc_fn.inspect }"
                ]
              )
            end
          end
          true
        end

      end
    end
  end
end
