class Repositext
  class Cli
    # This namespace contains methods related to the `report` command.
    # These are one time reports that we'll likely never user again.
    module Report

    private

      # Generates a list of how each file in content AT was sourced (Folio or Idml)
      def report_content_sources(options)
        content_base_dir = config.base_dir(:content_dir)
        docx_import_base_dir = config.base_dir(:docx_import_dir)
        folio_import_base_dir = config.base_dir(:folio_import_dir)
        idml_import_base_dir = config.base_dir(:idml_import_dir)
        total_count = 0
        docx_sourced = []
        folio_sourced = []
        idml_sourced = []
        other_sourced = []

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
        ) do |contents, filename|
          total_count += 1
          docx_input_filename = filename.gsub(content_base_dir, docx_import_base_dir)
                                        .gsub(/\.at/, '.docx.at')
          folio_input_filename = filename.gsub(content_base_dir, folio_import_base_dir)
                                         .gsub(/\.at/, '.folio.at')
          idml_input_filename = filename.gsub(content_base_dir, idml_import_base_dir)
                                        .gsub(/\.at/, '.idml.at')
          if File.exists?(idml_input_filename)
            idml_sourced << filename
          elsif File.exists?(folio_input_filename)
            folio_sourced << filename
          elsif File.exists?(docx_input_filename)
            docx_sourced << filename
          else
            other_sourced << filename
          end
        end

        lines = [
          "List sources of content_at files",
          '-' * 40,
        ]
        if idml_sourced.any?
          lines << " - The following #{ idml_sourced.length } content AT files are sourced from Idml:"
          idml_sourced.each do |f|
            lines << "   - #{ f }"
          end
        else
          lines << " - There are no content AT files sourced from Idml."
        end
        if folio_sourced.any?
          lines << " - The following #{ folio_sourced.length } content AT files are sourced from Folio:"
          folio_sourced.each do |f|
            lines << "   - #{ f }"
          end
        else
          lines << " - There are no content AT files sourced from Folio."
        end
        if docx_sourced.any?
          lines << " - The following #{ docx_sourced.length } content AT files are sourced from DOCX:"
          docx_sourced.each do |f|
            lines << "   - #{ f }"
          end
        else
          lines << " - There are no content AT files sourced from DOCX."
        end
        if other_sourced.any?
          lines << " - The following #{ folio_sourced.length } content AT files are from other sources:"
          other_sourced.each do |f|
            lines << "   - #{ f }"
          end
        else
          lines << " - There are no content AT files from other sources."
        end
        lines << '-' * 40
        lines << "Sources summary:"
        lines << " - DOCX: #{ docx_sourced.length }"
        lines << " - Folio: #{ folio_sourced.length }"
        lines << " - Idml: #{ idml_sourced.length }"
        lines << " - Other: #{ other_sourced.length }"
        total_sourced = docx_sourced.length + folio_sourced.length + idml_sourced.length + other_sourced.length
        lines << "Determined sources for #{ total_sourced } of #{ total_count } files at #{ Time.now.to_s }."
        $stderr.puts
        lines.each { |l| $stderr.puts l }
        report_file_path = File.join(config.base_dir(:reports_dir), 'content_sources.txt')
        File.open(report_file_path, 'w') { |f|
          f.write lines.join("\n")
          f.write "\n\n"
          f.write "Command to generate this file: `repositext report content_sources`\n"
        }
      end

      # Reports content data.json files that have invalid st_sync_commits,
      # e.g., not aligned with from/to commits of st_ops files.
      def report_data_json_files_with_unexpected_st_sync_commits(options)
        invalid_files = []
        total_file_count = 0

        primary_config = if config.setting(:is_primary_repo)
          config
        else
          content_type.corresponding_primary_content_type.config
        end
        git_commits_from_st_ops_files = Subtitle::OperationsFile.get_sync_commits(
          primary_config.base_dir(:subtitle_operations_dir)
        )

        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(
            options['base-dir'] || :content_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :json_extension
          ),
          options['file_filter'],
          nil,
          "Reading data.json files",
          options.merge(
            use_new_repositext_file_api: true,
            content_type: content_type,
          )
        ) do |data_json_file|
          total_file_count += 1
          st_sync_commit = data_json_file.read_data['st_sync_commit']
          next  if '' == st_sync_commit.to_s
          truncated_commit_sha = Subtitle::OperationsFile.truncate_git_commit_sha1(st_sync_commit)
          next  if git_commits_from_st_ops_files.include?(truncated_commit_sha)
          # We found an unexpected st_sync_commit
          invalid_files << {
            filename: data_json_file.repo_relative_path(true),
            unexpected_st_sync_commit: st_sync_commit
          }
        end

        if invalid_files.any?
          $stderr.puts "\n\n"
          $stderr.puts "Found #{ invalid_files.length } data.json files with unexpected st_sync_commits in total of #{ total_file_count } files at #{ Time.now.to_s }:"
          $stderr.puts '-' * 40
          invalid_files.each { |f_attrs|
            $stderr.puts " * #{ f_attrs[:filename].ljust(70, ' ') } - (#{ f_attrs[:unexpected_st_sync_commit] })"
          }
        end
        $stderr.puts '-' * 40
        $stderr.puts "Command to generate this file: `repositext report data_json_files_with_unexpected_st_sync_commits`\n"
      end

      # Reports files that contain editors notes with multiple paragraphs
      def report_files_with_multi_para_editors_notes(options)
        multi_para_editors_notes = []
        total_file_count = 0
        mpen_files_count = 0

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
        ) do |contents, filename|
          total_file_count += 1
          mpen = contents.scan(/(\[[^\]]+\n[^\]]+\])/)
          if mpen.any?
            mpen_files_count += 1
            $stderr.puts " - #{ filename }"
          end
          mpen.each do |match|
            multi_para_editors_notes << { filename: filename, contents: match }
            $stderr.puts "   - #{ match.inspect }"
          end
        end

        summary_line = "Found #{ multi_para_editors_notes.length } editors notes with multiple paragraphs in #{ mpen_files_count } of #{ total_file_count } files at #{ Time.now.to_s }."
        $stderr.puts summary_line
        report_file_path = File.join(config.base_dir(:reports_dir), 'files_with_multi_para_editors_notes.txt')
        File.open(report_file_path, 'w') { |f|
          f.write "Files with long editors notes\n"
          f.write '-' * 40
          f.write "\n"
          f.write multi_para_editors_notes.join("\n")
          f.write "\n"
          f.write '-' * 40
          f.write "\n"
          f.write summary_line
          f.write "\n\n"
          f.write "Command to generate this file: `repositext report files_with_multi_para_editors_notes`\n"
        }
      end

      # Generate summary of folio import warnings
      def report_folio_import_warnings(options)
        uniq_warnings = Hash.new(0)
        file_count = 0
        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(
            options['base-dir'] || :folio_import_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :json_extension
          ),
          /\.folio.warnings\.json\Z/i,
          nil,
          "Reading folio import warnings",
          options
        ) do |contents, filename|
          warnings = JSON.parse(contents)
          warnings.each do |warning|
            message_stub = warning['message'].split(':').first || ''
            uniq_warnings[message_stub] += 1
          end
          file_count += 1
        end
        w = []
        uniq_warnings.to_a.sort { |a,b| a.first <=> b.first }.each do |(message, count)|
          l = " - #{ message }: #{ count }"
          $stderr.puts l
          w << l
        end
        report_file_path = File.join(config.base_dir(:reports_dir), 'folio_import_warnings_summary.txt')
        File.open(report_file_path, 'w') { |f|
          f.write "Folio Import Warnings Summary\n"
          f.write '-' * 40
          f.write "\n"
          f.write w.join("\n")
          f.write "\n"
          f.write '-' * 40
          f.write "\n"
          f.write "Found #{ w.length } warnings in #{ file_count } files at #{ Time.now.to_s }.\n\n"
          f.write "Command to generate this file: `repositext report folio_import_warnings`\n"
        }
      end

      # Prints report with all words that contain 'oe' and their counts
      def report_inventory_of_words_with_oe(options)
        file_count = 0
        words_with_oe = Hash.new(0)
        word_with_oe_regex = /\b\w{0,100}oe\w{0,100}\b/i
        before_word_with_oe_regex = /(?=#{ word_with_oe_regex })/

        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(
            options['base-dir'] || :content_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :at_extension
          ),
          options['file_filter'],
          nil,
          "Reading Content AT files",
          options
        ) do |contents, filename|
          file_count += 1
          # Extract words with oe
          str_sc = Kramdown::Utils::StringScanner.new(contents)
          while !str_sc.eos? do
            if(str_sc.skip_until(before_word_with_oe_regex))
              word_with_oe = str_sc.scan(word_with_oe_regex)
              next  if '' == word_with_oe
              words_with_oe[word_with_oe] += 1
            else
              str_sc.terminate
            end
          end
        end

        $stderr.puts 'Words with oe'
        $stderr.puts '-' * 40
        words_with_oe.to_a.sort.each { |e|
          $stderr.puts "#{ e.first }: #{ e.last }"
        }
        $stderr.puts '-' * 40
        $stderr.puts "Checked #{ file_count } files at #{ Time.now.to_s }."
        $stderr.puts "Command to generate this file: `repositext report inventory_of_words_with_oe`"
      end

      # Generate summary of paragraphs with class `q` where the contained span
      # is not aligned with the para. In other words: question paras that contain
      # text outside of the span.
      def report_misaligned_question_paragraphs(options)
        file_count = 0
        misaligned_paras = []
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
          # parse AT, find all paras with q, analyze inner
          # Since the kramdown parser is specified as module in Rtfile,
          # I can't use the standard kramdown API:
          # `doc = Kramdown::Document.new(contents, :input => 'kramdown_repositext')`
          # We have to patch a base Kramdown::Document with the root to be able
          # to convert it.
          root, warnings = config.kramdown_parser(:kramdown).parse(contents)
          doc = Kramdown::Document.new('')
          doc.root = root
          misaligned_paras += doc.to_report_misaligned_question_paragraphs.map { |mp|
            mp[:location] = filename
            mp
          }
          file_count += 1
        end
        misaligned_paras.each do |mp|
          $stderr.puts " - #{ mp }"
        end
        report_file_path = File.join(config.base_dir(:reports_dir), 'misaligned_question_paragraphs.txt')
        File.open(report_file_path, 'w') { |f|
          f.write "Misaligned question paragraphs\n"
          f.write "\n"
          misaligned_paras.each do |mp|
            f.write '-' * 40
            f.write "\n"
            f.write mp[:location]
            f.write "\n"
            f.write mp[:source]
          end
          f.write "\n"
          f.write '-' * 40
          f.write "\n"
          f.write "Found #{ misaligned_paras.length } paragraphs in #{ file_count } files at #{ Time.now.to_s }.\n\n"
          f.write "Command to generate this file: `repositext report misaligned_question_paragraphs`\n"
        }
      end

    end
  end
end
