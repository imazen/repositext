require_relative '../../helper'
require_relative '../parser/folio/helper.rb'

module Kramdown
  module Parser
    describe Folio do

      describe "#post_process_kramdown_tree!" do

        em1 = ElementRt.new(:em)
        em_a1 = ElementRt.new(:em, nil, 'class' => 'a', 'id' => 'em_a1')
        entity1 = ElementRt.new(:entity, Utils::Entities::Entity.new(160, nil), { 'original' => "&#x00A0;" })
        p1 = ElementRt.new(:p, nil, 'id' => 'p1')
        rm1 = ElementRt.new(:record_mark, nil, { "class" => "rid", "id" => "rid-C19" })
        space = ElementRt.new(:text, " ")
        text1 = ElementRt.new(:text, "text1")
        text2 = ElementRt.new(:text, "text2")
        text3 = ElementRt.new(:text, "text3")
        text4 = ElementRt.new(:text, "text4")

        [
          [
            "removes :em with whitespace only",
            construct_kramdown_rt_tree(
              [rm1, [
                [p1, [
                  [em_a1, [text1]],
                  text2,
                  entity1,
                  text3,
                  [em1, [space]],
                  text4,
                ]],
              ]]
            ),
            %( - :record_mark - {\"class\"=>\"rid\", \"id\"=>\"rid-C19\"}
                 - :p - {\"id\"=>\"p1\"}
                   - :em - {\"class\"=>\"a\", \"id\"=>\"em_a1\"}
                     - :text - \"text1\"
                   - :text - \"text2\"
                   - :entity - {\"original\"=>\"&#x00A0;\"} - code_point: 160
                   - :text - \"text3 text4\"
              )
          ],
        ].each do |desc, kt, xpect|
          it desc do
            parser = Parser::Folio.new("")
            parser.send(:post_process_kramdown_tree!, kt)
            kt.inspect_tree.must_equal xpect.gsub(/\n              /, "\n")
          end
        end

      end

    end
  end
end
