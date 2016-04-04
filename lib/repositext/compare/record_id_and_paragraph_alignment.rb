class Repositext
  class Compare
    class RecordIdAndParagraphAlignment

      # Compares the alignment of record ids and paragraphs between contents_1
      # and contents_2.
      # Expects contents to contain one row per record with the record_id at
      # the beginning of the line and all text on the same line.
      # @param contents_1 [String]
      # @param filename_1 [String]
      # @param contents_2 [String]
      # @param filename_2 [String]
      # @param base_dir [String] the base directory for html reports
      # @param report_name [String] the name of the report, used for filenames and dirs
      # @return [Outcome]
      def self.compare(contents_1, filename_1, contents_2, filename_2, base_dir, report_name)
        tokenized_contents_1 = tokenize(contents_1)
        tokenized_contents_2 = tokenize(contents_2)
        combined_tokens = combine_tokens(tokenized_contents_1, tokenized_contents_2)
        confidence_levels = compute_correctness_confidence_levels(combined_tokens)
        html_report_filename = compute_html_report_filename(base_dir, report_name, filename_1, filename_2)
        path_to_index_page = "../#{ report_name }-index.html"
        html_report = generate_html_report(
          confidence_levels,
          path_to_index_page,
          filename_1.gsub(base_dir, ''),
          filename_2.gsub(base_dir, '')
        )
        Outcome.new(
          true,
          {
            html_report_filename: html_report_filename,
            html_report: html_report,
            number_of_confidence_levels: confidence_levels.each_with_object({}) { |e,m|
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
        contents.split(/\n(?=\d)/).map { |record_text|
          if(record_id = record_text.strip.match(record_id_regex))
            text = record_text.gsub(record_id_regex, '').strip.gsub(/^\s+/, '')
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
            source_1: token_1[:text],
            source_2: '',
            confidence: nil,
            css_class: 'label-default',
          }
        }
        tokens_2.each { |token_2|
          entry = combined_tokens.detect { |e| e[:record_id] == token_2[:record_id] }
          if entry.nil?
            # no matching record id in tokens_1 found, create entry
            entry = {
              record_id: token_2[:record_id],
              source_1: '',
              source_2: token_2[:text],
              confidence: nil,
              css_class: 'label-default',
            }
            combined_tokens << entry
          else
            # Update existing entry with token_2 data
            entry[:source_2] = token_2[:text]
          end
        }
        # Manually set confidence of first record (title) since it won't get
        # processed using each_cons(2) in #compute_correctness_confidence_levels
        combined_tokens.sort! { |a,b| a[:record_id] <=> b[:record_id] }
        combined_tokens.first[:confidence] = 1.0
        combined_tokens
      end

      def self.compute_correctness_confidence_levels(combined_tokens)
        combined_tokens.each_cons(2) { |(record_1, record_2)|
          s = compute_confidence_level(
            record_1[:source_1],
            record_1[:source_2],
            record_2[:source_1],
            record_2[:source_2]
          )
          record_2[:confidence] = s
          record_2[:css_class] = compute_css_class(s)
        }
        combined_tokens
      end

      def self.compute_html_report_filename(base_dir, report_name, filename_1, filename_2)
        basename_1 = File.basename(filename_1, '.txt')
        File.join(base_dir, report_name, [basename_1, 'html'].join('.'))
      end

      # Computes confidence level that the boundary between record_1 and record_2
      # is in the correct location. It uses the texts surrounding the record_mark
      # from source_1 and source_2. It stores the confidence level of correctness
      # on record_2.
      # It uses the following features to compute the confidence level:
      #  * record_2 first paragraph_number similarity
      #  * record_1 end text similarity
      #  * record_2 start text similarity
      # @param rec1_s1 [String] record_1 text from source 1
      # @param rec1_s2 [String] record_1 text from source 2
      # @param rec2_s1 [String] record_2 text from source 1
      # @param rec2_s2 [String] record_2 text from source 2
      # @return [Float] 1.0 = identical, 0.0 = no similarity at all
      def self.compute_confidence_level(rec1_s1, rec1_s2, rec2_s1, rec2_s2)
        text_window_size = 200 # in chars

        # Compute record_2 first paragraph_number similarity.
        r2_first_par_num_similarity = compute_paragraph_number_similarity(
          rec2_s1, rec2_s2
        )

        # Compute record_1 end text similarity
        r1_end_text_similarity = compute_text_similarity(
          rec1_s1, rec1_s2, :end, text_window_size, nil
        )
        # Compute record_2 start text similarity
        r2_start_text_similarity = compute_text_similarity(
          rec2_s1, rec2_s2, :start, text_window_size, nil
        )
        # Compute confidence level that boundary is correct
        outcome = compute_confidence_level_for_features(
          r2_first_par_num_similarity,
          r1_end_text_similarity,
          r2_start_text_similarity,
        )
        return outcome.result  if outcome.success?

        # If we're not convinced at this point that the boundary is correct,
        # we try a different approach where we remove editors notes:
        # Compute record_1 end text similarity
        r1_end_text_similarity = compute_text_similarity(
          rec1_s1, rec1_s2, :end, text_window_size, :remove_editors_notes
        )
        # Compute record_2 start text similarity
        r2_start_text_similarity = compute_text_similarity(
          rec2_s1, rec2_s2, :start, text_window_size, :remove_editors_notes
        )
        # Compute confidence level that boundary is correct
        outcome = compute_confidence_level_for_features(
          r2_first_par_num_similarity,
          r1_end_text_similarity,
          r2_start_text_similarity,
        )
        return outcome.result  if outcome.success?

        # If we're not convinced at this point that the boundary is correct,
        # we print out details on the record inspected and assume that the boundary
        # is not correct.
        puts '-' * 40
        puts "rec1_s1:"
        p rec1_s1.inspect
        puts "rec1_s2:"
        p rec1_s2.inspect
        puts "rec2_s1:"
        p rec2_s1.inspect
        puts "rec2_s2:"
        p rec2_s2.inspect
        puts "r2_first_par_num_similarity: #{ r2_first_par_num_similarity.inspect }"
        puts "r1_end_text_similarity: #{ r1_end_text_similarity.inspect }"
        puts "r2_start_text_similarity: #{ r2_start_text_similarity.inspect }"

        outcome.result
      end

      # Computes the similarity of a leading paragraph number in the two texts.
      # @param txt_s1 [String] the text from the first source
      # @param txt_s2 [String] the text from the second source
      # @return [Array] A tuple with [<description>, <metric>]
      def self.compute_paragraph_number_similarity(txt_s1, txt_s2)
        pn_s1, pn_s2 = [txt_s1, txt_s2].map { |e| e.strip.scan(/\A\d+[a-z]?/).first }
        case
        when pn_s1 && pn_s2
          # Both texts start with a paragraph number
          if pn_s1 == pn_s2
            # They start with the same paragraph number
            [:identical, nil]
          else
            # They start with different paragraph numbers
            [:same_position_with_different_numbers, pn_s1.to_i - pn_s2.to_i]
          end
        when (
          (idx1 = (pn_s1.nil? && pn_s2 && txt_s1.index(pn_s2))) ||
          (idx2 = (pn_s2.nil? && pn_s1 && txt_s2.index(pn_s1)))
        )
          # Same pn is present in both sources, however in one of them it's not at
          # the beginning.
          # Compute similarity based on how far pn is moved from start position
          # 1.0 = pn at start, 0.0 = at end of or outside of text window
          max_text_len = idx1 ? txt_s1.length : txt_s2.length
          idx = idx1 || idx2
          pos_metric = 1.0 - (idx / max_text_len.to_f)
          [:different_position_with_same_numbers, pos_metric]
        when pn_s1.nil? && pn_s2.nil?
          # pn is missing in both
          [:missing_in_both, nil]
        else
          # pn is missing in one
          [:missing_in_one, nil]
        end
      end

      # Computes similarity of txt_1 and txt_2:
      #  * Removes all but whitespace and alphabetic characters
      #  * Splits text into array of words
      #  * Computes something similar to Jaccard index. Only difference: Operates on
      #    an array with duplicate words, not on a set where duplicates are discarded.
      # @param txt_1 [String]
      # @param txt_2 [String]
      # @param which_end [Symbold] one of :start or :end
      # @param text_window_size [Integer] how far to look into the text
      # @param fall_back [Nil, Symbol] whether to apply a fallback operation. One of
      #                                nil or :remove_editors_notes
      # @return [Float] 1.0 for identity, 0.0 for completely different, nothing in common.
      def self.compute_text_similarity(txt_1, txt_2, which_end, text_window_size, fall_back)
        words_1, words_2 = [txt_1, txt_2].map { |e|
          e = e.unicode_downcase
          case fall_back
          when :remove_editors_notes
            e.gsub!(/\[[^\]]+\]/, '') # remove editors notes
          when NilClass
            # nothing to do
          else
            raise "Invalid fall_back: #{ fall_back.inspect }"
          end
          e.gsub!(/[^[:alpha:]\s]+/, '') # Remove all but alphabetical chars and whitespace
          e.gsub!(/\s+/, ' ') # Normalize and squeeze whitespace
          e.strip!
          e = case which_end
          when :start
            e.truncate(text_window_size, omission: '', separator: ' ')
          when :end
            e.truncate_from_beginning(text_window_size, omission: '', separator: ' ')
          else
            raise "Invalid which_end: #{ which_end.inspect }"
          end
          e.split # return array of words
        }
        # Compute Jaccard index
        union_size = (words_1 + words_2).length
        intersection_size = full_array_intersection(words_1, words_2).length
        return 0  if 0 == union_size # avoid division by zero
        (intersection_size * 2) / union_size.to_f
      end

      # Computes the confidence level that the record_mark between r1 and r2 is in
      # the correct spot. Uses the following three features to compute confidence level:
      # @param r2_first_par_num_similarity [Array] how similar are the paragraph numbers
      #                 at the beginning of the two sources?
      # @param r1_end_text_similarity [Float] how similar are the ends of the texts in record 1
      # @param r2_start_text_similarity [Float] how similar are the beginnings of the texts in record 2
      # @return [Outcome] successful if we have 100% confidence of correctness.
      #                   Otherwise #result contains the computed confidence level.
      def self.compute_confidence_level_for_features(r2_first_par_num_similarity, r1_end_text_similarity, r2_start_text_similarity)
        if( # both paragraph numbers are correct
          :identical == r2_first_par_num_similarity.first
        ) or ( # texts at beginning of record 2 are almost identical
          r2_start_text_similarity > 0.9
        ) or ( # paragraph number is missing in one source, however both texts are very similar
          :missing_in_one == r2_first_par_num_similarity.first and
          (r1_end_text_similarity + r2_start_text_similarity) > 1.6 and
          r1_end_text_similarity > 0.7 and
          r2_start_text_similarity > 0.7
        ) or ( # differences in paragraph numbers, however texts are highly similar
          [:different_position_with_same_numbers, :same_position_with_different_numbers].include?(r2_first_par_num_similarity.first) and
          (
            r1_end_text_similarity > 0.95 || r2_start_text_similarity > 0.95 or
            r1_end_text_similarity > 0.85 && r2_start_text_similarity > 0.85
          )
        )
          # We are 100% confident that the record_marks are in the correct location
          Outcome.new(true, 1.0)
        else
          # We're not 100% confident, return the lowest text similarity
          Outcome.new(false, [r1_end_text_similarity, r2_start_text_similarity].min)
        end
      end

      # @param [Array<Hash>] confidence_levels
      # @param [String] path_to_index a relative URL to the index page
      # @param [String] filename_1
      # @param [String] filename_2
      def self.generate_html_report(confidence_levels, path_to_index, filename_1, filename_2)
        return nil  if confidence_levels.empty? # Don't generate a report if they are all the same
        template_path = File.expand_path(
          "../../../../templates/html_diff_report.html.erb", __FILE__
        )
        @title = 'Compare Record id and paragraph alignment'
        @confidence_levels = confidence_levels.each_with_index.map { |e,idx|
          confidence_percent = (e[:confidence] * 100).round
          confidence_widget = %(<span class="label #{ e[:css_class] }">#{ confidence_percent }%</span>)
          collapse_css_class = if e[:css_class].index('label-default')
            "record-#{ idx } collapse"
          else
            "record-#{ idx } collapse in"
          end
          %(
            <tr>
              <td style="width: 40%">
                <div class="#{ collapse_css_class }">#{ e[:source_1].split("\n").map { |e| "<p>#{ e }</p>"}.join }</div>
              </td>
              <td style="width: 20%">
                <button data-toggle="collapse" data-target=".record-#{ idx }">#{ e[:record_id] }</button>
                #{ confidence_widget }
              </td>
              <td style="width: 40%">
                <div class="#{ collapse_css_class }">#{ e[:source_2].split("\n").map { |e| "<p>#{ e }</p>"}.join }</div>
              </td>
            </tr>
          )
        }.join
        @low_confidence_levels_count = confidence_levels.count { |e|
          ["label-warning", "label-danger"].include?(e[:css_class])
        }
        @filename_1 = filename_1
        @filename_2 = filename_2
        @path_to_index = path_to_index
        erb_template = ERB.new(File.read(template_path))
        erb_template.result(binding)
      end

      # Computes the css class for the given confidence
      # @param [Float] confidence from 0.0 to 1.0
      def self.compute_css_class(confidence)
        case confidence
        when 0.0...0.5
          'label-danger'
        when 0.5...1.0
          'label-warning'
        else
          'label-default'
        end
      end

      # Returns full intersection of array elements, maintaining any duplicates
      def self.full_array_intersection(a, b)
        b = b.dup
        a.inject([]) do |intersect, s|
          index = b.index(s)
          if index
           intersect << s
           b.delete_at(index)
          end
          intersect
        end
      end

    end
  end
end
