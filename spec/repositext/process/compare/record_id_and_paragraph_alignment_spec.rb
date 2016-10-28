require_relative '../../../helper'

class Repositext
  class Process
    class Compare
      describe RecordIdAndParagraphAlignment do

        describe 'record_id_regex' do
          [
            ['12345678', 0],
            ['not an rid', nil],
            ['123A5678', 0],
            ['123a5678', nil],
            ['not at beginning of line 12345678', nil],
            ["on second line\n12345678", 15],
          ].each do |txt, xpect|
            it "handles #{ txt.inspect }" do
              (txt =~ RecordIdAndParagraphAlignment.send(:record_id_regex)).must_equal(xpect)
            end
          end
        end

        describe 'tokenize' do
          [
            [
              "\n12345678\n  para1 word\n  para2 word\n12345679\n  para1 word\n  para2 word",
              [
                { record_id: "12345678", text: "para1 word\npara2 word" },
                { record_id: "12345679", text: "para1 word\npara2 word" }
              ]
            ],
          ].each do |txt, xpect|
            it "handles #{ txt.inspect }" do
              RecordIdAndParagraphAlignment.send(:tokenize, txt).must_equal(xpect)
            end
          end
        end

        describe 'compute_confidence_level' do
          [
            ['full confidence', 'rec1 identical text', 'rec1 identical text', '2 rec2 identical text', '2 rec2 identical text', 1.0],
            ['medium confidence', 'rec1 similar text', 'rec1 similar text added words', '2 rec2 similar text added words', 'rec2 similar text', 0.75],
            ['no confidence', 'rec1 totally different text', 'worda wordb wordc wordd', '2 rec2 totall different text', 'worda wordb wordc wordd worde', 0.0],
          ].each do |test, rec1_s1, rec1_s2, rec2_s1, rec2_s2, xpect|
            it "handles #{ test.inspect }" do
              RecordIdAndParagraphAlignment.send(
                :compute_confidence_level,
                rec1_s1,
                rec1_s2,
                rec2_s1,
                rec2_s2,
              ).must_equal(xpect)
            end
          end
        end

        describe 'compute_paragraph_number_similarity' do
          [
            ['identical', '1 word', '1 word', [:identical, nil]],
            ['same pos diff nums', '1 word', '2 word', [:same_position_with_different_numbers, -1]],
            ['diff pos same nums', '1 word', 'word 1', [:different_position_with_same_numbers, 1 - (5/6.0)]],
            ['missing in both', 'word', 'word', [:missing_in_both, nil]],
            ['missing in one', '1 word', 'word', [:missing_in_one, nil]],
          ].each do |test, txt_1, txt_2, xpect|
            it "handles #{ test.inspect }" do
              RecordIdAndParagraphAlignment.send(
                :compute_paragraph_number_similarity,
                txt_1,
                txt_2,
              ).must_equal(xpect)
            end
          end
        end

        describe 'compute_text_similarity' do
          [
            ['identical start', 'worda wordb wordc wordd', 'worda wordb wordc wordd', :start, 200, nil, 1.0],
            ['identical end', 'worda wordb wordc wordd', 'worda wordb wordc wordd', :end, 200, nil, 1.0],
            ['missing word', 'worda wordb wordc wordd', 'worda wordb wordc', :start, 200, nil, 6.0/7.0],
            ['added word', 'worda wordb wordc', 'worda wordb wordc wordd', :start, 200, nil, 6.0/7.0],
            ['changed word', 'worda wordb wordc wordd', 'worda wordb wordc worde', :start, 200, nil, 6.0/8.0],
            ['all but space and chars removed', 'worda wordb wordc [{}],."/?!@%*', 'worda wordb wordc', :start, 200, nil, 1.0],
            ['case insensitive', 'worda wordb wordc', 'worda wordb wordc', :start, 200, nil, 1.0],
            ['remove editors notes', 'worda wordb wordc [editors note]', 'worda wordb wordc', :start, 200, :remove_editors_notes, 1.0],
            ['squeeze and strip whitespace', 'worda     wordb      wordc       ', 'worda wordb wordc', :start, 200, nil, 1.0],
            ['text_window_size on start', 'worda wordb wordc wordd worde wordf wordg', 'worda wordb wordc wordd', :start, 23, nil, 1.0],
            ['text_window_size on end', 'worda wordb wordc wordd worde wordf wordg', 'wordd worde wordf wordg', :end, 23, nil, 1.0],
          ].each do |test, txt_1, txt_2, which_end, text_window_size, fall_back, xpect|
            it "handles #{ test.inspect }" do
              RecordIdAndParagraphAlignment.send(
                :compute_text_similarity,
                txt_1,
                txt_2,
                which_end,
                text_window_size,
                fall_back
              ).must_equal(xpect)
            end
          end
        end

        describe 'compute_confidence_level_for_features' do
          [
            ['identical', [:identical, '_'], '_', '_', 1.0],
            ['r2_start_text_similarity almost 1.0', ['_', '_'], '_', 0.95, 1.0],
            ['pn missing in one, both texts similar', [:missing_in_one, '_'], 0.85, 0.85, 1.0],
            ['pn missing in one, both texts not similar', [:missing_in_one, '_'], 0.7, 0.8, 0.7],
            ['pn different, both texts highly similar 1', [:different_position_with_same_numbers, '_'], 0.96, 0.8, 1.0],
            ['pn different, both texts highly similar 2', [:different_position_with_same_numbers, '_'], 0.8, 0.96, 1.0],
            ['pn different, both texts highly similar 3', [:different_position_with_same_numbers, '_'], 0.86, 0.86, 1.0],
            ['pn different, both texts highly similar 4', [:same_position_with_different_numbers, '_'], 0.96, 0.8, 1.0],
            ['pn different, both texts highly similar 5', [:same_position_with_different_numbers, '_'], 0.8, 0.96, 1.0],
            ['pn different, both texts highly similar 6', [:same_position_with_different_numbers, '_'], 0.86, 0.86, 1.0],
            ['low confidence 1', [:different_position_with_same_numbers, '_'], 0.8, 0.8, 0.8],
            ['low confidence 2', [:different_position_with_same_numbers, '_'], 0.8, 0.4, 0.4],
          ].each do |test, r2_first_par_num_similarity, r1_end_text_similarity, r2_start_text_similarity, xpect|
            it "handles #{ test.inspect }" do
              RecordIdAndParagraphAlignment.send(
                :compute_confidence_level_for_features,
                r2_first_par_num_similarity,
                r1_end_text_similarity,
                r2_start_text_similarity,
              ).result.must_equal(xpect)
            end
          end
        end

        describe 'compute_css_class' do
          [
            [0.0, 'label-danger'],
            [0.4999, 'label-danger'],
            [0.5, 'label-warning'],
            [0.99999, 'label-warning'],
            [1.0, 'label-default'],
          ].each do |confidence, xpect|
            it "handles #{ confidence.inspect }" do
              RecordIdAndParagraphAlignment.send(
                :compute_css_class, confidence
              ).must_equal(xpect)
            end
          end
        end

        describe 'full_array_intersection' do
          [
            [[1,2,3,4,5], [3,4,5,6,7], [3,4,5]],
            [[1,2,3], [], []],
            [[1,2,2,3,3,3,4,4,4,4], [1,1,2,2,3,3,4,4], [1,2,2,3,3,4,4]],
            [[], [1,2,3], []],
          ].each do |a1, a2, xpect|
            it "handles #{ a1.inspect } and #{ a2.inspect }" do
              RecordIdAndParagraphAlignment.send(
                :full_array_intersection, a1, a2
              ).must_equal(xpect)
            end
          end
        end

      end
    end
  end
end
