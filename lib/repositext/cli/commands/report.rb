class Repositext
  class Cli
    # This namespace contains methods related to the `report` command.
    module Report

    private

      # Runs all reports that pertain to content at.
      def report_all_content_at_reports(options)
        report_variants.each do |variant|
          self.send("report_#{ variant }", options)
        end
      end

      # Prints an inventory of all characters found in the current language.
      def report_character_inventory(options)
        chars = Hash.new(0)
        total_file_count = 0
        lines = []

        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(
            options['base-dir'] || :content_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :at_extension
          ),
          options['file_filter'],
          nil,
          "Reading content AT files",
          options
        ) do |content_at_file|
          total_file_count += 1

          # Build character inventory
          content_at_file.plain_text_contents({}).codepoints.each { |cp|
            chars[cp] += 1
          }
        end

        lines << "Character inventory for #{ content_type.language_name }"

        char_groups = chars.group_by { |code, count|
          case code.chr('UTF-8')
          # We switched to using plain text instead of content AT, so we don't
          # need this char_group.
          # when /\A[#{ Regexp.escape("#%&*@^_=\"{}") }]\z/
          #   "Repositext markup"
          when /\A[#{ Regexp.escape("\n !()/,-+$.:;?[]–—‘’“”…") }0-9A-Za-z]\z/
            # ImplementationTag #punctuation_characters
            "English chars and punctuation"
          else
            "Language specific characters"
          end
        }
        char_groups.each { |group_name, chrs|
          lines << ''
          lines << group_name
          lines << '*' * group_name.length

          chrs.sort_by { |k,v|
            k
          }.map { |(code,count)|
            char = case code
            when 34
              # Don't inspect double quotes
              '"'
            when 37
              # Escape percent for sprintf
              '%%'
            else
              code.chr('UTF-8').inspect.gsub("\"", '')
            end
            lines << sprintf("#{ char.ljust(4) } U+%04x %9d", code, count)
          }
        }
        $stderr.puts
        lines.each { |e| $stderr.puts(e) }
        report_file_path = File.join(config.base_dir(:reports_dir), 'character_inventory_report.txt')
        File.open(report_file_path, 'w') { |f|
          f.write lines.join("\n")
          f.write "\n\n"
          f.write "Command to generate this file: `repositext report character_inventory`\n"
        }
      end

      # Compares the files present in the repository with the list of titles from
      # ERP. Lists any files that are missing/added in the repository
      def report_compare_file_inventory_with_erp(options)
        date_codes_from_erp = load_titles_from_erp.keys
        date_codes_from_repo = []
        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(
            options['base-dir'] || :content_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :at_extension
          ),
          options['file_filter'],
          nil,
          "Reading AT files",
          options
        ) do |content_at_file|
          date_codes_from_repo << content_at_file.extract_date_code.downcase
        end
        # compute differences
        common_date_codes = date_codes_from_erp & date_codes_from_repo
        missing_date_codes = date_codes_from_erp - common_date_codes
        added_date_codes = date_codes_from_repo - common_date_codes
        missing_count = missing_date_codes.length
        added_count = added_date_codes.length
        common_count = common_date_codes.length
        total_count = missing_count + added_count + common_count
        lines = [
          "Compare content AT file inventory with ERP",
          '-' * 40,
        ]
        lines << " - There are #{ common_count } files in both content AT and ERP."
        if missing_date_codes.empty?
          lines << " - There are no files in ERP that aren't also in content AT."
        else
          lines << " - The following #{ missing_count } files in ERP are NOT in content AT:"
          missing_date_codes.each do |dc|
            lines << " - - #{ dc }"
          end
        end
        if added_date_codes.empty?
          lines << " - There are no files in content AT that aren't also in ERP."
        else
          lines << " - The following #{ added_count } files in content AT are NOT in ERP:"
          added_date_codes.each do |dc|
            lines << " - - #{ dc }"
          end
        end
        lines << '-' * 40
        lines << "Found #{ missing_count + added_count } differences in #{ total_count } files at #{ Time.now.to_s }."
        $stderr.puts
        lines.each { |l| $stderr.puts l }
        report_file_path = File.join(config.base_dir(:reports_dir), 'compare_file_inventory_with_erp.txt')
        File.open(report_file_path, 'w') { |f|
          f.write lines.join("\n")
          f.write "\n\n"
          f.write "Command to generate this file: `repositext report compare_file_inventory_with_erp`\n"
        }
      end

      # Generates two counts of files: those with gap_marks and those with subtitle_marks
      def report_count_files_with_gap_marks_and_subtitle_marks(options)
        total_count = 0
        with_gap_marks = 0
        with_subtitle_marks = 0

        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(
            options['base-dir'] || :content_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :at_extension
          ),
          options['file_filter'],
          nil,
          "Reading AT files",
          options
        ) do |content_at_file|
          total_count += 1
          with_gap_marks += 1  if content_at_file.contents.index('%')
          with_subtitle_marks += 1  if content_at_file.contents.index('@')
          # Uncomment next line to print line 7 of each file
          # puts contents.split("\n")[6][0,80] + '       ' + filename.split('/').last
        end

        lines = [
          "Count of files with gap_marks and subtitle_marks",
          '-' * 40,
        ]
        lines << " - With gap_marks: #{ with_gap_marks }"
        lines << " - With subtitle_marks: #{ with_subtitle_marks }"
        lines << '-' * 40
        lines << "Checked #{ total_count } files at #{ Time.now.to_s }."
        $stderr.puts
        lines.each { |l| $stderr.puts l }
        report_file_path = File.join(config.base_dir(:reports_dir), 'count_files_with_gap_marks_and_subtitle_marks.txt')
        File.open(report_file_path, 'w') { |f|
          f.write lines.join("\n")
          f.write "\n\n"
          f.write "Command to generate this file: `repositext report count_files_with_gap_marks_and_subtitle_marks`\n"
        }
      end

      # Generates a report with subtitle_mark counts for all content AT files.
      def report_count_subtitle_marks(options)
        file_count = 0
        subtitle_marks_count = 0
        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(
            options['base-dir'] || :content_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :at_extension
          ),
          options['file_filter'],
          nil,
          "Reading AT files",
          options
        ) do |content_at_file|
          subtitle_marks_count += content_at_file.contents.count('@')
          file_count += 1
        end
        $stderr.puts "Found #{ subtitle_marks_count } subtitle_marks in #{ file_count } files at #{ Time.now.to_s }."
      end

      # Reports all content AT files that don't have st_sync_active.
      def report_files_that_dont_have_st_sync_active(options)
        inactive_files = []
        active_files = []
        total_file_count = 0

        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(
            options['base-dir'] || :content_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :at_extension
          ),
          options['file_filter'],
          nil,
          "Reading content AT files",
          options
        ) do |content_at_file|
          data_json_file = content_at_file.corresponding_data_json_file
          total_file_count += 1
          lang_and_date_code = [
            content_at_file.language_code_3_chars,
            content_at_file.extract_date_code
          ].join
          if data_json_file.contents.index('"st_sync_active":false')
            inactive_files << lang_and_date_code
            $stderr.puts "   - doesn't have st_sync_active".color(:blue)
          else
            active_files << lang_and_date_code
          end
        end
        inactive_files_count = inactive_files.length
        active_files_count = active_files.length
        if inactive_files_count > 0
          $stderr.puts "\n\n#{ inactive_files_count } files that DON'T HAVE st_sync_active:"
          $stderr.puts '-' * 80
          inactive_files.each { |e| $stderr.puts e }
          $stderr.puts
        end
        if active_files_count > 0
          $stderr.puts "\n\n#{ active_files_count } files that HAVE st_sync_active:"
          $stderr.puts '-' * 80
          active_files.each { |e| $stderr.puts e }
          $stderr.puts
        end
        summary_line = "Found #{ inactive_files_count } of #{ total_file_count } files that don't have st_sync_active at #{ Time.now.to_s }."
        $stderr.puts summary_line
      end

      # Reports all foreign files with subtitles that require review.
      # Objective: To know what files require review and haven't been sent out.
      # We distinguish between files that have been exported and those that
      # have not been.
      # We can tell if a file has been exported when exported_subtitles_at_st_sync_commit
      # is not null.
      # For those files that haven't been exported, we further distinguish the
      # following three groups:
      #     * File has subtitle operations (+ optional content changes)
      #     * File has just content changes
      #     * File was autosplit
      def report_files_with_subtitles_that_require_review(options)
        if config.setting(:is_primary_repo)
          raise "This command can only be used in foreign repos."
        end

        fwstrr = {
          subtitles_not_exported: {
            st_ops_and_content_changes: [],
            content_changes_only: [],
            autosplit: []
          },
          subtitles_exported: []
        }
        files_found_count = 0
        total_file_count = 0

        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(
            options['base-dir'] || :content_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :json_extension
          ),
          /\.data\.json\z/,
          nil,
          "Reading data.json files",
          options
        ) do |data_json_file|
          total_file_count += 1
          fd = data_json_file.read_data
          filename = data_json_file.filename
          subtitles_have_been_exported = '' != fd['exported_subtitles_at_st_sync_commit'].to_s.strip
          st_tr = (fd['st_sync_subtitles_to_review'] || {})
          next  if st_tr.none?
          st_tr_keys = st_tr.keys
          st_tr_cnt = st_tr_keys.count
          desc = nil
          if subtitles_have_been_exported
            # No further distinction required
            files_found_count += 1
            if st_tr.any? { |e| ['all', ['autosplit']] == e }
              # all sts need to be reviewed, don't print details
              fwstrr[:subtitles_exported] << [filename, 'all', []]
            else
              # only some sts need to be reviewed, print details
              # Add subtitle index + type of change to this file group
              # st_tr: { "6938579" => ["content_change"], "2756941" => ["content_change"] }
              subtitles = data_json_file.corresponding_content_at_file.subtitles
              st_tr_attrs = st_tr.map { |stid, ops|
                st = subtitles.detect { |e| stid == e.persistent_id }
                # st may not exist if it was deleted via merge or delete operation.
                idx = ((st && st.tmp_index) || '[N/A]').to_s.rjust(5, ' ')
                { index: idx, operations: ops.join(', ') }
              }
              fwstrr[:subtitles_exported] << [filename, st_tr_cnt, st_tr_attrs]
            end
            desc = "   - subtitles have been exported, has #{ st_tr_cnt } subtitles to review".color(:blue)
          else
            # subtitles have not been exported, further distinguish kinds of changes
            if data_json_file.is_autosplit?
              # This file is autosplit
              files_found_count += 1
              fwstrr[:subtitles_not_exported][:autosplit] << [filename, 'all']
              desc = "   - subtitles have not been exported, was autosplit".color(:blue)
            elsif st_tr.all? { |stid,ops| ops.all? { |op| 'content_change' == op } }
              # content_changes only
              files_found_count += 1
              fwstrr[:subtitles_not_exported][:content_changes_only] << [filename, st_tr_cnt]
              desc = "   - subtitles have not been exported, #{ st_tr_cnt } content_changes to review".color(:blue)
            else
              # st ops and content_changes
              files_found_count += 1
              # Add subtitle index + type of change to this file group
              # st_tr: { "6938579" => ["content_change"], "2756941" => ["content_change"] }
              subtitles = data_json_file.corresponding_content_at_file.subtitles
              st_tr_attrs = st_tr.map { |stid, ops|
                st = subtitles.detect { |e| stid == e.persistent_id }
                # st may not exist if it was deleted via merge or delete operation.
                idx = ((st && st.tmp_index) || '[N/A]').to_s.rjust(5, ' ')
                { index: idx, operations: ops.join(', ') }
              }
              fwstrr[:subtitles_not_exported][:st_ops_and_content_changes] << [filename, st_tr_cnt, st_tr_attrs]
              desc = "   - subtitles have not been exported, #{ st_tr_cnt } st_ops and content_changes to review".color(:blue)
            end
          end
          $stderr.puts desc
        end
        if files_found_count > 0
          $stderr.puts "\nThe following #{ files_found_count } files have subtitles requiring review".color(:blue)
          $stderr.puts '-' * 80
          if(fs = fwstrr[:subtitles_not_exported][:st_ops_and_content_changes]).any?
            $stderr.puts "  With st ops (subtitles not exported yet):".color(:blue)
            fs.each { |(fn, cnt, sts_tr)|
              $stderr.puts "   * #{ fn } (#{ cnt })"
              sts_tr.each { |st_tr|
                $stderr.puts "         - index #{ st_tr[:index] }: #{ st_tr[:operations] }"
              }
            }
          end
          if(fs = fwstrr[:subtitles_not_exported][:content_changes_only]).any?
            $stderr.puts "  With content_changes (subtitles not exported yet):".color(:blue)
            fs.each { |(fn, cnt)| $stderr.puts "   * #{ fn } (#{ cnt })" }
          end
          if(fs = fwstrr[:subtitles_not_exported][:autosplit]).any?
            $stderr.puts "  Autosplit (subtitles not exported yet):".color(:blue)
            fs.each { |(fn, cnt)| $stderr.puts "   * #{ fn } (#{ cnt })" }
          end
          if(fs = fwstrr[:subtitles_exported]).any?
            $stderr.puts "  Subtitles already exported:".color(:blue)
            # fs.each { |(fn, cnt)| $stderr.puts "   * #{ fn } (#{ cnt })" }
            fs.each { |(fn, cnt, sts_tr)|
              $stderr.puts "   * #{ fn } (#{ cnt })"
              sts_tr.each { |st_tr|
                $stderr.puts "         - index #{ st_tr[:index] }: #{ st_tr[:operations] }"
              }
            }
          end
          $stderr.puts
        end
      end

      # Reports all primary content AT files that require an st_sync.
      def report_files_that_have_st_sync_required(options)
        if !config.setting(:is_primary_repo)
          raise "This command can only be used in the primary repo."
        end
        ftrss = []
        total_file_count = 0

        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(
            options['base-dir'] || :content_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :json_extension
          ),
          /\.data\.json\z/,
          nil,
          "Reading data.json files",
          options
        ) do |data_json_file|
          total_file_count += 1
          rrfn = data_json_file.repo_relative_path(true)
          if data_json_file.read_data['st_sync_required']
            ftrss << rrfn
            $stderr.puts "   - has st_sync_required".color(:blue)
          end
        end
        if ftrss.any?
          $stderr.puts "\n\n#{ ftrss.length } files that require st_sync:"
          $stderr.puts '-' * 80
          ftrss.each { |e| $stderr.puts e }
          $stderr.puts
        end
        summary_line = "Found #{ ftrss.length } of #{ total_file_count } files that require st_sync at #{ Time.now.to_s }."
        $stderr.puts summary_line
      end

      # Generates a report with all content AT files that contain subtitles. This is based
      # on the presence of a subtitle markers CSV file that contains non-zero
      # timestamps.
      def report_files_with_subtitles(options)
        total_csv_file_count = 0
        files_with_subtitles = []

        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(
            options['base-dir'] || :content_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :csv_extension
          ),
          options['file_filter'] || /\.subtitle_markers\.csv\z/,
          nil,
          "Reading subtitle marker CSV files",
          options
        ) do |csv_file|
          total_csv_file_count += 1
          uniq_first_col_vals = csv_file.contents.scan(/^\d+/).uniq
          if ['0'] != uniq_first_col_vals
            # File has non-zero timestamps
            file_base_name = csv_file.basename
            files_with_subtitles << file_base_name.gsub(/\.subtitle_markers\.csv\z/, '.at')
            $stderr.puts " - #{ file_base_name }"
          end
        end

        summary_line = "Found #{ files_with_subtitles.length } of #{ total_csv_file_count } CSV files with subtitles at #{ Time.now.to_s }."
        $stderr.puts summary_line
        report_file_path = File.join(config.base_dir(:reports_dir), 'files_with_subtitles.txt')
        File.open(report_file_path, 'w') { |f|
          f.write "Files with subtitles\n"
          f.write '-' * 40
          f.write "\n"
          f.write files_with_subtitles.join("\n")
          f.write "\n"
          f.write '-' * 40
          f.write "\n"
          f.write summary_line
          f.write "\n\n"
          f.write "Command to generate this file: `repositext report files_with_subtitles`\n"
        }
      end

      # Generates a report with gap_mark counts for all content AT files that
      # contain gap_marks
      def report_gap_mark_count(options)
        file_count = 0
        files_with_gap_marks = []
        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(
            options['base-dir'] || :content_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :at_extension
          ),
          options['file_filter'],
          nil,
          "Reading AT files",
          options
        ) do |content_at_file|
          gap_mark_count = content_at_file.contents.scan(/(?<!\\)%/).size
          date_code = content_at_file.extract_date_code
          if gap_mark_count > 0
            files_with_gap_marks << {
              gap_mark_count: gap_mark_count + 2, # add two for correct count in final document
              filename: content_at_file.filename,
              date_code: date_code,
            }
          end
          file_count += 1
        end
        lines = []
        files_with_gap_marks.sort { |a,b| a[:date_code] <=> b[:date_code] }.each do |attrs|
          l = " - #{ attrs[:date_code].ljust(10) } - #{ attrs[:gap_mark_count].to_s.rjust(5) }"
          $stderr.puts l
          lines << l
        end
        summary_line = "Found #{ lines.length } of #{ file_count } files with gap_marks at #{ Time.now.to_s }."
        $stderr.puts summary_line
        report_file_path = File.join(config.base_dir(:reports_dir), 'gap_mark_count.txt')
        File.open(report_file_path, 'w') { |f|
          f.write "Gap_mark count\n"
          f.write '-' * 40
          f.write "\n"
          f.write lines.join("\n")
          f.write "\n"
          f.write '-' * 40
          f.write "\n"
          f.write summary_line
          f.write "\n\n"
          f.write "Command to generate this file: `repositext report gap_mark_count`\n"
        }
      end

      # Prints a list of public version ids (or their absence) for all files
      # matching (the mandatory) file-selector argument.
      # Raises an error if no file-selector is given.
      # File selector has to be provided either via
      # * --dc option OR
      # * --file-selector option in the form "**/*{<date code>,<date code>}*"
      # Key is that we need a specific list of files and not a pattern that matches
      # a group of files (e.g., just the year)
      def report_pdf_public_version_ids(options)
        if options['skip-erp-api']
          raise("\n\nERP API access is required for this command.\n\n".color(:red))
        end
        # Validate that file-selector is given
        if options['file-selector'].blank? || !options['file-selector'][/\{[^\}]+\}/]
          raise ArgumentError.new(
            "\n\nYou must provide a list of files for this command via --dc or --file-selector (using \"**/*{<date code>,<date code>}*\").\n".color(:red)
          )
        end
        # Compute list of all files matching file-selector
        file_list_pattern = config.compute_glob_pattern(
          options['base-dir'] || :content_dir,
          options['file-selector'],
          options['file-extension'] || :at_extension
        )
        file_list = Dir.glob(file_list_pattern)
        language = content_type.language
        file_pi_ids_and_datecodes = file_list.map { |filename|
          rf = RFile::Content.new(
            '_',
            language,
            filename
          )
          [rf.extract_product_identity_id, rf.extract_date_code]
        }
        file_pi_ids = file_pi_ids_and_datecodes.map { |e| e.first.to_i }
        erp_data = Services::ErpApi.call(
          config.setting(:erp_api_protocol_and_host),
          ENV['ERP_API_APPID'],
          ENV['ERP_API_NAMEGUID'],
          :get_pdf_public_versions,
          {
            languageids: [content_type.language_code_3_chars],
            ids: file_pi_ids.join(',')
          }
        )
        Services::ErpApi.validate_product_identity_ids(erp_data, file_pi_ids)
        public_version_ids_and_versions = erp_data.inject({}) { |m,e|
          pi_id = e['productidentityid'].to_s.rjust(4, '0')
          m[pi_id] = {
            public_version_id: e['publicversionid'].to_s,
            version: e['version'].to_s,
          }
          m
        }
        puts
        puts("Public version IDs and Versions from ERP:".color(:blue))
        puts("-----------------------------------------".color(:blue))
        puts "   [Date code]     [PV id]  [Version]"
        file_pi_ids_and_datecodes.each { |(file_pi_id, date_code)|
          combined_marker = [date_code, file_pi_id].join('_')
          if(
            (attrs = public_version_ids_and_versions[file_pi_id]) &&
            '0' != attrs[:version]
          )
            puts [
              ' * ',
              combined_marker.ljust(13, ' '),
              attrs[:public_version_id].rjust(10, ' '),
              attrs[:version].rjust(11, ' '),
            ].join
          else
            puts(
              [
                ' * ',
                combined_marker.ljust(13, ' '),
                '-'.rjust(10, ' '),
                '-'.rjust(11, ' '),
              ].join.color(:yellow)
            )
          end
        }
        puts
      end

      def report_subtitle_mark_count(options)
        file_count = 0
        files_with_subtitle_marks = []
        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(
            options['base-dir'] || :content_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :at_extension
          ),
          options['file_filter'],
          nil,
          "Reading AT files",
          options
        ) do |content_at_file|
          subtitle_mark_count = content_at_file.contents.scan(/(?<!\\)@/).size
          date_code = content_at_file.extract_date_code
          if subtitle_mark_count > 0
            files_with_subtitle_marks << {
              subtitle_mark_count: subtitle_mark_count,
              filename: content_at_file.filename,
              date_code: date_code,
            }
          end
          file_count += 1
        end
        lines = []
        files_with_subtitle_marks.sort { |a,b| a[:date_code] <=> b[:date_code] }.each do |attrs|
          l = " - #{ attrs[:date_code].ljust(10) } - #{ attrs[:subtitle_mark_count].to_s.rjust(5) }"
          $stderr.puts l
          lines << l
        end
        summary_line = "Found #{ lines.length } of #{ file_count } files with subtitle_marks at #{ Time.now.to_s }."
        $stderr.puts summary_line
        report_file_path = File.join(config.base_dir(:reports_dir), 'subtitle_mark_count.txt')
        File.open(report_file_path, 'w') { |f|
          f.write "Subtitle_mark count\n"
          f.write '-' * 40
          f.write "\n"
          f.write lines.join("\n")
          f.write "\n"
          f.write '-' * 40
          f.write "\n"
          f.write summary_line
          f.write "\n\n"
          f.write "Command to generate this file: `repositext report subtitle_mark_count`\n"
        }
      end

      # Prints report that counts all html tag/class combinations it encounters.
      def report_html_tag_classes_inventory(options)
        file_count = 0
        tag_classes_inventory = Hash.new(0)

        # Updates tci with xn's inventory
        # @param parent_stack [Array<String>] contains tag names of parents
        # @param xn [Nokogiri::XmlNode]
        # @param tci [Hash] tag_classes_inventory collector
        tag_classes_inventory_extractor = lambda { |parent_stack, xn, tci|
          own_key = [xn.name, xn['class']].compact.join('.')
          k = [
            parent_stack.join(' > '),
            ' > ',
            own_key,
          ].join
          tci[k] += 1
          parent_stack.push(own_key)
          xn.children.each { |cxn|
            tag_classes_inventory_extractor.call(parent_stack, cxn, tci)
          }
          parent_stack.pop
        }

        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(
            options['base-dir'] || :content_type_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :html_extension
          ),
          options['file_filter'],
          nil,
          "Reading HTML files",
          options
        ) do |content_at_file|
          file_count += 1
          html_doc = Nokogiri::HTML(content_at_file.contents)
          # Compute tag/classes inventory
          parent_stack = ['body']
          html_doc.at_css('body').children.each do |cxn|
            tag_classes_inventory_extractor.call(parent_stack, cxn, tag_classes_inventory)
          end
        end

        $stderr.puts 'HTML Tag/Classes inventory'
        $stderr.puts '-' * 40
        tag_classes_inventory.to_a.sort.each { |e|
          $stderr.puts "#{ e.first }: #{ e.last }"
        }
        $stderr.puts '-' * 40
        $stderr.puts "Checked #{ file_count } files at #{ Time.now.to_s }."
        $stderr.puts "Command to generate this file: `repositext report html_tag_classes_inventory`"
      end

      # Generates a report that highlights the following:
      # * Any files that don't have an eagle at the beginning of the second record
      # * Any files that don't have an eagle at the end of the last record
      #   (before id page if it exists)
      # * Any records other than the second or last in each file that contain an eagle
      # Allows exemption of records from the above rules.
      def report_invalid_eagles(options)
        file_count = 0
        issues = {}
        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(
            options['base-dir'] || :content_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :at_extension
          ),
          options['file_filter'],
          nil,
          "Reading content AT files",
          options
        ) do |content_at_file|
          # parse AT, use converter to generate warnings
          # Since the kramdown parser is specified as module in Rtfile,
          # I can't use the standard kramdown API:
          # `doc = Kramdown::Document.new(contents, :input => 'kramdown_repositext')`
          # We have to patch a base Kramdown::Document with the root to be able
          # to convert it.
          contents_without_id_page, _ = Repositext::Utils::IdPageRemover.remove(content_at_file.contents)
          root, _warnings = config.kramdown_parser(:kramdown).parse(contents_without_id_page)
          doc = Kramdown::Document.new('')
          doc.root = root
          file_issues = doc.to_report_invalid_eagles
          if file_issues.any?
            issues[content_at_file.filename] = file_issues
            file_issues.each { |issue|
              $stderr.puts "   - #{ issue.inspect }"
            }
          end
          file_count += 1
        end
        report_file_path = File.join(config.base_dir(:reports_dir), 'invalid_eagles.txt')
        File.open(report_file_path, 'w') { |f|
          f.write "Invalid eagles\n"
          f.write "==============\n"
          f.write "\n"
          # Sort by filename
          issues.sort { |a,b| a.first <=> b.first }.each do |(filename, file_issues)|
            f.write '-' * 40
            f.write "\n"
            f.write filename
            f.write "\n"
            file_issues.each do |file_issue|
              f.write " - #{ file_issue[:issue] }, record_id: #{ file_issue[:record_id] }"
              f.write "\n"
            end
          end
          f.write '-' * 40
          f.write "\n"
          f.write "Found #{ issues.length } of #{ file_count } files with issues at #{ Time.now.to_s }.\n\n"
          f.write "Command to generate this file: `repositext report invalid_eagles`\n"
        }
      end

      # Finds invalid quote sequences. See class for details.
      # @param [Hash] options
      def report_invalid_typographic_quotes(options)
        # For primary repo we want limited context, and for foreign we want
        # all text from paragraph number
        context_size = config.setting(:is_primary_repo) ? 5 : 0
        report = Repositext::Process::Report::InvalidTypographicQuotes.new(
          context_size,
          content_type.language
        )

        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(
            options['base-dir'] || :content_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :at_extension
          ),
          options['file_filter'],
          nil,
          "Reading folio at files",
          options
        ) do |content_at_file|
          report.process(content_at_file.contents, content_at_file.filename)
        end
        output_lines = []
        output_lines << "Detecting invalid typographic quotes"
        output_lines << '-' * 80
        total_count = 0
        report.results.each do |(filename, instances)|
          output_lines << "File: #{ filename }"
          instances.each do |instance|
            total_count += 1
            output_lines << [
              " - #{ sprintf("line %5s", instance[:line]) }",
              " - #{ instance[:excerpt] }",
            ].join
          end
        end
        output_lines << "-" * 80
        output_lines << "Found #{ total_count } instances of invalid typographic quotes in #{ report.results.size } files."
        output_lines.each { |e| $stderr.puts e }
        report_file_path = File.join(config.base_dir(:reports_dir), 'invalid_typographic_quotes.txt')
        File.open(report_file_path, 'w') { |f|
          f.write "Invalid Typographic Quotes in Content\n"
          f.write '-' * 40
          f.write "\n"
          f.write output_lines.join("\n")
          f.write "\n"
          f.write "Command to generate this file: `repositext report invalid_typographic_quotes`\n"
        }
      end

      # Generates a report that counts all kramdown element class combinations it encounters.
      def report_kramdown_element_classes_inventory(options)
        file_count = 0
        class_combinations = {}
        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(
            options['base-dir'] || :content_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :at_extension
          ),
          options['file_filter'],
          nil,
          "Reading AT files",
          options
        ) do |content_at_file|
          # Since the kramdown parser is specified as module in Rtfile,
          # I can't use the standard kramdown API:
          # `doc = Kramdown::Document.new(contents, :input => 'kramdown_repositext')`
          # We have to patch a base Kramdown::Document with the root to be able
          # to convert it.
          root, _warnings = config.kramdown_parser(:kramdown).parse(content_at_file.contents)
          doc = Kramdown::Document.new('')
          doc.root = root
          doc_class_combinations = doc.to_report_kramdown_element_classes_inventory
          doc_class_combinations.each do |et, class_combinations_hash|
            class_combinations[et] ||= Hash.new(0)
            class_combinations_hash.each do |cc, count|
              class_combinations[et][cc] += count
            end
          end
          file_count += 1
        end
        lines = []
        class_combinations.each do |(ke_type, class_combinations_hash)|
          lines << " - #{ ke_type }:"
          class_combinations_hash.each do |(classes_combination, count)|
            lines << "   - #{ classes_combination }: #{ count }"
          end
        end
        lines.each { |e| $stderr.puts e }
        report_file_path = File.join(config.base_dir(:reports_dir), 'kramdown_element_classes_inventory.txt')
        File.open(report_file_path, 'w') { |f|
          f.write "Kramdown element classes inventory\n"
          f.write '-' * 40
          f.write "\n"
          f.write lines.join("\n")
          f.write "\n"
          f.write '-' * 40
          f.write "\n"
          f.write "Extracted combinations of kramdown element classes from #{ file_count } files at #{ Time.now.to_s }.\n\n"
          f.write "Command to generate this file: `repositext report kramdown_element_classes_inventory`\n"
        }
      end

      # Generates a report of all editor notes in content AT with more than
      # char_cutoff characters
      def report_long_editor_notes(options)
        total_file_count = 0
        total_editor_notes_count = 0
        long_editor_notes_count = 0
        long_editor_notes = []
        char_cutoff = 240

        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(
            options['base-dir'] || :content_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :at_extension
          ),
          options['file_filter'],
          nil,
          "Reading AT files",
          options
        ) do |content_at_file|
          total_file_count += 1
          str_sc = Kramdown::Utils::StringScanner.new(content_at_file.contents)
          while !str_sc.eos? do
            if(str_sc.skip_until(/(?=\[)/))
              start_line = str_sc.current_line_number
              if(editor_note = str_sc.scan(/\[[^\]]*\]/))
                total_editor_notes_count += 1
                num_chars = editor_note.length
                next  if num_chars < char_cutoff
                long_editor_notes_count += 1
                long_editor_notes << {
                  :filename => content_at_file.filename,
                  :line => start_line,
                  :editor_note => editor_note.truncate_in_the_middle(120),
                  :num_chars => num_chars,
                }
              else
                raise "Unbalanced bracket"
              end
            else
              str_sc.terminate
            end
          end
        end

        lines = [
          "Editor notes with more than #{ char_cutoff } characters",
          '-' * 40,
        ]
        long_editor_notes.each { |e|
          lines << " - #{ e[:filename].split('/').last } - line #{ e[:line] } - #{ e[:num_chars] } chars - #{ e[:editor_note].inspect }"
        }
        lines << '-' * 40
        lines << "Found #{ long_editor_notes_count } of #{ total_editor_notes_count } editor notes with more than #{ char_cutoff } chars in #{ total_file_count } files at #{ Time.now.to_s }."
        $stderr.puts
        lines.each { |l| $stderr.puts l }
        report_file_path = File.join(config.base_dir(:reports_dir), 'long_editor_notes.txt')
        File.open(report_file_path, 'w') { |f|
          f.write lines.join("\n")
          f.write "\n\n"
          f.write "Command to generate this file: `repositext report long_editor_notes`\n"
        }
      end

      # This report produces a list of discrepancies between the quote of the day
      # content and content AT.
      # In order to run this report, put the qotd test file into the following
      # location: <repo>/data/qotd_data.json
      def report_quote_of_the_day_discrepancies(options)
        # NOTE: The original test files contained Unicode BOM. I'm removing
        # that in the File.read.
        # Returns JSON with the following keys:
        # * pageid: 19848,
        # * title: "47-0412",
        # * publishdate: "2017-02-26T00:00:00",
        # * contents: "word word"
        qotd_records = JSON.parse(
          File.read(
            File.join(config.base_dir(:data_dir), 'qotd_data.json'),
            :encoding => 'bom|utf-8'
          ),
          symbolize_names: true
        )

        discrepancies = Repositext::Process::Report::QuoteOfTheDayDiscrepancies.new(
          qotd_records,
          content_type,
          content_type.language
        ).report

        discrepancy_groups = [
          [
            'Content',
            discrepancies.find_all { |e| :content == e[:type] }.sort { |a,b|
              a[:posting_date_time] <=> b[:posting_date_time]
            }
          ],
          [
            'Style',
            discrepancies.find_all { |e| :style == e[:type] }.sort { |a,b|
              a[:posting_date_time] <=> b[:posting_date_time]
            }
          ],
          [
            'Subtitle',
            discrepancies.find_all { |e| :subtitle == e[:type] }.sort { |a,b|
              a[:posting_date_time] <=> b[:posting_date_time]
            }
          ],
        ]
        group_counts = discrepancy_groups.map { |heading, discrepncs|
          [discrepncs.count, heading].join(' ')
        }.join(', ')
        $stderr.puts "Quote Of The Day discrepancies"
        $stderr.puts "-" * 40
        discrepancy_groups.each do |heading, discrepncs|
          $stderr.puts "#{ heading } discrepancies:".color(:blue)
          discrepncs.each { |qotd_record|
            $stderr.puts
            $stderr.puts " - #{ qotd_record[:date_code] }, #{ qotd_record[:posting_date_time] }, #{ qotd_record[:type] }:".color(:blue)
            $stderr.puts "   - QOTD:".color(:blue)
            $stderr.puts "     #{ qotd_record[:qotd_content] }"
            $stderr.puts "   - Repositext:".color(:blue)
            $stderr.puts "     #{ qotd_record[:content_at_content] }"
          }
        end
        $stderr.puts "-" * 40
        $stderr.puts "Found #{ group_counts } discrepancies in #{ qotd_records.length } QOTDs."
        # Write date codes and posting_times to report file
        report_file_path = File.join(config.base_dir(:reports_dir), 'quote_of_the_day_discrepancies.txt')
        File.open(report_file_path, 'w') { |f|
          f.write "QOTD discrepancies\n"
          f.write '-' * 40
          f.write "\n"
          discrepancy_groups.each do |heading, discrepncs|
            f.write "\n#{ heading }:\n\n"
            discrepncs.each do |d|
              f.write d[:date_code]
              f.write "\t"
              f.write d[:posting_date_time]
              f.write "\n"
            end
          end
          f.write '-' * 40
          f.write "\n"
          group_counts = discrepancy_groups.map { |heading, discrepncs|
            [discrepncs.count, heading].join(' ')
          }.join(', ')
          f.write "Found #{ group_counts } discrepancies in #{ qotd_records.length } QOTDs.\n"
          f.write "Command to generate this file: `repositext report quote_of_the_day_discrepancies`\n"
        }
      end

      def report_quotes_details(options)
        output_lines = []
        ["'", '"'].each { |quote_char|
          output_lines << "Detecting #{ quote_char } quotes"
          output_lines << '-' * 80
          instances = find_all_quote_instances(quote_char, options)
          sequences = {}
          instances.each do |attrs|
            # normalize key
            key = compute_sequence_key(attrs[:pre], quote_char, attrs[:post])
            # add to hash
            sequences[key] ||= []
            extract = "#{ attrs[:pre] }#{ quote_char }#{ attrs[:post] }".gsub(/\n/, '\\n')
            sequences[key] << { :extract => extract, :filename => attrs[:filename] }
          end
          quote_instances_count = 0
          sequences.to_a.sort { |a,b| a.first <=> b.first }.each do |(key, instncs)|
            instncs.each { |quote_instance|
              output_lines << " #{ key } - #{ quote_instance[:extract].ljust(45, ' ') } - #{ quote_instance[:filename] }"
              quote_instances_count += 1
            }
          end
          output_lines << "-" * 80
          output_lines << "Found #{ quote_instances_count } #{ quote_char } quotes in #{ sequences.size } distinct character sequences."
          output_lines << ''
        }
        output_lines.each { |e| $stderr.puts e }
        report_file_path = File.join(config.base_dir(:reports_dir), 'content_quotes_details.txt')
        File.open(report_file_path, 'w') { |f|
          f.write "Quotes Details in Content\n"
          f.write '-' * 40
          f.write "\n"
          f.write output_lines.join("\n")
          f.write "\n"
          f.write "Command to generate this file: `repositext report quotes_details`\n"
        }
      end

      def report_quotes_summary(options)
        output_lines = []
        ["'", '"'].each { |quote_char|
          output_lines << "Detecting #{ quote_char } quotes"
          output_lines << '-' * 80
          instances = find_all_quote_instances(quote_char, options)
          sequences = {}
          instances.each do |attrs|
            # normalize key
            key = compute_sequence_key(attrs[:pre], quote_char, attrs[:post])
            # add to hash
            sequences[key] ||= { :pre => nil, :post => nil, :count => 0 }
            sequences[key][:count] += 1
            sequences[key][:pre] = attrs[:pre]
            sequences[key][:post] = attrs[:post]
          end
          quote_instances_count = 0
          sequences.to_a.sort { |a,b| a.first <=> b.first }.each do |(key, attrs)|
            example = "#{ attrs[:pre] }#{ quote_char }#{ attrs[:post] }".gsub(/\n/, '\\n')
            output_lines << " #{ key }    - #{ example.ljust(50, ' ') }   - #{ attrs[:count] }"
            quote_instances_count += attrs[:count]
          end
          output_lines << "-" * 80
          output_lines << "Found #{ quote_instances_count } #{ quote_char } quotes in #{ sequences.size } distinct character sequences."
          output_lines << ''
        }
        output_lines.each { |e| $stderr.puts e }
        report_file_path = File.join(config.base_dir(:reports_dir), 'content_quotes_summary.txt')
        File.open(report_file_path, 'w') { |f|
          f.write "Quotes Summary in Content\n"
          f.write '-' * 40
          f.write "\n"
          f.write output_lines.join("\n")
          f.write "\n"
          f.write "Command to generate this file: `repositext report quotes_summary`\n"
        }
      end

      # Reports where record boundaries are located (inside paragraphs or spans)
      def report_record_boundary_locations(options)
        file_count = 0
        record_boundary_locations = { root: 0, paragraph: 0, span: 0 }
        comments = []
        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(
            options['base-dir'] || :content_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :at_extension
          ),
          options['file_filter'],
          nil,
          "Reading content AT files",
          options
        ) do |content_at_file|
          outcome = Repositext::Process::Report::RecordBoundaryLocations.new(
            content_at_file,
            config.kramdown_parser(:kramdown)
          ).report
          if outcome.success?
            $stderr.puts "   - analyzed #{ content_at_file.basename }"
            srbls = outcome.result
            record_boundary_locations.keys.each { |key|
              record_boundary_locations[key] += srbls[key]
            }
            comments += outcome.messages.map { |e| [content_at_file.basename, e].join(': ') }
          else
            $stderr.puts "   - skipped #{ content_at_file.basename }"
          end
          file_count += 1
        end
        $stderr.puts "Record Boundary Locations"
        $stderr.puts "-" * 40
        record_boundary_locations.keys.each { |context|
          $stderr.puts " - #{ context }: #{ record_boundary_locations[context] }"
        }
        if comments.any?
          $stderr.puts "-" * 40
          comments.each { |comment|
            $stderr.puts " - #{ comment }"
          }
        end
      end

      # Reports anomalies and stats in the latest st-ops file.
      def report_st_ops_file_analysis(options)
        $stderr.puts "st-ops file analysis:".color(:blue)
        $stderr.puts "-" * 40
        st_ops_file_path = Subtitle::OperationsFile.find_latest(
          config.base_dir(:subtitle_operations_dir)
        )
        if st_ops_file_path.nil?
          $stderr.puts "No st-ops file found, aborting.".color(:red)
        end
        $stderr.puts " - Loading st-ops file at #{ st_ops_file_path }"
        st_ops_for_repository = Subtitle::OperationsForRepository.from_json(
          File.read(st_ops_file_path),
          repository.base_dir
        )
        r = {
          files_count: 0,
          ops_type_counts: Hash.new(0),
          ops_type_signatures: {
            delete: Hash.new(0),
            insert: Hash.new(0),
            merge: Hash.new(0),
            move_left: Hash.new(0),
            move_right: Hash.new(0),
            split: Hash.new(0),
          },
          st_ops_count: 0,
          unexpected_ops: [],
        }
        st_ops_for_repository.operations_for_files.each do |st_ops_for_file|
          r[:files_count] += 1
          # Record ops_type_signatures
          st_ops_for_file.operations.each do |st_op|
            r[:st_ops_count] += 1
            type_signature = st_op.operation_type.to_sym
            r[:ops_type_counts][type_signature] += 1
            ins_del_signature = st_op.affected_stids.map { |e|
              # Mark unchanged/existing st as :noc, added as :add, and deleted as :del
              case ['' == e.tmp_attrs[:before], '' == e.tmp_attrs[:after]]
              when [false, false]
                # No subtitles were added or deleted
                :noc
              when [false, true]
                # before is present, after is blank
                :del
              when [true, false]
                # before is blank, after is present
                :add
              else
                # both before and after are blank. Shouldn't happen!
                raise "Handle this: #{ st_op.to_hash }"
              end
            }
            # Record unexpected ops
            if :merge == type_signature && [:noc, :del] != ins_del_signature.uniq
              r[:unexpected_ops] << [
                "\nFirst st was deleted in merge:\n".color(:red),
                "File: #{ st_ops_for_file.content_at_file.filename }",
                st_op.print_pretty,
              ].join("\n")
            end
            r[:ops_type_signatures][type_signature][ins_del_signature] += 1
          end
        end
        $stderr.puts
        $stderr.puts " - File count: #{ r[:files_count] }".color(:blue)
        $stderr.puts " - Subtitle operations count: #{ r[:st_ops_count] }".color(:blue)

        $stderr.puts " - Operation signatures:".color(:blue)
        r[:ops_type_signatures].each { |ops_type, ins_del_signatures|
          $stderr.puts "   - #{ ops_type.inspect }: #{ r[:ops_type_counts][ops_type] }"
          ins_del_signatures.each { |ins_del_sig, count|
            $stderr.puts "     - #{ ins_del_sig.inspect}: #{ count }"
          }
        }

        $stderr.puts " - Unexpected operations:".color(:red)
        r[:unexpected_ops].each { |op| $stderr.puts op }
      end

      # Finds .stanza paragraphs that are not followed by .song paragraphs
      def report_stanza_without_song_paragraphs(options)
        file_count = 0
        stanza_without_song_paragraph_files = []
        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(
            options['base-dir'] || :content_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :at_extension
          ),
          options['file_filter'],
          nil,
          "Reading content AT files",
          options
        ) do |content_at_file|
          outcome = Repositext::Process::Report::StanzaWithoutSongParagraphs.new(
            content_at_file,
            config.kramdown_parser(:kramdown)
          ).report
          stanza_without_song_paragraph_files << outcome.result
          file_count += 1
        end
        $stderr.puts "Stanza without Song paragraphs"
        $stderr.puts "-" * 40
        stanza_without_song_paragraph_files.each do |swsf|
          next  if swsf[:stanzas_without_song].empty?
          $stderr.puts " - #{ swsf[:filename] }"
          swsf[:stanzas_without_song].each do |sws|
            $stderr.puts "   - line #{ sws[:line] }: "
            sws[:para_class_sequence].each do |p|
              $stderr.puts "     - #{ p }"
            end
          end
        end
      end

      # Computes stats for the latest st-ops file
      def report_st_ops_file_stats(options)
        latest_st_ops_file_path = Subtitle::OperationsFile.find_latest(
          config.base_dir(:subtitle_operations_dir)
        )
        st_ops_json_string = File.read(latest_st_ops_file_path)

        operations = Hash.new(0)
        # Match lines like `      "operation_type": "content_change",`
        st_ops_json_string.scan(/^\s+"operation_type": "([^"]+)"/) { |match|
          # match example: ["insert"]
          operations[match.first] += 1
        }

        l = ['']
        l << "st-ops file stats".color(:blue)
        l << ("=" * 24).color(:blue)
        l << "File: #{ latest_st_ops_file_path }"
        l << "Size: #{ (File.size(latest_st_ops_file_path).to_f / 2**20).round } MB"
        l << ''
        l << "Operations:"
        l << "-" * 24
        operations.to_a.sort { |(k_a, _v_a),(k_b, _v_b)|
          k_a <=> k_b
        }.each { |k,v|
          number_with_delimiter = v.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
          l << "#{ k.ljust(16) } #{ number_with_delimiter.rjust(7) }"
        }
        l << "-" * 24
        total_ops_count = operations.values.inject(0) { |m,v| m += v; m }
        l << "Total: #{ total_ops_count.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse.rjust(17) }"
        l << ''

        l.each { |e| $stderr.puts e }
      end

      # Prints an inventory of all words found in the current language, sorted
      # by word frequency and alphabetically.
      def report_terms_inventory(options)
        terms = Hash.new(0)
        total_file_count = 0
        lines = []

        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(
            options['base-dir'] || :content_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :at_extension
          ),
          options['file_filter'],
          nil,
          "Reading content AT files",
          options
        ) do |content_at_file|
          total_file_count += 1

          # Build character inventory
          content_at_file.plain_text_contents({}).split(/[^[[:word:]]]+/).each { |term|
            terms[term.unicode_downcase] += 1
          }
        end

        lines << "Terms inventory for #{ content_type.language_name }"
        lines << "=================================="
        lines << ''
        lines << 'Sorted by frequency first'
        lines << '-------------------------'
        sorted_by_freq = terms.sort { |(term_a, freq_a), (term_b, freq_b)|
          [freq_a, term_a] <=> [freq_b, term_b]
        }
        longest_freq = sorted_by_freq.map(&:first).max.to_s.length
        sorted_by_freq.each { |term, freq|
          lines << "#{ freq.to_s.rjust(longest_freq) } #{ term }"
        }
        lines << ''
        lines << 'Sorted alphabetically'
        lines << '---------------------'
        sorted_alpha = terms.sort { |(term_a, _freq_a), (term_b, _freq_b)|
          term_a <=> term_b
        }
        longest_term = sorted_alpha.map { |term, freq| term.length }.max
        sorted_alpha.each { |term, freq|
          lines << "#{ term.to_s.ljust(longest_term) } #{ freq }"
        }
        lines << ''
        lines << '-' * 40
        lines << "Found #{ terms.count } terms in #{ total_file_count } files at #{ Time.now.to_s }."

        $stderr.puts
        lines.each { |e| $stderr.puts(e) }
        report_file_path = File.join(config.base_dir(:reports_dir), 'terms_inventory_report.txt')
        File.open(report_file_path, 'w') { |f|
          f.write lines.join("\n")
          f.write "\n\n"
          f.write "Command to generate this file: `repositext report terms_inventory`\n"
        }
      end

      def report_words_with_apostrophe(options)
        # TODO: add report that shows all words starting with apostrophe that have only one character
        apostrophe_at_beginning = {}
        apostrophe_in_the_middle = {}
        other = {}
        output_lines = []
        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(
            options['base-dir'] || :folio_import_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :at_extension
          ),
          /\.folio\.at\Z/i,
          nil,
          "Reading folio at files",
          options
        ) do |content_at_file|
          # iterate over all single quotes followed by a character
          content_at_file.contents.scan(/(.{0,20})('(?=\w))(\w{0,20})/m) { |(pre, s_quote, post)|
            bin = nil
            # process key
            if pre.length > 0 && pre[-1] =~ /[^\w]/
              # at beginning of word
              l_pre = pre.rjust(4, ' ')[-4..-1]
              key = [s_quote, post].compact.join
              #key = [l_pre, s_quote, post].compact.join
              bin = apostrophe_at_beginning
            elsif pre.length > 0 && pre[-1] =~ /\w/
              # inside a word
              l_pre = pre.match(/\w+\z/)
              key = [l_pre, s_quote, post].compact.join
              bin = apostrophe_in_the_middle
            else
              # other
              key = [pre, s_quote, post].compact.join
              bin = other
            end
            key = key.downcase.ljust(20, ' ')

            # add to hash
            bin[key] ||= 0
            bin[key] += 1
          }
        end
        output_lines << "-" * 80
        output_lines << "Words starting with apostrophe."
        apostrophe_at_beginning.to_a.sort { |a,b| a.first <=> b.first }.each do |(key, count)|
          output_lines << " #{ key } - #{ count }"
        end
        output_lines << "-" * 80
        output_lines << "Words containing apostrophe."
        apostrophe_in_the_middle.to_a.sort { |a,b|
          # sort first by post, then by pre
          a_pre, a_post = a.first.split("'")
          b_pre, b_post = b.first.split("'")
          [a_post.strip, a_pre.strip] <=> [b_post.strip, b_pre.strip]
        }.each do |(key, count)|
          output_lines << " #{ key } - #{ count }"
        end
        output_lines << "-" * 80
        output_lines << "Others."
        other.to_a.sort { |a,b| a.first <=> b.first }.each do |(key, count)|
          output_lines << " #{ key } - #{ count }"
        end
        output_lines.each { |e| $stderr.puts e }
        report_file_path = File.join(config.base_dir(:reports_dir), 'words_with_apostrophe.txt')
        File.open(report_file_path, 'w') { |f|
          f.write "Words with Apostrophe in Folio import\n"
          f.write '-' * 40
          f.write output_lines.join("\n")
          f.write "\n"
          f.write "Command to generate this file: `repositext report words_with_apostrophe`\n"
        }
      end

    private

      # Detects and counts quote instances. Returns an array of hashes with an entry
      # for each quote instance in the following form:
      # [
      #   { :pre => 'text before quote', :post => 'text after quote', :filename => 'path to file' },
      # ]
      # {
      #   '.".' => { :pre => 'text before quote', :post => 'text after quote', :count => 42 },
      #   ...
      # }
      # @param [String] quote_char the type of quote to detect
      # @param [Hash] options
      def find_all_quote_instances(quote_char, options)
        instances = []
        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(
            options['base-dir'] || :content_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :at_extension
          ),
          options['file_filter'],
          nil,
          "Reading content AT files",
          options
        ) do |contents, filename|
          # iterate over all straight quotes
          # Don't include straight quotes inside IALs (remove all ials)
          contents.gsub(/\{[^\{\}]*\}/, ' ')
                  .scan(/(.{0,20})((?<!\=)#{ quote_char }(?!\}))(.{0,20})/m) { |(pre, _quote, post)|
            # add to array
            instances << { :pre => pre, :post => post, :filename => filename }
          }
        end
        instances
      end

      def compute_sequence_key(pre, quote_char, post)
        key = [pre[-1], quote_char, post[0]].compact.join
        key.gsub!(/^[a-zA-Z]/, 'a') # Replace all leading chars with 'a'
        key.gsub!(/[a-zA-Z]$/, 'z') # Replace all trailing chars with 'z'
        key.downcase!
        # Make non-printable chars visible
        key = key.inspect
        key.gsub!(/^\"/, '') # Remove leading double quotes (from inspect)
        key.gsub!(/\"$/, '') # Remove trailing double quotes (from inspect)
        key.gsub!(/\\"/, '"') # Unescape double quotes
        key.ljust(8, ' ') # pad on the right with space for tabular display
      end

      # Returns a hash with the titles from ERP with the date code as keys
      def load_titles_from_erp
        # Expects pwd to be root of the current repo
        filename = File.expand_path('data/titles_from_erp.csv', Dir.pwd)
        h = {}
        CSV.foreach(filename, { col_sep: "\t", headers: :first_row }) do |row|
          if row['ProductID'].nil?
            raise "Please remove space from ProductID column header in csv file #{filename}"
          end
          h[row['ProductID'].downcase] = {
            date_code: row['ProductID'].downcase,
            product_identity_id: row['ProductIdentityID'],
            title: row['ProductTitle']
          }
        end
        h
      end

      def report_variants
        %w[
          compare_file_inventory_with_erp
          content_sources
          count_files_with_gap_marks_and_subtitle_marks
          count_subtitle_marks
          files_with_multi_para_editors_notes
          files_with_subtitles
          gap_mark_count
          invalid_eagles
          invalid_typographic_quotes
          kramdown_element_classes_inventory
          long_editor_notes
          quotes_details
          quotes_summary
        ]
      end

    end
  end
end
