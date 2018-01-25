class Repositext
  class Language
    # Custom behavior for this language.
    class English < Language

      def words_that_can_be_capitalized_differently_in_title_consistency_validation
        %w[and in of on the]
      end

      def words_that_can_be_different_in_title_consistency_validation
        %w[on]
      end

    end
  end
end
