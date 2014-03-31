class Repositext
  class Merge
    class RecordMarksFromFolioXmlAtIntoIdmlAt

      # @param[String] at_folio
      # @param[String] at_idml
      # @return[String] at with merged tokens
      def self.merge(at_folio, at_idml)
        case 'use_new'
        when 'use_new'
          # Get txt from at_idml
          at_idml_txt_only = Suspension::TokenRemover.new(
            at_idml,
            Suspension::REPOSITEXT_TOKENS
          ).remove

          # Remove all tokens but :record_mark from at_folio
          # Need to retain both :record_mark as well as the connected :ial_span.
          # Otherwise only '^^^' would be left (without the IAL)
          at_folio_with_record_marks_only = Suspension::TokenRemover.new(
            at_folio,
            Suspension::REPOSITEXT_TOKENS.find_all { |e| ![:ial_span, :record_mark].include?(e.name) }
          ).remove

          # Replay idml text changes on at_folio_with_record_marks_only
          at_with_record_marks_only = Suspension::TextReplayer.new(
            at_idml_txt_only,
            at_folio_with_record_marks_only,
            Suspension::REPOSITEXT_TOKENS
          ).replay

          # Remove :record_mark tokens from at_idml (there shouldn't be any in there, just to be sure)
          at_idml_without_record_marks = Suspension::TokenRemover.new(
            at_idml,
            Suspension::REPOSITEXT_TOKENS.find_all { |e| :record_mark == e.name }
          ).remove

          # Add :record_marks to text and all other tokens.
          at_with_merged_tokens = Suspension::TokenReplacer.new(
            at_with_record_marks_only,
            at_idml_without_record_marks
          ).replace([:record_mark])
        when 'use_old'
          # Get plain text from at_idml
          at_without_tokens = Suspension::TokenRemover.new(
            at_idml,
            Suspension::REPOSITEXT_TOKENS
          ).remove

          # Add :record_mark tokens only to at_idml plain text
          at_with_record_marks_only = Suspension::TextReplayer.new(
            at_without_tokens,
            at_folio,
            Suspension::REPOSITEXT_TOKENS.find_all { |e| [:record_mark].include?(e.name) }
          ).replay

          # Remove :record_mark tokens from at_idml
          at_without_record_marks = Suspension::TokenRemover.new(
            at_idml,
            Suspension::REPOSITEXT_TOKENS.find_all { |e| [:record_mark].include?(e.name) }
          ).remove

          # Add :record_marks to text and all other tokens.
          at_with_merged_tokens = Suspension::TokenReplacer.new(
            at_with_record_marks_only,
            at_without_record_marks
          ).replace([:record_mark])
        end
        at_with_merged_tokens
      end

    end
  end
end
