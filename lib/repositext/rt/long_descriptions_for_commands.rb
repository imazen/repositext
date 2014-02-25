class Repositext
  class Rt
    module LongDescriptionsForCommands

      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods

        def long_description_for_compare
          %(
            Compares files for consistency.

            Available commands:

            compare_idml_roundtrip

            [Describe the command here]
          )
        end

        def long_description_for_convert
          %(
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
          )
        end

        def long_description_for_fix
          %(
            Modifies files in place. Updates contents of existing files.

            Available commands:

            renumber_paragraphs

            adjust_position_of_record_marks
          )
        end

        def long_description_for_init
          %(
            Generates a default Rtfile in the current working directory if it doesn't
            exist already. Can be forced to overwrite an existing Rtfile.
          )
        end

        def long_description_for_merge
          %(
            Merges the contents of two files and writes the result to an output
            file, typically using a suspension-based operation.
            Each of the two input files contributes a different kind of data.

            Available commands:

            merge_record_marks

            [Describe command]
          )
        end

        def long_description_for_sync
          %(
            Syncs data between different file types in master.
            Applies a suspension-based operation between files of different types.

            Available commands:

            from_txt

            Replays text changes from TXT to AT and PT files in master.

            from_at

            Replays text and some token changes from AT to PT. Replays text changes from
            AT to TXT.
          )
        end

        def long_description_for_validate
          %(
            Validates files.

            Available commands:

            utf8_encoding

            Validates that all text files (AT, PT, and TXT) are UTF8 encoded.
          )
        end

        def long_description_for_export
          %(
            Exports files from /master, performing all steps required to generate
            files of the desired output file type.

            Examples:

            * Export PT to ICML
          )
        end

        def long_description_for_import
          %(
            Imports files from a source, performs all steps required to merge changes
            into master

            Available commands:

            from_docx

            Imports changes from DOCX files in /import_docx to master.
          )
        end

      end
    end
  end
end
