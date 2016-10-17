# -*- coding: utf-8 -*-
require_relative "../../../helper"

module Kramdown
  module Converter
    class LatexRepositext
      describe SmallcapsKerningMap do

        let(:default_character_mappings){
          {
            "À" => "A",
            "Á" => "A",
            "Â" => "A",
          }
        }
        let(:default_kerning_values){
          {
            "Arial" => {
              "bold" => {
                "Wa" => -0.1,
              },
              "bold italic" => {
                "Wa" => -0.1,
              },
              "italic" => {
                "Wa" => -0.1,
              },
              "regular" => {
                "Wa" => -0.1,
              }
            }
          }
        }
        let(:default_kerning_map_override){
          {
            "character_mappings" => default_character_mappings,
            "kerning_values" => default_kerning_values
          }
        }
        let(:default_kerning_map){
          SmallcapsKerningMap.new(default_kerning_map_override)
        }

        describe "#initialize" do

          it "Loads kerning_map from default file location" do
            SmallcapsKerningMap.new.lookup_kerning("Arial", "regular", "Wa").must_equal(-0.1)
          end

        end

        describe "#lookup_kerning" do

          [
            ["Arial", "regular", "Wa", -0.1],
            ["Arial", "regular", "Wä", nil],
            ["Arial", "regular", "Wá", -0.1],
            ["Unhandled font", "regular", "Wa", nil],
            ["Arial", "regular", "unhandled", nil],
          ].each do |font_name, font_attribute, character_pair, xpect|
            it "looks up #{ [font_name, character_pair].inspect }" do
              default_kerning_map.lookup_kerning(
                font_name,
                font_attribute,
                character_pair
              ).must_equal(xpect)
            end
          end

          it "raises on unhandled font" do
            proc{
              default_kerning_map.lookup_kerning("Unhandled font", "regular", "Wa", true)
            }.must_raise SmallcapsKerningMap::UnhandledFontError
          end

          it "raises on unhandled character_pair" do
            proc{
              default_kerning_map.lookup_kerning("Arial", "regular", "unhandled", true)
            }.must_raise SmallcapsKerningMap::UnhandledCharacterPairError
          end

        end

        describe "#sanitize_character_pair" do

          [
            ["Unmapped upper case car is returned as is", "WA", "WA"],
            ["Unmapped lower case car is returned as is", "wa", "wa"],
            ["Mapped lower case char is returned as lower case", "Wâ", "Wa"],
            ["Mapped upper case char is returned as upper case", "Âw", "Aw"],
            ["Non-letter is returned as is 1", "11", "11"],
            ["Non-letter is returned as is 2", ".,", ".,"],
          ].each do |desc, char_pair, xpect|
            it "handles #{ desc }" do
              default_kerning_map.send(
                :sanitize_character_pair,
                char_pair,
                default_character_mappings
              ).must_equal(xpect)
            end
          end

        end

      end
    end
  end
end
