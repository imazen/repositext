require_relative '../../helper'

class Repositext
  class Services
    describe ExtractContentAtMainTitles do

      describe 'call' do
        [
          [
            "# *The title*{: .a_class}\n\nAnd a para\n\n",
            :plain_text,
            false,
            'The title'
          ],
          [
            "^^^ {: .rid #rid-1234}\n\n# *The title*{: .a_class}\n\nAnd a para\n\n",
            :plain_text,
            false,
            'The title'
          ],
          [
            "# *The title*{: .a_class}\n\nAnd a para\n\n",
            :content_at,
            false,
            '*The title*{: .a_class}'
          ],
          [
            "^^^ {: .rid #rid-1234}\n\n# *The title*{: .a_class}\n\nAnd a para\n\n",
            :content_at,
            false,
            '*The title*{: .a_class}'
          ],
          [
            "# *The title*{: .a_class}\n\nAnd a para\n\n",
            :content_at,
            false,
            '*The title*{: .a_class}'
          ],
          [
            "^^^ {: .rid #rid-1234}\n\n# Title\n\n## Subtitle\n\n^^^ {: .rid #rid-1235}\n\n",
            :content_at,
            true,
            ['Title', 'Subtitle']
          ],
        ].each do |content_at, format, include_level_2_title, xpect|
          it "handles #{ content_at.inspect }" do
            ExtractContentAtMainTitles.call(
              content_at,
              format,
              include_level_2_title
            ).result.must_equal(xpect)
          end
        end
      end

    end
  end
end
