# require_relative '../../helper'

# module Kramdown
#   module Converter
#     describe LatexRepositextRecording do

#       describe '#post_process_latex_body' do

#         describe "Moves gap_mark numbers" do

#           [
#             ['eagle', ' TMP_GAP_MARKword', '\\RtGapMark word'],
#           ].each do |(name, test, xpect)|
#             it "moves gap_mark numbers outside of #{ name}" do
#               c = LatexRepositext.send(:new, '_', {})
#               c.send(:post_process_latex_body, '').must_equal ''
#             end
#           end

#         end
#       end

#     end
#   end
# end
