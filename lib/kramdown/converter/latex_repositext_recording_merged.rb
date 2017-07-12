module Kramdown
  module Converter
    # Custom latex converter for PDF recording merged format.
    class LatexRepositextRecordingMerged < LatexRepositext

      include DocumentMixin
      include RenderSubtitleAndGapMarksMixin

      # Called from the export command, merges contents of target and primary
      # languages into a single interleaved kramdown AT document.
      # Wraps english splits in temporary markers that will be replaced with
      # Latex environment.
      # @param [String] target_contents kramdown AT source for target language
      # @param [String] primary_contents kramdown AT source for primary language
      # @return [String] interleaved kramdown AT string
      def self.custom_pre_process_content(target_contents, primary_contents)
        validate_same_number_of_gap_marks(target_contents, primary_contents)
        # process each content
        target_contents_splits = split_kramdown(target_contents)
        primary_contents_splits = split_kramdown(primary_contents, true)

        # interleave elements of both arrays, insert hr between each pair and
        # serialize to string for merged AT
        begin
          r = [
            primary_contents_splits,
            target_contents_splits
          ].transpose
           .map { |pair|
             pair.map(&:strip).join("\n\n")
           }.join("\n\n***\n\n") + "\n\n***\n"
          r
        rescue IndexError
          primary_contents_splits.each_with_index do |pcs, idx|
            tcs = target_contents_splits[idx]
            puts '-'
            puts pcs.inspect
            puts tcs.inspect
          end
          raise ArgumentError.new("After splitting the text, we ended up with different counts of splits.")
        end
      end

      # Called from the export command, makes some modifications to generated
      # latex source
      # @param latex [String]
      def self.custom_post_process_latex(latex)
        # remove all empty RtGapMarkText commands
        l = latex.dup
        l.gsub!("\\RtGapMarkText{}", '')
        # adjust highlighting of word after gap_mark in chinese, limit to single character
        l.gsub!(
          /
            (?<=\\RtGapMarkText\{) # preceded by beginning of RtGapMarkText
            (\p{Han}) # first chinese character in capture group 1
            ([^}]*) # remaining characters capture group 2
            (\}) # closing brace of RtGapMarkText capture group 3
          /x,
          '\1\3\2'
        )
        # modify horizontal rules: make wider, reduce spacing above and below
        rule_latex = "\n\\vskip6pt\\hrule\\vskip2pt\n"
        l.gsub!(
          "\n\\begin{center}\n\\rule{3in}{0.4pt}\n\\end{center}\n",
          rule_latex
        )
        # prevent page breaks inside pairs
        rule_regexp = Regexp.escape(rule_latex)
        l.gsub!(
          /
            (#{ rule_regexp }) # rule capture group 1
            (.*?) # anything, non greedy capture group 2
            (?=#{ rule_regexp }|#{ Regexp.escape("\begin{RtMetaInfo}") }) # followed by another rule or meta info
          /mx,
          '\1' + "\n\\noindent\\begin{RtSplitPair}" + '\2' + "\n\\end{RtSplitPair}\n"
        )
        # Insert temporary markers into title. Insert RtPrimaryFont markers
        # inside the first pair of \begin{RtTitle}...\end{RtTitle}
        l.sub!(/(?<=#{ Regexp.escape('\\begin{RtTitle}') })/, ".RtPrimaryFontStart.") # after begin
        l.sub!(/(?=#{ Regexp.escape('\\end{RtTitle}') })/, ".RtPrimaryFontEnd.") # before end
        # Fix environment for paragraphs that don't start with gap_marks. I need
        # to break the RtPrimaryFont environment around the internal paragraph
        # number
        # NOTE: I check for ascii chars to detect primary text. That works
        # when target uses non-ascii text (e.g., chinese), however it will
        # break if target language uses ascii chars and we may have to find
        # a different way of doing this.
        # ImplementationTag #paragraph_numbers_regex
        l.gsub!(
          /
            (\\RtParagraphNumber\{\d+[a-z]?\}) # RtParagraphNumber command
            (?!\.RtPrimaryFontStart\.) # not followed by .RtPrimaryFontStart.
            (?=[\[]*[a-zA-Z]) # followed by optional control char and required ascii char to detect english in contrast to chinese
          /x,
          '.RtPrimaryFontEnd.\1.RtPrimaryFontStart.'
        )
        # Replace temporary markers with RtPrimaryFont environment
        l.gsub!(".RtPrimaryFontStart.", "\\begin{RtPrimaryFont}")
        l.gsub!(".RtPrimaryFontEnd.", "\\end{RtPrimaryFont}")
        l
      end

    protected

      # TODO: compare paragraph counts in both, print warning if they are different.

      # NOTE: This should eventually be handled by Validator::GapMarkCountsMatch
      # This is just a quick hack so that we can get going. Code is duplicated.
      def self.validate_same_number_of_gap_marks(target_contents, primary_contents)
        # remove record_marks in both
        target_contents = target_contents.gsub(/^\^\^\^[^\n]+\n\n/, '')
        primary_contents = primary_contents.gsub(/^\^\^\^[^\n]+\n\n/, '')
        primary_lines = primary_contents.split(/\n+/)
        target_lines = target_contents.split(/\n+/)
        diffs = []
        primary_lines.each_with_index do |pl, idx|
          tl = target_lines[idx]
          if tl
            # there is a corresponding target_line
            pc = pl.count('%')
            tc = tl.count('%')
            if pc != tc
              diffs << {
                line: idx + 1,
                primary_text: pl.inspect,
                primary_count: pc,
                target_text: tl.inspect,
                target_count: tc,
              }
            end
          else
            # no corresponding target_line found
            diffs << {
              line: idx + 1,
              primary_text: pl.inspect,
              primary_count: pc,
              target_text: tl.inspect,
              target_count: nil,
            }
          end
        end
        return true  if diffs.empty?
        error_msg = diffs.unshift("Mismatch in gap marks:").join("\n")
        raise ArgumentError.new(error_msg)
      end

      # Splits kramdown_txt into gaps. Also removes unwanted elements.
      # @param [String] kramdown_txt
      # @param [Boolean] is_primary
      # @return [Array<String>] Array of gaps
      def self.split_kramdown(kramdown_txt, is_primary = false)
        contents = kramdown_txt.dup
        # extract contents of id_paragraph for later use
        id_paragraph = contents.match(
          /
            (?<=\n) # preceded by newline
            [^\n]+ # one or more chars that are not a newline
            (?=\n#{ Regexp.escape("{: .id_paragraph}") }) # followed by id paragraph class IAL
          /x
        ).to_s.strip
        # ImplementationTag #paragraph_numbers_regex
        paragraph_number_regex = /\*\d+[a-z]?\*\{: \.pn\}\s/

        # remove unwanted elements
        contents.gsub!(/@/, '') # subtitle marks
        contents.gsub!(/^\^\^\^[^\n]*\n/, "\n") # record_marks
        # id_title1, id_title2, id_title3, id_paragraph
        contents.gsub!(
          /
            (?<=\n) # preceded by newline
            [^\n]+ # one or more chars that are not a newline
            \n # newline
            (?=\{\:\s\.(?:id_paragraph|id_title1|id_title2|id_title3)\}) # followed by id paragraph, id title1 or id title2 id title3 class IAL
          /x,
          ''
        )
        contents.gsub!(/\n\{\:[^\n]*$/, "") # block IALs (paragraph classes)

        # Move gap_marks to the beginning of their respective contexts:
        contents.gsub!(
          /
            ^ # beginning of line
            (
              (?:#{ paragraph_number_regex }) # paragraph number
              | # or
              (?:\*\*?) # em or strong
            ) # one of the contexts
            (%) # followed by gap mark
          /x,
          '\2\1'
        )

        # Successively split on paragraphs, spans and gap_marks
        para_splits = split_kramdown_paras(contents)
        span_splits = split_kramdown_spans(para_splits)
        gap_mark_splits = split_kramdown_gap_marks(span_splits)

        # Serialize and merge splits
        serialized_splits = ['']
        gap_mark_splits.each do |gap_mark_split|
          serialized_text = [
            gap_mark_split[:starts_with_gap_mark] ? '%' : nil,
            gap_mark_split[:parents].first,
            gap_mark_split[:txt],
            gap_mark_split[:parents].last
          ].compact.join
          if gap_mark_split[:starts_with_gap_mark]
            # gap_mark_split starts with gap_mark, or previous split ends with newline: create new split
            serialized_splits << serialized_text
          else
            # append to previous split
            serialized_splits.last << serialized_text
          end
        end

        # Move gap_marks back to after paragraph numbers
        splits = serialized_splits.map { |e| e.gsub(/^(%)(#{ paragraph_number_regex })/, '\2\1') }

        # insert id_paragraph as second split (after title)
        splits.insert(1, id_paragraph)  unless '' == id_paragraph

        # Wrap primary gaps in markers so they can be wrapped in latex environment later
        if is_primary
          splits = splits.map { |e|
            if e =~ /\A#/
              # Don't wrap title in RtPrimaryFont, it doesn't work because it
              # gets converted to small caps. Have to insert RtPrimaryFont in
              # latex post processing
              e
            elsif e =~ /%/
              # Change order on leading eagle
              " .RtPrimaryFontStart.#{ e.gsub("", '') }.RtPrimaryFontEnd."
            else
              # wrap, and move start marker to after paragraph numbers
              ".RtPrimaryFontStart.#{ e }.RtPrimaryFontEnd.".gsub(
                /(\.RtPrimaryFontStart\.)(#{ paragraph_number_regex })/,
                '\2\1'
              )
            end
          }
        end

        splits
      end

      # Splits kramdown_txt into paragraphs
      # @param [String] kramdown_txt
      # @return [Array<Hash>] An array of hashes with :txt, :parents, and
      #   :starts_with_gap_mark keys for each split
      def self.split_kramdown_paras(kramdown_txt)
        kramdown_txt.split(/(?<=\n\n)/).map { |e|
          starts_with_gap_mark = if e =~ /\A%/
            e.gsub!(/\A%/, '')
            true
          else
            false
          end
          { txt: e, parents: [], starts_with_gap_mark: starts_with_gap_mark }
        }
      end

      # Further splits para_splits into spans.
      # @param [Array<Hash>] para_splits as returned from split_kramdown_paras
      # @return [Array<Hash>] Array of Hashes, one for each span split
      def self.split_kramdown_spans(para_splits)
        span_splits = []
        para_splits.each do |para_split|
          if para_split[:txt].index('*').nil?
            # Return early if this split doesn't contain any spans (em or strong)
            span_splits << para_split
            next
          end
          # para_split contains spans, use stateful stringscanner
          str_sc = StringScanner.new(para_split[:txt])
          next_split_starts_with_gap_mark = para_split[:starts_with_gap_mark]
          while !str_sc.eos? do
            # check the varios options, going from specific to general
            if str_sc.scan(/%/)
              next_split_starts_with_gap_mark = true
            elsif str_sc.scan(/\*\*/)
              # a strong span begins
              strong_span_contents_and_end = str_sc.scan_until(/\*\*/)
              raise "Unclosed strong span"  if(strong_span_contents_and_end).nil?
              swgm = if next_split_starts_with_gap_mark
                next_split_starts_with_gap_mark = false
                true
              else
                false
              end
              span_splits << {
                txt: strong_span_contents_and_end.gsub(/\*\*\z/, ''),
                parents: para_split[:parents] + ['**', '**'],
                starts_with_gap_mark: swgm,
              }
            elsif str_sc.scan(/\*/)
              # an em span begins
              em_span_contents_and_end = str_sc.scan_until(/\*/)
              raise "Unclosed strong span"  if(em_span_contents_and_end).nil?
              swgm = if next_split_starts_with_gap_mark
                next_split_starts_with_gap_mark = false
                true
              else
                false
              end
              span_splits << {
                txt: em_span_contents_and_end.gsub(/\*\z/, ''),
                parents: para_split[:parents] + ['*', '*'],
                starts_with_gap_mark: swgm,
              }
            elsif(plain_text = str_sc.scan(/[^\*]+/))
              # plain text
              swgm = if next_split_starts_with_gap_mark
                next_split_starts_with_gap_mark = false
                true
              else
                false
              end
              span_splits << {
                txt: plain_text,
                parents: para_split[:parents],
                starts_with_gap_mark: swgm
              }
            else
              raise str_sc.rest
            end
          end
        end
        span_splits
      end

      # Further splits span_splits at gap_marks
      # @param [Array<Hash>] span_splits as returned from split_kramdown_spans
      # @return [Array<Hash>] Array of Hashes, one for each gap_mark split
      def self.split_kramdown_gap_marks(span_splits)
        # Split on gap_marks
        gap_mark_splits = []
        span_splits.each do |span_split|
          if span_split[:txt].index('%').nil?
            # Return early if this split doesn't contain any gap_marks
            gap_mark_splits << span_split
            next
          end
          next_split_starts_with_gap_mark = span_split[:starts_with_gap_mark]
          # span_split contains gap_marks
          span_split[:txt].scan(/%[^%]*|[^%]+/).each do |gap_mark_split|
            swgm = if next_split_starts_with_gap_mark || gap_mark_split =~ /\A%/
              next_split_starts_with_gap_mark = false
              true
            else
              false
            end
            txt = gap_mark_split.gsub(/\A%/, '')
            parents = span_split[:parents]
            # Push trailing whitespace outside of spans
            if txt =~ /\s\z/ && !parents.last.nil?
              txt.gsub!(/\s+\z/, '')
              parents.last << ' '
            end

            gap_mark_splits << {
              txt: txt,
              parents: parents,
              starts_with_gap_mark: swgm,
            }
          end
        end
        gap_mark_splits
      end

    end
  end
end
