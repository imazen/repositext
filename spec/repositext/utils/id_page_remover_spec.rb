require_relative '../../helper'

class Repositext
  class Utils
    describe IdPageRemover do

      describe '.remove' do
        [
          [
            'word word',
            ['word word', '']
          ],
          [
            "word word \n{: .normal}\n\n*word word word*\n{: .id_title1}\n\n123 456\n{: .id_title2}\n\nword word word.\n{: .id_paragraph}",
            ["word word \n{: .normal}\n\n", "*word word word*\n{: .id_title1}\n\n123 456\n{: .id_title2}\n\nword word word.\n{: .id_paragraph}"]
            ],
        ].each do |input, xpect|
          it "handles #{ input.inspect }" do
            IdPageRemover.remove(input).must_equal(xpect)
          end
        end
      end

    end
  end
end

