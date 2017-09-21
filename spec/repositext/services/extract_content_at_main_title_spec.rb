require_relative '../../helper'

class Repositext
  class Services
    describe ExtractContentAtMainTitle do

      describe 'call' do
        [
          ["# *The title*{: .a_class}\n\nAnd a para\n\n", 'The title'],
          ["^^^ {: .rid #rid-1234}\n\n# *The title*{: .a_class}\n\nAnd a para\n\n", 'The title'],
        ].each do |content_at, xpect|
          it "handles #{ content_at.inspect }" do
            ExtractContentAtMainTitle.call(content_at).result.must_equal(xpect)
          end
        end
      end

    end
  end
end
