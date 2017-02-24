class Repositext
  class Process
    class Split
      class Subtitles

        # This name space provides methods for transferring subtitles from
        # foreign plain text to foreign content AT.
        module TransferStsFromFPlainText2ForeignContentAt

          # @param f_pt [String] foreign plain text with subtitles.
          # @param f_cat [String] foreign content AT to transfer subtitles to.
          # @param f_st_confs [Array<Float>] Array with foreign subtitle confidences.
          # @param remove_existing_sts [Boolean] if true will remove any
          #   subtitle_marks that already exist in f_cat.
          # @return [Outcome] with new content AT with subtitles and subtitle confidences as result.
          def transfer_sts_from_f_plain_text_2_f_content_at(f_pt, f_cat, f_st_confs, remove_existing_sts)
            if f_pt.count('@') != f_st_confs.length
              raise ArgumentError.new("Mismatch in subtitle (#{ f_pt.count('@') }) and confidence (#{ f_st_confs.length }) counts!")
            end

            # Separate content from id page
            cat_wo_id, id_page = Repositext::Utils::IdPageRemover.remove(f_cat)
            prepared_pt = pre_process_plain_text(f_pt)
            prepared_cat = pre_process_content_at(cat_wo_id, remove_existing_sts)

            # Use suspension to transfer subtitle_marks from plain_text to content AT
            f_cat_w_st = Suspension::TokenReplacer.new(
              prepared_pt,
              prepared_cat
            ).replace(:subtitle_mark)

            # Add id_page back
            f_cat_w_st << id_page

            # post process content AT
            final_f_cat = post_process_content_at(f_cat_w_st)

            validate_that_no_content_at_was_changed(f_cat, final_f_cat)

            Outcome.new(true, [final_f_cat, f_st_confs])
          end

          # Prepares plain text for suspension processing
          # @param pt [String] raw plain text
          # @return [String]
          def pre_process_plain_text(pt)
            new_pt = pt.dup

            # Modify title lines:
            # * Add second newline after any header line that is not followed
            #   by another header line.
            new_pt.gsub!(/^(@?\#[^\n]+\n)(?!@?\#)/, '\1' + "\n")
            # * Remove hash mark prefixes (with optional preceding newline)
            #   See comment above Suspension::RepositextTokens::BLOCK_START for
            #   reason of leading newline removal.
            # * Leave optional subtitle_mark and leading space
            new_pt.gsub!(/(?:\n|\A)(@?)\#/, '\1')

            # Modify horizontal rules so they match content AT:
            # Replace 7 asterisks with placeholder. Also append extra newline
            # to satisfy Suspention::TokenReplacer.
            new_pt.gsub!('* * * * * * *', repositext_hr_placeholder + "\n")

            # Move any subtitles that were placed before horizontal rules to the
            # end of the previous line:
            new_pt.gsub!("\n@#{ repositext_hr_placeholder }", "@\n#{ repositext_hr_placeholder }")

            # Encode entities
            new_pt = Repositext::Utils::EntityEncoder.encode(new_pt)

            # Append newline at the end
            new_pt << "\n"
            new_pt
          end

          # Prepares content AT for suspension processing
          # @param cat [String] content AT
          # @return [String]
          def pre_process_content_at(cat, remove_existing_sts)
            # Convert hrs to temporary placeholder
            r = cat.gsub("* * *", repositext_hr_placeholder)
            # Make sure file has two trailing newlines
            r.gsub!(/\n+\z/, "\n\n")
            r.gsub!('@', '')  if remove_existing_sts
            r
          end

          # Post processes content AT after suspension processing
          # @param cat [String] content AT
          # @return [String]
          def post_process_content_at(cat)
            # Convert temporary placeholders back to hrs and normalize to single
            # newline at end of file.
            cat.gsub(repositext_hr_placeholder, "* * *")
               .gsub(/\n+\z/, "\n")
          end

          # Raises an exception if any content was changed
          # @param f_cat [String] the original foreign content AT
          # @param f_cat_w_a_st [String] the new foreign content AT with subtitles
          def validate_that_no_content_at_was_changed(f_cat, f_cat_w_a_st)
            # Remove subtitles in both texts. f_cat may already have sts.
            orig_f_cat_wo_st = f_cat.gsub('@', '')
            new_f_cat_wo_st = f_cat_w_a_st.gsub('@', '')
            if new_f_cat_wo_st != orig_f_cat_wo_st
              diffs = Suspension::StringComparer.compare(orig_f_cat_wo_st, new_f_cat_wo_st)
              raise "Text mismatch between original content AT and content AT with subtitles: #{ diffs.inspect }"
            end
          end

          def repositext_hr_placeholder
            'Repositext-Hr-Placeholder'
          end
        end
      end
    end
  end
end
