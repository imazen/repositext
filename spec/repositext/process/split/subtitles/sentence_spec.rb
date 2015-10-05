# encoding UTF-8
require_relative '../../../../helper'

class Repositext
  class Process
    class Split
      class Subtitles

        describe Sentence do

          let(:contents) { 'contents' }
          let(:language) { Language::English.new }

          describe 'Initializing' do

            it "initializes contents" do
              t = Sentence.new(contents, language)
              t.contents.must_equal(contents)
            end

            it "initializes language" do
              t = Sentence.new(contents, language)
              t.language.must_equal(language)
            end

          end

          describe '#content_length' do
            [
              [%(word1 word2 word3), 17],
            ].each do |(txt, xpect)|
              it "handles #{ txt.inspect }" do
                t = Sentence.new(txt, language)
                t.content_length.must_equal(xpect)
              end
            end
          end

        end

      end
    end
  end
end
