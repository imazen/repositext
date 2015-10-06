class Repositext
  class RFile

    # Contains code that is specific to Content AT files
    module ContentAtSpecific

      def compute_similarity_with_corresponding_primary_file
        Kramdown::TreeStructuralSimilarity.new(
          corresponding_primary_file.kramdown_doc,
          kramdown_doc
        ).compute
      end

      def kramdown_doc
        Kramdown::Document.new(
          contents,
          is_primary_repositext_file: is_primary_repo,
          input: 'KramdownVgr',
          line_width: 100000, # set to very large value so that each para is on a single line
        )
      end

    end
  end
end
