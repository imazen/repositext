require_relative '../../helper'

module Kramdown
  module Converter
    describe LatexRepositextRecordingMerged do

      describe 'custom_pre_process_content' do

        it "handles standard case" do
          target_contents = "# the target title\n\n%target_word\n{: .normal}\n\n%target_word %target_word\n\n"
          primary_contents = "^^^ {: .rid #rid-123}\n\n# the primary title\n\n@%primary_word\n\n^^^ {: .rid #rid-456}\n\n@%primary_word %primary_word\n\n"
          xpect = "# the primary title\n\n# the target title\n\n***\n\n%primary_word\n\n%target_word\n\n***\n\n%primary_word\n\n%target_word\n\n***\n\n%primary_word\n\n%target_word\n"
          c = LatexRepositextRecordingMerged.custom_pre_process_content(
            target_contents,
            primary_contents
          ).must_equal(xpect)
        end

        it "raises exception if number of gap_marks is different" do
          proc{
            LatexRepositextRecordingMerged.custom_pre_process_content(
              "%target_word %target_word",
              "%primary_word"
            )
          }.must_raise ArgumentError
        end

      end

      describe 'custom_post_process_latex' do

        it "removes empty RtGapMarkText commands" do
          c = LatexRepositextRecordingMerged.custom_post_process_latex(
            "word \\RtGapMarkText{} word"
          ).must_equal('word  word')
        end

        it "adjusts highlighting of word after gap_mark in chinese to single character" do
          c = LatexRepositextRecordingMerged.custom_post_process_latex(
            "word \\RtGapMarkText{这是一个测试} word"
          ).must_equal("word \\RtGapMarkText{这}是一个测试 word")
        end

        it "doesn't adjust highlighting of word after gap_mark in english" do
          c = LatexRepositextRecordingMerged.custom_post_process_latex(
            "word \\RtGapMarkText{word} word word"
          ).must_equal("word \\RtGapMarkText{word} word word")
        end

      end

    end
  end
end
