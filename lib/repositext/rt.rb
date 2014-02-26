require 'thor'

# Establish namespace and class inheritance before we require nested classes
# Otherwise we get a subclass mismatch error because Rt is initialized as
# standalone class (not inheriting from Thor)
class Repositext
  class Rt < Thor
  end
end

require 'repositext/rt/config'
require 'repositext/rt/long_descriptions_for_commands'
require 'repositext/rt/patch_thor_with_rtfile'
require 'repositext/rt/rtfile_dsl'
require 'repositext/rt/utils'

require 'repositext/rt/compare'
require 'repositext/rt/convert'
require 'repositext/rt/fix'
require 'repositext/rt/init'
require 'repositext/rt/merge'
require 'repositext/rt/sync'
require 'repositext/rt/validate'

require 'repositext/rt/export'
require 'repositext/rt/import'

class Repositext

  class RtfileError < RuntimeError; end

  class Rt < Thor

    include Thor::Actions
    include Rt::RtfileDsl
    include Rt::LongDescriptionsForCommands

    include Rt::Compare
    include Rt::Convert
    include Rt::Fix
    include Rt::Init
    include Rt::Merge
    include Rt::Sync
    include Rt::Validate

    include Rt::Export
    include Rt::Import

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
      @config ||= Rt::Config.new(self)
    end

  end
end
