class Repositext
  class RFile

    # Contains code that is specific to Content AT files
    module ContentAtMixin
      def compute_similarity_with_corresponding_primary_file
        Kramdown::TreeStructuralSimilarity.new(
          corresponding_primary_file.kramdown_doc,
          kramdown_doc
        ).compute
      end

      # Returns the corresponding subtitle markers csv file or nil if it
      # doesn't exist
      def corresponding_subtitle_markers_csv_file
        return nil  if !File.exist?(corresponding_subtitle_markers_csv_filename)
        self.class.new(
          File.read(corresponding_subtitle_markers_csv_filename),
          language,
          corresponding_subtitle_markers_csv_filename,
          content_type
        )
      end

      def corresponding_subtitle_markers_csv_filename
        filename.sub(/\.at\z/, '.subtitle_markers.csv')
      end

      def has_subtitles?
        subtitles.any?
      end

      # @param options [Hash, optional]
      def kramdown_doc(options = {})
        options = {
          is_primary_repositext_file: is_primary_repo,
          input: 'KramdownVgr',
          line_width: 100000, # set to very large value so that each para is on a single line
        }.merge(options)
        Kramdown::Document.new(contents, options)
      end

      def plain_text_contents(options)
        kramdown_doc(options).to_plain_text
      end

      # Returns subtitles
      # @return [Array<Subtitle>]
      def subtitles
        return []  if (csmcf = corresponding_subtitle_markers_csv_file).nil?
        Repositext::Subtitle::ExtractFromStmCsvFile.new(csmcf).extract
      end
    end
  end
end
