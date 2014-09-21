# A customized parser for validation purposes. It has the following modifications
# from Kramdown::Parser::Kramdown:
#
# * parses all kramdown features, not just repositext ones so that we can
#   test for whitelisted features only.
#
module Kramdown
  module Parser
    class KramdownValidation < Kramdown::Parser::KramdownRepositext

      # Create a new Kramdown parser object with the given +options+.
      def initialize(source, options)
        super
        # NOTE: the order of parsers is important, don't change it!
        @block_parsers = [
          :blank_line,
          :codeblock,
          :codeblock_fenced,
          :blockquote,
          :atx_header,
          :horizontal_rule,
          :list,
          :definition_list,
          :block_html,
          :setext_header,
          :table,
          :footnote_definition,
          :link_definition,
          :abbrev_definition,
          :block_extensions,
          :block_math,
          :eob_marker,
          :record_mark,
          :paragraph
        ]
        @span_parsers = [
          :emphasis,
          :codespan,
          :autolink,
          :span_html,
          :footnote_marker,
          :link,
          :smart_quotes,
          :inline_math,
          :subtitle_mark,
          :gap_mark,
          :span_extensions,
          :html_entity,
          :typographic_syms,
          :line_break,
          :escaped_chars
        ]
      end

    end
  end
end
