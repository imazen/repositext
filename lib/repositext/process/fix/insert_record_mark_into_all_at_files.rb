class Repositext
  class Process
    class Fix
      # Inserts a single record mark at the beginning of all files that don't
      # contain any record_marks yet. This is so that we can safely assume
      # the presence of record_marks in all content AT files.
      # Uses the first record mark from the corresponding file in the primary_repo
      class InsertRecordMarkIntoAllAtFiles

        # @param [String] text
        # @param [String] filename of the file to fix
        # @param [String] corresponding_filename of the source file in primary repo
        # @return [Outcome]
        def self.fix(text, filename, corresponding_filename)
          text = text.dup
          if contains_no_record_marks?(text)
            insert_record_mark(text, filename, corresponding_filename)
          else
            Outcome.new(true, { contents: text }, ['File already contains record_marks'])
          end
        end

      protected

        # Returns true if text contains no record marks
        def self.contains_no_record_marks?(text)
          !text.match(/^\^\^\^/)
        end

        # @param [String] text
        # @param [String] filename of the file to fix
        # @param [String] corresponding_filename of the source file in primary repo
        # @return [Outcome]
        def self.insert_record_mark(text, filename, corresponding_filename)
          if !File.exist?(corresponding_filename)
            return Outcome.new(false, nil, ["Corresponding primary file not found: #{ corresponding_filename.inspect }"])
          end
          primary_text = File.read(corresponding_filename)
          first_record_mark = primary_text.match(/^\^\^\^[^\n]*\n\n/).to_s
          if '' == first_record_mark
            return Outcome.new(false, nil, ["Corresponding primary file #{ corresponding_filename.inspect } contained no record marks"])
          end
          text.insert(0, first_record_mark)
          Outcome.new(true, { contents: text }, ['Successfully inserted record_mark'])
        end

      end
    end
  end
end
