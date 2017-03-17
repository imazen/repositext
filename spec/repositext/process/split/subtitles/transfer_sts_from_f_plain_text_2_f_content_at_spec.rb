# encoding UTF-8
require_relative '../../../../helper'

class Repositext
  class Process
    class Split
      class Subtitles

        describe TransferStsFromFPlainText2ForeignContentAt do

          let(:default_split_instance) { Split::Subtitles.new('_', '_') }

          describe '#transfer_sts_from_f_plain_text_2_f_content_at' do
            [
              [
                'Simple case',
                " Header\n\n@1 word @word word.\n@2 word word word.",
                [
                  %(^^^ {: .rid #rid-12345678}),
                  %(),
                  %(# *Header*),
                  %(),
                  %(*1*{: .pn} word word word.),
                  %({: .first_par .normal}),
                  %(),
                  %(*2*{: .pn} word word word.),
                  %({: .normal_pn}),
                ].join("\n"),
                [1,1,1],
                [
                  [
                    %(^^^ {: .rid #rid-12345678}),
                    %(),
                    %(# *Header*),
                    %(),
                    %(@*1*{: .pn} word @word word.),
                    %({: .first_par .normal}),
                    %(),
                    %(@*2*{: .pn} word word word.),
                    %({: .normal_pn}),
                  ].join("\n"),
                  [1,1,1],
                ],
              ],
            ].each do |(desc, f_pt, f_cat, f_st_confs, xpect)|
              it "handles #{ desc }" do
                default_split_instance.transfer_sts_from_f_plain_text_2_f_content_at(
                  f_pt, f_cat, f_st_confs, false
                ).result.must_equal(xpect)
              end
            end
          end

        end
      end
    end
  end
end
