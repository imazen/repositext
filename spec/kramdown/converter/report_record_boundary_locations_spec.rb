require_relative '../../helper'

module Kramdown
  module Converter
    describe ReportRecordBoundaryLocations do

      [
        [
          'Basic example',
          %(@word word\n\n@*word word*),
          ['rid-1', 'rid-2'],
          { root: 2, paragraph: 0, span: 0, comments: [] },
        ],
        [
          'Inside paragraph',
          %(@word @word\n\n@word word),
          ['rid-1', 'rid-2', 'rid-2'],
          { root: 1, paragraph: 1, span: 0, comments: [] },
        ],
        [
          'Inside span',
          %(@word *word @word* word),
          ['rid-1', 'rid-2'],
          { root: 1, paragraph: 0, span: 1, comments: ["STM inside span: [{:type=>:root, :current_child_index=>1}, {:type=>:paragraph, :current_child_index=>3}, {:type=>:span, :current_child_index=>2}]"] },
        ],
        [
          'Inside paragraph and span',
          %(@word *word @word*\n\n@word word),
          ['rid-1', 'rid-2', 'rid-2'],
          { root: 1, paragraph: 0, span: 1, comments: ["STM inside span: [{:type=>:root, :current_child_index=>1}, {:type=>:paragraph, :current_child_index=>3}, {:type=>:span, :current_child_index=>2}]"] },
        ],
      ].each do |(description, kramdown, subtitle_rids, xpect)|
        it "handles #{ description }" do
          doc = Document.new(
            kramdown,
            {
              input: 'KramdownRepositext',
              subtitles: subtitle_rids.map { |rid|
                Repositext::Subtitle.new(record_id: rid)
              }
            }
          )
          doc.to_report_record_boundary_locations.must_equal(xpect)
        end
      end

      [
        [
          'too few',
          %(@word word\n\nword word),
          ['rid-1', 'rid-2'],
        ],
        [
          'too many',
          %(@word @word\n\n@word @word),
          ['rid-1', 'rid-2', 'rid-2'],
        ],
      ].each do |(description, kramdown, subtitle_rids)|
        it "raises on subtitle count mismatch #{ description }" do
          doc = Document.new(
            kramdown,
            {
              input: 'KramdownRepositext',
              subtitles: subtitle_rids.map { |rid|
                Repositext::Subtitle.new(record_id: rid)
              }
            }
          )
          proc{
            doc.to_report_record_boundary_locations
          }.must_raise(RuntimeError, NoMethodError)
        end
      end

    end
  end
end
