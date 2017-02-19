class Repositext
  class Process
    class Split
      class Subtitles

        # This name space provides methods for transferring subtitles from
        # foreign plain text to foreign content AT.
        module TransferStsFromFPlainText2ForeignContentAt

          # @param f_pt [String] foreign plain text with subtitles
          # @param f_cat [String] foreign content AT to transfer subtitles to
          # @return [Outcome] with new content AT with subtitles as result.
          def transfer_sts_from_f_plain_text_2_f_content_at(f_pt, f_cat)
            # Separate content from id page
            cat_wo_id, id_page = Repositext::Utils::IdPageRemover.remove(f_cat)
            prepared_pt = prepare_plain_text(f_pt)

            # Use suspension to transfer subtitle_marks from plain_text to content AT
            f_cat_w_st = Suspension::TokenReplacer.new(
              prepared_pt,
              cat_wo_id
            ).replace(:subtitle_mark)
          end

          # Prepares plain text for suspension processing
          # @param pt [String] raw plain text
          def prepare_plain_text(pt)
            # Modify title
            new_pt = pt.dup
            second_line = pt.split("\n")[1]
            if second_line =~ /\A@?/
              # 2nd line starts with eagle, modify title in first line
              # Insert space at beginning of line
              new_pt.prepend(' ')
              # Insert second newline after title
              new_pt.sub!(/\n/, "\n\n")
            end
            # Append newline at the end
            new_pt << "\n"
            new_pt
          end
        end
      end
    end
  end
end
