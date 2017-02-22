# encoding UTF-8
require_relative '../../../../helper'

class Repositext
  class Process
    class Split
      class Subtitles

        describe AlignSentences do

          let(:default_split_instance) { Split::Subtitles.new('_', '_') }

          describe '#align_sentences' do
            # NOTE: This is tricky to test since it uses LF Aligner and temporary files
          end
        end
      end
    end
  end
end
