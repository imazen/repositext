class Repositext
  class Merge
    class GapMarkTaggingImportIntoContentAt

      # Merges gap_marks and .omit classes from gap_mark_tagging import into content_at.
      #
      # General approach:
      #
      # * make sure nothing but gap_marks and .omit pargraph classes has changed
      # * merge gap_marks from gmt_import into content_at
      #     * using current suspension based approach
      # * merge .omit classes from gmt_import into content_at
      #     * use string tools, iterate over paragraphs and update .omit classes
      #
      # @param[String] gap_mark_tagging_import the authority for gap_mark tokens.
      # @param[String] content_at the authority for text and all tokens except gap_marks
      # @return[Outcome] the merged document is returned as #result if successful.
      def self.merge(gap_mark_tagging_import, content_at)
        # Make sure nothing but gap_marks and .omit pargraph classes has changed
        ensure_no_invalid_changes(gap_mark_tagging_import, content_at)
        # Merge gap_marks from gap_mark_tagging_import into content_at
        gap_mark_outcome = merge_gap_marks(gap_mark_tagging_import, content_at)
        return gap_mark_outcome  if !gap_mark_outcome.success?
        # Merge .omit classes from gmt_import into content_at
        omit_outcome = merge_omit_classes(gap_mark_tagging_import, gap_mark_outcome.result)
      end

    protected

      # Makes sure that only gap_marks and paragraph.omit classes have changed
      # between gap_mark_tagging_import and content_at. Raises an exception
      # if there are invalid changes.
      # @param[String] gap_mark_tagging_import
      # @param[String] conten_at
      # @return[Outcome] true if no invalid changes are found
      def self.ensure_no_invalid_changes(gap_mark_tagging_import, content_at)
        # Export content_at to gap_mark_tagging
        tmp_gap_mark_tagging_export = Repositext::Export::GapMarkTagging.export(content_at).result
        # Strip gap_marks and .omit classes from both import and tmp_export
        tmp_gap_mark_tagging_export = remove_gap_marks_and_omit_classes(tmp_gap_mark_tagging_export)
        gap_mark_tagging_import = remove_gap_marks_and_omit_classes(gap_mark_tagging_import)
        # Both strings should be identical
        diffs = Suspension::StringComparer.compare(tmp_gap_mark_tagging_export, gap_mark_tagging_import)
        if diffs.any?
          raise(
            ArgumentError.new(
              [
                "Cannot proceed with import. Please resolve text differences first:",
                diffs.inspect
              ].join("\n")
            )
          )
        end
      end

      # Removes gap_marks and paragraph.omit classes from txt
      # @param[String] txt
      # @return[String]
      def self.remove_gap_marks_and_omit_classes(txt)
        txt.gsub('%', '')
           .gsub(
              /
                \s*\.omit\s* # .omit class
                (?=[^\{\}]{0,40}\}) # followed by end of IAL
              /x,
              ''
            )
           .gsub(/\{:\s*\}\n?/, '') # remove empty IALs {:} (after only .omit class was removed)
      end

      # Merges gap_marks from gap_mark_tagging_import into content_at. Expects that both
      # filtered_texts are identical. Otherwise Suspension::TokenReplacer will
      # raise an error.
      # @param[String] gap_mark_tagging_import document that has all modifications
      #   undone. Contains gap_mark tokens.
      # @param[String] content_at the AT document to merge gap_marks into
      # @return[Outcome] if successful, #result contains the resulting text
      def self.merge_gap_marks(gap_mark_tagging_import, content_at)
        # Remove all tokens but :gap_mark from gap_mark_tagging_import
        gap_mark_tagging_import_with_gap_marks_only = Suspension::TokenRemover.new(
          gap_mark_tagging_import,
          Suspension::REPOSITEXT_TOKENS.find_all { |e| :gap_mark != e.name }
        ).remove
        # Remove :gap_mark tokens from content_at
        content_at_without_gap_marks = Suspension::TokenRemover.new(
          content_at,
          Suspension::REPOSITEXT_TOKENS.find_all { |e| :gap_mark == e.name }
        ).remove
        # Add :gap_marks to (text and all other tokens).
        at_with_merged_tokens = Suspension::TokenReplacer.new(
          gap_mark_tagging_import_with_gap_marks_only,
          content_at_without_gap_marks
        ).replace([:gap_mark])
        Outcome.new(true, at_with_merged_tokens)
      # rescue StandardError => e
      #   Outcome.new(false, nil, ["#{ e.class.name } - #{ e.message }\n#{ e.backtrace.join("\n") }"])
      end

      # Merges paragraph.omit classes from gap_mark_tagging_import into content_at.
      # Doesn't touch any other classes.
      # @param[String] gap_mark_tagging_import
      # @param[String] content_at
      # @return[Outcome] if successful, #result contains the resulting text
      def self.merge_omit_classes(gap_mark_tagging_import, content_at)
        # Extract paragraph classes from gap_mark_tagging_import
        gap_mark_tagging_import_paragraph_classes = extract_paragraph_ials(gap_mark_tagging_import)
        # Build new txt with merged .omit classes
        new_txt = ''
        s = StringScanner.new(content_at)
        while !s.eos? do
          # Advance cursor up to and excluding next paragraph IAL
          txt_before_ial = s.scan_until(/\n(?=\{:)/)
          if txt_before_ial
            new_txt << txt_before_ial
            # capture paragraph IAL
            content_ial = s.scan(/\{[^\}]+\}/)
            if content_ial
              # merge classes
              import_ial = gap_mark_tagging_import_paragraph_classes.shift
              new_ial = merge_omit_paragraph_class(import_ial, content_ial)
              new_txt << new_ial
            else
              raise "Expected paragraph IAL: #{ s.match.inspect }"
            end
          else
            # no further paragraph IALs found
            new_txt << s.rest
            s.terminate
          end
        end
        # TODO: Make sure no gap_mark_tagging_import_paragraph_classes are left
        Outcome.new(true, new_txt)
      end

      # Extracts all paragraph IALs in txt and returns them as array in the order
      # they appear in txt
      # @param[String] txt
      # @param[Array<String>] an array with one item for each IAL, as it is found in txt
      def self.extract_paragraph_ials(txt)
        txt.scan(/(?<=\n)\{:[^\{\}]+\}/)
      end

      # Merges source_ial's .omit class into target_ial
      # @param[String] source_ial
      # @param[String] target_ial
      # @return[String] merged IAL
      def self.merge_omit_paragraph_class(source_ial, target_ial)
        tmp_kramdown_doc = Kramdown::Document.new("para\n#{ target_ial }", :input => 'KramdownRepositext')
        tmp_para_el = tmp_kramdown_doc.root.children.first
        if source_ial.index('.omit')
          tmp_para_el.add_class('omit')
        else
          tmp_para_el.remove_class('omit')
        end
        new_ial = tmp_kramdown_doc.to_kramdown.gsub("para\n", '').strip
        new_ial
      end

    end
  end
end
