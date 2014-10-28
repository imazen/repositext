class Repositext
  class Fix
    class InsertRecordMarkIntoAllAtFiles

      # Inserts a single record mark at the beginning of all files that don't
      # contain any record_marks yet. This is so that we can safely assume
      # the presence of record_marks in all content AT files.
      # Uses the first record mark from the corresponding file in the primary_repo
      # @param[String] text
      # @param[String] filename of the file to fix
      # @param[String] repo_base_dir of the file's repo
      # @param[String] primary_repo_base_dir
      # @param[Array<String>] lang_code_transform, tuple of own lang code and primary lang code
      # @return[Outcome]
      def self.fix(text, filename, repo_base_dir, primary_repo_base_dir, lang_code_transform)
        text = text.dup
        outcome = if contains_no_record_marks?(text)
          insert_record_mark(text, filename, repo_base_dir, primary_repo_base_dir, lang_code_transform)
        else
          Outcome.new(true, { contents: text }, ['File already contains record_marks'])
        end
      end

    protected

      # Returns true if text contains no record marks
      def self.contains_no_record_marks?(text)
        text.index("\n^^^").nil?
      end

      # @param[String] text
      # @param[String] filename of the file to fix
      # @param[String] repo_base_dir of the file's repo
      # @prram[String] primary_repo_base_dir
      # @param[Array<String>] lang_code_transform, tuple of own lang code and primary lang code
      # @return[Outcome]
      def self.insert_record_mark(text, filename, repo_base_dir, primary_repo_base_dir, lang_code_transform)
        corresponding_primary_filename = filename.gsub(
          repo_base_dir,
          primary_repo_base_dir
        ).gsub(
          /\/#{ lang_code_transform.first }/,
          "/#{ lang_code_transform.last }"
        )
        if !File.exists?(corresponding_primary_filename)
          return Outcome.new(false, nil, ["No corresponding primary file found for #{ filename.inspect }"])
        end
        primary_text = File.read(corresponding_primary_filename)
        first_record_mark = primary_text.match(/^\^\^\^[^\n]*\n\n/).to_s
        if '' == first_record_mark
          return Outcome.new(false, nil, ["Corresponding primary file #{ corresponding_primary_filename.inspect } contained no record marks"])
        end
        text.insert(0, first_record_mark)
        Outcome.new(true, { contents: text }, ['Successfully inserted record_mark'])
      end

    end
  end
end
