require_relative '../../helper'

class Repositext
  class Utils
    describe ArrayDiffer do

      let(:a1){ %w[a b c   e 1 f] }
      let(:a2){     %w[c d e 2 f g h]}

      describe '#diff' do
        it "computes diff" do
          # NOTE: Have to cast Diff::LCS::ContextChange to Array for comparison
          ArrayDiffer.diff(a1, a2).map { |e| e.to_a }.must_equal(
            [["-", [0, "a"], [0, nil]],
             ["-", [1, "b"], [0, nil]],
             ["=", [2, "c"], [0, "c"]],
             ["+", [3, nil], [1, "d"]],
             ["=", [3, "e"], [2, "e"]],
             ["!", [4, "1"], [3, "2"]],
             ["=", [5, "f"], [4, "f"]],
             ["+", [6, nil], [5, "g"]],
             ["+", [6, nil], [6, "h"]]]
          )
        end
      end

      describe '#diff_simple' do
        it "computes diff_simple" do
          ArrayDiffer.diff_simple(a1, a2).must_equal(
            [["-", "a"],
             ["-", "b"],
             ["+", "d"],
             ["!", "1", "2"],
             ["+", "g"],
             ["+", "h"]]
          )
        end
      end

    end
  end
end
