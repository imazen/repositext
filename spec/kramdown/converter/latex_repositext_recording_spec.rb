require_relative '../../helper'

module Kramdown
  module Converter
    describe LatexRepositextRecording do

      describe '#post_process_latex_body' do

        tmp_gap_mark_complete = "<<<gap-mark-number>>><<<gap-mark>>>"

        language = Repositext::Language::English

        describe "Moves gap_mark numbers outside of" do
          [
            [
              'apostrophe',
              "#{ language.chars[:apostrophe] }#{ tmp_gap_mark_complete }word",
              "\\RtGapMarkNumber#{ language.chars[:apostrophe] }\\RtGapMarkText{word}"
            ],
            [
              'double quote open',
              "#{ language.chars[:d_quote_open] }#{ tmp_gap_mark_complete }word",
              "\\RtGapMarkNumber#{ language.chars[:d_quote_open] }\\RtGapMarkText{word}"
            ],
          ].each do |(name, test_string, xpect)|
            it "moves gap_mark numbers outside of #{ name}" do
              c = LatexRepositextRecording.send(:new, '_', { language: language })
              c.send(:post_process_latex_body, test_string).must_equal(xpect)
            end
          end
        end
        describe "Moves gap_mark numbers after" do
          [
            ['eagle', "#{ tmp_gap_mark_complete } word", "\\RtFirstEagle \\RtGapMarkNumber \\RtGapMarkText{word}"],
          ].each do |(name, test_string, xpect)|
            it "moves gap_mark numbers after #{ name}" do
              c = LatexRepositextRecording.send(:new, '_', { language: language })
              c.send(:post_process_latex_body, test_string).must_equal(xpect)
            end
          end
        end
      end
    end
  end
end
