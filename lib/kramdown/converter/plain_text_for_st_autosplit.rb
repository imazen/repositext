module Kramdown
  module Converter
    # Converts kramdown element tree to plain text for subtitle autosplitting.
    #
    # This subclass of PlainText expects the :st_autosplit_context option to
    # have one of the following values:
    # * :for_lf_aligner OR
    # @ :for_st_transfer
    class PlainTextForStAutosplit < PlainText

      # Returns false to ignore .line_break IAL classes will be handled.
      # @param options [Hash]
      def self.handle_line_break_class?(options)
        false
      end

      # Return false to ignore id
      # @param options [Hash]
      def self.include_id_elements?(options)
        false
      end

      # Return false to ignore paragraph numbers or true to include them.
      # @param options [Hash]
      def self.include_paragraph_numbers?(options)
        case options[:st_autosplit_context]
        when :for_lf_aligner_foreign, :for_lf_aligner_primary, :for_st_transfer_primary
          # We don't want paragraph numbers
          false
        when :for_st_transfer_foreign
          # We want paragraph numbers
          true
        else
          raise "Handle invalid :st_autosplit_context option: #{ options[:st_autosplit_context].inspect }"
        end
      end

      # Return true to prefix header lines with hash marks
      # @param options [Hash]
      def self.prefix_header_lines?(options)
        case options[:st_autosplit_context]
        when :for_lf_aligner_foreign, :for_st_transfer_foreign
          # We want header prefixes
          true
        when :for_lf_aligner_primary, :for_st_transfer_primary
          # We don't want header prefixes
          false
        else
          raise "Handle invalid :st_autosplit_context option: #{ options[:st_autosplit_context].inspect }"
        end
      end

      # We don't want subtitle marks for LF Aligner (It throws off the sentence
      # splitter), however we want them for subtitle transfer.
      # @param options [Hash]
      def self.subtitle_mark_output(options)
        case options[:st_autosplit_context]
        when :for_lf_aligner_foreign, :for_lf_aligner_primary
          # We don't want subtitle marks
          nil
        when :for_st_transfer_foreign, :for_st_transfer_primary
          # We want subtitle_marks for st_transfer
          ['@', nil]
        else
          raise "Handle invalid :st_autosplit_context option: #{ options[:st_autosplit_context].inspect }"
        end
      end

      # Post processes the exported plain text.
      # @param raw_plain_text [String]
      # @return [String]
      def post_process_export(raw_plain_text, options)
        # Remove leftover spaces at beginning of line from skipped paragraph
        # numbers. There may be an optional subtitle_mark first.
        raw_plain_text.strip.gsub(/^(@?) /, '\1')
      end
    end
  end
end
