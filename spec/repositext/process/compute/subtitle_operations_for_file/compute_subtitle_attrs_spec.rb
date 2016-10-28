require_relative '../../../../helper'

class Repositext
  class Process
    class Compute
      class SubtitleOperationsForFile
        describe ComputeSubtitleAttrs do

          let(:language) { Language::English.new }
          let(:content_at_file) { RFile::ContentAt.new('_', language, 'filename') }
          let(:default_computer){
            SubtitleOperationsForFile.new(
              content_at_file,
              '_repo_base_dir',
              {}
            )
          }

          let(:default_content_at_from){
            [
              "^^^ {: .rid #rid-54040019}\n\n",
              "@Abcd Efgh Ijkl Mnop Qrst ",
              "@Vwxy Z123 A456 B789 C012 ",
              "@D345 Qwer Tyui Opas Dfgh Jklz Xcvb Nmqw Erty Uiop",
            ].join
          }

          let(:default_subtitle_attrs_from){
            [
              {
                content: "Abcd Efgh Ijkl Mnop Qrst ",
                content_sim: "abcd efgh ijkl mnop qrst",
                first_in_para: true,
                index: 0,
                para_index: 0,
                record_id: "54040019",
                repetitions: {},
                subtitle_count: 1,
              }, {
                content: "Vwxy Z123 A456 B789 C012 ",
                content_sim: "vwxy z123 a456 b789 c012",
                index: 1,
                para_index: 0,
                record_id: "54040019",
                repetitions: {},
                subtitle_count: 1,
              }, {
                content: "D345 Qwer Tyui Opas Dfgh Jklz Xcvb Nmqw Erty Uiop\n",
                content_sim: "d345 qwer tyui opas dfgh jklz xcvb nmqw erty uiop",
                index: 2,
                last_in_para: true,
                para_index: 0,
                record_id: "54040019",
                repetitions: {},
                subtitle_count: 1,
              },
            ]
          }

          let(:default_content_at_to){
            [
              "^^^ {: .rid #rid-54040019}\n\n",
              "@Abcd Efgh Ijkl Mnop Qrst Vwxy Z123 A456 B789 ",
              "@C012 D345 Qwer Tyui Opas Dfgh Jklz Xcvb Nmqw Erty Uiop ",
              "@Uiop Asdf Mnbv Cxzl",
            ].join
          }

          let(:default_subtitle_attrs_to){
            [
              {
                content: "Abcd Efgh Ijkl Mnop Qrst Vwxy Z123 A456 B789 ",
                content_sim: "abcd efgh ijkl mnop qrst vwxy z123 a456 b789",
                first_in_para: true,
                index: 0,
                para_index: 0,
                record_id: "54040019",
                repetitions: {},
                subtitle_count: 1,
              }, {
                content: "C012 D345 Qwer Tyui Opas Dfgh Jklz Xcvb Nmqw Erty Uiop ",
                content_sim: "c012 d345 qwer tyui opas dfgh jklz xcvb nmqw erty uiop",
                index: 1,
                para_index: 0,
                record_id: "54040019",
                repetitions: {},
                subtitle_count: 1,
              }, {
                content: "Uiop Asdf Mnbv Cxzl\n",
                content_sim: "uiop asdf mnbv cxzl",
                index: 2,
                last_in_para: true,
                para_index: 0,
                record_id: "54040019",
                repetitions: {},
                subtitle_count: 1,
              },
            ]
          }

          let(:default_st_objects_from){
            [
              ::Repositext::Subtitle.new(
                persistent_id: "1000001",
                record_id: "123123123",
                tmp_attrs: {}
              ),
              ::Repositext::Subtitle.new(
                persistent_id: "1000002",
                record_id: "123123124",
                tmp_attrs: {}
              ),
              ::Repositext::Subtitle.new(
                persistent_id: "1000003",
                record_id: "123123125",
                tmp_attrs: {}
              ),
            ]
          }

          let(:default_enriched_subtitle_attrs_from){
            enriched_attrs = [
              { :persistent_id=>"1000001" },
              { :persistent_id=>"1000002" },
              { :persistent_id=>"1000003" }
            ]
            r = []
            default_subtitle_attrs_from.each_with_index {|saf, idx|
              r << saf.merge(enriched_attrs[idx])
            }
            r
          }

          describe '#convert_content_at_to_subtitle_attrs' do
            it "Handles default from data" do
              default_computer.send(
                :convert_content_at_to_subtitle_attrs,
                default_content_at_from,
              ).must_equal(default_subtitle_attrs_from)
            end

            it "Handles default to data" do
              default_computer.send(
                :convert_content_at_to_subtitle_attrs,
                default_content_at_to,
              ).must_equal(default_subtitle_attrs_to)
            end

            it "Removes paragraph numbers" do
              default_computer.send(
                :convert_content_at_to_subtitle_attrs,
                "^^^ {: .rid #rid-54040019}\n\n@1    word1 word2 word3",
              ).first[:content].must_equal("word1 word2 word3\n")
            end

            it "Removes trailing newlines" do
              default_computer.send(
                :convert_content_at_to_subtitle_attrs,
                "^^^ {: .rid #rid-54040019}\n\n@word1 word2 word3\n",
              ).first[:content].must_equal("word1 word2 word3\n")
            end
          end

          describe '#enrich_st_attrs_from' do
            it "Handles default from data" do
              default_computer.send(
                :enrich_st_attrs_from,
                default_subtitle_attrs_from,
                default_st_objects_from
              ).must_equal(default_enriched_subtitle_attrs_from)
            end
          end

          describe 'NUMBER_SEQUENCE_REGEX' do
            [
              ["abc", nil],
              ["123", nil],
              ["123 456", nil],
              ["123 456 789", '123 456 789'],
              ["start text 21 22 23 24 end text", '21 22 23 24'],
            ].each do |test_string, xpect|
              it "Handles #{ test_string.inspect }" do
                match = test_string.match(NUMBER_SEQUENCE_REGEX)
                if xpect
                  match[0].must_equal(xpect)
                else
                  match.must_equal(nil)
                end
              end
            end
          end

          describe '#replace_digit_sequences_with_words' do
            [
              ["abc", "abc"],
              [
                "start 21 22 23 24 25 end",
                "start twenty one twenty two twenty three twenty four twenty five end"
              ],
              [
                "f 21 22 23 24 25 26 27 28 29 30 now let them",
                "f twenty one twenty two twenty three twenty four twenty five twenty six twenty seven twenty eight twenty nine thirty now let them",
              ],
              [
                "1 2 3 4 separated by some text 7 8 9 10",
                "one two three four separated by some text seven eight nine ten",
              ],
            ].each do |test_string, xpect|
              it "Handles #{ test_string.inspect }" do
                default_computer.send(
                  :replace_digit_sequences_with_words,
                  test_string
                ).must_equal(xpect)
              end
            end
          end

        end
      end
    end
  end
end
