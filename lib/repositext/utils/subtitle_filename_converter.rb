class Repositext
  class Utils
    # Converts filenames between repositext and subtitle/subtitle_tagging conventions.
    class SubtitleFilenameConverter

      # TODO: handle this via Repositext::Language!
      # Maps from 3 to 2 character language codes
      LANGUAGE_CODE_MAP = [
        %w[afr af],
        %w[alb sq],
        %w[amh am],
        %w[ara ar],
        %w[ast ak],
        %w[ate teo],
        %w[bem bem],
        %w[ben bn],
        %w[bul bg],
        %w[ceb ceb],
        %w[cha ny],
        %w[chn zh],
        %w[cnt cnt],
        %w[cre ht],
        %w[ctk tum],
        %w[czh cs],
        %w[dan da],
        %w[dut nl],
        %w[eng en],
        %w[est et],
        %w[ewe ee],
        %w[fin fi],
        %w[fon fon],
        %w[frn fr],
        %w[frs fa],
        %w[ger de],
        %w[hil hil],
        %w[hin hi],
        %w[hun hu],
        %w[ind id],
        %w[itl it],
        %w[jpn ja],
        %w[kan kn],
        %w[kde kqn],
        %w[khm km],
        %w[kin rw],
        %w[kir rn],
        %w[kor ko],
        %w[kya nyy],
        %w[lao lo],
        %w[lat lv],
        %w[lin ln],
        %w[lit lt],
        %w[loz loz],
        %w[lua lua],
        %w[lug lg],
        %w[mag mg],
        %w[mal ml],
        %w[man mni],
        %w[mar mr],
        %w[nde nd],
        %w[nep ne],
        %w[nor no],
        %w[nst nso],
        %w[ori or],
        %w[osh kj],
        %w[pol pl],
        %w[por pt],
        %w[pun pa],
        %w[rom ro],
        %w[rus ru],
        %w[ser sr],
        %w[sho sn],
        %w[sin si],
        %w[slo sk],
        %w[spn es],
        %w[sst st],
        %w[ssw ss],
        %w[swa sw],
        %w[swd sv],
        %w[tag tl],
        %w[tam ta],
        %w[tel te],
        %w[tng tog],
        %w[tso ts],
        %w[tsv ve],
        %w[tsw tn],
        %w[ukr uk],
        %w[urd ur],
        %w[uzb uz],
        %w[vie vi],
        %w[xho xh],
        %w[zul zu],
      ].freeze

      # Converts a repositext filename to the corresponding subtitle_export one
      # like so:
      #
      # /eng47-0412_0002.at => /47-0412_0002.en.txt OR /47-0412_0002.en.rt.txt
      # and
      # /eng47-0412_0002.at => /47-0412_0002.markers.txt
      #
      # @param [String] rt_filename the repositext filename
      # @param [Hash] output_file_attrs key: :extension
      # @return [String] the corresponding subtitle_export filename
      def self.convert_from_repositext_to_subtitle_export(rt_filename, output_file_attrs)
        extension = output_file_attrs[:extension]
        file_basename = File.basename(rt_filename)
        input_lang_code = file_basename[0,3] # should be 'eng'
        output_lang_code = if(['markers.txt', 'subtitle_markers.csv'].include?(extension))
          # don't include language extension for markers file
          ''
        else
          ".#{ convert_language_code(input_lang_code) }"
        end
        output_file_basename = file_basename.sub(/\A#{ input_lang_code }/, '')
                                            .sub(/\.at\z/, "#{ output_lang_code }.#{ extension }")
        rt_filename.sub(file_basename, output_file_basename)
      end

      # Converts a repositext filename to the corresponding subtitle_import one
      # like so:
      #
      # /eng47-0412_0002.at => /47-0412_0002.en.txt
      #
      # NOTE: import filenames are like export ones, except without the `.rt` extension.
      # @param [String] rt_filename the repositext filename
      # @return [String] the corresponding subtitle filename
      def self.convert_from_repositext_to_subtitle_import(rt_filename)
        file_basename = File.basename(rt_filename)
        lang_code = file_basename[0,3] # should be 'eng'
        output_file_basename = file_basename.sub(/\A#{ lang_code }/, '')
                                            .sub(/\.at\z/, ".#{ convert_language_code(lang_code) }.txt")
        rt_filename.sub(file_basename, output_file_basename)
      end

      # Converts a subtitle filename to the corresponding repositext one
      # like so:
      #
      # /47/47-0412_0002.en.txt => /47/eng47-0412_0002.at
      # OR
      # /cab_01_...1234.en.txt => /engcab_01...1234.at
      #
      # @param [String] st_filename the subtitle filename
      # @return [String] the corresponding repositext filename
      def self.convert_from_subtitle_import_to_repositext(st_filename)
        lang_code = st_filename.match(/(?<=\.)[[:alpha:]]{2,3}(?=\.txt\z)/).to_s # should be 'en'
        st_filename.sub(
                     /(?<=\/)(\d\d|cab)(?=[\-\_])/, # handle year digits or cab prefix
                     [convert_language_code(lang_code), '\1'].join
                   )
                   .sub(/\.#{ lang_code }\.txt\z/, '.at')
      end

    private

      # Converts language codes from 3 to 2 character ones.
      # @param [String] lang_code a 2 or 3 character language code
      def self.convert_language_code(lang_code)
        r = case lang_code.length
        when 2
          # return corresponding 3 char code
          mapping = LANGUAGE_CODE_MAP.detect { |e| lang_code.unicode_downcase == e.last }
          mapping ? mapping.first : nil
        when 3
          # return corresponding 2 char code
          mapping = LANGUAGE_CODE_MAP.detect { |e| lang_code.unicode_downcase == e.first }
          mapping ? mapping.last : nil
        else
          raise(ArgumentError.new("Invalid lang_code length, must be 2 or 3 chars: #{ lang_code.inspect }"))
        end
        raise(ArgumentError.new("Unknown lang_code: #{ lang_code.inspect }"))  if r.nil?
        r
      end

    end
  end
end
