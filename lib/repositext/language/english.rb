class Repositext
  class Language
    # Custom behavior for this language.
    class English < Language

      def short_words_for_title_capitalization
        %w[and in of on the]
      end

    end
  end
end
