class Repositext
  class Merge
    class TitlesFromFolioRoundtripCompareIntoContentAt

      # Merges titles from folio roundtrip compare files into content_at.
      # @param[String] folio_roundtrip_compare the folio roundtrip compare file
      # @param[String] content_at to merge title into
      # @return[Outcome] the merged document is returned as #result if successful.
      def self.merge(folio_roundtrip_compare, content_at)
        t = extract_title(folio_roundtrip_compare)
        t = Repositext::Utils::EntityEncoder.encode(t)
        outcome = merge_title_into_content_at(t, content_at)
      end

    protected

      def self.extract_title(folio_roundtrip_compare)
        m = folio_roundtrip_compare.match(
          /
            \A # beginning of document
            \s* # optional whitespace
            ([^\s]+) # record id capture group 1
            \s+ # required whitespace
            ([^\n]+) # any character except newline, capture group 2
          /x
        )
        if m && m[2]
          t = m[2].to_s.strip
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
