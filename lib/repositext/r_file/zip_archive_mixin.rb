class Repositext
  class RFile

    # Provides behavior related to ZIP archives
    module ZipArchiveMixin

      # Extracts 'word/document.xml' from docx file
      # @return [String] the contents of the file
      def extract_docx_document_xml
        extract_zip_archive_file_contents(
          'word/document.xml'
        )
      end

      # Extracts contents of a file in ZIP archive
      # @param file_path [String] relative path to the file in archive
      #     Example: 'word/document.xml'
      # @return [String] the contents of the addressed file
      def extract_zip_archive_file_contents(file_path)
        addressed_file_contents = nil
        Zip::File.open_buffer(contents) do |zipped_files|
          addressed_file_contents = zipped_files.get_entry(
            file_path
          ).get_input_stream.read
        end
        addressed_file_contents
      end

    end
  end
end
