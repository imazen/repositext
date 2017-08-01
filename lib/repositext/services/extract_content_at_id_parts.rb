class Repositext
  class Services

    # This service extracts parts from a file's id page:
    #
    # Usage:
    #  outcome = ExtractContentAtIdParts.call(content_at)
    #  id_parts = outcome.result
    #
    class ExtractContentAtIdParts

      # @param content_at [String]
      def self.call(content_at)
        new(content_at).call
      end

      # @param content_at [String]
      def initialize(content_at)
        @content_at = content_at
      end

      def call
        parts_to_extract = %w[id_title1 id_title2 id_paragraph]
        parts_collector = parts_to_extract.inject({}) { |m,part_class|
          m[part_class] = []
          m[part_class] << @content_at[/^[^\n]+(?=\n\{: \.#{ part_class }\})/]
          m
        }
        Outcome.new(true, parts_collector, [])
      end

    end
  end
end
