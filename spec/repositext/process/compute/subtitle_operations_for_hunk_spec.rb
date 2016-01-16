require_relative '../../../helper'

class Repositext
  class Process
    class Compute

      describe SubtitleOperationsForHunk do

        let(:default_computer){
          SubtitleOperationsForHunk.new([], 'dummy_hunk')
        }
        let(:default_subtitles){
          [
            Repositext::Subtitle.new({}),
            Repositext::Subtitle.new({}),
          ]
        }

        describe '#compute_hunk_operations_for_deletion_addition' do

          # We specify dc and ac as arrays of words for better alignment and readability
          [
            # We decided to ignore content changes
            # [
            #   'Content change (insignificant)',
            #   %w[@1word1 2word2  @3word3 4word4],
            #   %w[@1word1 2word2b @3word3 4word4],
            #   [{
            #     affectedStids: [],
            #     operationId: '',
            #     operationType: :contentChange,
            #   }],
            # ],
            # [
            #   'Content change',
            #   %w[@word1 word2       @word4 word5],
            #   %w[@word1 word2 word3 @word4 word5],
            #   [{
            #     affectedStids: [],
            #     operationId: '',
            #     operationType: :contentChange,
            #   }],
            # ],
            [
              'Delete (at beginning)',
              %w[@word1 word2 @word3 word4 @word5 word6],
              %w[             @word3 word4 @word5 word6],
              [{
                affectedStids: [],
                operationId: '',
                operationType: :delete,
              }],
            ],
            [
              'Delete (in the middle)',
              %w[@word1 word2 @word3 word4 @word5 word6],
              %w[@word1 word2              @word5 word6],
              [{
                affectedStids: [],
                operationId: '',
                operationType: :delete,
              }],
            ],
            [
              'Delete (at end)',
              %w[@word1 word2 @word3 word4 @word5 word6],
              %w[@word1 word2 @word3 word4],
              [{
                affectedStids: [],
                operationId: '',
                operationType: :delete,
              }],
            ],
            [
              'Insert (at beginning)',
              %w[             @word3 word4 @word5 word6],
              %w[@word1 word2 @word3 word4 @word5 word6],
              [{
                affectedStids: [],
                operationId: '',
                operationType: :insert,
              }],
            ],
            [
              'Insert (in the middle)',
              %w[@word1 word2              @word5 word6],
              %w[@word1 word2 @word3 word4 @word5 word6],
              [{
                affectedStids: [],
                operationId: '',
                operationType: :insert,
              }],
            ],
            [
              'Insert (at end)',
              %w[@word1 word2 @word3 word4],
              %w[@word1 word2 @word3 word4 @word5 word6],
              [{
                affectedStids: [],
                operationId: '',
                operationType: :insert,
              }],
            ],
            [
              'Insert (initial)',
              %w[ word1 word2  word3 word4  word5 word6],
              %w[@word1 word2 @word3 word4 @word5 word6],
              [
                {
                  affectedStids: [],
                    operationId: '',
                  operationType: :split,
                },
                {
                  affectedStids: [],
                    operationId: '',
                  operationType: :split,
                },
                {
                  affectedStids: [],
                    operationId: '',
                  operationType: :split,
                },
              ],
            ],
            [
              'Merge',
              %w[@word1 word2 @word3 word4 @word5 word6],
              %w[@word1 word2  word3 word4 @word5 word6],
              [{
                affectedStids: [],
                operationId: '',
                operationType: :merge,
              }],
            ],
            [
              'Move left',
              %w[@word1 word2  word3 @word4 @word5 word6],
              %w[@word1 word2 @word3  word4 @word5 word6],
              [{
                affectedStids: [],
                operationId: '',
                operationType: :moveLeft,
              }],
            ],
            [
              'Move right',
              %w[@word1 word2 @word3  word4 @word5 word6],
              %w[@word1 word2  word3 @word4 @word5 word6],
              [{
                affectedStids: [],
                operationId: '',
                operationType: :moveRight,
              }],
            ],
            [
              'Split',
              %w[@word1 word2  word3 word4 @word5 word6],
              %w[@word1 word2 @word3 word4 @word5 word6],
              [{
                affectedStids: [],
                operationId: '',
                operationType: :split,
              }],
            ],
          ].each do |description, dc, ac, xpect|

            it "handles #{ description }" do
              r = default_computer.send(
                :compute_hunk_operations_for_deletion_addition,
                [
                  { content: dc.join(' '), line_no: 1, subtitles: default_subtitles }
                ],
                [
                  { line_origin: :deletion, content: dc.join(' ') + "\n", old_linenos: 1 },
                  { line_origin: :addition, content: ac.join(' ') + "\n", old_linenos: nil },
                ],
              )
              r.map { |e| e.to_hash }.must_equal(xpect)
            end

          end

        end

        describe '#compute_aligned_similarity' do

          [
            [
              %(@And I trust that God will make them such examples till, the neighborhood, ),
              %(@these people are coming to…And I trust that God will make them such examples till, the neighborhood, ),
              :right,
              1.0
            ],
          ].each do |a, b, alignment, xpect|

            it "handles #{ a }" do
              r = default_computer.send(
                :compute_aligned_similarity,
                a,
                b,
                alignment
              )
              r.must_equal(xpect)
            end

          end

        end

      end

    end
  end
end
