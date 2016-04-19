class Repositext
  class Process
    class Extract

      # Extracts corrections from submitted text file
      class SubmittedSpotCorrections

        # @param spot_corrections_file_contents [String]
        # @return [Array<Hash>] a hash describing the corrections
        def self.extract(spot_corrections_file_contents)
          editor_initials = %w[JSR NCH RMM]
          correction_number_regex = /^\d+[a-z]?/
          segment_start_regexes = [
            { key: :first_line, regex: /(?=#{ correction_number_regex }\.)/ }, # first line, starting with correction number
            { key: :reads, regex: /^Reads:/ }, # `Reads:` segment
            { key: :becomes, regex: /^Becomes:/ }, # `Becomes:` segment
            { key: :submitted, regex: /^Submitted:/ }, # `Submitted:` segment
            { key: :no_change, regex: /^ASREADS/ }, # `ASREADS:` segment
            { key: :translator_note, regex: /^TRN:/ }, # Translator notes
          ] + editor_initials.map { |e| { key: "#{ e }_note".unicode_downcase.to_sym, regex: /^#{ e }:/ } } # editor notes
          # Each segment ends at beginning of next segment, or at end of string
          segment_end_regex = Regexp.new(
            (segment_start_regexes.map{ |e| e[:regex] } + [/\z/]).join('|')
          )
          # Remove preamble. We want corrections only
          corrections_only = spot_corrections_file_contents.sub(/.*?(?=#{ correction_number_regex }\.)/m, '')

          # Split on lines that begin with correction numbers
          individual_corrections = corrections_only.split(/(?=#{ correction_number_regex }\.)/)

          # Return array of correction attributes
          individual_corrections.map { |correction_text|

            c_attrs = {}
            s = StringScanner.new(correction_text)
            segment_start_regexes.each do |e|
              segment_key = e[:key]
              segment_start_regex = e[:regex]
              s.reset
              if s.skip_until(segment_start_regex) # advance up to and including segment start marker
                # fetch everything up to next segment start
                c_attrs[segment_key] = s.scan(/.+?(?=#{ segment_end_regex })/m).to_s.strip
              end
            end

            # extract correction number
            c_attrs[:correction_number] = c_attrs[:first_line].match(/#{ correction_number_regex }(?=\.)/)[0].to_s
            c_attrs[:paragraph_number] = c_attrs[:first_line].match(/paragraphs?\s+(\d+)/i)[1].to_s

            # Handle :no_change vs. :becomes
            if c_attrs[:no_change]
              # We found `ASREADS`, change attrs so that no change will be applied
              c_attrs[:no_change] = true
              # make sure `Becomes` is not present as well.
              raise("Unexpected `Becomes`: #{ correction_text }") if c_attrs[:becomes]
            end

            c_attrs # Return correction attributes
          }
        end

      end
    end
  end
end
