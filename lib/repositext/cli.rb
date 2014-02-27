require 'thor'

# Establish namespace and class inheritance before we require nested classes
# Otherwise we get a subclass mismatch error because Cli is initialized as
# standalone class (not inheriting from Thor)
class Repositext
  class Cli < Thor
  end
end

require 'repositext/cli/config'
require 'repositext/cli/long_descriptions_for_commands'
require 'repositext/cli/patch_thor_with_rtfile'
require 'repositext/cli/rtfile_dsl'
require 'repositext/cli/utils'

require 'repositext/cli/commands/compare'
require 'repositext/cli/commands/convert'
require 'repositext/cli/commands/fix'
require 'repositext/cli/commands/init'
require 'repositext/cli/commands/merge'
require 'repositext/cli/commands/sync'
require 'repositext/cli/commands/validate'

require 'repositext/cli/commands/export'
require 'repositext/cli/commands/import'

class Repositext

  class Cli < Thor

    class RtfileError < RuntimeError; end

    include Thor::Actions
    include Cli::RtfileDsl
    include Cli::LongDescriptionsForCommands

    include Cli::Compare
    include Cli::Convert
    include Cli::Fix
    include Cli::Init
    include Cli::Merge
    include Cli::Sync
    include Cli::Validate

    include Cli::Export
    include Cli::Import

    # For rtfile template loading
    def self.source_root
      File.dirname(__FILE__)
    end


    class_option :rtfile,
                 :aliases => '-rt',
                 :type => :string,
                 :required => true,
                 :desc => 'Specifies which Rtfile to use. Defaults to the closest Rtfile found in the directory hierarchy.'
    class_option :input,
                 :aliases => '-i',
                 :type => :string,
                 :desc => 'Specifies the input file pattern. Expects an absolute path pattern that can be used with Dir.glob.'


    # Basic commands


    desc "compare SPEC", "Compares files for consistency"
    long_desc long_description_for_compare
    # @param[String] command_spec Specification of the operation
    def compare(command_spec)
      self.send("compare_#{ command_spec }", options)
    end


    desc 'convert SPEC', 'Converts files from one format to another'
    long_desc long_description_for_convert
    # @param[String] command_spec Specification of the operation
    def convert(command_spec)
      self.send("convert_#{ command_spec }", options)
    end


    desc 'fix SPEC', 'Modifies files in place'
    long_desc long_description_for_fix
    # @param[String] command_spec Specification of the operation
    def fix(command_spec)
      self.send("fix_#{ command_spec }", options)
    end


    desc "init", "Generates a default Rtfile"
    long_desc long_description_for_init
    method_option :force,
                  :aliases => "-f",
                  :desc => "Flag to force overwriting an existing Rtfile"
    # TODO: allow specification of Rtfile path
    # @param[String, optional] command_spec Specification of the operation. This
    #     is used for testing (pass 'test' as command_spec)
    def init(command_spec = nil)
      if command_spec
        self.send("init_#{ command_spec }", options)
      else
        generate_rtfile(options)
      end
    end


    desc 'merge SPEC', 'Merges the contents of two files'
    long_desc long_description_for_merge
    # @param[String] command_spec Specification of the operation
    def merge(command_spec)
      self.send("merge_#{ command_spec }", options)
    end


    desc 'sync SPEC', 'Syncs data between different file types in master'
    long_desc long_description_for_sync
    # @param[String] command_spec Specification of the operation
    def sync(command_spec)
      self.send("sync_#{ command_spec }", options)
    end

    desc 'validate SPEC', 'Validates files'
    long_desc long_description_for_validate
    # @param[String] command_spec Specification of the operation
    def validate(command_spec)
      self.send("validate_#{ command_spec }", options)
    end


    # Higher level commands


    desc 'export SPEC', 'Exports files from /master'
    long_desc long_description_for_export
    # @param[String] command_spec Specification of the operation
    def export(command_spec)
      self.send("export_#{ command_spec }", options)
    end

    desc 'import SPEC', 'Imports files and merges changes into master'
    long_desc long_description_for_import
    # @param[String] command_spec Specification of the operation
    def import(command_spec)
      self.send("import_#{ command_spec }", options)
    end

  private

    def config
      @config ||= Cli::Config.new
    end

  end
end
