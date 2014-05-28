class Repositext
  class Validation

    extend Forwardable

    def_delegators :reporter, :errors, :warnings

    # Resets the validation report at report_file_path, initializes it with
    # marker and current time
    # @param[String] report_file_path
    # @param[String] marker
    # @param[DateTime, optional] time_stamp
    def self.reset_report(report_file_path, marker, time_stamp = Time.now)
      File.open(report_file_path, 'w') { |f|
        f.write "Validation report reset by '#{ marker }' at #{ time_stamp.to_s }\n\n"
      }
    end

    # Instantiates a new instance of self.
    # @param[Hash] file_specs a hash with names as keys and an array with base_dir
    #     and file_pattern which can be combined to a Dir.glob pattern.
    # @param[Hash] options with stringified keys
    #     * 'import_parser_class' class of parser to use for parsing import
    #               source document, e.g., Kramdown::Parser::Folio
    #     * 'kramdown_converter_method_name' method to call on kramdown tree for
    #               conversion to kramdown.
    #     * 'kramdown_parser_class' class of parser to use for parsing
    #               kramdown, e.g., Kramdown::Parser::Kramdown
    #     * 'log_level' => :debug, :info (default), :warn, :error
    #     * 'logger' => 'Logger' (default) or 'LoggerTest'
    #     * 'report_file' => If given will write report to file at this location
    #     * 'run_options' => Array of custom run options for validations (e.g., 'pre_import', 'post_import')
    #     * 'strictness' => :strict, :loose/liberal/lax
    def initialize(file_specs, options)
      @file_specs = file_specs
      @options = options
      @options['log_level'] ||= 'info'
      @logger = initialize_logger(@options['logger'])
      @reporter = initialize_reporter
      @options['run_options'] ||= [] # make sure this is always an array since validators may add to it
    end

    def run
      @logger.validation_header(@file_specs[:primary].join, self)
      start_time = Time.now
      run_list
      end_time = Time.now
      @logger.validation_footer(@reporter, end_time - start_time)
      @reporter.write(self.class.to_s, @options['report_file'])
      self
    end

    # @param[String, optional] logger_name one of 'Logger' (default) or 'LoggerTest'
    # @return[logger]
    def initialize_logger(logger_name = nil)
      logger_name ||= 'Logger'
      self.class.const_get(logger_name).new(
        *primary_file_spec, @options['log_level'], self
      )
    end

    # @return[Repositext::Validation::Reporter]
    def initialize_reporter
      Reporter.new(*primary_file_spec, @logger)
    end

    # Returns the primary file spec for self. This is used for reporting where
    # we want a single file spec only.
    # Uses the one with key :primary if present, otherwise a random one.
    def primary_file_spec
      @file_specs[:primary] || @file_specs[@file_specs.keys.first]
    end

  private

    # @param[Symbol] file_spec_name
    def validate_files(file_spec_name, &block)
      base_dir, file_pattern = @file_specs[file_spec_name]
      Dir.glob(base_dir + file_pattern).each do |file_name|
        yield(file_name)
      end
    end

    # @param[Symbol] file_spec_name
    # @param[Proc] paired_file_proc a proc that given the primary file path returns
    #     the path to the paired file
    def validate_file_pairs(file_spec_name, paired_file_proc, &block)
      base_dir, file_pattern = @file_specs[file_spec_name]
      Dir.glob(base_dir + file_pattern).each do |file_name_one|
        file_name_two = paired_file_proc.call(file_name_one, @file_specs)
        yield(file_name_one, file_name_two)
      end
    end

  end
end
