class Repositext
  # Abstract base class for validations.
  # @abstract
  class Validation

    extend Forwardable

    def_delegators :reporter, :errors, :warnings

    # Resets the validation report at report_file_path, initializes it with
    # marker and current time. Creates directories as needed.
    # @param [String] report_file_path
    # @param [String] marker
    # @param [DateTime, optional] time_stamp
    def self.reset_report(report_file_path, marker, time_stamp = Time.now)
      # First make sure that parent directory exists
      FileUtils.mkdir_p(File.dirname(report_file_path))
      # Then truncate report
      File.open(report_file_path, 'w') { |f|
        f.write "Validation report reset by '#{ marker }' at #{ time_stamp.to_s }\n\n"
      }
    end

    # Instantiates a new instance of self.
    # @param [Hash] file_specs a hash with names as keys and an array with base_dir,
    #     file_selector, and file_extension which can be combined to a Dir.glob pattern.
    # @param [Hash] options with stringified keys
    #     * 'import_parser_class' class of parser to use for parsing import
    #               source document, e.g., Kramdown::Parser::Folio
    #     * 'kramdown_converter_method_name' method to call on kramdown tree for
    #               conversion to kramdown.
    #     * 'kramdown_parser_class' class of parser to use for parsing
    #               kramdown, e.g., Kramdown::Parser::Kramdown
    #     * 'log_level' => :debug, :info (default), :warn, :error
    #     * 'logger' => 'Logger' (default) or 'LoggerTest'
    #     * 'report_file' => If given will write report to file at this location
    #     * 'reporter' => 'Reporter' (default) or 'ReporterTest'
    #     * 'run_options' => Array of custom run options for validations (e.g., 'pre_import', 'post_import')
    #     * 'strictness' => :strict, :loose/liberal/lax,
    #     * 'use_new_r_file_api' => If true, uses new API based on Repositext::RFile instead of just paths.
    #       When using new r_file api, then these to options apply:
    #         * 'as_of_git_commit_attrs' => optional, see RFile#as_of_git_commit for details.
    #         * 'content_type' => required, ContentType that applies to all validated files.
    def initialize(file_specs, options)
      @file_specs = file_specs
      @options = options
      @options['log_level'] ||= 'info'
      @logger = initialize_logger(@options['logger'])
      @reporter = initialize_reporter(@options['reporter'])
      @options['run_options'] ||= [] # make sure this is always an array since validators may add to it
    end

    def run
      @logger.validation_header(@file_specs[:primary].join, self.class)
      start_time = Time.now
      run_list
      end_time = Time.now
      @logger.validation_footer(@reporter, end_time - start_time)
      @reporter.write(self.class.to_s, @options['report_file'])
      self
    end

    # @param [String, optional] logger_name one of 'Logger' (default) or 'LoggerTest'
    # @return [logger]
    def initialize_logger(logger_name = nil)
      logger_name ||= 'Logger'
      self.class.const_get(logger_name).new(
        *primary_file_spec, @options['log_level'], self
      )
    end

    # @param reporter_name [String, optional] Example: 'Reporter' (default) or 'ReporterTest'
    # @return [Repositext::Validation::Reporter]
    def initialize_reporter(reporter_name = nil)
      reporter_name ||= 'Reporter'
      self.class.const_get(reporter_name).new(
        *primary_file_spec, @logger, @options
      )
    end

    # Returns the primary file spec for self. This is used for reporting where
    # we want a single file spec only.
    # Uses the one with key :primary if present, otherwise a random one.
    def primary_file_spec
      @file_specs[:primary] || @file_specs[@file_specs.keys.first]
    end

  private

    # @param [Symbol] file_spec_name
    def validate_files(file_spec_name, option_overrides={}, &block)
      options = @options.merge(option_overrides)
      base_dir, file_selector, file_extension = @file_specs[file_spec_name]
      if options['use_new_r_file_api']
        # Use RFile based API
        content_type = options['content_type']
        language = content_type.language
        Dir.glob([base_dir, file_selector, file_extension].join).each do |file_name|
          r_file = if options['as_of_git_commit_attrs']
            Repositext::RFile.get_class_for_filename(
              file_name
            ).new(
              '_',
              language,
              file_name,
              content_type
            ).as_of_git_commit(*options['as_of_git_commit_attrs'])
          else
            r = Repositext::RFile.get_class_for_filename(
              file_name
            ).new(
              '_',
              language,
              file_name,
              content_type
            )
            r.reload_contents! # Let the class load contents to handle binary files
            r
          end
          yield(r_file)
        end
      else
        # Use legacy file path based approach
        Dir.glob([base_dir, file_selector, file_extension].join).each do |file_name|
          yield(file_name)
        end
      end
    end

    # @param [Symbol] file_spec_name
    # @param paired_file_proc_or_method_name [Proc] Depending on whether
    #   the legacy or new_r_file_based_api is used, provide one of the following:
    #   legacy: A proc that given the primary file path returns the path to the paired file.
    #   new_r_file: A proc that given the r_file returns the paired RFile.
    def validate_file_pairs(file_spec_name, paired_file_proc, option_overrides={}, &block)
      options = @options.merge(option_overrides)
      base_dir, file_selector, file_extension = @file_specs[file_spec_name]
      if options['use_new_r_file_api']
        # Use RFile based API
        content_type = options['content_type']
        language = content_type.language
        Dir.glob([base_dir, file_selector, file_extension].join).each do |file_name|
          r_file = if options['as_of_git_commit_attrs']
            Repositext::RFile.get_class_for_filename(
              file_name
            ).new(
              '_',
              language,
              file_name,
              content_type
            ).as_of_git_commit(*options['as_of_git_commit_attrs'])
          else
            r = Repositext::RFile.get_class_for_filename(
              file_name
            ).new(
              '_',
              language,
              file_name,
              content_type
            )
            r.reload_contents! # Let the class load contents to handle binary files
            r
          end
          paired_r_file = if r_file
            paired_file_proc.call(r_file)
          else
            # r_file may be nil. In that case there can't be a paired_r_file
            nil
          end
          yield(r_file, paired_r_file)
        end
      else
        # Use legacy file path based approach
        Dir.glob([base_dir, file_selector, file_extension].join).each do |file_name_one|
          file_name_two = paired_file_proc.call(file_name_one, @file_specs)
          yield(file_name_one, file_name_two)
        end
      end

    end

  end
end
