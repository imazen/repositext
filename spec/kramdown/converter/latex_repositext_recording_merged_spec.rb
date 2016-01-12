# require_relative '../../helper'

# module Kramdown
#   module Converter
#     describe LatexRepositextRecordingMerged do

#       describe 'custom_pre_process_content' do

#         it "handles standard case" do
#           target_contents = "# the target title\n\n%target_word\n{: .normal}\n\n%target_word %target_word\n\n"
#           primary_contents = "^^^ {: .rid #rid-123}\n\n# the primary title\n\n*123*{: .pn} @%primary_word\n{: .normal}\n\n^^^ {: .rid #rid-456}\n\n@%primary_word %primary_word\n\n"
#           xpect = "# the primary title\n\n# the target title\n\n***\n\n*123*{: .pn} .RtPrimaryFontStart.%primary_word\n\n.RtPrimaryFontEnd.\n\n%target_word\n\n***\n\n.RtPrimaryFontStart.%primary_word .RtPrimaryFontEnd.\n\n%target_word\n\n***\n\n.RtPrimaryFontStart.%primary_word\n\n.RtPrimaryFontEnd.\n\n%target_word\n\n***\n"
#           c = LatexRepositextRecordingMerged.custom_pre_process_content(
#             target_contents,
#             primary_contents
#           ).must_equal(xpect)
#         end

#         it "raises exception if number of gap_marks is different" do
#           proc{
#             LatexRepositextRecordingMerged.custom_pre_process_content(
#               "%target_word %target_word",
#               "%primary_word"
#             )
#           }.must_raise ArgumentError
#         end

#       end

#       describe 'custom_post_process_latex' do

#         it "removes empty RtGapMarkText commands" do
#           c = LatexRepositextRecordingMerged.custom_post_process_latex(
#             "word \\RtGapMarkText{} word"
#           ).must_equal('word  word')
#         end

#         it "adjusts highlighting of word after gap_mark in chinese to single character" do
#           c = LatexRepositextRecordingMerged.custom_post_process_latex(
#             "word \\RtGapMarkText{这是一个测试} word"
#           ).must_equal("word \\RtGapMarkText{这}是一个测试 word")
#         end

#         it "doesn't adjust highlighting of word after gap_mark in english" do
#           c = LatexRepositextRecordingMerged.custom_post_process_latex(
#             "word \\RtGapMarkText{word} word word"
#           ).must_equal("word \\RtGapMarkText{word} word word")
#         end

#         it "replaces temporary RtPrimaryFont markers with environment" do
#           c = LatexRepositextRecordingMerged.custom_post_process_latex(
#             ".RtPrimaryFontStart.\\RtGapMarkText{word} .RtPrimaryFontEnd."
#           ).must_equal("\n\\begin{RtPrimaryFont}\n\\RtGapMarkText{word} \n\\end{RtPrimaryFont}\n")
#         end

#       end

#       describe '.split_kramdown' do
#         [
#           [
#             'Handles :em with and without gap_marks inside',
#             "%*word word %word word.* word *word*",
#             ["%*word word* ", "%*word word.*  word *word*"],
#           ],
#           [
#             'Handles :strong with and without gap_marks inside',
#             "%**word word %word word.** word %word word word **word**",
#             ["%**word word** ", "%**word word.**  word ", "%word word word **word**"],
#           ],
#           [
#             'Moves id_para to after title',
#             "# title\n\nnormal para\n{: .normal}\n\nid_para\n{: .id_paragraph}",
#             ["# title\n\n", "id_para", "normal para\n"],
#           ],
#           [
#             'Handles gap_mark after paragraph number',
#             "*123*{: .pn} %word %word",
#             ["*123*{: .pn} %word ", "%word",],
#           ],
#           [
#             'Removes record_marks, subtitle_marks, block IALs, id_title1, and id_title2',
#             "^^^ {: .rid #rid-123}\n\n%@word word\n{: .normal}\n\nword\n{: .id_title1}\n\nword\n{: .id_title1}\n\n",
#             ["%word word\n\n"],
#           ],
#         ].each do |description, test_string, xpect|
#           it description do
#             LatexRepositextRecordingMerged.send(:split_kramdown, test_string).must_equal(xpect)
#           end
#         end

#         it 'wraps primary splits in temp markers' do
#           LatexRepositextRecordingMerged.send(
#             :split_kramdown,
#             "%word %word",
#             true
#           ).must_equal(
#             [
#               ".RtPrimaryFontStart.%word .RtPrimaryFontEnd.",
#               ".RtPrimaryFontStart.%word.RtPrimaryFontEnd.",
#             ]
#           )
#         end

#       end

#     end
#   end
# end
