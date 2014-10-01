require_relative '../../helper'

class Repositext
  class Merge
    describe GapMarkTaggingImportIntoContentAt do

      describe 'ensure_no_invalid_changes' do
        [
          ['gap_mark removed', "%para1\n{: .class1}\n", "para1\n{: .class1}\n", nil],
          ['gap_mark added', "para1\n{: .class1}\n", "%para1\n{: .class1}\n", nil],
          ['.omit removed', "para1\n{: .class1 .omit}\n", "para1\n{: .class1}\n", nil],
          ['.omit added', "para1\n{: .class1}\n", "para1\n{: .class1 .omit}\n", nil],
          ['text changed', "para1\n{: .class1}\n", "para2\n{: .class1}\n", ArgumentError],
          ['other class changed', "para1\n{: .class1}\n", "para1\n{: .class2}\n", ArgumentError],
        ].each do |desc, gap_mark_tagging_import, content_at, expected_exception|
          it "handles #{ desc }" do
            if expected_exception
              lambda {
                GapMarkTaggingImportIntoContentAt.send(
                  :ensure_no_invalid_changes, gap_mark_tagging_import, content_at
                )
              }.must_raise(expected_exception)
            else
              GapMarkTaggingImportIntoContentAt.send(
                :ensure_no_invalid_changes, gap_mark_tagging_import, content_at
              )
              1.must_equal(1)
            end
          end
        end
      end

      describe 'extract_paragraph_ials' do
        [
          ["para1\n{: .class1}\n\npara2\n{: .class2}\n", ["{: .class1}", "{: .class2}"]],
        ].each do |(test_string, xpect)|
          it "handles #{ test_string.inspect }" do
            GapMarkTaggingImportIntoContentAt.send(
              :extract_paragraph_ials, test_string
            ).must_equal(xpect)
          end
        end
      end

      describe 'merge_gap_marks' do
        [
          ["%word\n{: .class1}\n", "word\n{: .class1}\n", "%word\n{: .class1}\n"],
          ["%word\n{: .class1}\n", "word%\n{: .class1}\n", "%word\n{: .class1}\n"],
          [
            " Header\n\n%word\n{: .class1}\n",
            "^^^ {: .rid}\n\n# Header\n\nword\n{: .class1}\n",
            "^^^ {: .rid}\n\n# Header\n\n%word\n{: .class1}\n"
          ],
        ].each do |gap_mark_tagging_import, content_at, xpect|
          it "handles #{ gap_mark_tagging_import.inspect }" do
            GapMarkTaggingImportIntoContentAt.send(
              :merge_gap_marks, gap_mark_tagging_import, content_at
            ).result.must_equal(xpect)
          end
        end
      end

      describe 'merge_omit_paragraph_class' do
        [
          ["{: .class1}", "{: .class1}", "{: .class1}"],
          ["{: .class1 .omit}", "{: .class1}", "{: .class1 .omit}"],
          ["{: .class1}", "{: .class1 .omit}", "{: .class1}"],
        ].each do |source_ial, target_ial, xpect|
          it "handles #{ source_ial.inspect }" do
            GapMarkTaggingImportIntoContentAt.send(
              :merge_omit_paragraph_class, source_ial, target_ial
            ).must_equal(xpect)
          end
        end
      end

      describe 'merge_omit_classes' do
        [
          ["para\n{: .class1}\n", "para\n{: .class1}\n", "para\n{: .class1}\n"], # no change
          ["para\n{: .class1 .omit}", "para\n{: .class1}", "para\n{: .class1 .omit}"], # add .omit
          ["para\n{: .class1}", "para\n{: .class1 .omit}", "para\n{: .class1}"], # remove .omit
          [
            "para1\n{: .class1}\n\npara2\n{: .class2 .omit}",
            "para1\n{: .class1}\n\npara2\n{: .class2}",
            "para1\n{: .class1}\n\npara2\n{: .class2 .omit}"
          ], # add omit with multiple paras
        ].each do |gap_mark_tagging_import, content_at, xpect|
          it "handles #{ gap_mark_tagging_import.inspect }" do
            GapMarkTaggingImportIntoContentAt.send(
              :merge_omit_classes, gap_mark_tagging_import, content_at
            ).result.must_equal(xpect)
          end
        end
      end

      describe 'remove_gap_marks_and_omit_classes' do
        [
          ["word\n{: .class1}\n", "word\n{: .class1}\n"],
          ["%word\n{: .class1}\n", "word\n{: .class1}\n"],
          ["word\n{: .class1 .omit}\n", "word\n{: .class1}\n"],
          ["%word\n{: .omit}\n", "word\n"],
        ].each do |(test_string, xpect)|
          it "handles #{ test_string.inspect }" do
            GapMarkTaggingImportIntoContentAt.send(
              :remove_gap_marks_and_omit_classes, test_string
            ).must_equal(xpect)
          end
        end
      end

    end
  end
end
