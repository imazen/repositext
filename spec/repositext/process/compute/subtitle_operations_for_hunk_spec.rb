require_relative '../../../helper'

class Repositext
  class Process
    class Compute

      describe SubtitleOperationsForHunk do

        let(:default_computer){
          SubtitleOperationsForHunk.new(
            [],
            'dummy_hunk',
            'previous_hunk_last_stid',
            'hunk_index',
          )
        }
        let(:default_subtitles){
          default_tmp_attrs = {
            before: "",
            after: "",
          }
          10.times.map { |idx|
            Repositext::Subtitle.new(
              persistent_id: (1000000 + idx).to_s,
              tmp_attrs: default_tmp_attrs.dup,
            )
          }
        }

        describe '#compute_hunk_operations_for_deletion_addition' do

          # We specify dc and ac as arrays of words for better alignment and readability
          [
            # ----------------------------------------------------------------
            # No-ops
            # ----------------------------------------------------------------
            [
              'Content change (correct word)',
              %w[@0word1 1word2  @1word3 3word4],
              %w[@0word1 1word2b @1word3 3word4],
              [],
            ],
            [
              'Content change (delete word at beginning of subtitle)',
              %w[@word1 word2 @word4  word5 word6 word7],
              %w[@word1 word2        @word5 word6 word7],
              [],
            ],
            [
              'Content change (delete word in the middle of subtitle)',
              %w[@word1 word2 @word4 word5 word6 word7],
              %w[@word1 word2 @word4 word5       word7],
              [],
            ],
            [
              'Content change (delete word at end of subtitle)',
              %w[@word1 word2 word3 @word4 word5],
              %w[@word1 word2       @word4 word5],
              [],
            ],
            [
              'Content change (insert word at beginning of subtitle)',
              %w[@word1 word2        @word5 word6 word7],
              %w[@word1 word2 @word4  word5 word6 word7],
              [],
            ],
            [
              'Content change (insert word in the middle of subtitle)',
              %w[@word1 word2 @word4 word5       word7],
              %w[@word1 word2 @word4 word5 word6 word7],
              [],
            ],
            [
              'Content change (insert word at end of subtitle)',
              %w[@word1 word2       @word4 word5],
              %w[@word1 word2 word3 @word4 word5],
              [],
            ],
            # ----------------------------------------------------------------
            # Single operations
            # ----------------------------------------------------------------
            [
              'Delete (at beginning)',
              %w[@word1 word2 @word3 word4 @word5 word6],
              %w[             @word3 word4 @word5 word6],
              [
                {
                  :operationId=>"hunk_index-0",
                  :operationType=>:delete,
                  :afterStid=>nil,
                  :affectedStids=>[
                    {
                      :stid=>"1000000",
                      :before=>"word1 word2 ",
                      :after=>""
                    }
                  ]
                }
              ],
            ],
            [
              'Delete (in the middle)',
              %w[@word1 word2 @word3 word4 @word5 word6],
              %w[@word1 word2              @word5 word6],
              [
                {
                  :operationId=>"hunk_index-1",
                  :operationType=>:delete,
                  :afterStid=>nil,
                  :affectedStids=>[
                    {
                      :stid=>"1000001",
                      :before=>"word3 word4 ",
                      :after=>"",
                    }
                  ]
                }
              ],
            ],
            [
              'Delete (at end)',
              %w[@word1 word2 @word3 word4 @word5 word6],
              %w[@word1 word2 @word3 word4],
              [
                {
                  :operationId=>"hunk_index-2",
                  :operationType=>:merge,
                  :afterStid=>nil,
                  :affectedStids=>[
                    {
                      :stid=>"1000001",
                      :before=>"word3 word4 ",
                      :after=>"word3 word4\n"
                    },{
                      :stid=>"1000002",
                      :before=>"word5 word6\n",
                      :after=>""
                    }
                  ]
                }
              ]
            ],
            [
              'Insert (at beginning)',
              %w[             @word3 word4 @word5 word6],
              %w[@word1 word2 @word3 word4 @word5 word6],
              [
                {
                  :operationId=>"hunk_index-0",
                  :operationType=>:insert,
                  :afterStid=>"previous_hunk_last_stid",
                  :affectedStids=>[
                    {
                      :stid=>"tmp-hunk_start+1",
                      :before=>'',
                      :after=>"word1 word2 "
                    }
                  ]
                }
              ],
            ],
            [
              'Insert (in the middle)',
              %w[@word1 word2              @word5 word6],
              %w[@word1 word2 @word3 word4 @word5 word6],
              [
                {
                  :operationId=>"hunk_index-1",
                  :operationType=>:insert,
                  :afterStid=>'1000000',
                  :affectedStids=>[
                    {
                      :stid=>"tmp-1000000+1",
                      :before=>'',
                      :after=>"word3 word4 "
                    }
                  ]
                }
              ],
            ],
            [
              'Insert (at end, interpreted as split)',
              %w[@word1 word2 @word3 word4],
              %w[@word1 word2 @word3 word4 @word5 word6],
              [
                {
                  :operationId=>"hunk_index-2",
                  :operationType=>:split,
                  :afterStid=>nil,
                  :affectedStids=>[
                    {
                      :stid=>"1000001",
                      :before=>"word3 word4\n",
                      :after=>"word3 word4 "
                    },{
                      :stid=>"tmp-1000001+1",
                      :before=>'',
                      :after=>"word5 word6\n"
                    }
                  ]
                }
              ],
            ],
            [
              'Insert (initial)',
              %w[ word1 word2  word3 word4  word5 word6],
              %w[@word1 word2 @word3 word4 @word5 word6],
              [
                {
                  :operationId=>"hunk_index-0",
                  :operationType=>:insert,
                  :afterStid=>'previous_hunk_last_stid',
                  :affectedStids=>[
                    {
                      :stid=>"tmp-hunk_start+1",
                      :before=>"word1 word2 word3 word4 word5 word6\n",
                      :after=>"word1 word2 "
                    }
                  ]
                },{
                  :operationId=>"hunk_index-1",
                  :operationType=>:insert,
                  :afterStid=>"tmp-hunk_start+1",
                  :affectedStids=>[
                    {
                      :stid=>"tmp-hunk_start+2",
                      :before=>'',
                      :after=>"word3 word4 "
                    }
                  ]
                },{
                  :operationId=>"hunk_index-2",
                  :operationType=>:insert,
                  :afterStid=>"tmp-hunk_start+2",
                  :affectedStids=>[
                    {
                      :stid=>"tmp-hunk_start+3",
                      :before=>'',
                      :after=>"word5 word6\n"
                    }
                  ]
                }
              ],
            ],
            [
              'Merge',
              %w[@word1 word2 @word3 word4 @word5 word6],
              %w[@word1 word2  word3 word4 @word5 word6],
              [
                {
                  :operationId=>"hunk_index-1",
                  :operationType=>:merge,
                  :afterStid=>nil,
                  :affectedStids=>[
                    {
                      :stid=>"1000000",
                      :before=>"word1 word2 ",
                      :after=>"word1 word2 word3 word4 "
                    },{
                      :stid=>"1000001",
                      :before=>"word3 word4 ",
                      :after=>""
                    }
                  ]
                }
              ],
            ],
            [
              'moveLeft',
              %w[@word1 word2  word3 @word4 @word5 word6],
              %w[@word1 word2 @word3  word4 @word5 word6],
              [
                {
                  :operationId=>"hunk_index-0",
                  :operationType=>:moveLeft,
                  :afterStid=>nil,
                  :affectedStids=>[
                    {
                      :stid=>"1000000",
                      :before=>"word1 word2 word3 ",
                      :after=>"word1 word2 ",
                    },{
                      :stid=>"1000001",
                      :before=>"word4 ",
                      :after=>"word3 word4 "
                    }
                  ]
                },
              ],
            ],
            [
              'moveRight',
              %w[@word1 word2 @word3  word4 @word5 word6],
              %w[@word1 word2  word3 @word4 @word5 word6],
              [
                {
                  :operationId=>"hunk_index-0",
                  :operationType=>:moveRight,
                  :afterStid=>nil,
                  :affectedStids=>[
                    {
                      :stid=>"1000000",
                      :before=>"word1 word2 ",
                      :after=>"word1 word2 word3 "
                    },{
                      :stid=>"1000001",
                      :before=>"word3 word4 ",
                      :after=>"word4 "
                    }
                  ]
                }
                ],
            ],
            [
              'Split',
              %w[@word1 word2  word3 word4 @word5 word6],
              %w[@word1 word2 @word3 word4 @word5 word6],
              [
                {
                  :operationId=>"hunk_index-1",
                  :operationType=>:split,
                  :afterStid=>nil,
                  :affectedStids=>[
                    {
                      :stid=>"1000000",
                      :before=>"word1 word2 word3 word4 ",
                      :after=>"word1 word2 "
                    },{
                      :stid=>"tmp-1000000+1",
                      :before=>'',
                      :after=>"word3 word4 "
                    }
                  ]
                }
              ],
            ],
            # ----------------------------------------------------------------
            # Compound operations
            # ----------------------------------------------------------------
            [
              'merge (fits more than 50%), moveLeft',
              %w[@0word1 word2 @1word3 word4 word5   word6 @2word7],
              %w[@0word1 word2   word3 word4 word5 @2word6   word7],
              [
                {
                  :operationId=>"hunk_index-1",
                  :operationType=>:merge,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000000", :before=>"0word1 word2 ", :after=>"0word1 word2 word3 word4 word5 " },
                    { :stid=>"1000001", :before=>"1word3 word4 word5 word6 ", :after=>"" },
                  ]
                },{
                  :operationId=>"hunk_index-2",
                  :operationType=>:moveLeft,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000001", :before=>"1word3 word4 word5 word6 ", :after=>"" },
                    { :stid=>"1000002", :before=>"2word7\n", :after=>"2word6 word7\n" },
                  ]
                }
              ]
            ],
            [
              'merge (fits less than 50%), moveLeft',
              %w[@0word1 word2 word3 word4 word5 word6 @1word7 word8   word9 word10 word11 word12 @2word13 word14 word15 word16 word17 word18],
              %w[@0word1 word2 word3 word4 word5 word6   word7 word8 @2word9 word10 word11 word12   word13 word14 word15 word16 word17 word18],
              [
                {
                  :operationId=>"hunk_index-1",
                  :operationType=>:merge,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000000", :before=>"0word1 word2 word3 word4 word5 word6 ", :after=>"0word1 word2 word3 word4 word5 word6 word7 word8 "},
                    { :stid=>"1000001", :before=>"1word7 word8 word9 word10 word11 word12 ", :after=>""}
                  ]
                },{
                  :operationId=>"hunk_index-2",
                  :operationType=>:moveLeft,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000001", :before=>"1word7 word8 word9 word10 word11 word12 ", :after=>""},
                    { :stid=>"1000002", :before=>"2word13 word14 word15 word16 word17 word18\n", :after=>"2word9 word10 word11 word12 word13 word14 word15 word16 word17 word18\n"}
                  ]
                }
              ]
            ],
            [
              'merge, moveLeft, moveLeft',
              %w[@0word1 word2 @1word3   word4 @2word5 word6   word7 @3word8],
              %w[@0word1 word2   word3 @2word4   word5 word6 @3word7   word8],
              [
                {
                  :operationId=>"hunk_index-1",
                  :operationType=>:merge,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000000", :before=>"0word1 word2 ", :after=>"0word1 word2 word3 " },
                    { :stid=>"1000001", :before=>"1word3 word4 ", :after=>"" },
                  ]
                },{
                  :operationId=>"hunk_index-2",
                  :operationType=>:moveLeft,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000001", :before=>"1word3 word4 ", :after=>"" },
                    { :stid=>"1000002", :before=>"2word5 word6 word7 ", :after=>"2word4 word5 word6 " },
                  ]
                },{
                  :operationId=>"hunk_index-3",
                  :operationType=>:moveLeft,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000002", :before=>"2word5 word6 word7 ", :after=>"2word4 word5 word6 " },
                    { :stid=>"1000003", :before=>"3word8\n", :after=>"3word7 word8\n" }
                  ]
                }
              ]
            ],
            [
              'merge, moveLeft, moveRight',
              %w[@0word1 word2 @1word3   word4 @2word5 word6 @3word7   word8],
              %w[@0word1 word2   word3 @2word4   word5 word6   word7 @3word8],
              [
                {
                  :operationId=>"hunk_index-1",
                  :operationType=>:merge,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000000", :before=>"0word1 word2 ", :after=>"0word1 word2 word3 " },
                    { :stid=>"1000001", :before=>"1word3 word4 ", :after=>"" },
                  ]
                },{
                  :operationId=>"hunk_index-2",
                  :operationType=>:moveLeft,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000001", :before=>"1word3 word4 ", :after=>"" },
                    { :stid=>"1000002", :before=>"2word5 word6 ", :after=>"2word4 word5 word6 word7 " },
                  ]
                },{
                  :operationId=>"hunk_index-3",
                  :operationType=>:moveRight,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000002", :before=>"2word5 word6 ", :after=>"2word4 word5 word6 word7 " },
                    { :stid=>"1000003", :before=>"3word7 word8\n", :after=>"3word8\n" }
                  ]
                }
              ]
            ],
            [
              'merge, moveLeft, split',
              %w[@0word1 word2 @1word3   word4 @2word5 word6 @3word7   word8],
              %w[@0word1 word2   word3 @2word4   word5 word6 @3word7 @4word8],
              [
                {
                  :operationId=>"hunk_index-1",
                  :operationType=>:merge,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000000", :before=>"0word1 word2 ", :after=>"0word1 word2 word3 " },
                    { :stid=>"1000001", :before=>"1word3 word4 ", :after=>"" }
                  ]
                },{
                  :operationId=>"hunk_index-2",
                  :operationType=>:moveLeft,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000001", :before=>"1word3 word4 ", :after=>"" },
                    { :stid=>"1000002", :before=>"2word5 word6 ", :after=>"2word4 word5 word6 " }
                  ]
                },{
                  :operationId=>"hunk_index-4",
                  :operationType=>:split,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000003", :before=>"3word7 word8\n", :after=>"3word7 " },
                    { :stid=>"tmp-1000003+1", :before=>"", :after=>"4word8\n" }
                  ]
                }
              ]
            ],
            [
              'moveLeft, merge',
              %w[@0word1 word2   word3 @1word4 @2word5 word6 @3word7 word8],
              %w[@0word1 word2 @1word3   word4 @2word5 word6   word7 word8],
              [
                {
                  :operationId=>"hunk_index-0",
                  :operationType=>:moveLeft,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000000", :before=>"0word1 word2 word3 ", :after=>"0word1 word2 " },
                    { :stid=>"1000001", :before=>"1word4 ", :after=>"1word3 word4 " }
                  ]
                },{
                  :operationId=>"hunk_index-3",
                  :operationType=>:merge,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000002", :before=>"2word5 word6 ", :after=>"2word5 word6 word7 word8\n" },
                    { :stid=>"1000003", :before=>"3word7 word8\n", :after=>"" }
                  ]
                }
              ]
            ],
            [
              'moveLeft, merge, moveLeft',
              %w[@0word1   word2 @1word3 @2word4 @3word5   word6 @4word7],
              %w[@0word1 @1word2   word3 @2word4   word5 @4word6   word7],
              [
                {
                  :operationId=>"hunk_index-0",
                  :operationType=>:moveLeft,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000000", :before=>"0word1 word2 ", :after=>"0word1 " },
                    { :stid=>"1000001", :before=>"1word3 ", :after=>"1word2 word3 " }
                  ]
                },{
                  :operationId=>"hunk_index-3",
                  :operationType=>:merge,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000002", :before=>"2word4 ", :after=>"2word4 word5 " },
                    { :stid=>"1000003", :before=>"3word5 word6 ", :after=>"" }
                  ]
                },{
                  :operationId=>"hunk_index-4",
                  :operationType=>:moveLeft,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000003", :before=>"3word5 word6 ", :after=>"" },
                    { :stid=>"1000004", :before=>"4word7\n", :after=>"4word6 word7\n" }
                  ]
                }
              ]
            ],
            [
              'moveLeft, merge, split',
              %w[@0word1   word2 @1word3 @2word4 @3word5 @4word6   word7],
              %w[@0word1 @1word2   word3 @2word4   word5 @4word6 @5word7],
              [
                {
                  :operationId=>"hunk_index-0",
                  :operationType=>:moveLeft,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000000", :before=>"0word1 word2 ", :after=>"0word1 " },
                    { :stid=>"1000001", :before=>"1word3 ", :after=>"1word2 word3 " }
                  ]
                },{
                  :operationId=>"hunk_index-3",
                  :operationType=>:merge,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000002", :before=>"2word4 ", :after=>"2word4 word5 " },
                    { :stid=>"1000003", :before=>"3word5 ", :after=>"" }
                  ]
                },{
                  :operationId=>"hunk_index-5",
                  :operationType=>:split,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000004", :before=>"4word6 word7\n", :after=>"4word6 " },
                    { :stid=>"tmp-1000004+1", :before=>"", :after=>"5word7\n" }
                  ]
                }
              ]
            ],
            [
              'moveLeft, moveLeft',
              %w[@0word1   word2 @1word3   word4 @2word5],
              %w[@0word1 @1word2   word3 @2word4   word5],
              [
                {
                  :operationId=>"hunk_index-1",
                  :operationType=>:moveLeft,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000000", :before=>"0word1 word2 ", :after=>"0word1 " },
                    { :stid=>"1000001", :before=>"1word3 word4 ", :after=>"1word2 word3 " }
                  ]
                },{
                  :operationId=>"hunk_index-2",
                  :operationType=>:moveLeft,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000001", :before=>"1word3 word4 ", :after=>"1word2 word3 " },
                    { :stid=>"1000002", :before=>"2word5\n", :after=>"2word4 word5\n" }
                  ]
                }
              ]
            ],
            [
              'moveLeft, moveRight',
              %w[@0word1   word2 @1word3 @2word4   word5],
              %w[@0word1 @1word2   word3   word4 @2word5],
              [
                {
                  :operationId=>"hunk_index-1",
                  :operationType=>:moveLeft,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000000", :before=>"0word1 word2 ", :after=>"0word1 " },
                    { :stid=>"1000001", :before=>"1word3 ", :after=>"1word2 word3 word4 " }
                  ]
                },{
                  :operationId=>"hunk_index-2",
                  :operationType=>:moveRight,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000001", :before=>"1word3 ", :after=>"1word2 word3 word4 " },
                    { :stid=>"1000002", :before=>"2word4 word5\n", :after=>"2word5\n" }
                  ]
                }
              ]
            ],
            [
              'moveLeft, split',
              %w[@0word1   word2 @1word3 @2word4   word5],
              %w[@0word1 @1word2   word3 @2word4 @3word5],
              [
                {
                  :operationId=>"hunk_index-0",
                  :operationType=>:moveLeft,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000000", :before=>"0word1 word2 ", :after=>"0word1 " },
                    { :stid=>"1000001", :before=>"1word3 ", :after=>"1word2 word3 " }
                  ]
                },{
                  :operationId=>"hunk_index-3",
                  :operationType=>:split,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000002", :before=>"2word4 word5\n", :after=>"2word4 " },
                    { :stid=>"tmp-1000002+1", :before=>"", :after=>"3word5\n" }
                  ]
                }
              ]
            ],
            [
              'moveLeft, split (2)',
              %w[@word1 word2 word3  word4 word5@word6 word7 word8 word9 word10 word11  word12 word13 word14 word15 @and some more],
              %w[@word1 word2 word3 @word4 word5 word6 word7 word8 word9 word10 word11 @word12 word13 word14 word15 @and some more],
              [
                {
                  :operationId=>"hunk_index-1",
                  :operationType=>:moveLeft,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000000", :before=>"word1 word2 word3 word4 word5", :after=>"word1 word2 word3 " },
                    { :stid=>"1000001", :before=>"word6 word7 word8 word9 word10 word11 word12 word13 word14 word15 ", :after=>"word4 word5 word6 word7 word8 word9 word10 word11 " }
                  ]
                }, {
                  :operationId=>"hunk_index-2",
                  :operationType=>:split,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000001", :before=>"word6 word7 word8 word9 word10 word11 word12 word13 word14 word15 ", :after=>"word4 word5 word6 word7 word8 word9 word10 word11 " },
                    { :stid=>"tmp-1000001+1", :before=>"", :after=>"word12 word13 word14 word15 " }
                  ]
                }
              ]
            ],
            [
              'moveRight, merge',
              %w[@0word1 word2 @1word3   word4 word5 word6 @2word7],
              %w[@0word1 word2   word3 @2word4 word5 word6   word7],
              [
                {
                  :operationId=>"hunk_index-1",
                  :operationType=>:moveRight,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000000", :before=>"0word1 word2 ", :after=>"0word1 word2 word3 "},
                    { :stid=>"1000001", :before=>"1word3 word4 word5 word6 ", :after=>"2word4 word5 word6 word7\n"}
                  ]
                },{
                  :operationId=>"hunk_index-2",
                  :operationType=>:merge,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000001", :before=>"1word3 word4 word5 word6 ", :after=>"2word4 word5 word6 word7\n"},
                    { :stid=>"1000002", :before=>"2word7\n", :after=>""}
                  ]
                }
              ]
            ],
            [
              'moveRight, merge, moveLeft, moveRight',
              %w[@0word1 @1word2   word3 @2word4 @3word5   word6 @4word7 @5word8   word9],
              %w[@0word1   word2 @1word3 @2word4   word5 @4word6   word7   word8 @5word9],
              [
                {
                  :operationId=>"hunk_index-0",
                  :operationType=>:moveRight,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000000", :before=>"0word1 ", :after=>"0word1 word2 "},
                    { :stid=>"1000001", :before=>"1word2 word3 ", :after=>"1word3 "}
                  ]
                },{
                  :operationId=>"hunk_index-3",
                  :operationType=>:merge,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000002", :before=>"2word4 ", :after=>"2word4 word5 "},
                    { :stid=>"1000003", :before=>"3word5 word6 ", :after=>""}
                  ]
                },{
                  :operationId=>"hunk_index-4",
                  :operationType=>:moveLeft,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000003", :before=>"3word5 word6 ", :after=>""},
                    { :stid=>"1000004", :before=>"4word7 ", :after=>"4word6 word7 word8 "}
                  ]
                },{
                  :operationId=>"hunk_index-5",
                  :operationType=>:moveRight,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000004", :before=>"4word7 ", :after=>"4word6 word7 word8 "},
                    { :stid=>"1000005", :before=>"5word8 word9\n", :after=>"5word9\n"}
                  ]
                }
              ]
            ],
            [
              'moveRight, moveLeft',
              %w[@0word1 @1word2   word3   word4 @2word5],
              %w[@0word1   word2 @1word3 @2word4   word5],
              [
                {
                  :operationId=>"hunk_index-1",
                  :operationType=>:moveRight,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000000", :before=>"0word1 ", :after=>"0word1 word2 "},
                    { :stid=>"1000001", :before=>"1word2 word3 word4 ", :after=>"1word3 "}
                  ]
                },{
                  :operationId=>"hunk_index-2",
                  :operationType=>:moveLeft,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000001", :before=>"1word2 word3 word4 ", :after=>"1word3 "},
                    { :stid=>"1000002", :before=>"2word5\n", :after=>"2word4 word5\n"}
                  ]
                }
              ]
            ],
            [
              'moveRight, moveRight, merge, moveLeft',
              %w[@0word1 @1word2   word3 @2word4   word5 @3word6 @4word7   word8 @5word9],
              %w[@0word1   word2 @1word3   word4 @2word5 @3word6   word7 @5word8   word9],
              [
                {
                  :operationId=>"hunk_index-1",
                  :operationType=>:moveRight,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000000", :before=>"0word1 ", :after=>"0word1 word2 "},
                    { :stid=>"1000001", :before=>"1word2 word3 ", :after=>"1word3 word4 "}
                  ]
                },{
                  :operationId=>"hunk_index-2",
                  :operationType=>:moveRight,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000001", :before=>"1word2 word3 ", :after=>"1word3 word4 "},
                    { :stid=>"1000002", :before=>"2word4 word5 ", :after=>"2word5 "}
                  ]
                },{
                  :operationId=>"hunk_index-4",
                  :operationType=>:merge,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000003", :before=>"3word6 ", :after=>"3word6 word7 "},
                    { :stid=>"1000004", :before=>"4word7 word8 ", :after=>""}
                  ]
                },{
                  :operationId=>"hunk_index-5",
                  :operationType=>:moveLeft,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000004", :before=>"4word7 word8 ", :after=>""},
                    { :stid=>"1000005", :before=>"5word9\n", :after=>"5word8 word9\n"}
                  ]
                }
              ]
            ],
            [
              'moveRight, moveRight, moveRight, moveRight, merge, merge',
              %w[@0word1 @1word2   word3 @2word4   word5 @3word6   word7 @4word8   word9 @5word10 @6word11 @7word12 @8word13],
              %w[@0word1   word2 @1word3   word4 @2word5   word6 @3word7   word8 @4word9 @5word10   word11 @7word12   word13],
              [
                {
                  :operationId=>"hunk_index-1",
                  :operationType=>:moveRight,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000000", :before=>"0word1 ", :after=>"0word1 word2 "},
                    { :stid=>"1000001", :before=>"1word2 word3 ", :after=>"1word3 word4 "}
                  ]
                },{
                  :operationId=>"hunk_index-2",
                  :operationType=>:moveRight,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000001", :before=>"1word2 word3 ", :after=>"1word3 word4 "},
                    { :stid=>"1000002", :before=>"2word4 word5 ", :after=>"2word5 word6 "}
                  ]
                },{
                  :operationId=>"hunk_index-3",
                  :operationType=>:moveRight,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000002", :before=>"2word4 word5 ", :after=>"2word5 word6 "},
                    { :stid=>"1000003", :before=>"3word6 word7 ", :after=>"3word7 word8 "}
                  ]
                },{
                  :operationId=>"hunk_index-4",
                  :operationType=>:moveRight,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000003", :before=>"3word6 word7 ", :after=>"3word7 word8 "},
                    { :stid=>"1000004", :before=>"4word8 word9 ", :after=>"4word9 "}
                  ]
                },{
                  :operationId=>"hunk_index-6",
                  :operationType=>:merge,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000005", :before=>"5word10 ", :after=>"5word10 word11 "},
                    { :stid=>"1000006", :before=>"6word11 ", :after=>""}
                  ]
                },{
                  :operationId=>"hunk_index-8",
                  :operationType=>:merge,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000007", :before=>"7word12 ", :after=>"7word12 word13\n"},
                    { :stid=>"1000008", :before=>"8word13\n", :after=>""}
                  ]
                }
              ]
            ],
            [
              'moveRight, moveRight, moveRight, moveRight, split, moveRight',
              %w[@0word1 @1word2   word3 @2word4   word5 @3word6   word7 @4word8   word9 @5word10   word11 @7word12   word13],
              %w[@0word1   word2 @1word3   word4 @2word5   word6 @3word7   word8 @4word9 @5word10 @6word11   word12 @7word13],
              [
                {
                  :operationId=>"hunk_index-1",
                  :operationType=>:moveRight,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000000", :before=>"0word1 ", :after=>"0word1 word2 "},
                    { :stid=>"1000001", :before=>"1word2 word3 ", :after=>"1word3 word4 "}
                  ]
                },{
                  :operationId=>"hunk_index-2",
                  :operationType=>:moveRight,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000001", :before=>"1word2 word3 ", :after=>"1word3 word4 "},
                    { :stid=>"1000002", :before=>"2word4 word5 ", :after=>"2word5 word6 "}
                  ]
                },{
                  :operationId=>"hunk_index-3",
                  :operationType=>:moveRight,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000002", :before=>"2word4 word5 ", :after=>"2word5 word6 "},
                    { :stid=>"1000003", :before=>"3word6 word7 ", :after=>"3word7 word8 "}
                  ]
                },{
                  :operationId=>"hunk_index-4",
                  :operationType=>:moveRight,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000003", :before=>"3word6 word7 ", :after=>"3word7 word8 "},
                    { :stid=>"1000004", :before=>"4word8 word9 ", :after=>"4word9 "}
                  ]
                },{
                  :operationId=>"hunk_index-6",
                  :operationType=>:split,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000005", :before=>"5word10 word11 ", :after=>"5word10 "},
                    { :stid=>"tmp-1000005+1", :before=>"", :after=>"6word11 word12 "}
                  ]
                },{
                  :operationId=>"hunk_index-7",
                  :operationType=>:moveRight,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"tmp-1000005+1", :before=>"", :after=>"6word11 word12 "},
                    { :stid=>"1000006", :before=>"7word12 word13\n", :after=>"7word13\n"}
                  ]
                }
              ]
            ],
            [
              'moveRight, moveRight',
              %w[@0word1 @1word2   word3 @2word4   word5],
              %w[@0word1   word2 @1word3   word4 @2word5],
              [
                {
                  :operationId=>"hunk_index-1",
                  :operationType=>:moveRight,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000000", :before=>"0word1 ", :after=>"0word1 word2 "},
                    { :stid=>"1000001", :before=>"1word2 word3 ", :after=>"1word3 word4 "}
                  ]
                },{
                  :operationId=>"hunk_index-2",
                  :operationType=>:moveRight,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000001", :before=>"1word2 word3 ", :after=>"1word3 word4 "},
                    { :stid=>"1000002", :before=>"2word4 word5\n", :after=>"2word5\n"}
                  ]
                }
              ]
            ],
            [
              'moveRight, split',
              %w[@0word1 word2 @1word3  word4 @2word5 word6   word7 word8],
              %w[@0word1 word2  word3 @1word4 @2word5 word6 @3word7 word8],
              [
                {
                  :operationId=>"hunk_index-0",
                  :operationType=>:moveRight,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000000", :before=>"0word1 word2 ", :after=>"0word1 word2 word3 "},
                    { :stid=>"1000001", :before=>"1word3 word4 ", :after=>"1word4 " },
                  ]
                },{
                  :operationId=>"hunk_index-3",
                  :operationType=>:split,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000002", :before=>"2word5 word6 word7 word8\n", :after=>"2word5 word6 " },
                    { :stid=>"tmp-1000002+1", :before=>"", :after=>"3word7 word8\n" },
                  ]
                }
              ]
            ],
            [
              'split, moveLeft',
              %w[@0word1   word2   word3 @2word4],
              %w[@0word1 @1word2 @2word3   word4],
              [
                {
                  :operationId=>"hunk_index-1",
                  :operationType=>:split,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000000", :before=>"0word1 word2 word3 ", :after=>"0word1 " },
                    { :stid=>"tmp-1000000+1", :before=>"", :after=>"1word2 "}
                  ]
                },{
                  :operationId=>"hunk_index-2",
                  :operationType=>:moveLeft,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"tmp-1000000+1", :before=>"", :after=>"1word2 " },
                    { :stid=>"1000001", :before=>"2word4\n", :after=>"2word3 word4\n"}
                  ]
                }
              ]
            ],
            [
              'split, merge, moveLeft',
              %w[@0word1   word2 @2word3 @3word4   word5 @4word6],
              %w[@0word1 @1word2 @2word3   word4 @4word5   word6],
              [
                {
                  :operationId=>"hunk_index-1",
                  :operationType=>:split,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000000", :before=>"0word1 word2 ", :after=>"0word1 "},
                    { :stid=>"tmp-1000000+1", :before=>"", :after=>"1word2 "}
                  ]
                },{
                  :operationId=>"hunk_index-3",
                  :operationType=>:merge,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000001", :before=>"2word3 ", :after=>"2word3 word4 "},
                    { :stid=>"1000002", :before=>"3word4 word5 ", :after=>""}
                  ]
                },{
                  :operationId=>"hunk_index-4",
                  :operationType=>:moveLeft,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000002", :before=>"3word4 word5 ", :after=>""},
                    { :stid=>"1000003", :before=>"4word6\n", :after=>"4word5 word6\n"}
                  ]
                }
              ]
            ],
            [
              'split, moveLeft, split',
              %w[@0word1   word2   word3 @2word4 @3word5   word6],
              %w[@0word1 @1word2 @2word3   word4 @3word5 @4word6],
              [
                {
                  :operationId=>"hunk_index-1",
                  :operationType=>:split,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000000", :before=>"0word1 word2 word3 ", :after=>"0word1 "},
                    { :stid=>"tmp-1000000+1", :before=>"", :after=>"1word2 "}
                  ]
                },{
                  :operationId=>"hunk_index-2",
                  :operationType=>:moveLeft,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"tmp-1000000+1", :before=>"", :after=>"1word2 "},
                    { :stid=>"1000001", :before=>"2word4 ", :after=>"2word3 word4 "}
                  ]
                },{
                  :operationId=>"hunk_index-4",
                  :operationType=>:split,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000002", :before=>"3word5 word6\n", :after=>"3word5 "},
                    { :stid=>"tmp-1000002+1", :before=>"", :after=>"4word6\n"}
                  ]
                }
              ]
            ],
            [
              'split, moveRight, moveRight, moveLeft',
              %w[@0word1   word3 @2word4   word5 @3word6   word7   word8 @4word9],
              %w[@0word1 @1word3   word4 @2word5   word6 @3word7 @4word8   word9],
              [
                {
                  :operationId=>"hunk_index-1",
                  :operationType=>:split,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000000", :before=>"0word1 word3 ", :after=>"0word1 "},
                    { :stid=>"tmp-1000000+1", :before=>"", :after=>"1word3 word4 "}
                  ]
                },{
                  :operationId=>"hunk_index-2",
                  :operationType=>:moveRight,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"tmp-1000000+1", :before=>"", :after=>"1word3 word4 "},
                    { :stid=>"1000001", :before=>"2word4 word5 ", :after=>"2word5 word6 "}
                  ]
                },{
                  :operationId=>"hunk_index-3",
                  :operationType=>:moveRight,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000001", :before=>"2word4 word5 ", :after=>"2word5 word6 "},
                    { :stid=>"1000002", :before=>"3word6 word7 word8 ", :after=>"3word7 "}
                  ]
                },{
                  :operationId=>"hunk_index-4",
                  :operationType=>:moveLeft,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000002", :before=>"3word6 word7 word8 ", :after=>"3word7 "},
                    { :stid=>"1000003", :before=>"4word9\n", :after=>"4word8 word9\n"}
                  ]
                }
              ]
            ],
            [
              'split, moveRight, moveRight',
              %w[@0word1   word3 @2word4   word5 @3word6   word7],
              %w[@0word1 @1word3   word4 @2word5   word6 @3word7],
              [
                {
                  :operationId=>"hunk_index-1",
                  :operationType=>:split,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000000", :before=>"0word1 word3 ", :after=>"0word1 "},
                    { :stid=>"tmp-1000000+1", :before=>"", :after=>"1word3 word4 "}
                  ]
                },{
                  :operationId=>"hunk_index-2",
                  :operationType=>:moveRight,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"tmp-1000000+1", :before=>"", :after=>"1word3 word4 "},
                    { :stid=>"1000001", :before=>"2word4 word5 ", :after=>"2word5 word6 "}
                  ]
                },{
                  :operationId=>"hunk_index-3",
                  :operationType=>:moveRight,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000001", :before=>"2word4 word5 ", :after=>"2word5 word6 "},
                    { :stid=>"1000002", :before=>"3word6 word7\n", :after=>"3word7\n"}
                  ]
                }
              ]
            ],
            [
              'split (fits more than 50%), moveRight',
              %w[@0word1 word2   word3 word4 word5 @2word6   word7],
              %w[@0word1 word2 @1word3 word4 word5   word6 @2word7],
              [
                {
                  :operationId=>"hunk_index-1",
                  :operationType=>:split,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000000", :before=>"0word1 word2 word3 word4 word5 ", :after=>"0word1 word2 "},
                    { :stid=>"tmp-1000000+1", :before=>"", :after=>"1word3 word4 word5 word6 "}
                  ]
                },{
                  :operationId=>"hunk_index-2",
                  :operationType=>:moveRight,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"tmp-1000000+1", :before=>"", :after=>"1word3 word4 word5 word6 "},
                    { :stid=>"1000001", :before=>"2word6 word7\n", :after=>"2word7\n"}
                  ]
                }
              ]
            ],
            [
              'split (fits less than 50%), moveRight',
              %w[@0word1 word2 word3   word4 @2word5 word6 word7   word8 word9 word10 word11 word12 word13],
              %w[@0word1 word2 word3 @1word4   word5 word6 word7 @2word8 word9 word10 word11 word12 word13],
              [
                {
                  :operationId=>"hunk_index-1",
                  :operationType=>:split,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000000", :before=>"0word1 word2 word3 word4 ", :after=>"0word1 word2 word3 "},
                    { :stid=>"tmp-1000000+1", :before=>"", :after=>"1word4 word5 word6 word7 "}
                  ]
                },{
                  :operationId=>"hunk_index-2",
                  :operationType=>:moveRight,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"tmp-1000000+1", :before=>"", :after=>"1word4 word5 word6 word7 "},
                    { :stid=>"1000001", :before=>"2word5 word6 word7 word8 word9 word10 word11 word12 word13\n", :after=>"2word8 word9 word10 word11 word12 word13\n"}
                  ]
                }
              ]
            ],
            [
              'split, split, split, moveRight',
              %w[@0word1   word2 @2word3   word4 @4word5   word6 @6word7   word8],
              %w[@0word1 @1word2 @2word3 @3word4 @4word5 @5word6   word7 @6word8],
              [
                {
                  :operationId=>"hunk_index-1",
                  :operationType=>:split,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000000", :before=>"0word1 word2 ", :after=>"0word1 "},
                    { :stid=>"tmp-1000000+1", :before=>"", :after=>"1word2 "}
                  ]
                },{
                  :operationId=>"hunk_index-3",
                  :operationType=>:split,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000001", :before=>"2word3 word4 ", :after=>"2word3 "},
                    { :stid=>"tmp-1000001+1", :before=>"", :after=>"3word4 "}
                  ]
                },{
                  :operationId=>"hunk_index-5",
                  :operationType=>:split,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000002", :before=>"4word5 word6 ", :after=>"4word5 "},
                    { :stid=>"tmp-1000002+1", :before=>"", :after=>"5word6 word7 "}
                  ]
                },{
                  :operationId=>"hunk_index-6",
                  :operationType=>:moveRight,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"tmp-1000002+1", :before=>"", :after=>"5word6 word7 "},
                    { :stid=>"1000003", :before=>"6word7 word8\n", :after=>"6word8\n"}
                  ]
                }
              ]
            ],
            # ----------------------------------------------------------------
            # Production regression scenarios
            # ----------------------------------------------------------------
            [
              'long subtitles (required tweaking of Jaccard similarity thresholds)',
              %w[@word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12 word13 word14 word15 word16 word17 word18  word19 word20 @word21 word22 word23 word24 word25  word26 word27 word28 word29 word30 word31 word32 @and some more],
              %w[@word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12 word13 word14 word15 word16 word17 word18 @word19 word20  word21 word22 word23 word24 word25 @word26 word27 word28 word29 word30 word31 word32 @and some more],
              [
                {
                  :operationId=>"hunk_index-1",
                  :operationType=>:split,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000000", :before=>"word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12 word13 word14 word15 word16 word17 word18 word19 word20 ", :after=>"word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12 word13 word14 word15 word16 word17 word18 " },
                    { :stid=>"tmp-1000000+1", :before=>"", :after=>"word19 word20 word21 word22 word23 word24 word25 " }
                  ]
                }, {
                  :operationId=>"hunk_index-2",
                  :operationType=>:moveRight,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"tmp-1000000+1", :before=>"", :after=>"word19 word20 word21 word22 word23 word24 word25 " },
                    { :stid=>"1000001", :before=>"word21 word22 word23 word24 word25 word26 word27 word28 word29 word30 word31 word32 ", :after=>"word26 word27 word28 word29 word30 word31 word32 " }
                  ]
                }
              ]
            ],
            [
              'subtitles with different amounts of duplicate tokens (required custom addition to jaccard index)',
              %w[@word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12 word13 word14 word15 word16 word17 word18  dup_token @word19 word20 word21 word22 word23 word24  word25 word26 word27 word28 word29 word30 word31 word32 word33 word34 word35 @word36 word37 word38  word39 word40 word41 word42 word43 word44 word45 word46 word47 word48 word49 @and more words],
              %w[@word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12 word13 word14 word15 word16 word17 word18 @dup_token  word19 word20 word21 word22 word23 word24 @word25 word26 word27 word28 word29 word30 word31 word32 word33 word34 word35  word36 word37 word38 @word39 word40 word41 word42 word43 word44 word45 word46 word47 word48 word49 @and more words],
              [
                {
                  :operationId=>"hunk_index-1",
                  :operationType=>:split,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000000", :before=>"word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12 word13 word14 word15 word16 word17 word18 dup_token ", :after=>"word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12 word13 word14 word15 word16 word17 word18 " },
                    { :stid=>"tmp-1000000+1", :before=>"", :after=>"dup_token word19 word20 word21 word22 word23 word24 " }
                  ]
                }, {
                  :operationId=>"hunk_index-2",
                  :operationType=>:moveRight,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"tmp-1000000+1", :before=>"", :after=>"dup_token word19 word20 word21 word22 word23 word24 " },
                    { :stid=>"1000001", :before=>"word19 word20 word21 word22 word23 word24 word25 word26 word27 word28 word29 word30 word31 word32 word33 word34 word35 ", :after=>"word25 word26 word27 word28 word29 word30 word31 word32 word33 word34 word35 word36 word37 word38 " }
                  ]
                }, {
                  :operationId=>"hunk_index-3",
                  :operationType=>:moveRight,
                  :afterStid=>nil,
                  :affectedStids=>[
                    { :stid=>"1000001", :before=>"word19 word20 word21 word22 word23 word24 word25 word26 word27 word28 word29 word30 word31 word32 word33 word34 word35 ", :after=>"word25 word26 word27 word28 word29 word30 word31 word32 word33 word34 word35 word36 word37 word38 " },
                    { :stid=>"1000002", :before=>"word36 word37 word38 word39 word40 word41 word42 word43 word44 word45 word46 word47 word48 word49 ", :after=>"word39 word40 word41 word42 word43 word44 word45 word46 word47 word48 word49 " }
                  ]
                }
              ]
            ],
            [
              'content change only, no st_ops',
              %w[word1 %word2 word3 word4 word5 word6                                   word7 word8 word9 @word10 word11 word12 @word13 word14 word15 word16 word17],
              %w[word1 %word2 word3 word4 word5 word6 added_at_least_30_chars_from_left word7 word8 word9 @word10 word11 word12 @word13 word14 word15 word16 word17],
              []
            ],
          ].each do |description, del_c, add_c, xpect|

            it "handles #{ description }" do
              r = default_computer.send(
                :compute_hunk_operations_for_deletion_addition,
                [
                  { content: del_c.join(' '), line_no: 1, subtitles: default_subtitles }
                ],
                [
                  { line_origin: :deletion, content: del_c.join(' ') + "\n", old_linenos: 1 },
                  { line_origin: :addition, content: add_c.join(' ') + "\n", old_linenos: nil },
                ],
              )
              r[:subtitle_operations].map { |e| e.to_hash }.must_equal(xpect)
            end

          end

        end

      end

    end
  end
end
