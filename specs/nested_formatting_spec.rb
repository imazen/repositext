require_relative 'helper'

describe 'Nested formatting' do

  it "handles nested formatting" do
    doc = Kramdown::Document.new(
      "*this is italic and **this is bold italic** and this is italic*",
      { :input => :repositext, :disable_record_mark => true }
    )
    doc.to_html.must_equal %(<p><em>this is italic and <strong>this is bold italic</strong> and this is italic</em></p>\n)
  end

end
