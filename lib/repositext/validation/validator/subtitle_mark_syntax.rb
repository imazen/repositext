class Repositext
  class Validation
    class Validator
      # Validates that all subtitle marks are valid.
      class SubtitleMarkSyntax < Validator

        class InvalidSubtitleMarkError < StandardError; end

        # Runs all validations for self
        def run
          content_at_file = @file_to_validate
          outcome = subtitle_marks_valid?(content_at_file)
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

      private

        # Checks that all subtitle marks are valid
        def subtitle_marks_valid?(content_at_file)
          # Early return if content doesn't contain any subtitle_marks
          return Outcome.new(true, nil)  if !content_at_file.contents.index('@')

          invalid_subtitle_marks = find_invalid_subtitle_marks(
            content_at_file.contents,
            content_at_file.subtitles
          )
          if invalid_subtitle_marks.empty?
            Outcome.new(true, nil)
          else
            Outcome.new(
              false, nil, [],
              invalid_subtitle_marks.map { |(error, location, excerpt)|
                Reportable.error(
                  {
                    filename: content_at_file.filename,
                  }.merge(location),
                  [error, excerpt]
                )
              }
            )
          end
        end

        # @param content [String] the content AT
        # @param subtitles [Array<Subtitle>] the content AT file's subtitles
        def find_invalid_subtitle_marks(content, subtitles)
          r = []
          # split on lines for location info
          content.split(/\n/).each_with_index { |para, line_idx|
            next  if '' == para # skip empty lines
            para_subtitles_count = para.count('@')
            para_subtitles = subtitles.shift(para_subtitles_count)
            if para =~ /\{[^\}]*@[^\}]*\}/
              r << ["Subtitle mark inside IAL", { line: line_idx + 1 }, para]
            end
            if para =~ /\(@|@\)/
              r << ["Subtitle mark on wrong side of parens", { line: line_idx + 1 }, para]
            end
            if para =~ /\*[^\*]*@[^\*]*\*\{: \.pn\}/
              r << ["Subtitle mark inside paragraph number", { line: line_idx + 1 }, para]
            end
            # Subtitle mark at record boundary inside an editor's note
            if(
              (sts_at_rb_w_idx = para_subtitles.each_with_index.find_all { |e,idx| e.tmp_is_record_boundary }).any? &&
              (ed_notes_w_st = para.scan(/\[[^\]]*@[^\]]*\]/)).any?
            )
              # Quick test determined if any subtitle marks inside editors notes exist.
              # Now we need to check if a subtitle mark at a record boundary
              # exists inside an editor's note.
              sts_at_rb_w_idx.each do |st_at_rb_w_idx|
                ed_notes_w_st.each do |ed_note|
                  txt_before, txt_after = para.split(ed_note)
                  st_count_before = txt_before.count('@')
                  st_count_inside = ed_note.count('@')
                  st_count_after = txt_after.count('@')
                  if (st_count_before + st_count_inside + st_count_after) != para_subtitles_count
                    raise "Handle this!\n\n#{ para.inspect }\n\n#{ ed_note.inspect }"
                  end
                  st, st_idx = st_at_rb_w_idx
                  last_st_before_idx = st_count_before - 1
                  first_st_after_idx = st_count_before + st_count_inside
                  if (last_st_before_idx < st_idx) && (first_st_after_idx > st_idx)
                    # Invalid subtitle mark is inside editor's note, report error
                    r << [
                      "Subtitle mark at record boundary inside editors note",
                      { line: line_idx + 1 },
                      ed_note
                    ]
                  end
                end
              end
            end
          }
          r
        end

      end
    end
  end
end
