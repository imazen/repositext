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

require 'repositext/cli/compare'
require 'repositext/cli/convert'
require 'repositext/cli/fix'
require 'repositext/cli/init'
require 'repositext/cli/merge'
require 'repositext/cli/sync'
require 'repositext/cli/validate'

require 'repositext/cli/export'
require 'repositext/cli/import'

class Repositext

  class ClifileError < RuntimeError; end

  class Cli < Thor

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


    # Basic commands


    desc "compare SPEC", "Compares files for consistency"
    long_desc long_description_for_compare
    # @param[String] command Specification of the operation
    def compare(command)
      self.send("compare_#{ command }", options)
    end


    desc 'convert SPEC', 'Converts files from one format to another'
    long_desc long_description_for_convert
    # @param[String] command Specification of the operation
    def convert(command)
      self.send("convert_#{ command }", options)
    end


    desc 'fix SPEC', 'Modifies files in place'
    long_desc long_description_for_fix
    # @param[String] command Specification of the operation
    def fix(command)
      self.send("fix_#{ command }", options)
    end


    desc "init", "Generates a default Rtfile"
    long_desc long_description_for_init
    method_option :force,
                  :aliases => "-f",
                  :desc => "Flag to force overwriting an existing Rtfile"
    # TODO: allow specification of Rtfile path
    def init
      generate_rtfile(options)
    end


    desc 'merge SPEC', 'Merges the contents of two files'
    long_desc long_description_for_merge
    # @param[String] command Specification of the operation
    def merge(command)
      self.send("merge_#{ command }", options)
    end


    desc 'sync SPEC', 'Syncs data between different file types in master'
    long_desc long_description_for_sync
    # @param[String] command Specification of the operation
    def sync(command)
      self.send("sync_#{ command }", options)
    end

    desc 'validate SPEC', 'Validates files'
    long_desc long_description_for_validate
    # @param[String] command Specification of the operation
    def validate(command)
      self.send("validate_#{ command }", options)
    end


    # Higher level commands


    desc 'export SPEC', 'Exports files from /master'
    long_desc long_description_for_export
    # @param[String] command Specification of the operation
    def export(command)
      self.send("export_#{ command }", options)
    end

    desc 'import SPEC', 'Imports files and merges changes into master'
    long_desc long_description_for_import
    # @param[String] command Specification of the operation
    def import(command)
      self.send("import_#{ command }", options)
    end

  private

    def config
      @config ||= Cli::Config.new(self)
    end

  end
end
