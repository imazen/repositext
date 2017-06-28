require_relative '../../helper'

module Kramdown
  module Parser
    describe Idml do

      [
        ['select_longest_story_1.idml', ["u1dc"], ["u712", "u6fa", "u1dc"]],
      ].each do |(_file_name, stories_to_import, all_stories)|

        let(:parser) {
          path = File.expand_path('../../../../test_data/idml/select_longest_story_1.idml', __FILE__)
          contents = File.binread(path)
          Idml.new(contents)
        }

        describe "stories_to_import" do
          it "selects the longest story" do
            parser.stories_to_import.map{ |e| e.name }.must_equal(stories_to_import)
          end
        end

        describe "assigns #stories" do
          it "extracts all stories in the idml file" do
            parser.stories.map{ |e| e.name }.must_equal(all_stories)
          end
        end

      end
    end
  end
end
