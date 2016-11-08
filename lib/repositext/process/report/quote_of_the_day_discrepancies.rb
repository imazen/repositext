class Repositext
  class Process
    class Report

      # Reports any discrepancies in content between quote of the day records
      # and content AT.
      class QuoteOfTheDayDiscrepancies

        # Initialize a new report
        # @param qotd_records [Array<{:symbol => {:symbol => Object}}>]
        #   Example record:
        #       {
        #         date_code: "55-1115",
        #         posting_date_time: "2017-01-15 00:00:00.000",
        #         content: "the content...",
        #       }
        # @param content_type [ContentType]
        # @param language [Language]
        def initialize(qotd_records, content_type, language)
          @qotd_records = qotd_records
          @content_type = content_type
          @language = language
          @double_opening_quote = @language.chars[:d_quote_open]
          @double_closing_quote = @language.chars[:d_quote_close]
          @single_opening_quote = @language.chars[:s_quote_open]
          @single_closing_quote = @language.chars[:s_quote_close]
        end

        # Returns an outcome with a report of discrepancies
        # @return [Array<Hash>] collection of qotd records.
        def report
          # Iterate over each qotd record and check if it is present verbatim
          # in the corresponding content AT file.
          discrepancies = []
          @qotd_records.each { |qotd_record|
            puts " - processing #{ qotd_record[:date_code] }"
            sanitized_qotd_content = sanitize_qotd_content(qotd_record[:content])
            corresponding_content_at_file = RFile::ContentAt.find_by_date_code(
              qotd_record[:date_code],
              "at",
              @content_type
            )

            sanitized_content_at_plain_text = sanitize_content_at_plain_text(
              corresponding_content_at_file.plain_text_with_subtitles_contents({})
            )

            find_diffs_between_qotd_and_content_at(
              qotd_record[:date_code],
              qotd_record[:posting_date_time],
              sanitized_qotd_content,
              sanitized_content_at_plain_text,
              discrepancies
            )
          }
          assign_discrepancy_types(discrepancies)
          discrepancies
        end

      protected

        # @param qotd_content [String]
        def sanitize_qotd_content(qotd_content)
          # remove surrounding <p> tags
          # replace html entities with chars
          # replace &nbsp; with space
          # remove <em> tags
          # replace br tags with newline.
          # remove leading or trailing elipses
          # strip surrounding whitespace
          qotd_content.sub(/\A<p>/, '')
                      .sub(/<\/p>\z/, '')
                      .gsub('&ldquo;', @double_opening_quote)
                      .gsub('&rdquo;', @double_closing_quote)
                      .gsub('&lsquo;', @single_opening_quote)
                      .gsub('&rsquo;', @single_closing_quote)
                      .gsub('&hellip;', '…')
                      .gsub('&nbsp;', ' ')
                      .gsub('&mdash;', '—')
                      .gsub(/<\/?em>/, '')
                      .gsub(/\s*<br \/>\s*/, "\n")
                      .gsub(/\A…/, '')
                      .gsub(/…\z/, '')
                      .strip
        end

        # @param content_at_plain_text [String]
        def sanitize_content_at_plain_text(content_at_plain_text)
          # remove paragraph numbers
          # strip surrounding whitespace
          content_at_plain_text.gsub(/(@?)\d+ /, '\1')
                               .strip
        end

        # Finds diffs between qotd_txt and content_at_txt, adds diffs to collector.
        # @param date_code [String]
        # @param posting_date_time [String]
        # @param qotd_txt [String]
        # @param content_at_txt [String] plain text with subtitle_marks
        # @param collector [Array]
        def find_diffs_between_qotd_and_content_at(date_code, posting_date_time, qotd_txt, content_at_txt, collector)
          content_at_txt_without_subtitles = content_at_txt.delete('@')
          perfect_content_match = content_at_txt_without_subtitles.index(qotd_txt)
          matching_content_at_fragment = find_matching_content_at_fragment(
            qotd_txt,
            content_at_txt
          )
          if perfect_content_match
            # content is identical, check for subtitle alignment
            matching_subtitles_txt = matching_content_at_fragment.split('@').find_all { |e|
              qotd_txt.index(e.strip)
            }.join.strip
            if qotd_txt != matching_subtitles_txt
              # qotd is not aligned with subtitles, report as discrepancy
              qotd_diff, content_at_diff, diff_tokens = compute_diffs(
                qotd_txt,
                matching_subtitles_txt
              )
              collector << {
                date_code: date_code,
                posting_date_time: posting_date_time,
                qotd_content: qotd_diff,
                content_at_content: content_at_diff,
                diff_tokens: ['@'],
              }
            end
          else
            # some kind of content or style mismatch
            qotd_diff, content_at_diff, diff_tokens = compute_diffs(
              qotd_txt,
              matching_content_at_fragment.delete('@')
            )
            collector << {
              date_code: date_code,
              posting_date_time: posting_date_time,
              qotd_content: qotd_diff,
              content_at_content: content_at_diff,
              diff_tokens: diff_tokens
            }
          end
          true
        end

        # Finds subtitle misalignments between qotd_txt and content_at_txt, adds diffs to collector.
        # @param date_code [String]
        # @param posting_date_time [String]
        # @param qotd_txt [String]
        # @param content_at_txt [String] plain text with subtitle_marks
        # @param collector [Array]
        def find_subtitle_misalignments_between_qotd_and_content_at(date_code, posting_date_time, qotd_txt, content_at_txt, collector)
        end

        # @param qotd_txt [String] the entire qotd text
        # @param content_at_txt [String] the entire content AT text
        # @return [String] the matching lines in content AT
        def find_matching_content_at_fragment(qotd_txt, content_at_txt)
          aligner = QotdToContentAtAligner.new(
            qotd_txt.split("\n"),
            content_at_txt.split("\n")
          )
          aligned_qotd_lines, aligned_content_at_lines = aligner.get_optimal_alignment
          matching_content_at_lines = []
          aligned_content_at_lines.each_with_index { |ca_l, idx|
            qotd_l = aligned_qotd_lines[idx]
            matching_content_at_lines << ca_l  if qotd_l
          }
          matching_content_at_lines.join("\n").strip
        end

        # @param qotd_txt [String]
        # @param matching_content_at_fragment [String]
        # @return [Array<String, Array>] tuple of qotd diff line, content_at diff
        #   line and array of all chars that are different.
        #   We treat double hyphens and three elipises as single tokens, i.e. we
        #   don't break them up into individual chars.
        def compute_diffs(qotd_txt, matching_content_at_fragment)
          diffs = Suspension::StringComparer.compare(
            qotd_txt,
            matching_content_at_fragment,
            true,
            false
          )
          content_at_diff = []
          qotd_diff = []
          # pad diffs with nil before and after so that we can detect first and
          # last diff using each_cons.
          diffs.unshift(nil)
          diffs.push(nil)
          diff_tokens = []
          diffs.each_cons(3) { |prev, cur, nxt|
            type, frag, context = cur
            case type
            when 0
              qotd_diff << frag
              content_at_diff << frag
            when 1
              # check for partial qotd at beginning and end of quote
              if prev.nil? && 0 == nxt[0]
                # This is an insertion at the beginning of qotd, and following
                # fragment is identical. We assume that this is caused by
                # qotd starting in the middle of content AT line. Ignore this insertion.
              elsif nxt.nil? && 0 == prev[0]
                # This is an insertion at the end of qotd, and previous
                # fragment is identical. We assume that this is caused by
                # qotd ending before end of content AT line. Ignore this insertion.
              else
                # regular insertion, capture
                content_at_diff << frag.color(:black).background(:green)
                capture_diff_tokens(frag, diff_tokens)
              end
            when -1
              qotd_diff << frag.color(:black).background(:red)
              capture_diff_tokens(frag, diff_tokens)
            else
              raise "Handle this: #{ [type, frag, context] }"
            end
          }
          [qotd_diff.join, content_at_diff.join, diff_tokens.uniq.sort]
        end

        # Determines for all discrepancies whether they are of type :style or
        # :content. Stores results in discrepancies under :type key.
        # @param discrepancies [Array<{Symbol => Object}>]
        def assign_discrepancy_types(discrepancies)
          style_tokens = [
            @double_opening_quote,
            @double_closing_quote,
            @single_opening_quote,
            @single_closing_quote,
            '"',
            "'",
            "…",
            "...",
            "--",
            "—",
          ].compact
          discrepancies.each { |qotd_record|
            qotd_record[:type] = if [] == qotd_record[:diff_tokens] - style_tokens
              # contains only quotes, hyphens, emdashes, and elipses,
              # considered a :style diff
              :style
            elsif ['@'] == qotd_record[:diff_tokens]
              :subtitle
            else
              :content
            end
          }
        end

        # Extracts diff tokens from frag and adds them to coll
        # @param frag [String]
        # @param coll [Array]
        def capture_diff_tokens(frag, coll)
          frag_dup = frag.dup
          special_tokens = ['...', '--']
          # extract three periods and double hyphens as single tokens
          special_tokens.each { |token|
            if frag_dup.index(token)
              coll << token
              frag_dup.gsub!(token, '')
            end
          }
          coll.concat(frag_dup.chars)
        end

      end
    end
  end
end
