require_relative '../../../helper'

class Repositext
  class Process
    class Convert
      describe LatexToPdf do

        describe '.find_overfull_hboxes' do
          [
            [
              [
                %(Overfull \\hbox (59.42838pt too wide) in paragraph at lines 557--558),
                %(\\EU1/Lohit-Tamil(0)/m/n/13.00003 Offending text line 1),
                %( Offending text line 2),
                %( []),
              ].join("\n"),
              [{ overhang_in_pt: 59, line: 557, offensive_string: "Offending text line 1 Offending text line 2" }],
            ],
          ].each do |(txt, xpect)|
            it "handles #{ txt.inspect }" do
              r = LatexToPdf.send(:find_overfull_hboxes, txt)
              r.must_equal(xpect)
            end
          end
        end

        describe '.insert_line_break_into_ohb!' do
          [
            [
              { overhang_in_pt: 59, line: 557, offensive_string: "Offending text line 1 Offending text line 2" },
              %(Offending text line 1 Offending text line 2),
              %(Offending text line 1 Offending text line\\linebreak\n2),
            ],
          ].each do |(ohb, latex, xpect)|
            it "handles #{ ohb.inspect }" do
              LatexToPdf.send(:insert_line_break_into_ohb!, ohb, latex)
              latex.must_equal(xpect)
            end
          end
        end

      end
    end
  end
end
