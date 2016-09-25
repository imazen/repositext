require_relative '../../../../helper'

class Repositext
  class Process
    class Compute
      class SubtitleOperationsForFile
        describe AlignSubtitlePairs do

          let(:default_computer){
            SubtitleOperationsForFile.new(
              '_content_at_file_to',
              '_repo_base_dir',
              {}
            )
          }
          let(:default_subtitle_attrs_from){
            [
              {
                content: "Abcd Efgh Ijkl Mnop Qrst ",
                content_sim: "abcd efgh ijkl mnop qrst",
                first_in_para: true,
                index: 0,
                persistent_id: "1000001",
                record_id: "123123123",
                repetitions: {},
                subtitle_count: 1,
              }, {
                content: "Vwxy Z123 A456 B789 C012 ",
                content_sim: "vwxy z123 a456 b789 c012",
                index: 1,
                persistent_id: "1000002",
                record_id: "123123124",
                repetitions: {},
                subtitle_count: 1,
              }, {
                content: "D345 Qwer Tyui Opas Dfgh Jklz Xcvb Nmqw Erty Uiop",
                content_sim: "d345 qwer tyui opas dfgh jklz xcvb nmqw erty uiop",
                index: 2,
                last_in_para: true,
                persistent_id: "1000003",
                record_id: "123123125",
                repetitions: {},
                subtitle_count: 1,
              },
            ]
          }
          let(:default_subtitle_attrs_to){
            [
              {
                content: "Abcd Efgh Ijkl Mnop Qrst Vwxy Z123 A456 B789 ",
                content_sim: "abcd efgh ijkl mnop qrst vwxy z123 a456 b789",
                first_in_para: true,
                index: 0,
                repetitions: {},
                subtitle_count: 1,
              }, {
                content: "C012 D345 Qwer Tyui Opas Dfgh Jklz Xcvb Nmqw Erty Uiop ",
                content_sim: "c012 d345 qwer tyui opas dfgh jklz xcvb nmqw erty uiop",
                index: 1,
                repetitions: {},
                subtitle_count: 1,
              }, {
                content: "Uiop Asdf Mnbv Cxzl",
                content_sim: "uiop asdf mnbv cxzl",
                index: 2,
                last_in_para: true,
                repetitions: {},
                subtitle_count: 1,
              },
            ]
          }
          let(:default_aligned_subtitle_pairs){
            [
              {
                from: {
                  content: "Abcd Efgh Ijkl Mnop Qrst ",
                  content_sim: "abcd efgh ijkl mnop qrst",
                  first_in_para: true,
                  index: 0,
                  repetitions: {},
                  persistent_id: "1000001",
                  record_id: "123123123",
                  subtitle_count: 1,
                },
                to: {
                  content: "Abcd Efgh Ijkl Mnop Qrst Vwxy Z123 A456 B789 ",
                  content_sim: "abcd efgh ijkl mnop qrst vwxy z123 a456 b789",
                  first_in_para: true,
                  index: 0,
                  repetitions: {},
                  subtitle_count: 1,
                },
              }, {
                from: {
                  content: "Vwxy Z123 A456 B789 C012 ",
                  content_sim: "vwxy z123 a456 b789 c012",
                  index: 1,
                  repetitions: {},
                  persistent_id: "1000002",
                  record_id: "123123124",
                  subtitle_count: 1,
                },
                to: {
                  content: "",
                  content_sim: "",
                  index: 0,
                  repetitions: {},
                  subtitle_count: 0,
                },
              }, {
                from: {
                  content: "D345 Qwer Tyui Opas Dfgh Jklz Xcvb Nmqw Erty Uiop",
                  content_sim: "d345 qwer tyui opas dfgh jklz xcvb nmqw erty uiop",
                  index: 2,
                  last_in_para: true,
                  repetitions: {},
                  persistent_id: "1000003",
                  record_id: "123123125",
                  subtitle_count: 1,
                },
                to: {
                  content: "C012 D345 Qwer Tyui Opas Dfgh Jklz Xcvb Nmqw Erty Uiop ",
                  content_sim: "c012 d345 qwer tyui opas dfgh jklz xcvb nmqw erty uiop",
                  index: 1,
                  repetitions: {},
                  subtitle_count: 1,
                },
              }, {
                from: {
                  content: "",
                  content_sim: "",
                  index: 2,
                  repetitions: {},
                  subtitle_count: 0,
                },
                to: {
                  content: "Uiop Asdf Mnbv Cxzl",
                  content_sim: "uiop asdf mnbv cxzl",
                  index: 2,
                  last_in_para: true,
                  repetitions: {},
                  subtitle_count: 1,
                },
              }
            ]
          }
          let(:default_enriched_subtitle_pairs){
            enriched_attrs = [
              {
                :content_length_change=>20,
                :first_in_para=>true,
                :index=>1,
                :last_in_para=>nil,
                :sim_abs=>[0.5454545454545454, 1.0],
                :sim_left=>[1.0, 1.0],
                :sim_right=>[0.16666666666666666, 1.0],
                :subtitle_count_change=>0,
                :subtitle_object => ::Repositext::Subtitle.new(persistent_id: "1000001", tmp_attrs: {:before=>"Abcd Efgh Ijkl Mnop Qrst ", :after=>"Abcd Efgh Ijkl Mnop Qrst Vwxy Z123 A456 B789 "}),
                :type=>:left_aligned,
              },
              {
                :content_length_change=>-24,
                :first_in_para=>nil,
                :index=>2,
                :last_in_para=>nil,
                :sim_abs=>[0.0, 0.0],
                :sim_left=>[0.0, 0.0],
                :sim_right=>[0.0, 0.0],
                :subtitle_count_change=>-1,
                :subtitle_object => ::Repositext::Subtitle.new(persistent_id: "1000002", tmp_attrs: {:before=>"Vwxy Z123 A456 B789 C012 ", :after=>""}),
                :type=>:st_removed,
              },
              {
                :content_length_change=>5,
                :first_in_para=>nil,
                :index=>3,
                :last_in_para=>nil,
                :sim_abs=>[0.9074074074074074, 1.0],
                :sim_left=>[0.8333333333333334, 1.0],
                :sim_right=>[1.0, 1.0],
                :subtitle_count_change=>0,
                :subtitle_object => ::Repositext::Subtitle.new(persistent_id: "1000003", tmp_attrs: {:before=>"D345 Qwer Tyui Opas Dfgh Jklz Xcvb Nmqw Erty Uiop", :after=>"C012 D345 Qwer Tyui Opas Dfgh Jklz Xcvb Nmqw Erty Uiop "}),
                :type=>:right_aligned,
              },
              {
                :content_length_change=>19,
                :first_in_para=>nil,
                :index=>4,
                :last_in_para=>true,
                :sim_abs=>[0.0, 0.0],
                :sim_left=>[0.0, 0.0],
                :sim_right=>[0.0, 0.0],
                :subtitle_count_change=>1,
                :subtitle_object =>  ::Repositext::Subtitle.new(persistent_id: "tmp-1000003+1", tmp_attrs: {:before=>"", :after=>"Uiop Asdf Mnbv Cxzl"}),
                :type=>:st_added,
              },
            ]
            r = []
            default_aligned_subtitle_pairs.each_with_index {|asp, idx|
              r << asp.merge(enriched_attrs[idx])
            }
            r
          }

          describe '#compute_aligned_subtitle_pairs' do
            it "Handles default data" do
              default_computer.send(
                :compute_aligned_subtitle_pairs,
                default_subtitle_attrs_from,
                default_subtitle_attrs_to
              ).must_equal(default_aligned_subtitle_pairs)
            end
          end

          describe '#enrich_aligned_subtitle_pair_attributes' do
            it "Handles default data" do
              default_computer.send(
                :enrich_aligned_subtitle_pair_attributes,
                default_aligned_subtitle_pairs
              ).must_equal(default_enriched_subtitle_pairs)
            end
          end

          describe '#compute_subtitle_count_change' do
            it "Handles default data" do
              default_enriched_subtitle_pairs.each { |esp|
                default_computer.send(
                  :compute_subtitle_count_change,
                  esp
                ).must_equal(esp[:subtitle_count_change])
              }
            end
          end

          describe '#compute_subtitle_pair_type' do
            it "Handles default data" do
              default_enriched_subtitle_pairs.each { |esp|
                default_computer.send(
                  :compute_subtitle_pair_type,
                  esp
                ).must_equal(esp[:type])
              }
            end
          end
        end
      end
    end
  end
end
