class Repositext
  class Compare
    class RecordIdAndParagraphAlignment

# TODO:

# * make a pair collapsible if its below a certain similarity threshold

      # Compares the alignment of record ids and paragraphs between contents_1
      # and contents_2.
      # Expects contents to contain one row per record with the record_id at
      # the beginning of the line and all text on the same line.
      # @param[String] contents_1
      # @param[String] filename_1
      # @param[String] contents_2
      # @param[String] filename_2
      # @param[String] out_dir the base directory for html reports
      # @param[String] report_name the name of the report, used for filenames and dirs
      # @return[Outcome]
      def self.compare(contents_1, filename_1, contents_2, filename_2, base_dir, report_name)
        tokenized_contents_1 = tokenize(contents_1)
        tokenized_contents_2 = tokenize(contents_2)
        combined_tokens = combine_tokens(tokenized_contents_1, tokenized_contents_2)
        diffs = compute_diffs(combined_tokens)
        html_report_filename = compute_html_report_filename(base_dir, report_name, filename_1, filename_2)
        path_to_index_page = "../#{ report_name }-index.html"
        html_report = generate_html_report(
          diffs,
          path_to_index_page,
          filename_1.gsub(base_dir, ''),
          filename_2.gsub(base_dir, '')
        )
        Outcome.new(
          true,
          {
            html_report_filename: html_report_filename,
            html_report: html_report,
            number_of_diffs: diffs.each_with_object({}) { |e,m|
              m[e[:css_class]] ||= 0
              m[e[:css_class]] += 1
            },
          },
          []
        )
      end

    protected

      def self.record_id_regex
        # Record ids are normally 8 digits, however there are three documents where
        # the 4th character is one of [ABC] (e.g., '620B0029')
        /^[0-9]{3}[0-9ABC][0-9]{4}/
      end

      # Tokenizes contents into an array of hashes, Each hash has keys :record_id
      # and :text
      def self.tokenize(contents)
        contents.split("\n").map { |line|
          if(record_id = line.strip.match(record_id_regex))
            text = line.gsub(record_id_regex, '').strip
            { record_id: record_id.to_s, text: text }
          else
            nil
          end
        }.compact
      end

      def self.combine_tokens(tokens_1, tokens_2)
        combined_tokens = tokens_1.map { |token_1|
          {
            record_id: token_1[:record_id],
            text_1: token_1[:text],
            text_2: '',
            similarity: nil,
            css_class: nil,
          }
        }
        tokens_2.each { |token_2|
          entry = combined_tokens.detect { |e| e[:record_id] == token_2[:record_id] }
          if entry.nil?
            # no matching record id in tokens_1 found, create entry
            entry = {
              record_id: token_2[:record_id],
              text_1: '',
              text_2: token_2[:text],
              similarity: nil,
              css_class: nil,
            }
            combined_tokens << entry
          else
            # Update existing entry with token_2 data
            entry[:text_2] = token_2[:text]
          end
        }
        combined_tokens.sort! { |a,b| a[:record_id] <=> b[:record_id] }
        combined_tokens
      end

      def self.compute_diffs(combined_tokens)
        combined_tokens.each { |e|
          s = compute_string_similarity(e[:text_1], e[:text_2])
          e[:similarity] = s
          e[:css_class] = compute_css_class(s)
        }
        combined_tokens.find_all { |e| e[:similarity] < 1.0 }
      end

      def self.compute_html_report_filename(base_dir, report_name, filename_1, filename_2)
        basename_1 = File.basename(filename_1, '.txt')
        File.join(base_dir, report_name, [basename_1, 'html'].join('.'))
      end

      # Computes similarity between s1 and s2
      # @param[String] s1
      # @param[String] s2
      # @return[Float] 1.0 = identical, 0.0 = no similarity at all
      def self.compute_string_similarity(s1, s2)
        s1 = UnicodeUtils.downcase(s1).gsub(/\[[^\]]+\]/, ' ') # remove editors notes
                                      .gsub(/[^[:alpha:]\n\t\s]/, ' ') # remove all but characters and space
                                      .gsub(/[\n\t ]+/, ' ') # collapse space
        s2 = UnicodeUtils.downcase(s2).gsub(/\[[^\]]+\]/, ' ') # remove editors notes
                                      .gsub(/[^[:alpha:]\n\t\s]/, ' ') # remove all but characters and space
                                      .gsub(/[\n\t ]+/, ' ') # collapse space
        sim = case
        when s1 == s2
          1.0
        else
          # I tried tokenizing by chars, bigrams and words.
          # Words with at least 2 chars yielded best results.
          s1_words = s1.split.find_all { |e| e.length > 1 }.uniq
          s2_words = s2.split.find_all { |e| e.length > 1 }.uniq
          sorted_num_of_tokens = [s1_words.length, s2_words.length].sort
          shorter, longer = sorted_num_of_tokens
          if (shorter / longer.to_f) < 0.6
            0
          else
            (s1_words & s2_words).length / (s1_words | s2_words).length.to_f
          end
        end
      end

      # @param[Array<Hash>] diffs
      # @param[String] path_to_index a relative URL to the index page
      # @param[String] filename_1
      # @param[String] filename_2
      def self.generate_html_report(diffs, path_to_index, filename_1, filename_2)
        return nil  if diffs.empty? # Don't generate a report if they are all the same
        template_path = File.expand_path(
          "../../../../templates/html_diff_report.html.erb", __FILE__
        )
        @title = 'Compare Record id and paragraph alignment'
        @diffs = diffs.each_with_index.map { |e,idx|
          sim_percent = (e[:similarity] * 100).round
          similarity_widget = %(<span class="label #{ e[:css_class] }">#{ sim_percent }%</span>)
          collapse_css_class = if e[:css_class].index('label-default')
            "record-#{ idx } collapse"
          else
            "record-#{ idx } collapse in"
          end
          %(
            <tr>
              <td style="width: 40%">
                <p class="#{ collapse_css_class }">#{ e[:text_1] }</p>
              </td>
              <td style="width: 20%">
                <button data-toggle="collapse" data-target=".record-#{ idx }">#{ e[:record_id] }</button>
                #{ similarity_widget }
              </td>
              <td style="width: 40%">
                <p class="#{ collapse_css_class }">#{ e[:text_2] }</p>
              </td>
            </tr>
          )
        }.join
        @diffs_count = diffs.length
        @filename_1 = filename_1
        @filename_2 = filename_2
        @path_to_index = path_to_index
        erb_template = ERB.new(File.read(template_path))
        erb_template.result(binding)
      end

      # Computes the css class for the given similarity
      # @param[Float] similarity from 0.0 to 1.0
      def self.compute_css_class(similarity)
        case similarity
        when 0.0..0.5
          'label-danger'
        when 0.5..0.9
          'label-warning'
        else
          'label-default'
        end
      end

    end
  end
end
