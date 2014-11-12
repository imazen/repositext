module Kramdown
  module Converter
    class LatexRepositextRecordingMerged < LatexRepositext

      include DocumentMixin
      include RenderSubtitleAndGapMarksMixin

      # Called from the export command, merges contents of target and primary
      # languages into a single interleaved kramdown AT document.
      # @param[String] target_contents kramdown AT source for target language
      # @param[String] primary_contents kramdown AT source for primary language
      # @return[String] interleaved kramdown AT string
      def self.custom_pre_process_content(target_contents, primary_contents)
        validate_same_number_of_gap_marks(target_contents, primary_contents)
        # process each content
        target_contents_splits, primary_contents_splits = [
          target_contents,
          primary_contents
        ].map { |contents|
          splits = contents.dup
          # extract contents of id_paragraph for later use
          id_paragraph = splits.match(
            /
              (?<=\n) # preceded by newline
              [^\n]+ # one or more chars that are not a newline
              (?=\n#{ Regexp.escape("{: .id_paragraph}") }) # followed by id paragraph class IAL
            /x
          ).to_s

          # remove unwanted elements
          splits.gsub!(/@/, '') # subtitle marks
          splits.gsub!(/^\^\^\^[^\n]*\n/, "\n") # record_marks
          # id_title1, id_title2, id_paragraph
          splits.gsub!(
            /
              (?<=\n) # preceded by newline
              [^\n]+ # one or more chars that are not a newline
              (?=\n\{\:\s\.(?:id_paragraph|id_title1|id_title2)\}) # followed by id paragraph, id title1 or id title2 class IAL
            /x,
            ''
          )
          splits.gsub!(/\n\{\:[^\n]*\n/, "\n") # block IALs (paragraph classes)

          # split both files on gap marks or their preceding pararaph numbers
          # The challenge is that we have to split on one of the two:
          # * '%'
          # * '*123*{: .pn} %'
          # In order to do this, we have to temporarily move the gap_mark to
          # before the .pn, and then after splitting move it back again
          pn_regex = /\*\d+\*\{: \.pn\}\s/
          splits.gsub!(/^(#{ pn_regex })(%)/, '\2\1')
          splits = splits.split(/(?=%)/)
          splits = splits.map { |e| e.gsub(/^(%)(#{ pn_regex })/, '\2\1') }

          # insert id_paragraph as second split (after title)
          splits.insert(1, id_paragraph)
        }
        # interleave elements of both arrays, insert hr between each pair and
        # serialize to string for merged AT
        r = [
          primary_contents_splits,
          target_contents_splits
        ].transpose
         .map { |pair|
           pair.map(&:strip).join("\n\n")
         }.join("\n\n***\n\n") + "\n"
        r
      end

      # Called from the export command, makes some modifications to generated
      # latex source
      # @param[String] latex
      # @param[String] modified latex source
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
        l
      end

    protected

      # NOTE: This should eventually be handled by Validator::GapMarkCountsMatch
      # This is just a quick hack so that we can get going. Code is duplicated.
      def self.validate_same_number_of_gap_marks(target_contents, primary_contents)
        primary_contents = primary_contents.gsub(/(?<=\n)\^\^\^[^\n]+\n\n/, '') # remove record_marks
        primary_lines = primary_contents.split("\n")
        target_lines = target_contents.split("\n")
        diffs = []
        primary_lines.each_with_index do |pl, idx|
          tl = target_lines[idx]
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
        end
        return true  if diffs.empty?
        error_msg = diffs.unshift("Mismatch in gap marks:").join("\n")
        raise error_msg
      end

    end
  end
end
