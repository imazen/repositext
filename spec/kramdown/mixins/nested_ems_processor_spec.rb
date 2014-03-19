require_relative '../../helper'
require_relative '../parser/folio/helper.rb'

describe ::Kramdown::TmpEmClassProcessor do

  describe "clean_up_nested_ems!" do

    it "handles em.smcaps inside em" do
      # - :p
      #   - :em
      #     - :text - "text1 "
      #     - :em - {"class"=>"smcaps"}
      #       - :text - "text2"
      #     - :text - " text3"
      t1 = Kramdown::ElementRt.new(:text, 'text1 ')
      nested_em = Kramdown::ElementRt.new(:em, nil, 'class' => 'smcaps')
        t2 = Kramdown::ElementRt.new(:text, 'text2')
        nested_em.add_child(t2)
      t3 = Kramdown::ElementRt.new(:text, ' text3')
      em = Kramdown::ElementRt.new(:em)
        em.add_child([t1, nested_em, t3])
      p = Kramdown::ElementRt.new(:p)
        p.add_child(em)
      parser = Kramdown::Parser::Folio.new("")
      parser.send(:clean_up_nested_ems!, p)
      p.inspect_tree.must_equal %( - :p
   - :em
     - :text - "text1 "
   - :em - {"class"=>"smcaps italic"}
     - :text - "text2"
   - :em
     - :text - " text3"
)
    end

  end

end
