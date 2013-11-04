require_relative '../../helper'

describe Kramdown::Converter::Kramdown do

  describe "convert" do

    it "adds ial for :record_mark in #convert_record_mark() method, not in @convert()" do
      Kramdown::Document.new(
        "^^^{:.rid #rid-123abc}\n\nA para\n{:.some-class}\n",
        { :input => :repositext, :disable_record_mark => false }
      ).to_kramdown.must_equal %(^^^ {: .rid #rid-123abc}\n\nA para\n{: .some-class}\n\n\n)
    end

  end

  describe "convert_record_mark" do
    it "inserts the record_mark if false == :disable_record_mark" do
      Kramdown::Document.new(
        "^^^{:.rid #rid-123abc}\nA para",
        { :input => :repositext, :disable_record_mark => false }
      ).to_kramdown.must_equal %(^^^ {: .rid #rid-123abc}\n\nA para\n\n\n)
    end

    it "discards the record_mark if true == :disable_record_mark" do
      Kramdown::Document.new(
        "^^^{:.rid #rid-123abc}\nA para",
        { :input => :repositext, :disable_record_mark => true }
      ).to_kramdown.must_equal %(A para\n\n\n)
    end
  end

  describe "convert_gap_mark" do
    it "discards the gap_mark if false == :disable_gap_mark" do
      Kramdown::Document.new(
        "%some text",
        { :input => :repositext, :disable_gap_mark => false }
      ).to_kramdown.must_equal %(%some text\n\n)
    end

    it "inserts the gap_mark if true == :disable_gap_mark" do
      Kramdown::Document.new(
        "%some text",
        { :input => :repositext, :disable_gap_mark => true }
      ).to_kramdown.must_equal %(some text\n\n)
    end
  end

  describe "convert_subtitle_mark" do
    it "discards the subtitle_mark if false == :disable_subtitle_mark" do
      Kramdown::Document.new(
        "@some text",
        { :input => :repositext, :disable_subtitle_mark => false }
      ).to_kramdown.must_equal %(@some text\n\n)
    end

    it "inserts the subtitle_mark if true == :disable_subtitle_mark" do
      Kramdown::Document.new(
        "@some text",
        { :input => :repositext, :disable_subtitle_mark => true }
      ).to_kramdown.must_equal %(some text\n\n)
    end
  end

  describe "convert_entity" do
    it "always converts entities to their numeric representation" do
      Kramdown::Document.new(
        "&#x00A0; &amp; &#x2028;",
        { :input => :repositext }
      ).to_kramdown.must_equal %(&#x00A0; &amp; &#x2028;\n\n)
    end
  end

  describe "ial_for_element" do
    it "adds a nullop ial for adjacent ems without whitespace separation" do
      Kramdown::Document.new(
        " *first half*{:.s}*second half*{:.italic}",
        { :input => :repositext }
      ).to_kramdown.must_equal %(*first half*{: .s}*second half*{: .italic}\n\n)
    end
  end


end
