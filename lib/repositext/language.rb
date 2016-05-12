class Repositext
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

    # @param lang_code [Symbol, String] 2 or 3 character language code
    def self.find_by_code(lang_code)
      symbolized_lang_code = lang_code.to_sym
      lang_attrs = case symbolized_lang_code.length
      when 2
        find_by(:code2, symbolized_lang_code)
      when 3
        find_by(:code3, symbolized_lang_code)
      else
        Raise "Invalid lang_code: #{ lang_code.inspect }"
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

    # def inspect
    #   %(#<#{ self.class.name }:#{ object_id } @name=#{ name.inspect } @code_2_chars=#{ code_2_chars.inspect } @code_3_chars=#{ code_3_chars.inspect })
    # end

    # @return [String]
    def name
      self.class.name.split('::').last
    end

    def split_into_words(txt)
      txt.split(/[— ]/)
    end

  private

    # @param attr_name [Symbol] one of :code2, :code3, :name
    # @param attr_val [Symbol, String] value to find language by
    def self.find_by(attr_name, attr_val)
      language_code_mappings.detect { |e| e[attr_name] == attr_val }
    end

  end
end
