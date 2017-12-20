require_relative '../../helper'

class Repositext
  class Services
    describe ExtractContentAtIdParts do

      let(:content_at){
        [
          "*210*{: .pn} Word word word word. ",
          "{: .normal_pn}",
          "",
          "*The foreign title*{: .italic .smcaps} ENG12-1234*m*{: .smcaps}",
          "{: .id_title1}",
          "",
          "(The primary title)",
          "{: .id_title2}",
          "",
          "Word word word word word.",
          "{: .id_paragraph}",
        ].join("\n")
      }

      describe 'call' do
        [
          [
            "All ID parts",
            nil,
            {
              "id_title1"=>["*The foreign title*{: .italic .smcaps} ENG12-1234*m*{: .smcaps}"],
              "id_title2"=>["(The primary title)"],
              "id_paragraph"=>["Word word word word word."],
            },
          ],
          [
            "Title1 only",
            %w[id_title1],
            { "id_title1"=>["*The foreign title*{: .italic .smcaps} ENG12-1234*m*{: .smcaps}"] },
          ],
        ].each do |description, parts_to_extract, xpect|
          it "handles #{ description }" do
            ExtractContentAtIdParts.call(
              content_at,
              parts_to_extract
            ).result.must_equal(xpect)
          end
        end
      end

    end
  end
end
