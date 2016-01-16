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
          repository
        )
      end

      def corresponding_subtitle_markers_csv_filename
        filename.sub(/\.at\z/, '.subtitle_markers.csv')
      end

      def kramdown_doc
        Kramdown::Document.new(
          contents,
          is_primary_repositext_file: is_primary_repo,
          input: 'KramdownVgr',
          line_width: 100000, # set to very large value so that each para is on a single line
        )
      end

      def has_subtitles?
        subtitles.any?
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
