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

      def corresponding_subtitle_markers_csv_file
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

      # Returns subtitles
      # @return [Array<Subtitle>]
      def subtitles
        Repositext::Subtitle::ExtractFromStmCsvFile.new(
          corresponding_subtitle_markers_csv_file
        ).extract
      end

    end
  end
end
