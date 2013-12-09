require_relative '../../helper'

describe Kramdown::Converter::Html do

  describe 'convert_record_mark' do

    it 'converts if false == disable_record_mark' do
      Kramdown::Document.new(
        "^^^{:.rid #rid-123abc}\nA para",
        { :input => :repositext, :disable_record_mark => false }
      ).to_html.must_equal %(<div class="rid" id="rid-123abc">\n  <p>A para</p>\n</div>\n)
    end

    it "doesn't convert if true == disable_record_mark" do
      Kramdown::Document.new(
        "^^^{:.rid #rid-123abc}\nA para",
        { :input => :repositext, :disable_record_mark => true }
      ).to_html.must_equal %(<p>A para</p>\n)
    end

  end

  describe 'convert_gap_mark' do

    it 'converts if false == disable_gap_mark' do
      Kramdown::Document.new(
        "%some text",
        { :input => :repositext, :disable_gap_mark => false }
      ).to_html.must_equal %(<p><span class=\"gap-mark\"></span>some text</p>\n)
    end

    it "doesn't convert if true == disable_gap_mark" do
      Kramdown::Document.new(
        "%some text",
        { :input => :repositext, :disable_gap_mark => true }
      ).to_html.must_equal %(<p>some text</p>\n)
    end

  end

  describe 'convert_subtitle_mark' do

    it 'converts if false == disable_subtitle_mark' do
      Kramdown::Document.new(
        "@some text",
        { :input => :repositext, :disable_subtitle_mark => false }
      ).to_html.must_equal %(<p><span class=\"subtitle-mark\"></span>some text</p>\n)
    end

    it "doesn't convert if true == disable_subtitle_mark" do
      Kramdown::Document.new(
        "@some text",
        { :input => :repositext, :disable_subtitle_mark => true }
      ).to_html.must_equal %(<p>some text</p>\n)
    end

  end

  describe 'em conversion' do

    it 'converts ems with classes other than italic to span' do
      Kramdown::Document.new(
        "*text*{:.other-class}",
        { :input => :repositext, :disable_gap_mark => true }
      ).to_html.must_equal %(<p><span class="other-class">text</span></p>\n)
    end

    it 'converts ems with class italic to <em> elements and adds classes' do
      Kramdown::Document.new(
        "*text*{:.italic .other-class}",
        { :input => :repositext, :disable_gap_mark => true }
      ).to_html.must_equal %(<p><em class="italic other-class">text</em></p>\n)
    end

    it 'converts ems without any classes to <em> elements' do
      Kramdown::Document.new(
        "*text*",
        { :input => :repositext, :disable_gap_mark => true }
      ).to_html.must_equal %(<p><em>text</em></p>\n)
    end

  end

  describe 'escaped chars' do

    it "doesn't escape brackets" do
      Kramdown::Document.new(
        "Some text with \\[escaped brackets\\].",
        { :input => :repositext }
      ).to_html.must_equal %(<p>Some text with [escaped brackets].</p>\n)
    end

  end

end
