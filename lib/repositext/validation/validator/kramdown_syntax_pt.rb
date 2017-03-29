class Repositext
  class Validation
    class Validator
      # Validates a kramdown PT string's valid syntax.
      # @deprecated we don't use kramdown PT at all.
      class KramdownSyntaxPt < KramdownSyntax

        def run
          document_to_validate = @file_to_validate.read
          outcome = valid_kramdown_syntax?(document_to_validate)
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

        # Returns an Array of features that are allowed in a PT document. Please
        # note: Not all of them are necessarily transformed. E.g., the repositext-
        # kramdown parser doesn't transform :typographic_syms, however since we
        # use the full kramdown parser for validation, they will appear in the
        # parse tree. Since they are allowed, just not transformed, we add them
        # here to the whitelist.
        #
        # kramdown features that are not allowed in PT:
        # ------------------------
        # :abbreviation,
        # :blockquote,
        # :codeblock,
        # :codespan,
        # :comment,
        # :dd,
        # :dl,
        # :dt,
        # :footnote,
        # :html_element,
        # :li,
        # :math,
        # :ol,
        # :raw,
        # :smart_quote,
        # :table,
        # :tbody,
        # :td,
        # :tfoot,
        # :thead,
        # :tr,
        # :ul,
        # :xml_comment,
        # :xml_pi,
        #
        # @return [Array<Symbol>]
        def self.whitelisted_kramdown_features
          [
            :a,
            :blank,
            :br,
            :em,
            :entity,
            :header,
            :hr,
            :img,
            :p,
            :root,
            :smart_quote,
            :strong,
            :text,
            :typographic_sym,
          ]
        end

        # Returns an array of whitelisted element class names.
        def self.whitelisted_class_names
          [
            { :name => 'bold', :allowed_contexts => [:span] },
            { :name => 'decreased_word_space', :allowed_contexts => [:block] },
            { :name => 'first_par', :allowed_contexts => [:block] },
            { :name => 'id_paragraph', :allowed_contexts => [:block] },
            { :name => 'id_title1', :allowed_contexts => [:block] },
            { :name => 'id_title2', :allowed_contexts => [:block] },
            { :name => 'id_title3', :allowed_contexts => [:block] },
            { :name => 'increased_word_space', :allowed_contexts => [:block] },
            { :name => 'indent_for_eagle', :allowed_contexts => [:block] },
            { :name => 'italic', :allowed_contexts => [:span] },
            { :name => 'line_break', :allowed_contexts => [:span] },
            { :name => 'no_highlight', :allowed_contexts => [:block] },
            { :name => 'normal', :allowed_contexts => [:block] },
            { :name => 'normal_pn', :allowed_contexts => [:block] },
            { :name => 'omit', :allowed_contexts => [:block] },
            { :name => 'pn', :allowed_contexts => [:span] },
            { :name => 'q', :allowed_contexts => [:block] },
            { :name => 'reading', :allowed_contexts => [:block] },
            { :name => 'rid', :allowed_contexts => [:block] },
            { :name => 'scr', :allowed_contexts => [:block] },
            { :name => 'smcaps', :allowed_contexts => [:span] },
            { :name => 'song', :allowed_contexts => [:block] },
            { :name => 'song_break', :allowed_contexts => [:block] },
            { :name => 'stanza', :allowed_contexts => [:block] },
            { :name => 'subscript', :allowed_contexts => [:span] },
            { :name => 'superscript', :allowed_contexts => [:span] },
            { :name => 'underline', :allowed_contexts => [:span] },
          ]
        end

        # Returns an array of regexes that will detect invalid characters.
        def self.invalid_character_detectors
          # '%' and '@' need to be entity encoded in PT files, so we add them
          # to list of invalid characters.
          Repositext::Validation::Config::INVALID_CHARACTER_REGEXES + [/[%@]/]
        end

      end
    end
  end
end
