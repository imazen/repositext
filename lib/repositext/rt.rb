require 'thor'

# Establish namespace and class inheritance before we require nested classes
# Otherwise we get a subclass mismatch error because Rt is initialized as
# standalone class (not inheriting from Thor)
class Repositext
  class Rt < Thor
  end
end

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


    class_option :rtfile, :type => :string, :required => true, :aliases => '-rt'


    # Basic commands


    desc "compare SPEC", "Compares files for consistency"
    long_desc <<-D
      Compares files for consistency.

      Available commands:

      compare_idml_roundtrip

      [Describe the command here]
    D
    # @param[String] command Specification of the operation
    def compare(command)
      self.send("compare_#{ command }", options)
    end


    desc 'convert SPEC', 'Converts files from one format to another'
    long_desc <<-D
      Converts files from one format to another, using Repositext Parsers and
      Converters. Has sensible defaults for input file patterns.
      Stores output files in same directory as input files.

      Available commands:

      at_to_html

      Converts AT files in master to HTML, storing the output files in /export_html.

      folio_xml_to_at

      Converts Folio XML files in import_folio to AT kramdown files, storing the
      output files in the same directory as the input files.

      idml_to_at

      Converts IDML files in import_idml to AT kramdown files, storing the output
      files in the same directory as the input files.

      Examples:

      * rt convert idml_to_at -i='../import_idml/idml/**/*.idml'

      * rt convert at_to_html
    D
    method_option :input,
                  :aliases => "-i",
                  :desc => "A glob pattern for the input file set, e.g., -i='../import_idml/idml/**/*.idml'"
    # @param[String] command Specification of the operation
    def convert(command)
      self.send("convert_#{ command }", options)
    end


    desc 'fix SPEC', 'Modifies files in place'
    long_desc <<-D
      Modifies files in place. Updates contents of existing files.

      Available commands:

      renumber_paragraphs

      adjust_position_of_record_marks
    D
    # @param[String] command Specification of the operation
    def fix(command)
      self.send("fix_#{ command }", options)
    end


    desc "init", "Generates a default Rtfile"
    long_desc <<-D
      Generates a default Rtfile in the current working directory if it doesn't
      exist already. Can be forced to overwrite an existing Rtfile.
    D
    method_option :force,
                  :aliases => "-f",
                  :desc => "Flag to force overwriting an existing Rtfile"
    # TODO: allow specification of Rtfile path
    def init
      generate_rtfile(options)
    end


    desc 'merge SPEC', 'Merges the contents of two files'
    long_desc <<-D
      Merges the contents of two files and writes the result to an output
      file, typically using a suspension-based operation.
      Each of the two input files contributes a different kind of data.

      Available commands:

      merge_record_marks

      [Describe command]
    D
    # @param[String] command Specification of the operation
    def merge(command)
      self.send("merge_#{ command }", options)
    end


    desc 'sync SPEC', 'Syncs data between different file types in master'
    long_desc <<-D
      Syncs data between different file types in master.
      Applies a suspension-based operation between files of different types.

      Available commands:

      from_txt

      Replays text changes from TXT to AT and PT files in master.

      from_at

      Replays text and some token changes from AT to PT. Replays text changes from
      AT to TXT.
    D
    # @param[String] command Specification of the operation
    def sync(command)
      self.send("sync_#{ command }", options)
    end

    desc 'validate SPEC', 'Validates files'
    long_desc <<-D
      Validates files.

      Available commands:

      utf8_encoding

      Validates that all text files (AT, PT, and TXT) are UTF8 encoded.
    D
    # @param[String] command Specification of the operation
    def validate(command)
      self.send("validate_#{ command }", options)
    end


    # Higher level commands


    desc 'export SPEC', 'Exports files from /master'
    long_desc <<-D
      Exports files from /master, performing all steps required to generate
      files of the desired output file type.

      Examples:

      * Export PT to ICML
    D
    # @param[String] command Specification of the operation
    def export(command)
      self.send("export_#{ command }", options)
    end


    desc 'import SPEC', 'Imports files and merges changes into master'
    long_desc <<-D
      Imports files from a source, performs all steps required to merge changes
      into master

      Available commands:

      from_docx

      Imports changes from DOCX files in /import_docx to master.
    D
    # @param[String] command Specification of the operation
    def import(command)
      self.send("import_#{ command }", options)
    end

  end
end
