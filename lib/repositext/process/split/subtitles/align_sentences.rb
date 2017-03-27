class Repositext
  class Process
    class Split
      class Subtitles

        # This name space provides methods for aligning the sentences of a
        # foreign content AT file and its corresponding primary content AT file.
        module AlignSentences

          # @param p_content_at_file [Repositext::RFile::ContentAt] the primary content AT file
          # @param f_content_at_file [Repositext::RFile::ContentAt] the foreign content AT file
          # @return [Outcome] with the aligned sentences as result.
          #   The aligned sentence pairs are an Array of arrays where the first
          #   item is the primary sentence (or nil) and the second item is the
          #   foreign sentence (or nil).
          def align_sentences(p_content_at_file, f_content_at_file)
            # Fetch input files
            p_input_filename = @p_content_at_file.corresponding_st_autosplit_filename
            f_input_filename = @f_content_at_file.corresponding_st_autosplit_filename

  # TODO: check that both files exist

            # Invoke lf_aligner
            lf_aligner_script_path = File.expand_path(
              "../../../../../../vendor/lf_aligner_3.12/scripts/LF_aligner_3.12_with_modules.pl",
              __FILE__
            )
            output_filename = f_input_filename.sub(/\.txt\z/, '.aligned.txt')
            lf_aligner_cmd = [
              lf_aligner_script_path,
              %(--filetype="t"),
              %(--infiles="#{ p_input_filename }","#{ f_input_filename }"),
              %(--outfile="#{ output_filename }"),
              %(--languages="#{ @p_content_at_file.language_code_2_chars }","#{ @f_content_at_file.language_code_2_chars }"),
              %(--segment="y"),
              %(--review="n"),
              %(--tmx="n"),
            ].join(' ')
            stdout_and_stderr_str, status = Open3.capture2e(lf_aligner_cmd)
  # TODO: check successful result (using lf_aligner console output)

            # Read aligned sentences back
            # <primary sentence>\t<foreign_sentence>\t<primary_filename>-<foreign_filename>
            lf_aligner_output = File.read(output_filename)

            aligned_sentence_pairs = lf_aligner_output.split("\n").map { |line|
              p_s, f_s, _ = line.split("\t")
              [p_s, f_s]
            }

            Outcome.new(true, aligned_sentence_pairs)
          end
        end
      end
    end
  end
end
