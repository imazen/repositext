require_relative '../helper.rb'

module Kramdown
  describe TreeStructuralSimilarity do

    let(:tree_structural_similarity) {
      Kramdown::TreeStructuralSimilarity.new(nil, nil)
    }

    describe '#compute_count_similarity' do

      [
        [0, 0, 1.0],
        [100, 99, 0.99],
        [100, 100, 1.0],
        [100, 101, 0.99],
        [nil, 1, 0],
        [nil, nil, 1.0],
      ].each do |ref_count, other_count, xpect|

        it "computes #{ ref_count.inspect } and #{ other_count.inspect }" do
          tree_structural_similarity.send(
            :compute_count_similarity, ref_count, other_count
          ).must_equal(xpect)
        end

      end

    end

    describe '#compute_sequence_similarity' do

      [
        [[1,2,3], [1,2,3], 1.0],
        [[1,2,3,4,5], [1,2,3,  5], 0.8],
        [[1,2,3,  5], [1,2,3,4,5], 0.8],
      ].each do |ref_seq, other_seq, xpect|

        it "computes #{ ref_seq.inspect } and #{ other_seq.inspect }" do
          tree_structural_similarity.send(
            :compute_sequence_similarity, ref_seq, other_seq
          ).must_equal(xpect)
        end

      end

    end

  end
end
