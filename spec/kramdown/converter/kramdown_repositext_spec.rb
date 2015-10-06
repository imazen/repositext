require_relative '../../helper'

module Kramdown
  module Converter
    describe KramdownRepositext do

      describe "convert" do

        it "adds ial for :record_mark in #convert_record_mark() method, not in @convert()" do
          Kramdown::Document.new(
            "^^^{:.rid #rid-123abc}\n\nA para\n{:.some-class}\n",
            { :input => 'KramdownVgr', :disable_record_mark => false }
          ).to_kramdown_vgr.must_equal %(^^^ {: .rid #rid-123abc}\n\nA para\n{: .some-class}\n\n\n)
        end

      end

      describe "convert_entity" do
        it "always converts entities to their numeric representation" do
          Kramdown::Document.new(
            "&#x00A0; &amp; &#x2028;",
            { :input => 'KramdownVgr' }
          ).to_kramdown_vgr.must_equal %(&#x00A0; &#x0026; &#x2028;\n\n)
        end
      end

      describe "convert_gap_mark" do
        it "discards the gap_mark if false == :disable_gap_mark" do
          Kramdown::Document.new(
            "%some text",
            { :input => 'KramdownVgr', :disable_gap_mark => false }
          ).to_kramdown_vgr.must_equal %(%some text\n\n)
        end

        it "inserts the gap_mark if true == :disable_gap_mark" do
          Kramdown::Document.new(
            "%some text",
            { :input => 'KramdownVgr', :disable_gap_mark => true }
          ).to_kramdown_vgr.must_equal %(some text\n\n)
        end
      end

      describe "convert_record_mark" do
        it "inserts the record_mark if false == :disable_record_mark" do
          Kramdown::Document.new(
            "^^^{:.rid #rid-123abc}\nA para",
            { :input => 'KramdownVgr', :disable_record_mark => false }
          ).to_kramdown_vgr.must_equal %(^^^ {: .rid #rid-123abc}\n\nA para\n\n\n)
        end

        it "discards the record_mark if true == :disable_record_mark" do
          Kramdown::Document.new(
            "^^^{:.rid #rid-123abc}\nA para",
            { :input => 'KramdownVgr', :disable_record_mark => true }
          ).to_kramdown_vgr.must_equal %(A para\n\n\n)
        end
      end

      describe "convert_subtitle_mark" do
        it "discards the subtitle_mark if false == :disable_subtitle_mark" do
          Kramdown::Document.new(
            "@some text",
            { :input => 'KramdownVgr', :disable_subtitle_mark => false }
          ).to_kramdown_vgr.must_equal %(@some text\n\n)
        end

        it "inserts the subtitle_mark if true == :disable_subtitle_mark" do
          Kramdown::Document.new(
            "@some text",
            { :input => 'KramdownVgr', :disable_subtitle_mark => true }
          ).to_kramdown_vgr.must_equal %(some text\n\n)
        end
      end

      describe '#convert_text' do

        [
          ['Does not escape colons 1', "look at this: here it is", "look at this: here it is\n\n"],
          ['Does not escape colons 2 (in text node after em, which is beginning of line for regex, as used for definition lists)', "look at *this*: here it is", "look at *this*: here it is\n\n"],
          ['Does not escape brackets', "this is [in brackets]", "this is [in brackets]\n\n"],
          ['Does not escape backticks', "this is `in backticks`", "this is `in backticks`\n\n"],
          ['Does not escape single quotes', "this is 'in single quotes'", "this is 'in single quotes'\n\n"],
          ['Does not escape double quotes', "this is \"in double quotes\"", "this is \"in double quotes\"\n\n"],
          ['Escapes double dollars', "this has $$ double dollars", "this has \\$$ double dollars\n\n"],
          ['Escapes backslash', "this has \\ backslash", "this has \\\\ backslash\n\n"],
          ['Escapes asterisk', "this has * asterisk", "this has \\* asterisk\n\n"],
          ['Escapes underscore', "this has _ underscore", "this has \\_ underscore\n\n"],
          ['Escapes curly brace', "this has { curly brace", "this has \\{ curly brace\n\n"],
        ].each do |(desc, test_string, xpect)|
          it desc do
            doc = Document.new(test_string, :input => 'KramdownRepositext')
            doc.to_kramdown_repositext.must_equal xpect
          end
        end

      end

      # This feature was originally a patch. Now it is part of kramdown proper
      # we just keep the test here.
      describe "ial_for_element" do
        it "adds a nullop ial for adjacent ems without whitespace separation" do
          Kramdown::Document.new(
            " *first half*{::}*second half*{:.italic}",
            { :input => 'KramdownVgr' }
          ).to_kramdown_vgr.must_equal %(*first half*{::}*second half*{: .italic}\n\n)
        end
      end

    end
  end
end
