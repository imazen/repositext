class Repositext
  class Utils
    # Removes id page from an AT document
    class IdPageRemover

      # Removes id page and its contents from txt
      # @param txt [String] complete AT document
      # @return [Array<String>] An array of content AT without id page, and the id page
      def self.remove(txt)
        id_page_regexp = /
          [^\n]+\n # the line before a line that contains '.id_title1'
          [^\n]+\.id_title1 # line that contains id_title
          .* # anything after the line that contains .id_title
        /mx # multiline so that the last .* matches multiple lines to the end of file

        id_page = txt.match(id_page_regexp).to_s
        txt_wo_id_page = txt.gsub(id_page_regexp, '')
        [txt_wo_id_page, id_page]
      end

    end
  end
end
