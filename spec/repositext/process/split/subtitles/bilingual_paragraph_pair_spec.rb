# encoding UTF-8
require_relative '../../../../helper'

class Repositext
  class Process
    class Split
      class Subtitles

        describe BilingualParagraphPair do

          let(:foreign_contents) { 'palabra1 palabra2 palabra3' }
          let(:primary_contents) { 'word1 word2 word3' }
          let(:foreign_language) { Language::Spanish.new }
          let(:primary_language) { Language::English.new }
          let(:foreign_text) { Text.new(foreign_contents, foreign_language) }
          let(:primary_text) { Text.new(primary_contents, primary_language) }
          let(:bilingual_text_pair) { BilingualTextPair.new(primary_text, foreign_text) }
          let(:text_pairs) { [bilingual_text_pair] }
          let(:bilingual_paragraph_pair) { BilingualParagraphPair.new(text_pairs) }

          describe 'Initializing' do

            it "initializes text_pairs" do
              bilingual_paragraph_pair.text_pairs.must_equal(text_pairs)
            end

          end

        end

      end
    end
  end
end
