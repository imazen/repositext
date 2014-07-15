class Repositext
  class Merge
    class SubtitleMarksFromSubtitleImportIntoContentAt

      # Merges subtitle_marks from subtitle/subtitle_tagging import into content_at.
      # Uses content_at as text authority.
      # @param[String] subtitle_import the authority for subtitle_mark tokens.
      # @param[String] content_at the authority for text and all tokens except subtitle_marks
      # @return[Outcome] the merged document is returned as #result if successful.
      def self.merge(subtitle_import, content_at)
        # undo subtitle_import customizations
        si = undo_subtitle_import_modifications(subtitle_import, content_at)
        # merge subtitle_marks from subtitle_import into content_at
        outcome = merge_subtitle_marks(si, content_at)
      end

    protected

      # Undoes the modifications we make during subtitle import:
      # * remove empty lines between paragraphs
      # * remove title escaping ([| ... |])
      # * reduce 4 spaces after para numbers to one
      # * replace eagles
      # * replace paragraphs at the end of the file (id_)
      # @param[String] si the subtitle import document
      # @param[String] content_at the content AT document
      # @return[String] a subtitle import document that has all modifications undone
      def self.undo_subtitle_import_modifications(si, content_at)
        # si.gsub!(/\[\|([^\|]+)\|\]/, '\1') # remove title escaping (has to come after removing empty lines)
        Suspension::TextReplayer.new(
          content_at,
          si,
          Suspension::REPOSITEXT_TOKENS
        ).replay
      end

      # Merges subtitle_marks from si into content_at. Expects that both
      # filtered_texts are identical. Otherwise Suspension::TokenReplacer will
      # raise an error.
      # @param[String] si subtitle_import document that has all modifications
      #   undone. Contains subtitle_mark tokens.
      # @param[String] content_at the AT document to merge subtitle_marks into
      # @return[Outcome] if successful, #result contains the resulting text
      def self.merge_subtitle_marks(si, content_at)
        # Remove all tokens but :subtitle_mark from si
        subtitle_import_with_subtitle_marks_only = Suspension::TokenRemover.new(
          si,
          Suspension::REPOSITEXT_TOKENS.find_all { |e| :subtitle_mark != e.name }
        ).remove
        # Remove :subtitle_mark tokens from content_at
        content_at_without_subtitle_marks = Suspension::TokenRemover.new(
          content_at,
          Suspension::REPOSITEXT_TOKENS.find_all { |e| :subtitle_mark == e.name }
        ).remove
        # Add :subtitle_marks to text and all other tokens.
        at_with_merged_tokens = Suspension::TokenReplacer.new(
          subtitle_import_with_subtitle_marks_only,
          content_at_without_subtitle_marks
        ).replace([:subtitle_mark])
        Outcome.new(true, at_with_merged_tokens)
      rescue StandardError => e
        Outcome.new(false, nil, ["#{ e.class.name } - #{ e.message }\n#{ e.backtrace.join("\n") }"])
      end

    end
  end
end
