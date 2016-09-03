require_relative '../../../../helper'

class Repositext
  class Process
    class Compute
      class SubtitleOperationsForFile
        describe ComputeSubtitleAttrs do

          let(:default_computer){
            SubtitleOperationsForFile.new(
              '_content_at_file_to',
              '_repo_base_dir',
              {}
            )
          }
          let(:default_content_at_from){
            [
              "@word1 word2 word3 word4 word5 ",
              "@word6 word7 word8 word9 word10 ",
              "@word11 word12 word13 word14 word15 word16 word17 word18 word19 word20",
            ].join
          }
          let(:default_subtitle_attrs_from){
            [
              {
                content: "word1 word2 word3 word4 word5 ",
                subtitle_count: 1,
                first_in_para: true,
              }, {
                content: "word6 word7 word8 word9 word10 ",
                subtitle_count: 1,
              }, {
                content: "word11 word12 word13 word14 word15 word16 word17 word18 word19 word20",
                subtitle_count: 1,
                last_in_para: true,
              },
            ]
          }
          let(:default_content_at_to){
            [
              "@word1 word2 word3 word4 word5 word6 word7 word8 word9 ",
              "@word10 word11 word12 word13 word14 word15 word16 word17 word18 word19 word20 ",
              "@word20 word21 word22 word23",
            ].join
          }
          let(:default_subtitle_attrs_to){
            [
              {
                content: "word1 word2 word3 word4 word5 word6 word7 word8 word9 ",
                subtitle_count: 1,
                first_in_para: true,
              }, {
                content: "word10 word11 word12 word13 word14 word15 word16 word17 word18 word19 word20 ",
                subtitle_count: 1,
              }, {
                content: "word20 word21 word22 word23",
                subtitle_count: 1,
                last_in_para: true,
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
              { :persistent_id=>"1000001", :record_id=>"123123123" },
              { :persistent_id=>"1000002", :record_id=>"123123124" },
              { :persistent_id=>"1000003", :record_id=>"123123125" }
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
                "@1    word1 word2 word3",
              ).first[:content].must_equal("word1 word2 word3")
            end

            it "Removes trailing newlines" do
              default_computer.send(
                :convert_content_at_to_subtitle_attrs,
                "@word1 word2 word3\n",
              ).first[:content].must_equal("word1 word2 word3")
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
        end
      end
    end
  end
end
