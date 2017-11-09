class Repositext
  # Implements the repositext command line interface.
  class Cli < Thor

    class RtfileError < RuntimeError; end

    include Thor::Actions
    include Cli::LongDescriptionsForCommands

    include Cli::Compare
    include Cli::Convert
    include Cli::Copy
    include Cli::Data
    include Cli::Delete
    include Cli::Distribute
    include Cli::Fix
    include Cli::GitRepo
    include Cli::Init
    include Cli::Merge
    include Cli::Move
    include Cli::Release
    include Cli::Report
    include Cli::Split
    include Cli::Sync
    include Cli::Validate

    include Cli::Export
    include Cli::Import

    # For rtfile template loading
    def self.source_root
      File.dirname(__FILE__)
    end

    # Tries to find Rtfile, starting in content_type_name child directory of current
    # working directory and traversing up the directory hierarchy until it finds
    # an Rtfile or reaches the file system root.
    # NOTE: This code is inspired by Bundler's find_gemfile
    # @param content_type_name [String] a valid content type
    # @return [String, nil] path to closest Rtfile or nil if none found.
    def self.find_rtfile(content_type_name)
      previous = nil
      current  = File.join(Dir.getwd, "ct-#{ content_type_name }")

      until !File.directory?(current) || current == previous
        filename = File.join(current, 'Rtfile')
        return filename  if File.file?(filename)
        current, previous = File.expand_path("..", current), current
      end
      nil
    end

    # Returns the names of all valid content type names
    # @return [Array<String>]
    def self.valid_content_type_names
      ContentType.all_names
    end

    # Verifies that content_type_name is given and valid
    # @param content_type_name [String]
    # @return [Boolean]
    def self.valid_content_type_name?(content_type_name)
      valid_content_type_names.include?(content_type_name)
    end

    class_option :'at-git-commit',
                 :type => :string,
                 :desc => "For commands that require git commit information (e.g., exporting files at a certain commit)"
    class_option :'base-dir',
                 :type => :string,
                 :desc => 'Specifies the input file base directory. Expects a named base_dir from Rtfile or an absolute directory path.'
    class_option :'changed-only',
                 :type => :boolean,
                 :default => false,
                 :desc => 'If true, only files that have been changed or added will be processed.'
    class_option :'content-type-name',
                 :type => :string,
                 :required => true,
                 :desc => 'Specifies which content type to operate on.'
    class_option :'date-code',
                 :aliases => "--dc",
                 :type => :string,
                 :desc => 'Gets rewritten as file selector for date codes.'
    class_option :debug,
                 :type => :boolean,
                 :default => false,
                 :desc => 'If true, will print debug information related to the command.'
    class_option :'file-extension',
                 :type => :string,
                 :desc => 'Specifies the input file extension. Expects a named file_extension from Rtfile or a Glob pattern that can be used with Dir.glob.'
    class_option :'file-selector',
                 :type => :string,
                 :desc => 'Specifies the input file selector. Expects a named file_selector from Rtfile or a Glob pattern that can be used with Dir.glob.'
    class_option :'from-commit',
                 :type => :string,
                 :desc => "For commands that require from and to commit information (e.g., subtitle operations)"
    class_option :'keep-existing',
                 :type => :boolean,
                 :default => false,
                 :desc => "Will keep existing files for any export commands that delete previously exported files."
    class_option :output,
                 :type => :string,
                 :desc => 'Overrides the output base directory.'
    class_option :rtfile,
                 :type => :string,
                 :required => true,
                 :desc => 'Specifies which Rtfile to use. Defaults to the closest Rtfile found in the directory hierarchy.'
    class_option :'skip-erp-api',
                 :type => :boolean,
                 :default => false,
                 :desc => 'If true, skips requests to the ERP API, and will skip any functionality that depends on ERP data.'
    class_option :'skip-git-up-to-date-check',
                 :aliases => "-g",
                 :type => :boolean,
                 :default => false,
                 :desc => 'If true, skips the check to make sure that the local repo is up-to-date with origin/master.'
    class_option :'to-commit',
                 :type => :string,
                 :desc => "For commands that require from and to commit information (e.g., subtitle operations)"
    class_option :'validation-reporter',
                 :type => :string,
                 :desc => "Specifies which reporter to use for validation. Possible values: %w[Reporter ReporterJson]. Defaults to 'Reporter'"
    class_option :'verbose',
                 :aliases => "-v",
                 :type => :boolean,
                 :default => false,
                 :desc => "Print more verbose console output."
    # Override original initialize so that the options hash is not frozen. We
    # need to modify it.
    def initialize(args=[], options={}, config={})
      super
      @options = @options.dup
    end


    # Basic commands


    desc "compare SPEC", "Compares files for consistency"
    long_desc long_description_for_compare
    # @param [String] command_spec Specification of the operation
    def compare(command_spec)
      invoke_repositext_command('compare', command_spec, options)
    end


    desc 'convert SPEC', 'Converts files from one format to another'
    long_desc long_description_for_convert
    # @param [String] command_spec Specification of the operation
    def convert(command_spec)
      invoke_repositext_command('convert', command_spec, options)
    end


    desc 'copy SPEC', 'Copies files from one location to another'
    long_desc long_description_for_copy
    # @param [String] command_spec Specification of the operation
    def copy(command_spec)
      invoke_repositext_command('copy', command_spec, options)
    end

    desc 'data SPEC', 'Manipulates contents of data.json files'
    long_desc long_description_for_data
    # @param [String] command_spec Specification of the operation
    def data(command_spec)
      invoke_repositext_command('data', command_spec, options)
    end

    desc 'delete SPEC', 'Deletes files'
    long_desc long_description_for_delete
    # @param [String] command_spec Specification of the operation
    def delete(command_spec)
      invoke_repositext_command('delete', command_spec, options)
    end

    desc 'distribute SPEC', 'Distributes files to destination location'
    long_desc long_description_for_distribute
    # @param [String] command_spec Specification of the operation
    def distribute(command_spec)
      invoke_repositext_command('distribute', command_spec, options)
    end

    desc 'fix SPEC', 'Modifies files in place'
    long_desc long_description_for_fix
    # @param [String] command_spec Specification of the operation
    def fix(command_spec)
      invoke_repositext_command('fix', command_spec, options)
    end


    desc 'git_repo SPEC', 'Performs git repository commands'
    long_desc long_description_for_git_repo
    # @param [String] command_spec Specification of the operation
    def git_repo(command_spec)
      invoke_repositext_command('git_repo', command_spec, options)
    end


    desc "init", "Generates a default Rtfile"
    long_desc long_description_for_init
    method_option :force,
                  :aliases => "-f",
                  :desc => "Flag to force overwriting an existing Rtfile"
    # TODO: allow specification of Rtfile path
    # @param [String, optional] command_spec Specification of the operation. This
    #     is used for testing (pass 'test' as command_spec)
    def init(command_spec = nil)
      if command_spec
        invoke_repositext_command('init', command_spec, options)
      else
        init_rtfile(options)
      end
    end


    desc 'merge SPEC', 'Merges the contents of two files'
    long_desc long_description_for_merge
    method_option :'base-dir-1',
                  :type => :string,
                  :desc => 'Specifies the base directory for the first file. Expects a named base_dir from Rtfile or an absolute directory path.'
    method_option :'base-dir-2',
                  :type => :string,
                  :desc => 'Specifies the base directory for the second file. Expects a named base_dir from Rtfile or an absolute directory path.'
    # @param [String] command_spec Specification of the operation
    def merge(command_spec)
      invoke_repositext_command('merge', command_spec, options)
    end


    desc 'move SPEC', 'Moves files to another location'
    long_desc long_description_for_move
    # @param [String] command_spec Specification of the operation
    def move(command_spec)
      invoke_repositext_command('move', command_spec, options)
    end


    desc 'release SPEC', 'Releases a product'
    long_desc long_description_for_release
    method_option :'release-version',
                  type: :string,
                  desc: "Argument to specify what version should be released"
    # @param [String] command_spec Specification of the operation
    def release(command_spec)
      # NOTE: we run git-up-to-date-check as part of Process::Release on a
      # number of repositories, so we don't have to do it here.
      invoke_repositext_command('release', command_spec, options)
    end


    desc 'report SPEC', 'Generates a report'
    long_desc long_description_for_report
    # @param [String] command_spec Specification of the operation
    def report(command_spec)
      check_that_current_branch_is_up_to_date_with_origin_master
      invoke_repositext_command('report', command_spec, options)
    end


    desc 'split SPEC', 'Splits files in /content'
    long_desc long_description_for_split
    method_option :'remove-existing-sts',
                  :type => :boolean,
                  :desc => 'If true, will remove any subtitle_marks that already exist in the content AT file.'
    # @param [String] command_spec Specification of the operation
    def split(command_spec)
      invoke_repositext_command('split', command_spec, options)
    end

    desc 'sync SPEC', 'Syncs data between different file types in /content'
    long_desc long_description_for_sync
    method_option :'auto-insert-missing-subtitle-marks',
                  :type => :boolean,
                  :desc => 'Automatically inserts missing subtitle marks into subtitle_marker files based on subtitles in /content AT'
    # @param [String] command_spec Specification of the operation
    def sync(command_spec)
      invoke_repositext_command('sync', command_spec, options)
    end

    desc 'validate SPEC', 'Validates files'
    long_desc long_description_for_validate
    method_option :report_file,
                  :type => :string,
                  :default => nil,
                  :desc => 'Specifies an absolute file path to which a validation report will be written.'
    method_option :run_options,
                  :type => :array,
                  :default => %w[pre_import post_import],
                  :desc => 'Specifies which validations to run. Possible values: %w[pre_import post_import]'
    # @param [String] command_spec Specification of the operation
    # NOTE: --input option can only use named file_specs, not dir.glob patterns.
    #
    # TODO: implement these command line options:
    #
    # '-r', '--report_file PATH', "optional, will write report to the file specified if given. Report will always be printed to STDOUT." do |arg|
    # '-l', '--logger LOGGER', "defaults to 'STDOUT'" do |arg|
    # '-v', '--log_level LOG_LEVEL', "optional, one of 'debug', 'info', 'warn' or 'error'. Defaults to 'info'." do |arg|
    # '-s', '--strictness STRICTNESS', "optional, one of 'strict' or 'loose'. Defaults to 'strict'." do |arg|
    def validate(command_spec)
      invoke_repositext_command('validate', command_spec, options)
    end


    # Higher level commands


    desc 'export SPEC', 'Exports files from /content'
    long_desc long_description_for_export
    method_option :'additional-footer-text',
                  type: :string,
                  desc: 'Adds additional text to the footer of an exported PDF'
    method_option :'include-version-control-info',
                  type: :boolean,
                  desc: 'Adds a version control info page to an exported PDF'
    method_option :'erp-data-file-path',
                  type: :string,
                  desc: "path to the ERP Data json file"
    # @param [String] command_spec Specification of the operation
    def export(command_spec)
      check_that_current_branch_is_up_to_date_with_origin_master
      invoke_repositext_command('export', command_spec, options)
    end

    desc 'import SPEC', 'Imports files and merges changes into /content'
    long_desc long_description_for_import
    method_option :'auto-insert-missing-subtitle-marks',
                  :type => :boolean,
                  :desc => 'Automatically inserts missing subtitle marks into subtitle_marker files based on subtitles in /content AT'
    # @param [String] command_spec Specification of the operation
    def import(command_spec)
      check_that_current_branch_is_up_to_date_with_origin_master
      invoke_repositext_command('import', command_spec, options)
    end

  private

    # Lazily compute effective settings in config object
    def config
      @config ||= content_type.config
    end
    # This writer is used for testing to inject a mock config
    def config=(a_config)
      @config = a_config
    end

    def content_type
      @content_type ||= ContentType.new(options['rtfile'].sub('/Rtfile', ''))
    end

    def repository
      content_type.repository
    end

    # Invokes the command derived from main_command and command_spec
    # @param [String] main_command
    # @param [String] command_spec
    def invoke_repositext_command(main_command, command_spec, options)
      method_name = "#{ main_command }_#{ command_spec }"
      if '' != (dc = options['date-code'].to_s.strip)
        # Rewrite dc option to file-selector
        options['file-selector'] = "**/*{#{ dc }}_*"
      end
      # Add content_type to options so that it is available for instantiating
      # RFiles for validations
      options[:content_type] = content_type

      if respond_to?(method_name, true)
        with_timer do
          self.send(method_name, options)
        end
      else
        raise("The command you entered is not implemented. Missing method: #{ method_name.inspect }")
      end
    end

    # Wrap code you want to time inside a block. Returns duration in seconds.
    def with_timer(&block)
      start_time = Time.now
      block.call
      end_time = Time.now
      duration_in_seconds = (end_time - start_time).to_i
      $stderr.puts "Total duration: #{ duration_in_seconds } seconds."
      $stderr.puts "Boom done!".color(:yellow)  if duration_in_seconds < 2
    end

    # Makes sure that the local branch is up-to-date with origin:master.
    # Raises an exception if it is not.
    def check_that_current_branch_is_up_to_date_with_origin_master
      return true  if options['skip-git-up-to-date-check']
      if !repository.up_to_date_with_remote?
        raise Repository::NotUpToDateWithRemoteError.new([
          '',
          "Your local '#{ repository.name_and_current_branch }' branch is not up-to-date with origin/master.",
          'Please get the updates from origin/master first before running a repositext command.',
          'You can bypass this check by appending "--skip-git-up-to-date-check=true" to the repositext command'
        ].join("\n"))
      end
    end

  end
end
