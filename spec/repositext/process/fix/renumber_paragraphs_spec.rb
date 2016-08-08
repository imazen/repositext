require_relative '../../../helper'

class Repositext
  class Process
    class Fix
      describe RenumberParagraphs do
        describe '#fix (valid)' do
          [
            [
              "Default case with placeholder",
              %(*###*{: .pn}),
              %(*2*{: .pn}),
            ],
            [
              "Default case with existing paragraph number",
              %(*3*{: .pn}),
              %(*2*{: .pn}),
            ],
            [
              "Default case with leading subtitle_mark",
              %(@*3*{: .pn}),
              %(@*2*{: .pn}),
            ],
            [
              "Default case with leading subtitle_mark and gap_mark",
              %(@%*3*{: .pn}),
              %(@%*2*{: .pn}),
            ],
            [
              "Default case with leading gap_mark",
              %(%*3*{: .pn}),
              %(%*2*{: .pn}),
            ],
          ].each do |description, test_string, xpect|
            it "handles #{ description }" do
              RenumberParagraphs.fix(test_string).result[:contents].must_equal(xpect)
            end
          end
        end

        describe '#fix (invalid)' do
          [
            [
              "Less than one character",
              %(**{: .pn}),
              1
            ],
            [
              "More than 4 characters",
              %(*12345*{: .pn}),
              1
            ],
            [
              "Other then digits or placeholders",
              %(*1a*{: .pn}),
              1
            ],
          ].each do |description, test_string, xpect_err_count|
            it "handles #{ description }" do
              RenumberParagraphs.fix(test_string).messages.length.must_equal(xpect_err_count)
            end
          end
        end
      end
    end
  end
end
