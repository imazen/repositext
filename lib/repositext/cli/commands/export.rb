class Repositext
  class Cli
    # This namespace contains methods related to the `export` command.
    module Export

    private

      # Export AT files in `/content` for Gap mark tagging.
      def export_gap_mark_tagging(options)
        input_base_dir = config.compute_base_dir(options['base-dir'] || :content_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        input_file_extension = config.compute_file_extension(options['file-extension'] || :at_extension)
        output_base_dir = options['output'] || config.base_dir(:gap_mark_tagging_export_dir)
        Repositext::Cli::Utils.export_files(
          input_base_dir,
          input_file_selector,
          input_file_extension,
          output_base_dir,
          options['file_filter'],
          "Exporting AT files to gap_mark tagging",
          options.merge(
            :output_path_lambda => lambda { |input_filename, output_file_attrs|
              input_filename.gsub(input_base_dir, output_base_dir)
                            .gsub(/\.at\z/, '.gap_mark_tagging.txt')
            }
          )
        ) do |contents, filename|
          outcome = Repositext::Process::Export::GapMarkTagging.new(contents).export
          if outcome.success?
            [Outcome.new(true, { contents: outcome.result, extension: 'gap_mark_tagging.txt' })]
          else
            outcome
          end
        end
      end

      # Export AT files in `/content` to ICML.
      def export_icml(options)
        input_base_dir = config.compute_base_dir(options['base-dir'] || :content_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        input_file_extension = config.compute_file_extension(options['file-extension'] || :at_extension)
        output_base_dir = options['output'] || config.base_dir(:icml_export_dir)
        Repositext::Cli::Utils.export_files(
          input_base_dir,
          input_file_selector,
          input_file_extension,
          output_base_dir,
          options['file_filter'],
          "Exporting AT files to ICML",
          options
        ) do |contents, filename|
          # We first convert AT to plain markdown to remove record_marks,
          # subtitle_marks, and gap_marks which aren't supported by ICML.
          md = convert_at_string_to_plain_markdown(contents)
          # Since the kramdown parser is specified as module in Rtfile,
          # I can't use the standard kramdown API:
          # `doc = Kramdown::Document.new(contents, :input => 'kramdown_repositext')`
          # We have to patch a base Kramdown::Document with the root to be able
          # to convert it.
          root, warnings = config.kramdown_parser(:kramdown).parse(md)
          doc = Kramdown::Document.new('')
          doc.root = root
          icml = doc.send(config.kramdown_converter_method(:to_icml))
          [Outcome.new(true, { contents: icml, extension: 'icml' })]
        end
      end

      # Export AT files in `/content` to plain kramdown (no record_marks,
      # subtitle_marks, or gap_marks)
      def export_plain_kramdown(options)
        input_base_dir = config.compute_base_dir(options['base-dir'] || :content_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        input_file_extension = config.compute_file_extension(options['file-extension'] || :at_extension)
        output_base_dir = options['output'] || config.base_dir(:plain_kramdown_export_dir)
        Repositext::Cli::Utils.export_files(
          input_base_dir,
          input_file_selector,
          input_file_extension,
          output_base_dir,
          options['file_filter'],
          "Exporting AT files to plain kramdown",
          options
        ) do |contents, filename|
          md = convert_at_string_to_plain_markdown(contents)
          [Outcome.new(true, { contents: md, extension: '.md' })]
        end
      end


      # Export AT files in `/content` to plain text
      def export_plain_text(options)
        input_base_dir = config.compute_base_dir(options['base-dir'] || :content_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        input_file_extension = config.compute_file_extension(options['file-extension'] || :at_extension)
        output_base_dir = options['output'] || config.base_dir(:plain_text_export_dir)
        Repositext::Cli::Utils.export_files(
          input_base_dir,
          input_file_selector,
          input_file_extension,
          output_base_dir,
          options['file_filter'],
          "Exporting AT files to plain text",
          options
        ) do |contents, filename|
          # Since the kramdown parser is specified as module in Rtfile,
          # I can't use the standard kramdown API:
          # `doc = Kramdown::Document.new(contents, :input => 'kramdown_repositext')`
          # We have to patch a base Kramdown::Document with the root to be able
          # to convert it.
          root, warnings = config.kramdown_parser(:kramdown).parse(contents)
          doc = Kramdown::Document.new('')
          doc.root = root
          txt = doc.send(config.kramdown_converter_method(:to_plain_text))
          [Outcome.new(true, { contents: txt, extension: 'txt' })]
        end
      end

      # Export content AT files in `/content` to plain text for autosplitting
      def export_plain_text_for_st_autosplit(options)
        input_base_dir = config.compute_base_dir(options['base-dir'] || :content_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        input_file_extension = config.compute_file_extension(options['file-extension'] || :at_extension)
        output_base_dir = options['output'] || config.base_dir(:autosplit_subtitles_dir)
        Repositext::Cli::Utils.export_files(
          input_base_dir,
          input_file_selector,
          input_file_extension,
          output_base_dir,
          options['file_filter'],
          "Exporting AT files to plain text for subtitle autosplit",
          options.merge(
            use_new_repositext_file_api: true,
            content_type: content_type,
          )
        ) do |content_at_file|
          st_as_ctxt = content_at_file.is_primary? ? :for_lf_aligner_primary : :for_lf_aligner_foreign
          txt = content_at_file.plain_text_for_st_autosplit_contents(
            st_autosplit_context: st_as_ctxt
          )
          [Outcome.new(true, { contents: txt, extension: 'txt' })]
        end
      end

      # Export Subtitle files. Behavior depends on whether we are in
      # * English:
      #     * Export subtitle_export/61/61-0723e_0794.en.txt
      #     * Copy 61/eng61-0723e_0794.subtitle_markers.csv
      # * Foreign calls itself recursively to obtain the following:
      #     * Export subtitle_export/61/61-0723e_0794.es.txt
      #     * Export subtitle_export/61/61-0723e_0794.en.txt
      #     * Copy 61/eng61-0723e_0794.subtitle_markers.csv
      def export_subtitle(options)
        if options['file-selector'] =~ /[a-z]{3}\d{2}-\d{4}/i
          # File selector contains language code (e.g., "*spn57-0123*"). This
          # prevents foreign subtitle exports from working as we also need to
          # export the corresponding primary files, however they will never
          # be processed as they don't match the file selector.
          raise ArgumentError.new("\nPlease don't add language codes to the file selector since export may have to run on primary and foreign languages: #{ options['file-selector'].inspect }")
        end
        files_that_could_not_be_exported_because_they_require_st_sync = []
        input_base_dir = config.compute_base_dir(options['base-dir'] || :content_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        input_file_extension = config.compute_file_extension(options['file-extension'] || :at_extension)
        output_base_dir = options['output'] || config.base_dir(:subtitle_export_dir)
        primary_repo = content_type.corresponding_primary_content_type.repository
        st_sync_commit_sha1 = primary_repo.read_repo_level_data['st_sync_commit']
        Repositext::Cli::Utils.export_files(
          input_base_dir,
          input_file_selector,
          input_file_extension,
          output_base_dir,
          options['file_filter'],
          "Exporting AT files to subtitle",
          options.merge(
            output_path_lambda: lambda { |input_filename, output_file_attrs|
              Repositext::Utils::SubtitleFilenameConverter.convert_from_repositext_to_subtitle_export(
                input_filename.gsub(input_base_dir, output_base_dir),
                output_file_attrs
              )
            },
            use_new_repositext_file_api: true,
            content_type: content_type,
          )
        ) do |content_at_file|
          config.update_for_file(content_at_file.corresponding_data_json_filename)
          file_st_sync_is_active = config.setting(:st_sync_active)

          if file_st_sync_is_active
            # Make sure primary file (or foreign file's corresponding primary file)
            # does not require a subtitle sync.
            # Reason: We want to make sure that foreign subtitle splitters get
            # the most recent English version to work with.
            self_or_corresponding_primary_file = content_at_file.corresponding_primary_file
            if self_or_corresponding_primary_file.read_file_level_data['st_sync_required']
              # If we get here on any foreign file, then we don't export any
              # primary files and we don't copy any marker files!
              files_that_could_not_be_exported_because_they_require_st_sync << content_at_file
              next  [Outcome.new(false, nil, ["Cannot export this file. A subtitle sync is required first!"])]
            end
          else
            # File's st_sync_active is false, however subtitles are being
            # exported. This is unexpected, we raise an exception.
            # The assumption is that when we export subtitles for a foreign
            # file we do so with the intention to activate subtitles for that
            # file. By exporting it, we create the working files, however
            # st sync will not touch this file until working files have been
            # imported back. At that point we'll apply any accumulated st ops.
            raise "You are exporting subtitles for a file that has 'st_sync_active' set to false. Please set it to true first, then try again.\n".color(:red)
          end

          # Since the kramdown parser is specified as module in Rtfile,
          # I can't use the standard kramdown API:
          # `doc = Kramdown::Document.new(contents, :input => 'kramdown_repositext')`
          # We have to patch a base Kramdown::Document with the root to be able
          # to convert it.
          root, warnings = config.kramdown_parser(:kramdown).parse(content_at_file.contents)
          doc = Kramdown::Document.new('')
          doc.root = root
          subtitle = doc.send(config.kramdown_converter_method(:to_subtitle))

          # Foreign files with st_sync_active only:
          # Record sync commit at which subtitles were exported
          if !config.setting(:is_primary_repo) && file_st_sync_is_active
            content_at_file.update_file_level_data!(
              'exported_subtitles_at_st_sync_commit' => st_sync_commit_sha1
            )
          end

          # Return Outcome
          [Outcome.new(true, { contents: subtitle, extension: 'txt' })]
        end
        if files_that_could_not_be_exported_because_they_require_st_sync.empty?
          # Fork depending on whether we're in primary or foreign repo.
          # If command is initially run on primary, it will reach the primary
          # brach only. If this command was called on foreign initially, it will
          # first execute the foreign branch, then call itself recursively on
          # the primary repo and execute the primary branch.
          if config.setting(:is_primary_repo)
            # We're in primary repo, copy subtitle_marker_csv_files to foreign repo
            # This works because options['output'] points to foreign repo.
            copy_subtitle_marker_csv_files_to_subtitle_export(options)
          else
            # Whe're operating on foreign repo: Export subtitles from primary
            # repo and copy them to this foreign repo's subtitle_export dir.
            # Recursively call this method with some options modified:
            # We call it via `Cli.start` so that we can use a different Rtfile.
            primary_repo_rtfile_path = File.join(config.primary_content_type_base_dir, 'Rtfile')
            args = [
              "export",
              "subtitle",
              "--content-type-name", options['content-type-name'], # use same content_type
              "--file-selector", input_file_selector, # use same file-selector
              "--rtfile", primary_repo_rtfile_path, # use primary repo's Rtfile
              "--output", output_base_dir, # use this foreign repo's subtitle_export dir
            ]
            args << '--skip-git-up-to-date-check'  if options['skip-git-up-to-date-check']
            Repositext::Cli.start(args)
          end
        else
          puts "The subtitle export could not be completed because the following files require a subtitle sync:".color(:red)
          puts "===============================================================================================".color(:red)
          files_that_could_not_be_exported_because_they_require_st_sync.each do |content_at_file|
            puts " * #{ content_at_file.filename }".color(:red)
          end
        end
      end

      # Export Subtitle Tagging files
      def export_subtitle_tagging(options)
        input_base_dir = config.compute_base_dir(options['base-dir'] || :content_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        input_file_extension = config.compute_file_extension(options['file-extension'] || :at_extension)
        output_base_dir = options['output'] || config.base_dir(:subtitle_tagging_export_dir)
        Repositext::Cli::Utils.export_files(
          input_base_dir,
          input_file_selector,
          input_file_extension,
          output_base_dir,
          options['file_filter'],
          "Exporting AT files to subtitle tagging",
          options.merge(
            :output_path_lambda => lambda { |input_filename, output_file_attrs|
              Repositext::Utils::SubtitleFilenameConverter.convert_from_repositext_to_subtitle_export(
                input_filename.gsub(input_base_dir, output_base_dir),
                output_file_attrs
              )
            }
          )
        ) do |contents, filename|
          # Since the kramdown parser is specified as module in Rtfile,
          # I can't use the standard kramdown API:
          # `doc = Kramdown::Document.new(contents, :input => 'kramdown_repositext')`
          # We have to patch a base Kramdown::Document with the root to be able
          # to convert it.
          root, warnings = config.kramdown_parser(:kramdown).parse(contents)
          doc = Kramdown::Document.new('')
          doc.root = root
          subtitle_tagging = doc.send(config.kramdown_converter_method(:to_subtitle_tagging))
          empty_markers_file = %(RelativeMS\tSamples\n0\t0\n)
          [
            Outcome.new(true, { contents: subtitle_tagging, extension: 'rt.txt' }),
            Outcome.new(true, { contents: empty_markers_file, extension: 'markers.txt' }),
          ]
        end
      end

      def export_test(options)
        # dummy method for testing
        puts 'export_test'
      end

    private

      def convert_at_string_to_plain_markdown(txt)
        # Remove AT specific tokens
        Suspension::TokenRemover.new(
          txt,
          Suspension::AT_SPECIFIC_TOKENS
        ).remove
      end

    end
  end
end
