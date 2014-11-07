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
          # remove unwanted elements
          splits.gsub!(/@/, '') # subtitle marks
          splits.gsub!(/^\^\^\^[^\n]*\n/, '') # record_marks
          splits.gsub!(/\n\{:[^\n]*\n/) # block IALs (paragraph classes)
          # split both files on gap marks or preceding pararaph numbers
          # (exception: gap_marks preceded by "\n*\d+*{: .pn} ")
          splits.split(/(?=%)/)
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

      def self.validate_same_number_of_gap_marks(target_contents, primary_contents)
        target_count, primary_count = [
          target_contents,
          primary_contents
        ].map { |c|
          c.count('%')
        }
        raise ArgumentError  if target_count != primary_count
        true
      end

    end
  end
end
