require_relative '../../helper'

describe Kramdown::Parser::Idml do

  let(:parser) {
    Kramdown::Parser::Idml.new(
      File.expand_path(File.dirname(__FILE__) + '../../../../test_data/idml/select_longest_story.idml')
    )
  }

  describe "stories_to_import" do
    it "selects the longest story" do
      parser.stories_to_import.map{ |e| e.name }.must_equal ["u1dc"]
    end
  end

  describe "extract_stories" do
    it "extracts all stories in the idml file" do
      parser.send(:extract_stories).map{ |e| e.name }.must_equal ["u712", "u6fa", "u1dc"]
    end
  end
end
