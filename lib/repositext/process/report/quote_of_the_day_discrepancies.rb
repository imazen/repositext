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
          @double_quotes = [:d_quote_close, :d_quote_open].map { |e| @language.chars[e] }.join
          @single_quotes = [:s_quote_close, :s_quote_open].map { |e| @language.chars[e] }.join
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
              corresponding_content_at_file.plain_text_contents({})
            )
            find_diffs_between_qotd_and_content_at(
              qotd_record[:date_code],
              qotd_record[:posting_date_time],
              sanitized_qotd_content,
              sanitized_content_at_plain_text,
              discrepancies
            )
          }
          discrepancies
        end

      protected

        # @param qotd_content [String]
        def sanitize_qotd_content(qotd_content)
          # replace three periods with elipsis
          # replace all para boundaries with newline.
          # replace two hyphens with emdash
          qotd_content.gsub('...', "…")
                      .gsub(/\s*<br \/>\s*|\s{2,}/, "\n")
                      .gsub("--", "—")
                      .strip
        end

        # @param content_at_plain_text [String]
        def sanitize_content_at_plain_text(content_at_plain_text)
          # replace typographic quotes with straight ones
          # remove paragraph numbers
          content_at_plain_text.gsub(/[#{ @double_quotes }]/, '"')
                               .gsub(/[#{ @single_quotes }]/, "'")
                               .gsub(/^\d+ /, '')
                               .strip
        end

        # Finds diffs between qotd_txt and content_at_txt, adds diffs to collector.
        # @param date_code [String]
        # @param posting_date_time [String]
        # @param qotd_txt [String]
        # @param content_at_txt [String]
        # @param collector [Array]
        def find_diffs_between_qotd_and_content_at(date_code, posting_date_time, qotd_txt, content_at_txt, collector)
          match = content_at_txt.index(qotd_txt)
          if !match
            matching_content_at_fragment = find_matching_content_at_fragment(
              qotd_txt,
              content_at_txt
            )

            qotd_diff, content_at_diff = compute_diffs(
              qotd_txt,
              matching_content_at_fragment
            )

            collector << {
              date_code: date_code,
              posting_date_time: posting_date_time,
              qotd_content: qotd_diff,
              content_at_content: content_at_diff,
            }
          end
          true
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
        # @return [Array<String>] tuple of qotd diff line and content_at diff line
        def compute_diffs(qotd_txt, matching_content_at_fragment)
          diffs = Suspension::StringComparer.compare(
            qotd_txt,
            matching_content_at_fragment,
            true,
            false
          )
          content_at_diff = []
          qotd_diff = []
          diffs.map { |type, frag, context|
            case type
            when 0
              qotd_diff << frag
              content_at_diff << frag
            when 1
              content_at_diff << frag.color(:black).background(:green)
            when -1
              qotd_diff << frag.color(:black).background(:red)
            else
              raise "Handle this: #{ [type, frag, context] }"
            end
          }
          [qotd_diff.join, content_at_diff.join]
        end

      end
    end
  end
end
