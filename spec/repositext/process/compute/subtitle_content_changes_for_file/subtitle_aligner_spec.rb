require_relative '../../../../helper'

class Repositext
  class Process
    class Compute
      class SubtitleContentChangesForFile
        describe SubtitleAligner do

          describe '#get_optimal_alignment' do
            [
              [
                'Identical sequences',
                [
                  "1045692",
                  "5729592",
                  "9798067",
                  "5605203",
                  "4177319",
                  "6831088",
                  "6692539",
                  "8246208",
                  "7970922",
                  "7518924",
                ],
                [
                  "1045692",
                  "5729592",
                  "9798067",
                  "5605203",
                  "4177319",
                  "6831088",
                  "6692539",
                  "8246208",
                  "7970922",
                  "7518924",
                ],
                [
                  [
                    "1045692",
                    "5729592",
                    "9798067",
                    "5605203",
                    "4177319",
                    "6831088",
                    "6692539",
                    "8246208",
                    "7970922",
                    "7518924",
                  ],
                  [
                    "1045692",
                    "5729592",
                    "9798067",
                    "5605203",
                    "4177319",
                    "6831088",
                    "6692539",
                    "8246208",
                    "7970922",
                    "7518924",
                  ],
                ],
              ],
            ].each do |desc, sts_from, sts_to, xpect|
              it "Handles #{ desc }" do
                aligner = SubtitleAligner.new(
                  sts_from.map { |e| Subtitle.new(persistent_id: e) },
                  sts_to.map { |e| Subtitle.new(persistent_id: e) },
                  diagonal_band_range: 100
                )
                r = aligner.get_optimal_alignment
                r.must_equal(
                  xpect.map { |seq|
                    seq.map { |stid| Subtitle.new(persistent_id: stid) }
                  }
                )
              end
            end
          end

          describe '#compute_score' do
            [
              [
                'identical',
                '1045692',
                '1045692',
                10
              ],
              [
                'different',
                '1045692',
                '1045693',
                -11
              ],
            ].each { |desc, left_stid, right_stid, xpect|
              it "Handles #{ desc }" do
                aligner = SubtitleAligner.new(
                  [],
                  [],
                  diagonal_band_range: 10
                )
                aligner.compute_score(
                  left_stid ? Subtitle.new(persistent_id: left_stid) : nil,
                  right_stid ? Subtitle.new(persistent_id: right_stid) : nil,
                  1,
                  1
                ).must_equal(xpect)
              end
            }
          end

        end
      end
    end
  end
end
