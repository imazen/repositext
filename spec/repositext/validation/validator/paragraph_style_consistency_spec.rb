require_relative '../../../helper'
require_relative 'shared_spec_behaviors'

class Repositext
  class Validation
    class Validator

      describe ParagraphStyleConsistency do

        include SharedSpecBehaviors

        describe '#run' do

          it 'reports no errors for consistent paragraph styles' do
            validator, logger, reporter = build_validator_logger_and_reporter(
              ParagraphStyleConsistency,
              [
                FileLikeStringIO.new('_path_f', "foreign para\n{: .normal}"),
                FileLikeStringIO.new('_path_p', "primary para\n{: .normal}"),
              ]
            )
            validator.run
            reporter.errors.must_be(:empty?)
          end

          it 'reports errors for inconsistent paragraph styles' do
            validator, logger, reporter = build_validator_logger_and_reporter(
              ParagraphStyleConsistency,
              [
                FileLikeStringIO.new('_path_f', "foreign para\n{: .normal1}\n"),
                FileLikeStringIO.new('_path_p', "primary para\n{: .normal2}\n"),
              ]
            )
            validator.run
            reporter.errors.wont_be(:empty?)
          end

        end

        describe '#paragraph_styles_consistent?' do
          [
            [
              "foreign para\n{: .normal}",
              "foreign para\n{: .normal}",
              true
            ],
            [
              "foreign para\n{: .normal1}",
              "foreign para\n{: .normal2}",
              false
            ],
          ].each do |test_string_f, test_string_p, xpect|
            it "handles #{ test_string_f.inspect }" do
              validator, logger, reporter = build_validator_logger_and_reporter(
                ParagraphStyleConsistency,
                [
                  FileLikeStringIO.new('_path', '_txt'),
                  FileLikeStringIO.new('_path', '_txt'),
                ]
              )
              validator.paragraph_styles_consistent?(
                test_string_f,
                test_string_p
              ).success.must_equal(xpect)
            end
          end
        end

        describe '#extract_paragraph_styles' do
          [
            ["first para with .normal and .decreased word space\n{: .decreased_word_space .first_par .normal}", ['', '.first_par .normal']],
            ["first para with .normal and .increased word space\n{: .first_par .increased_word_space .normal}", ['', '.first_par .normal']],
            ["first para with .normal and .omit\n{: .first_par .normal .omit}", ['', '.first_par .normal']],
            ["first para with .normal, .decreased_word_space and .omit\n{: .decreased_word_space .first_par .normal .omit}", ['', '.first_par .normal']],
            ["first para with .normal, .increased_word_space and .omit\n{: .first_par .increased_word_space .normal .omit}", ['', '.first_par .normal']],
            ["first para with .normal\n{: .first_par .normal}", ['', '.first_par .normal']],
            ["first para with .scr and .decreased word space\n{: .decreased_word_space .first_par .scr}", ['', '.first_par .scr']],
            ["first para with .scr and .increased word space\n{: .first_par .increased_word_space .scr}", ['', '.first_par .scr']],
            ["first para with .scr\n{: .first_par .scr}", ['', '.first_par .scr']],
            ["first para with .stanza and .decreased word space\n{: .decreased_word_space .first_par .stanza}", ['', '.first_par .stanza']],
            ["first para with .stanza and .increased word space\n{: .first_par .increased_word_space .stanza}", ['', '.first_par .stanza']],
            ["first para with .stanza\n{: .first_par .stanza}", ['', '.first_par .stanza']],
            ["id para with .decreased_word_space\n{: .decreased_word_space .id_paragraph}", ['', '.id_paragraph']],
            ["id para with .increased_word_space\n{: .id_paragraph .increased_word_space}", ['', '.id_paragraph']],
            ["id para\n{: .id_paragraph}", ['', '.id_paragraph']],
            ["id title 1 para\n{: .id_title1}", ['', '.id_title1']],
            ["id title 2 para\n{: .id_title2}", ['', '.id_title2']],
            ["id title 3 para\n{: .id_title3}", ['', '']],
            ["normal para with .decreased_word_space and .indent_for_eagle\n{: .decreased_word_space .indent_for_eagle .normal}", ['', '.normal']],
            ["normal para with .decreased_word_space\n{: .decreased_word_space .normal}", ['', '.normal']],
            ["normal para with .increased_word_space and .indent_for_eagle\n{: .increased_word_space .indent_for_eagle .normal}", ['', '.normal']],
            ["normal para with .increased_word_space\n{: .increased_word_space .normal}", ['', '.normal']],
            ["normal para with .indent_for_eagle\n{: .indent_for_eagle .normal}", ['', '.normal']],
            ["normal para with .omit\n{: .normal .omit}", ['', '.normal']],
            ["normal para\n{: .normal}", ['', '.normal']],
            ["normal pn para with .decreased_word_space and .indent_for_eagle\n{: .decreased_word_space .indent_for_eagle .normal_pn}", ['', '.normal_pn']],
            ["normal pn para with .decreased_word_space\n{: .decreased_word_space .normal_pn}", ['', '.normal_pn']],
            ["normal pn para with .increased_word_space and .indent_for_eagle\n{: .increased_word_space .indent_for_eagle .normal_pn}", ['', '.normal_pn']],
            ["normal pn para with .increased_word_space\n{: .increased_word_space .normal_pn}", ['', '.normal_pn']],
            ["normal pn para with .indent_for_eagle\n{: .indent_for_eagle .normal_pn}", ['', '.normal_pn']],
            ["normal pn para with .omit\n{: .normal_pn .omit}", ['', '.normal_pn']],
            ["normal pn para\n{: .normal_pn}", ['', '.normal_pn']],
            ["question para with .decreased_word_space\n{: .decreased_word_space .q}", ['', '.q']],
            ["question para with .increased_word_space\n{: .increased_word_space .q}", ['', '.q']],
            ["question para\n{: .q}", ['', '.q']],
            ["reading para with .decreased_word_space and .reading\n{: .decreased_word_space .reading}", ['', '.reading']],
            ["reading para with .increased_word_space and .reading\n{: .increased_word_space .reading}", ['', '.reading']],
            ["reading para\n{: .reading}", ['', '.reading']],
            ["scripture para with .decreased_word_space\n{: .decreased_word_space .scr}", ['', '.scr']],
            ["scripture para with .increased_word_space\n{: .increased_word_space .scr}", ['', '.scr']],
            ["scripture para\n{: .scr}", ['', '.scr']],
            ["song break para with .decreased_word_space\n{: .decreased_word_space .song_break}", ['', '.song']],
            ["song break para with .increased_word_space\n{: .increased_word_space .song_break}", ['', '.song']],
            ["song break para with .omit first\n{: .omit .song_break}", ['', '.song']],
            ["song para with .decreased_word_space\n{: .decreased_word_space .song}", ['', '.song']],
            ["song para with .increased_word_space\n{: .increased_word_space .song}", ['', '.song']],
            ["song para with .omit first\n{: .omit .song}", ['', '.song']],
            ["song para with .song_break\n{: .song_break}", ['', '.song']],
            ["song para\n{: .song}", ['', '.song']],
            ["stanza para with .decreased_word_space\n{: .decreased_word_space .stanza}", ['', '.stanza']],
            ["stanza para with .increased_word_space\n{: .increased_word_space .stanza}", ['', '.stanza']],
            ["stanza para with .omit first\n{: .omit .stanza}", ['', '.stanza']],
            ["stanza para\n{: .stanza}", ['', '.stanza']],
          ].each do |test_string, xpect|
            it "handles #{ test_string.inspect }" do
              validator, logger, reporter = build_validator_logger_and_reporter(
                ParagraphStyleConsistency,
                [
                  FileLikeStringIO.new('_path', '_txt'),
                  FileLikeStringIO.new('_path', '_txt'),
                ]
              )
              validator.send(
                :extract_paragraph_styles, test_string
              ).must_equal(xpect)
            end
          end
        end

        describe '#compute_paragraph_style_diff' do
          [
            [['{: .normal}'], ['{: .normal}'], true, []],
            [['{: .normal1}'], ['{: .normal2}'], true, [:different_style_in_foreign]],
            [['', ''], ['', '{: .normal}', ''], true, [:missing_style_in_foreign]],
            [['', '{: .normal}', ''], ['', ''], true, [:extra_style_in_foreign]],
            [['{: .normal}'], ['{: .normal_pn}'], true, [:different_style_in_foreign]],
            [['{: .normal}'], ['{: .normal_pn}'], false, []],
          ].each do |test_styles_f, test_styles_p, distinguish_between_normal_and_normal_pn, xpect|
            it "handles #{ test_styles_f.inspect }" do
              validator, logger, reporter = build_validator_logger_and_reporter(
                ParagraphStyleConsistency,
                [
                  FileLikeStringIO.new('_path', '_txt'),
                  FileLikeStringIO.new('_path', '_txt'),
                ]
              )
              validator.distinguish_between_normal_and_normal_pn = distinguish_between_normal_and_normal_pn
              validator.send(
                :compute_paragraph_style_diff, test_styles_f, test_styles_p
              ).map { |e| e[:type] }.must_equal(xpect)
            end
          end
        end

        describe '#foreign_has_paragraph_numbers?' do
          [
            ["1 para 1\n\n2 para 2", true],
            ["para 1\n\npara 2", false],
            ["1 para 1\n\n2 para 2\n\npara 3", true],
            ["1 para 1\n\npara 2\n\npara 3", true],
            ["1 para 1\n\npara 2\n\npara 3\n\npara 4", false],
          ].each do |foreign_test_doc, xpect|
            it "handles #{ foreign_test_doc.inspect }" do
              validator, logger, reporter = build_validator_logger_and_reporter(
                ParagraphStyleConsistency,
                [
                  FileLikeStringIO.new('_path', '_txt'),
                  FileLikeStringIO.new('_path', '_txt'),
                ]
              )
              validator.send(
                :foreign_has_paragraph_numbers?, foreign_test_doc
              ).must_equal(xpect)
            end
          end
        end

      end

    end
  end
end
