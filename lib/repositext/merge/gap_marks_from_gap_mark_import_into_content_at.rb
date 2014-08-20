class Repositext
  class Merge
    class GapMarksFromGapMarkImportIntoContentAt

      # Merges gap_marks from gap_mark_tagging import into content_at.
      # Uses content_at as text authority.
      # @param[String] gap_mark_import the authority for gap_mark tokens.
      # @param[String] content_at the authority for text and all tokens except gap_marks
      # @return[Outcome] the merged document is returned as #result if successful.
      def self.merge(gap_mark_import, content_at)
        # undo gap_mark_import customizations
        gi = undo_gap_mark_import_modifications(gap_mark_import, content_at)
        # merge gap_marks from gap_mark_import into content_at
        outcome = merge_gap_marks(gi, content_at)
      end

    protected

      # Undoes the modifications we make during gap_mark import:
      # * reduce 4 spaces after para numbers to one
      # * replace eagles
      # * replace paragraphs at the end of the file (id_)
      # @param[String] gi the gap_mark import document
      # @param[String] content_at the content AT document
      # @return[String] a gap_mark import document that has all modifications undone
      def self.undo_gap_mark_import_modifications(gi, content_at)
        new_gi = gi.dup
        # Do some manual operations first
        # Reduce 4 spaces after para numbers to one
        new_gi.gsub!(/(\d+)    /, '\1 ')
        # Then let TextReplayer take care of the rest
        Suspension::TextReplayer.new(
          content_at,
          new_gi,
          Suspension::REPOSITEXT_TOKENS
        ).replay
      end

      # Merges gap_marks from gi into content_at. Expects that both
      # filtered_texts are identical. Otherwise Suspension::TokenReplacer will
      # raise an error.
      # @param[String] gi gap_mark_import document that has all modifications
      #   undone. Contains gap_mark tokens.
      # @param[String] content_at the AT document to merge gap_marks into
      # @return[Outcome] if successful, #result contains the resulting text
      def self.merge_gap_marks(gi, content_at)
        # Remove all tokens but :gap_mark from gi
        gap_mark_import_with_gap_marks_only = Suspension::TokenRemover.new(
          gi,
          Suspension::REPOSITEXT_TOKENS.find_all { |e| :gap_mark != e.name }
        ).remove
        # Remove :gap_mark tokens from content_at
        content_at_without_gap_marks = Suspension::TokenRemover.new(
          content_at,
          Suspension::REPOSITEXT_TOKENS.find_all { |e| :gap_mark == e.name }
        ).remove
        # Add :gap_marks to (text and all other tokens).
        at_with_merged_tokens = Suspension::TokenReplacer.new(
          gap_mark_import_with_gap_marks_only,
          content_at_without_gap_marks
        ).replace([:gap_mark])
        Outcome.new(true, at_with_merged_tokens)
      rescue StandardError => e
        Outcome.new(false, nil, ["#{ e.class.name } - #{ e.message }\n#{ e.backtrace.join("\n") }"])
      end

    end
  end
end
