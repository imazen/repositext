require_relative '../../helper'

class Repositext
  class Utils
    describe ArrayDiffer do

      let(:a1){ %w[a b c   e f] }
      let(:a2){     %w[c d e f g h]}

      describe '#diff' do
        it "computes diff" do
          # NOTE: Have to cast Diff::LCS::ContextChange to Array for comparison
          ArrayDiffer.diff(a1, a2).map { |e| e.to_a }.must_equal(
            [["-", [0, "a"], [0, nil]],
             ["-", [1, "b"], [0, nil]],
             ["=", [2, "c"], [0, "c"]],
             ["+", [3, nil], [1, "d"]],
             ["=", [3, "e"], [2, "e"]],
             ["=", [4, "f"], [3, "f"]],
             ["+", [5, nil], [4, "g"]],
             ["+", [5, nil], [5, "h"]]]
          )
        end
      end

      describe '#diff_simple' do
        it "computes diff_simple" do
          ArrayDiffer.diff_simple(a1, a2).must_equal(
            [["-", "a"],
             ["-", "b"],
             ["+", "d"],
             ["+", "g"],
             ["+", "h"]]
          )
        end
      end

    end
  end
end
