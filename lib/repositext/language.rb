class Repositext
  # Abstract class to represent a language.
  # @abstract
  class Language

    def self.language_code_mappings
      [
        { code2: :af, code3: :afr, name: 'Afrikaans' },
        { code2: :en, code3: :eng, name: 'English' },
        { code2: :es, code3: :spn, name: 'Spanish' },
        { code2: :vi, code3: :vie, name: 'Vietnamese' },
        { code2: :x_, code3: :x__, name: 'Generic' },
      ]
    end

    # Returns a map of semantic character names and their language
    # specific implementation, e.g., double opening quote.
    def self.chars
      {
        apostrophe: "’",
        d_quote_close: "”",
        d_quote_open: "“",
        elipsis: "…",
        em_dash: "—",
        s_quote_close: "’",
        s_quote_open: "‘",
      }
    end

    def self.all_typographic_chars
      [
        :apostrophe,
        :d_quote_close,
        :d_quote_open,
        :elipsis,
        :em_dash,
        :s_quote_close,
        :s_quote_open,
      ].map { |e| chars[e] }
    end

    # TODO: Remove this hack and make all methods on Language class either class
    # or instance methods!
    def chars
      self.class.chars
    end

    # @param lang_code [Symbol, String] 2 or 3 character language code (lower case)
    def self.find_by_code(lang_code)
      symbolized_lang_code = lang_code.to_sym
      lang_attrs = case symbolized_lang_code.length
      when 2
        find_by(:code2, symbolized_lang_code)
      when 3
        find_by(:code3, symbolized_lang_code)
      else
        raise "Invalid lang_code: #{ lang_code.inspect }"
      end
      Object.const_get("Repositext::Language::#{ lang_attrs[:name] }").new
    end

    # @param repo_dir_name [String] e.g., "english" or "haitian-creole"
    # @return [Language]
    def self.find_by_repo_dir_name(repo_dir_name)
      # Convert 'haitian-creole' => 'HaitianCreole'
      lang_class_name = repo_dir_name.split('-').map { |e| e.capitalize }.join
      Object.const_get("Repositext::Language::#{ lang_class_name }").new
    end

    # @return [Symbol] 2 character language code
    def code_2_chars
      self.class.find_by(:name, self.class.name.split('::').last)[:code2]
    end

    # @return [Symbol] 3 character language code
    def code_3_chars
      self.class.find_by(:name, self.class.name.split('::').last)[:code3]
    end

    # Returns the first sentence boundary's position in str or Nil if none found.
    # @param str [String]
    # @return [Integer, Nil]
    def sentence_boundary_position(str)
      str.index('.') || str.index('!') || str.index('?')
    end

     # Returns list of words that may be capitalized differently in titles.
    def short_words_for_title_capitalization
      # Override this method in subclasses
      []
    end

    def inspect
      %(#<#{ self.class.name }:#{ object_id } @name=#{ name.inspect } @code_2_chars=#{ code_2_chars.inspect } @code_3_chars=#{ code_3_chars.inspect }>)
    end

    # @return [String]
    def name
      self.class.name.split('::').last
    end

    # Returns self's repo base directory name (last segment).
    # Example: Hawaiian Creole => "hawaiian-creole"
    # @return [String]
    def repo_base_dir_name
      name.gsub(/\s+/, '-').underscore.dasherize
    end

    # Returns absolute path to repo_base_dir.
    # Expects pwd to be in one of the language dirs.
    # @return [String]
    def repo_base_dir
      File.join(Repositext::PARENT_DIR, repo_base_dir_name)
    end

    def split_into_words(txt)
      txt.split(/[— ]/)
    end

    # Returns a set of rules to be used when running the paragraph_style_consistency
    # validations on files in this language. It determines what kind of differences
    # in formatting_spans are reported:
    # First the :map_foreign_to_primary_formatting_spans lambda is applied with each
    # paragraph's :formatting_spans attributes. The lambda returns the transformed
    # :formatting_spans that will then be validated.
    # Then the applicable validation rule is computed given the formatting_span_type
    # (e.g., :italic) and the containing paragraph classes. The most specific
    # rule will be returned, starting at language level, then formatting_span_types,
    # then paragraph_classes.
    # The rules are:
    # * :strict - report any difference
    # * :report_extra - report only formatting spans that are extra in foreign,
    #     ignore any missing ones.
    # * :report_missing - report only formatting spans that are missing in
    #     foreign, ignore extra ones.
    # * :none - don't report any differences.
    def paragraph_style_consistency_validation_rules
      {
        map_foreign_to_primary_formatting_spans: ->(paragraph_attrs) {
          # paragraph_attrs:
          # {
          #   :type=>:p,
          #   :paragraph_classes=>['normal'],
          #   :formatting_spans=>[:italic],
          #   :line_number=>1
          # }
          paragraph_attrs[:formatting_spans]
        },
        language: :strict,
        formatting_span_type: {
          smcaps: :report_extra,
        },
        paragraph_class: {
          p: {
            id_paragraph: :none,
            id_title1: :none,
            id_title2: :none,
            scr: { smcaps: :strict },
          },
          header: {
            smcaps: :strict
          }
        }
      }
    end

  private

    # @param attr_name [Symbol] one of :code2, :code3, :name
    # @param attr_val [Symbol, String] value to find language by
    def self.find_by(attr_name, attr_val)
      language_code_mappings.detect { |e| e[attr_name] == attr_val }
    end

  end
end
