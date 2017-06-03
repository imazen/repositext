require_relative '../../../helper'

class Repositext
  class Process
    class Fix
      describe ReplaceLatinWithCyrillicCharacters do
        describe '#fix' do

          ReplaceLatinWithCyrillicCharacters::LATIN_TO_CYRILLIC_MAP.each { |l,c|
            it "handles #{ l.inspect }" do
              o = ReplaceLatinWithCyrillicCharacters.fix(
                c,
                "filename"
              )
              o.result.must_equal(
                contents: c,
                lctwnr: []
              )
            end
          }

          [
            [
              "Default case with all mapped chars",
              %(AА aа BВ CС cс EЕ eе HН IІ jј JЈ KК MМ OО oо PР pр SЅ sѕ TТ VѴ vѵ XХ xх YУ yу ëё ÏЇ ïї),
              {
                contents: "АА аа ВВ СС сс ЕЕ ее НН ІІ јј ЈЈ КК ММ ОО оо РР рр ЅЅ ѕѕ ТТ ѴѴ ѵѵ ХХ хх УУ уу ёё ЇЇ її",
                lctwnr: []
              },
            ],
            [
              "Report run of latin chars",
              %(СурІ\nlatin СурІ),
              {
                contents: "СурІ\nlatin СурІ",
                lctwnr: [{:filename=>"filename", :line=>2, :latin_chars=>"latin", :reason=>"Sequence of multiple latin chars, may be English word."}]
              },
            ],
            [
              "Report isolated unmapped latin chars",
              %(СурІ\nd СурІ),
              {
                contents: "СурІ\nd СурІ",
                lctwnr: [{:filename=>"filename", :line=>2, :latin_chars=>"d", :reason=>"No mapping for this character provided."}]
              },
            ],
          ].each do |description, test_string, xpect|
            it "handles #{ description }" do
              ReplaceLatinWithCyrillicCharacters.fix(
                test_string,
                "filename"
              ).result.must_equal(xpect)
            end
          end
        end
      end
    end
  end
end
