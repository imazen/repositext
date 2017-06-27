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
                :contents=>"АА аа ВВ СС сс ЕЕ ее НН ІІ јј ЈЈ КК ММ ОО оо РР рр ЅЅ ѕѕ ТТ ѴѴ ѵѵ ХХ хх УУ уу ёё ЇЇ її",
                :lctwnr=>[],
                :replaced=>{
                  :filename=>"filename",
                  :replaced_chars=>{"А"=>1, "а"=>1, "В"=>1, "С"=>1, "с"=>1, "Е"=>1, "е"=>1, "Н"=>1, "І"=>1, "ј"=>1, "Ј"=>1, "К"=>1, "М"=>1, "О"=>1, "о"=>1, "Р"=>1, "р"=>1, "Ѕ"=>1, "ѕ"=>1, "Т"=>1, "Ѵ"=>1, "ѵ"=>1, "Х"=>1, "х"=>1, "У"=>1, "у"=>1, "ё"=>1, "Ї"=>1, "ї"=>1}
                }
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
                lctwnr: [{:filename=>"filename", :line=>2, :latin_chars=>"d", :reason=>"Unhandled latin character."}]
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
