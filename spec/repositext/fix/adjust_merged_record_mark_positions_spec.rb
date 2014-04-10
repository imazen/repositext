require_relative '../../helper'

describe Repositext::Fix::AdjustMergedRecordMarkPositions do

  [
    [
      "Moves :record_mark to before para 1",
      %(\n\nword\n^^^ {: .rid #f-58660019 kpn="001"}\n %word word word word \n\n),
      %(\n\n^^^ {: .rid #f-58660019 kpn="001"}\n\nword %word word word word \n\n),
    ],
    [
      "Moves :record_mark to before para 2",
      %(# *word word word*\n\nword\n^^^ {: .rid #f-54250019 kpn="001"}\n …-%word word word\n\n),
      %(# *word word word*\n\n^^^ {: .rid #f-54250019 kpn="001"}\n\nword …-%word word word\n\n),
    ],
    [
      "Moves :record_mark to after para 1",
      %(# *word word word*\n\nword word word word\n^^^ {: .rid #f-54250019 kpn="001"}\n …-%word word\n\n),
      %(# *word word word*\n\nword word word word …-%word word\n\n^^^ {: .rid #f-54250019 kpn="001"}\n\n),
    ],
    [
      "Moves :record_mark symmetrically between two paragraphs",
      %(word word\n{: .normal_pn}\n\n\n^^^ {: .rid #f-54250049 kpn="004"}\n*11*{: .pn} %word word),
      %(word word\n{: .normal_pn}\n\n^^^ {: .rid #f-54250049 kpn="004"}\n\n*11*{: .pn} %word word),
    ],
  ].each do |(desc, txt, xpect)|
    it desc do
      o = Repositext::Fix::AdjustMergedRecordMarkPositions.fix(txt)
      o.result[:contents].must_equal(xpect)
    end
  end

  describe '#distance_to_last_para_break' do
    [
      ["word word\n\n", 1],
      ["word word", Float::INFINITY],
      ["\n\nword word", 10],
    ].each do |(txt, xpect)|
      it "handles '#{ txt }'" do
        Repositext::Fix::AdjustMergedRecordMarkPositions.distance_to_last_para_break(
          txt
        ).must_equal xpect
      end
    end
  end

  describe '#distance_to_first_para_break' do
    [
      ["word word\n\n", 10],
      ["word word", Float::INFINITY],
      ["\n\nword word", 1],
    ].each do |(txt, xpect)|
      it "handles '#{ txt }'" do
        Repositext::Fix::AdjustMergedRecordMarkPositions.distance_to_first_para_break(
          txt
        ).must_equal xpect
      end
    end
  end

end
