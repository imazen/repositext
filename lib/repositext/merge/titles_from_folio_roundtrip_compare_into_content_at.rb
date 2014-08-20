class Repositext
  class Merge
    class TitlesFromFolioRoundtripCompareIntoContentAt

      # Merges titles from folio roundtrip compare files into content_at.
      # @param[String] folio_roundtrip_compare the folio roundtrip compare file
      # @param[String] content_at to merge title into
      # @return[Outcome] the merged document is returned as #result if successful.
      def self.merge(folio_roundtrip_compare, content_at)
        title_from_folio_roundtrip_compare = extract_title(folio_roundtrip_compare)
        outcome = merge_title_into_content_at(title_from_folio_roundtrip_compare, content_at)
      end

    protected

      def self.extract_title(folio_roundtrip_compare)
        m = folio_roundtrip_compare.match(/\A([^\s]+)\s+([^\n]+)/)
        if m && m[2]
          t = m[2].to_s
        else
          raise "No title found in #{ folio_roundtrip_compare[0,100].inspect }"
        end
        t
      end

      def self.merge_title_into_content_at(title, content_at)
        r = content_at.gsub(/^# [^\n]+/, "# *#{ title.strip }*")
        Outcome.new(true, r)
      end

    end
  end
end
