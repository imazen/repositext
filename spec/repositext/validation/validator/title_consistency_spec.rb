require_relative '../../../helper'
require_relative 'shared_spec_behaviors'

class Repositext
  class Validation
    class Validator

      describe TitleConsistency do

        include SharedSpecBehaviors

        let(:product_identity_id) { 1234 }
        let(:product_id) { '16-0403' }

        let(:primary_repo_path) { Repository::Test.create!('rt-english').first }
        let(:primary_content_type) {
          ContentType.new(File.join(primary_repo_path, 'ct-general'))
        }
        let(:primary_language) { Language::English.new }
        let(:primary_filename) { "/content/16/eng#{ product_id }_#{ product_identity_id }.at" }
        let(:primary_file_contents) {
          [
            "^^^ {: .rid #rid-1234}",
            "",
            "# *Header level one*{: .italic .smcaps} *.*{: .line_break}*new line*{: .italic .smcaps}",
            "",
            "^^^ {: .rid #rid-1235}",
            "",
            " Word word word.",
            "{: .first_par .normal}",
            "",
            "Word word.",
            "{: .normal}",
            "",
            "*Header level one*{: .italic .smcaps} *.*{: .line_break}*new line*{: .italic .smcaps}",
            "{: .id_title1}",
            "",
            product_id,
            "{: .id_title2}",
            "",
            "Word word.",
            "{: .id_paragraph}",
          ].join("\n")
        }
        let(:primary_content_at_file){
          RFile::ContentAt.new(
            primary_file_contents,
            primary_language,
            primary_filename,
            primary_content_type
          )
        }
        let(:primary_erp_data) {
          [
            {
              "productidentityid" => product_identity_id,
              "productid" => product_id,
              "foreigntitle" => "Header level one new line",
              "languageid" => "ENG",
              "englishtitle" => "Header level one new line"
            },
          ]
        }
        let(:primary_val_attrs_stub) {
          {
            exceptions: [],
            has_erp_data: true,
            has_id_titles: true,
            is_primary: true,
            raw: {
              content: {
                header_1_kd: nil,
                header_2_kd: nil,
                header_1_pt: nil,
                header_2_pt: nil,
              },
              erp: {
                date_code: nil,
                language_code: nil,
                primary_title: nil,
                title: nil,
              },
              filename: {
                date_code: nil,
                language_code: nil,
              },
              id: {
                id_title1: nil,
                id_title2: nil,
              },
            },
            prepared: {
              content: {},
              erp: {},
              filename: {},
              id: {},
            },
          }
        }
        let(:primary_val_attrs){
          {
            exceptions: [],
            has_erp_data: true,
            has_id_titles: true,
            is_primary: true,
            raw: {
              content: {
                header_1_kd: "*Header level one*{: .italic .smcaps} *.*{: .line_break}*new line*{: .italic .smcaps}",
                header_1_pt: "Header level one \nnew line"
              },
              erp: {
                title: "Header level one new line",
                primary_title: "Header level one new line",
                date_code: "16-0403",
                language_code: "ENG"
              },
              filename: {
                date_code: "16-0403",
                language_code: :eng
              },
              id: {
                id_title1: ["*Header level one*{: .italic .smcaps} *.*{: .line_break}*new line*{: .italic .smcaps}"],
                id_title2: ["16-0403"],
              }
            },
            prepared: {
              content: {
                title_for_erp: "Header level one new line",
                title_for_id: "*Header level one new line*{: .italic .smcaps}"
              },
              erp: {
                title: "Header level one new line",
                primary_title: "Header level one new line",
                date_code: "16-0403",
                language_code: "ENG"
              },
              filename: {
                date_code: "16-0403",
                language_code: "ENG"
              },
              id: {
                title: "*Header level one new line*{: .italic .smcaps}",
                primary_title: "",
                date_code: "16-0403"
              }
            }
          }
        }

        let(:foreign_repo_path) { Repository::Test.create!('rt-spanish').first }
        let(:foreign_content_type) {
          ContentType.new(File.join(foreign_repo_path, 'ct-general'))
        }
        let(:foreign_language) { Language::Spanish.new }
        let(:foreign_filename) { "/content/16/spn#{ product_id }_#{ product_identity_id }.at" }
        let(:foreign_file_contents) {
          [
            "^^^ {: .rid #rid-1234}",
            "",
            "# *Header level uno*{: .italic .smcaps} *.*{: .line_break}*nuevo line*{: .italic .smcaps}",
            "",
            " Palabra palabra palabra.",
            "{: .first_par .normal}",
            "",
            "Palabra palabra.",
            "{: .normal}",
            "",
            "*Header level uno*{: .italic .smcaps} *.*{: .line_break}*nuevo line*{: .italic .smcaps} SPN#{ product_id }",
            "{: .id_title1}",
            "",
            "(Header level one new line)",
            "{: .id_title2}",
            "",
            "Word word.",
            "{: .id_paragraph}",
          ].join("\n")
        }
        let(:foreign_content_at_file){
          RFile::ContentAt.new(
            foreign_file_contents,
            foreign_language,
            foreign_filename,
            foreign_content_type
          )
        }
        let(:foreign_erp_data) {
          [
            {
              "productidentityid" => product_identity_id,
              "productid" => product_id,
              "foreigntitle" => "Header level uno nuevo line",
              "languageid" => "SPN",
              "englishtitle" => "Header level one new line"
            },
          ]
        }
        let(:foreign_val_attrs_stub) {
          r = primary_val_attrs_stub
          r[:is_primary] = false
          r
        }
        let(:foreign_val_attrs){
          {
            exceptions: [],
            has_erp_data: true,
            has_id_titles: true,
            is_primary: false,
            raw: {
              content: {
                header_1_kd: "*Header level uno*{: .italic .smcaps} *.*{: .line_break}*nuevo line*{: .italic .smcaps}",
                header_1_pt: "Header level uno \nnuevo line"
              },
              erp: {
                title: "Header level uno nuevo line",
                primary_title: "Header level one new line",
                date_code: "16-0403",
                language_code: "SPN"
              },
              filename: {
                date_code: "16-0403",
                language_code: :spn
              },
              id: {
                id_title1: ["*Header level uno*{: .italic .smcaps} *.*{: .line_break}*nuevo line*{: .italic .smcaps} SPN#{ product_id }"],
                id_title2: ["(Header level one new line)"],
              }
            },
            prepared: {
              content: {
                title_for_erp: "Header level uno nuevo line",
                title_for_id: "*Header level uno nuevo line*{: .italic .smcaps}"
              },
              erp: {
                title: "Header level uno nuevo line",
                primary_title: "Header level one new line",
                date_code: "16-0403",
                language_code: "SPN"
              },
              filename: {
                date_code: "16-0403",
                language_code: "SPN"
              },
              id: {
                title: "*Header level uno nuevo line*{: .italic .smcaps}",
                primary_title: "Header level one new line",
                date_code: "16-0403",
                language_code: "SPN",
              }
            }
          }
        }

        describe '#run' do

          it 'reports no errors for consistent primary titles' do
            validator, _logger, reporter = build_validator_logger_and_reporter(
              TitleConsistency,
              primary_content_at_file,
              nil,
              nil,
              {
                "erp_data" => primary_erp_data,
                "validator_exceptions" => [],
              }
            )
            validator.run
            reporter.errors.must_be(:empty?)
          end

          it 'reports errors for inconsistent primary titles' do
            validator, _logger, reporter = build_validator_logger_and_reporter(
              TitleConsistency,
              RFile::ContentAt.new(
                primary_file_contents.gsub("Header level one", "Different header level one"),
                primary_language,
                primary_filename,
                primary_content_type
              ),
              nil,
              nil,
              {
                "erp_data" => primary_erp_data,
                "validator_exceptions" => []
              }
            )
            validator.run
            reporter.errors.wont_be(:empty?)
          end

          it 'reports no errors for consistent foreign titles' do
            validator, _logger, reporter = build_validator_logger_and_reporter(
              TitleConsistency,
              foreign_content_at_file,
              nil,
              nil,
              {
                "erp_data" => foreign_erp_data,
                "validator_exceptions" => [],
              }
            )
            validator.run
            reporter.errors.must_be(:empty?)
          end

          it 'reports errors for inconsistent foreign titles' do
            validator, _logger, reporter = build_validator_logger_and_reporter(
              TitleConsistency,
              RFile::ContentAt.new(
                foreign_file_contents.gsub("Header level one", "Different header level one"),
                foreign_language,
                foreign_filename,
                foreign_content_type
              ),
              nil,
              nil,
              {
                "erp_data" => foreign_erp_data,
                "validator_exceptions" => []
              }
            )
            validator.run
            reporter.errors.wont_be(:empty?)
          end

        end

        describe '#titles_consistent?' do
          it 'reports invalid validator_exceptions as errors' do
            validator, _logger, reporter = build_validator_logger_and_reporter(
              TitleConsistency,
              primary_content_at_file,
              nil,
              nil,
              {
                "erp_data" => primary_erp_data,
                "validator_exceptions" => ['invalid_exception']
              }
            )
            validator.run
            reporter.errors[0].details[0].must_equal('Invalid validator_exceptions')
          end
        end

        describe '#extract_raw_attrs!' do
          it 'extracts raw attrs from primary content' do
            validator, _logger, _reporter = build_validator_logger_and_reporter(
              TitleConsistency,
              primary_content_at_file
            )
            val_attrs = primary_val_attrs_stub
            validator.send(
              :extract_raw_attrs_content!,
              primary_content_at_file,
              val_attrs
            )
            val_attrs[:raw][:content].must_equal(primary_val_attrs[:raw][:content])
          end

          it 'extracts raw attrs from primary erp' do
            validator, _logger, _reporter = build_validator_logger_and_reporter(
              TitleConsistency,
              primary_content_at_file
            )
            val_attrs = primary_val_attrs_stub
            validator.send(
              :extract_raw_attrs_erp!,
              primary_content_at_file,
              val_attrs,
              primary_erp_data
            )
            val_attrs[:raw][:erp].must_equal(primary_val_attrs[:raw][:erp])
          end

          it 'extracts raw attrs from primary filename' do
            validator, _logger, _reporter = build_validator_logger_and_reporter(
              TitleConsistency,
              primary_content_at_file
            )
            val_attrs = primary_val_attrs_stub
            validator.send(
              :extract_raw_attrs_filename!,
              primary_content_at_file,
              val_attrs
            )
            val_attrs[:raw][:filename].must_equal(primary_val_attrs[:raw][:filename])
          end

          it 'extracts raw attrs from primary id' do
            validator, _logger, _reporter = build_validator_logger_and_reporter(
              TitleConsistency,
              primary_content_at_file
            )
            val_attrs = primary_val_attrs_stub
            validator.send(
              :extract_raw_attrs_id!,
              primary_content_at_file,
              val_attrs
            )
            val_attrs[:raw][:id].must_equal(primary_val_attrs[:raw][:id])
          end

          it 'extracts raw attrs from foreign content' do
            validator, _logger, _reporter = build_validator_logger_and_reporter(
              TitleConsistency,
              foreign_content_at_file
            )
            val_attrs = foreign_val_attrs_stub
            validator.send(
              :extract_raw_attrs_content!,
              foreign_content_at_file,
              val_attrs
            )
            val_attrs[:raw][:content].must_equal(foreign_val_attrs[:raw][:content])
          end

          it 'extracts raw attrs from foreign erp' do
            validator, _logger, _reporter = build_validator_logger_and_reporter(
              TitleConsistency,
              foreign_content_at_file
            )
            val_attrs = foreign_val_attrs_stub
            validator.send(
              :extract_raw_attrs_erp!,
              foreign_content_at_file,
              val_attrs,
              foreign_erp_data
            )
            val_attrs[:raw][:erp].must_equal(foreign_val_attrs[:raw][:erp])
          end

          it 'extracts raw attrs from foreign filename' do
            validator, _logger, _reporter = build_validator_logger_and_reporter(
              TitleConsistency,
              foreign_content_at_file
            )
            val_attrs = foreign_val_attrs_stub
            validator.send(
              :extract_raw_attrs_filename!,
              foreign_content_at_file,
              val_attrs
            )
            val_attrs[:raw][:filename].must_equal(foreign_val_attrs[:raw][:filename])
          end

          it 'extracts raw attrs from foreign id' do
            validator, _logger, _reporter = build_validator_logger_and_reporter(
              TitleConsistency,
              foreign_content_at_file
            )
            val_attrs = foreign_val_attrs_stub
            validator.send(
              :extract_raw_attrs_id!,
              foreign_content_at_file,
              val_attrs
            )
            val_attrs[:raw][:id].must_equal(foreign_val_attrs[:raw][:id])
          end
        end

        describe '#prepare_validation_attrs!' do
          it 'prepares validation attrs from primary content' do
            validator, _logger, _reporter = build_validator_logger_and_reporter(
              TitleConsistency,
              primary_content_at_file
            )
            val_attrs = primary_val_attrs_stub
            # To populate raw attrs
            validator.send(
              :extract_raw_attrs!,
              primary_content_at_file,
              val_attrs,
              primary_erp_data
            )
            validator.send(
              :prepare_validation_attrs_content!,
              primary_content_at_file,
              val_attrs
            )
            val_attrs[:prepared][:content].must_equal(primary_val_attrs[:prepared][:content])
          end

          it 'prepares validation attrs from primary erp' do
            validator, _logger, _reporter = build_validator_logger_and_reporter(
              TitleConsistency,
              primary_content_at_file
            )
            val_attrs = primary_val_attrs_stub
            # To populate raw attrs
            validator.send(
              :extract_raw_attrs!,
              primary_content_at_file,
              val_attrs,
              primary_erp_data
            )
            validator.send(
              :prepare_validation_attrs_erp!,
              primary_content_at_file,
              val_attrs
            )
            val_attrs[:prepared][:erp].must_equal(primary_val_attrs[:prepared][:erp])
          end

          it 'prepares validation attrs from primary filename' do
            validator, _logger, _reporter = build_validator_logger_and_reporter(
              TitleConsistency,
              primary_content_at_file
            )
            val_attrs = primary_val_attrs_stub
            # To populate raw attrs
            validator.send(
              :extract_raw_attrs!,
              primary_content_at_file,
              val_attrs,
              primary_erp_data
            )
            validator.send(
              :prepare_validation_attrs_filename!,
              primary_content_at_file,
              val_attrs
            )
            val_attrs[:prepared][:filename].must_equal(primary_val_attrs[:prepared][:filename])
          end

          it 'prepares validation attrs from primary id' do
            validator, _logger, _reporter = build_validator_logger_and_reporter(
              TitleConsistency,
              primary_content_at_file
            )
            val_attrs = primary_val_attrs_stub
            # To populate raw attrs
            validator.send(
              :extract_raw_attrs!,
              primary_content_at_file,
              val_attrs,
              primary_erp_data
            )
            validator.send(
              :prepare_validation_attrs_id!,
              primary_content_at_file,
              val_attrs
            )
            val_attrs[:prepared][:id].must_equal(primary_val_attrs[:prepared][:id])
          end

          it 'prepares validation attrs from foreign content' do
            validator, _logger, _reporter = build_validator_logger_and_reporter(
              TitleConsistency,
              foreign_content_at_file
            )
            val_attrs = foreign_val_attrs_stub
            # To populate raw attrs
            validator.send(
              :extract_raw_attrs!,
              foreign_content_at_file,
              val_attrs,
              foreign_erp_data
            )
            validator.send(
              :prepare_validation_attrs_content!,
              foreign_content_at_file,
              val_attrs
            )
            val_attrs[:prepared][:content].must_equal(foreign_val_attrs[:prepared][:content])
          end

          it 'prepares validation attrs from foreign erp' do
            validator, _logger, _reporter = build_validator_logger_and_reporter(
              TitleConsistency,
              foreign_content_at_file
            )
            val_attrs = foreign_val_attrs_stub
            # To populate raw attrs
            validator.send(
              :extract_raw_attrs!,
              foreign_content_at_file,
              val_attrs,
              foreign_erp_data
            )
            validator.send(
              :prepare_validation_attrs_erp!,
              foreign_content_at_file,
              val_attrs
            )
            val_attrs[:prepared][:erp].must_equal(foreign_val_attrs[:prepared][:erp])
          end

          it 'prepares validation attrs from foreign filename' do
            validator, _logger, _reporter = build_validator_logger_and_reporter(
              TitleConsistency,
              foreign_content_at_file
            )
            val_attrs = foreign_val_attrs_stub
            # To populate raw attrs
            validator.send(
              :extract_raw_attrs!,
              foreign_content_at_file,
              val_attrs,
              foreign_erp_data
            )
            validator.send(
              :prepare_validation_attrs_filename!,
              foreign_content_at_file,
              val_attrs
            )
            val_attrs[:prepared][:filename].must_equal(foreign_val_attrs[:prepared][:filename])
          end

          it 'prepares validation attrs from foreign id' do
            validator, _logger, _reporter = build_validator_logger_and_reporter(
              TitleConsistency,
              foreign_content_at_file
            )
            val_attrs = foreign_val_attrs_stub
            # To populate raw attrs
            validator.send(
              :extract_raw_attrs!,
              foreign_content_at_file,
              val_attrs,
              foreign_erp_data
            )
            validator.send(
              :prepare_validation_attrs_id!,
              foreign_content_at_file,
              val_attrs
            )
            val_attrs[:prepared][:id].must_equal(foreign_val_attrs[:prepared][:id])
          end
        end

        describe '#apply_exceptions_content' do
          [
            [
              [],
              {
                title_for_erp: "Title for erp",
                title_for_id: "Title for id",
              },
              {
                title_for_erp: "Title for erp",
                title_for_id: "Title for id",
              },
            ],
            [
              ['ignore_short_word_capitalization'],
              {
                title_for_erp: "Word AND IN OF ON THE",
                title_for_id: "Word AND IN OF ON THE",
              },
              {
                title_for_erp: "Word and in of on the",
                title_for_id: "Word and in of on the",
              },
            ],
            [
              ['remove_trailing_digits_content'],
              {
                title_for_erp: "Word 1",
                title_for_id: "Word 1",
              },
              {
                title_for_erp: "Word",
                title_for_id: "Word",
              },
            ],
          ].each do |exceptions, attrs, xpect|
            it "applies #{ exceptions.inspect } to #{ attrs.inspect } (primary)" do
              validator, _logger, _reporter = build_validator_logger_and_reporter(
                TitleConsistency,
                primary_content_at_file
              )
              validator.send(
                :apply_exceptions_content,
                attrs,
                exceptions,
                primary_content_at_file.language
              ).must_equal(xpect)
            end
          end
        end

        describe '#apply_exceptions_erp' do
          [
            [
              [],
              {
                title: "Title",
                primary_title: "Primary title",
              },
              {
                title: "Title",
                primary_title: "Primary title",
              },
            ],
            [
              ['ignore_end_diff_starting_at_pound_sign_erp'],
              {
                title: "Title #this will disappear",
                primary_title: "Primary title #this will disappear",
              },
              {
                title: "Title",
                primary_title: "Primary title",
              },
            ],
            [
              ['ignore_short_word_capitalization'],
              {
                title: "Word AND IN OF ON THE",
                primary_title: "Word AND IN OF ON THE",
              },
              {
                title: "Word and in of on the",
                primary_title: "Word and in of on the",
              },
            ],
            [
              ['remove_pound_sign_and_digits_erp'],
              {
                title: "Title #1",
                primary_title: "Primary title #1",
              },
              {
                title: "Title",
                primary_title: "Primary title",
              },
            ],
            [
              ['remove_pound_sign_erp'],
              {
                title: "Title #1",
                primary_title: "Primary title #1",
              },
              {
                title: "Title 1",
                primary_title: "Primary title 1",
              },
            ],
          ].each do |exceptions, attrs, xpect|
            it "applies #{ exceptions.inspect } to #{ attrs.inspect } (primary)" do
              validator, _logger, _reporter = build_validator_logger_and_reporter(
                TitleConsistency,
                primary_content_at_file
              )
              validator.send(
                :apply_exceptions_erp,
                attrs,
                exceptions,
                primary_content_at_file.language
              ).must_equal(xpect)
            end
          end
        end

        describe '#apply_exceptions_erp' do
          [
            [
              [],
              {
                title: "Title",
                primary_title: "Primary title",
              },
              {
                title: "Title",
                primary_title: "Primary title",
              },
            ],
            [
              ['ignore_short_word_capitalization'],
              {
                title: "Word AND IN OF ON THE",
                primary_title: "Word AND IN OF ON THE",
              },
              {
                title: "Word and in of on the",
                primary_title: "Word and in of on the",
              },
            ],
          ].each do |exceptions, attrs, xpect|
            it "applies #{ exceptions.inspect } to #{ attrs.inspect } (primary)" do
              validator, _logger, _reporter = build_validator_logger_and_reporter(
                TitleConsistency,
                primary_content_at_file
              )
              validator.send(
                :apply_exceptions_erp,
                attrs,
                exceptions,
                primary_content_at_file.language
              ).must_equal(xpect)
            end
          end
        end

        describe '#compare_erp_with_content' do
          [
            [
              "Adds warning if no ERP data present",
              {
                has_erp_data: false,
                exceptions: [],
                prepared: {
                  content: { title_for_erp: "Title ERP" },
                  erp: { title: "Title ERP" },
                },
              },
              {
                errors: [],
                warnings: ['No ERP data present'],
              }
            ],
            [
              "Reports error if :content/:title_for_erp is missing",
              {
                has_erp_data: true,
                exceptions: [],
                prepared: {
                  content: { title_for_erp: nil },
                  erp: { title: "Title ERP" },
                },
              },
              {
                errors: [
                  'Title from content is missing',
                  'ERP title is different from content title',
                ],
                warnings: [],
              }
            ],
            [
              "Reports error if :erp/:title is missing",
              {
                has_erp_data: true,
                exceptions: [],
                prepared: {
                  content: { title_for_erp: "Title ERP" },
                  erp: { title: nil },
                },
              },
              {
                errors: [
                  'Title from ERP is missing',
                ],
                warnings: [],
              }
            ],
            [
              "Reports error if titles are different",
              {
                has_erp_data: true,
                exceptions: [],
                prepared: {
                  content: { title_for_erp: "Title ERP" },
                  erp: { title: "Title ERP diff" },
                },
              },
              {
                errors: [
                  'ERP title is different from content title',
                ],
                warnings: [],
              }
            ],
            [
              "Accepts title containment for ignore_end_diff_starting_at_pound_sign_erp",
              {
                has_erp_data: true,
                exceptions: ['ignore_end_diff_starting_at_pound_sign_erp'],
                prepared: {
                  content: { title_for_erp: "Title ERP with extra text" },
                  erp: { title: "Title ERP" },
                },
              },
              {
                errors: [],
                warnings: [],
              }
            ],
          ].each do |description, val_attrs, xpect|
            it description do
              validator, _logger, _reporter = build_validator_logger_and_reporter(
                TitleConsistency,
                primary_content_at_file
              )
              errors = []
              warnings = []
              validator.send(
                :compare_erp_with_content,
                primary_content_at_file,
                val_attrs,
                errors,
                warnings
              )
              errors.map { |e| e.details[0] }.must_equal(xpect[:errors])
              warnings.map { |e| e.details[0] }.must_equal(xpect[:warnings])
            end
          end
        end

        describe '#compare_erp_with_filename' do
          [
            [
              "Reports error if :filename/:datecode is missing",
              {
                has_erp_data: true,
                exceptions: [],
                prepared: {
                  filename: {
                    date_code: nil,
                    language_code: 'ENG',
                  },
                  erp: {
                    date_code: "16-0403",
                    language_code: 'ENG',
                  },
                },
              },
              {
                errors: [
                  'Date code from filename is missing',
                  "ERP datecode is different from filename datecode"
                ],
                warnings: [],
              }
            ],
            [
              "Reports error if :erp/:date_code is missing",
              {
                has_erp_data: true,
                exceptions: [],
                prepared: {
                  filename: {
                    date_code: "16-0403",
                    language_code: 'ENG',
                  },
                  erp: {
                    date_code: nil,
                    language_code: 'ENG'
                  },
                },
              },
              {
                errors: [
                  'Date code from ERP is missing',
                ],
                warnings: [],
              }
            ],
            [
              "Reports error if date codes are different",
              {
                has_erp_data: true,
                exceptions: [],
                prepared: {
                  filename: {
                    date_code: "16-0403",
                    language_code: 'ENG',
                  },
                  erp: {
                    date_code: "17-0403",
                    language_code: 'ENG',
                  },
                },
              },
              {
                errors: [
                  "ERP datecode is different from filename datecode",
                ],
                warnings: [],
              }
            ],
            [
              "Reports error if language code from filename is missing",
              {
                has_erp_data: true,
                exceptions: [],
                prepared: {
                  filename: {
                    date_code: "16-0403",
                    language_code: nil,
                  },
                  erp: {
                    date_code: "16-0403",
                    language_code: 'ENG',
                  },
                },
              },
              {
                errors: [
                  "Language code from filename is missing",
                  "ERP language code is different from filename language code",
                ],
                warnings: [],
              }
            ],
            [
              "Reports error if language code from erp is missing",
              {
                has_erp_data: true,
                exceptions: [],
                prepared: {
                  filename: {
                    date_code: "16-0403",
                    language_code: 'ENG',
                  },
                  erp: {
                    date_code: "16-0403",
                    language_code: nil,
                  },
                },
              },
              {
                errors: [
                  "Language code from ERP is missing",
                ],
                warnings: [],
              }
            ],
            [
              "Reports error if language codes are different",
              {
                has_erp_data: true,
                exceptions: [],
                prepared: {
                  filename: {
                    date_code: "16-0403",
                    language_code: 'ENG',
                  },
                  erp: {
                    date_code: "16-0403",
                    language_code: 'SPN',
                  },
                },
              },
              {
                errors: [
                  "ERP language code is different from filename language code",
                ],
                warnings: [],
              }
            ],
          ].each do |description, val_attrs, xpect|
            it description do
              validator, _logger, _reporter = build_validator_logger_and_reporter(
                TitleConsistency,
                primary_content_at_file
              )
              errors = []
              warnings = []
              validator.send(
                :compare_erp_with_filename,
                primary_content_at_file,
                val_attrs,
                errors,
                warnings
              )
              errors.map { |e| e.details[0] }.must_equal(xpect[:errors])
              warnings.map { |e| e.details[0] }.must_equal(xpect[:warnings])
            end
          end
        end

        describe '#compare_id_with_content' do
          [
            [
              "Reports error if title from id is missing",
              {
                has_id_titles: true,
                exceptions: [],
                prepared: {
                  content: { title_for_id: 'Title ID' },
                  id: { title: nil },
                },
              },
              {
                errors: [
                  'Title from id is missing',
                ],
                warnings: [],
              }
            ],
            [
              "Reports error if titles are different",
              {
                has_id_titles: true,
                exceptions: [],
                prepared: {
                  content: { title_for_id: "Title ID" },
                  id: { title: "Title ID diff" },
                },
              },
              {
                errors: [
                  'ID title is different from content title',
                ],
                warnings: [],
              }
            ],
          ].each do |description, val_attrs, xpect|
            it description do
              validator, _logger, _reporter = build_validator_logger_and_reporter(
                TitleConsistency,
                primary_content_at_file
              )
              errors = []
              warnings = []
              validator.send(
                :compare_id_with_content,
                primary_content_at_file,
                val_attrs,
                errors,
                warnings
              )
              errors.map { |e| e.details[0] }.must_equal(xpect[:errors])
              warnings.map { |e| e.details[0] }.must_equal(xpect[:warnings])
            end
          end
        end

        describe '#compare_id_with_erp' do
          [
            [
              "Reports error on foreign if primary_title from id is missing",
              {
                has_erp_data: true,
                has_id_titles: true,
                is_primary: false,
                exceptions: [],
                prepared: {
                  erp: { primary_title: "Primary title" },
                  id: { primary_title: nil },
                },
              },
              {
                errors: [
                  'Primary title from ID is missing',
                  "ERP primary title is different from ID primary title",
                ],
                warnings: [],
              }
            ],
            [
              "Reports error on foreign if primary_title from erp is missing",
              {
                has_erp_data: true,
                has_id_titles: true,
                is_primary: false,
                exceptions: [],
                prepared: {
                  erp: { primary_title: nil },
                  id: { primary_title: "Primary title" },
                },
              },
              {
                errors: [
                  'Primary title from ERP is missing',
                ],
                warnings: [],
              }
            ],
          ].each do |description, val_attrs, xpect|
            it description do
              validator, _logger, _reporter = build_validator_logger_and_reporter(
                TitleConsistency,
                primary_content_at_file
              )
              errors = []
              warnings = []
              validator.send(
                :compare_id_with_erp,
                primary_content_at_file,
                val_attrs,
                errors,
                warnings
              )
              errors.map { |e| e.details[0] }.must_equal(xpect[:errors])
              warnings.map { |e| e.details[0] }.must_equal(xpect[:warnings])
            end
          end
        end

        describe '#compare_id_with_filename' do
          [
            [
              "Reports error if date code from id is missing",
              {
                has_id_titles: true,
                is_primary: true,
                exceptions: [],
                prepared: {
                  filename: {
                    date_code: '16-0403',
                    language_code: 'ENG'
                  },
                  id: {
                    date_code: nil,
                    language_code: 'ENG'
                  },
                },
              },
              {
                errors: [
                  "Date code from ID is missing",
                ],
                warnings: [],
              }
            ],
            [
              "Reports error if date codes from filename and id are different",
              {
                has_id_titles: true,
                is_primary: true,
                exceptions: [],
                prepared: {
                  filename: {
                    date_code: '16-0403',
                    language_code: 'ENG'
                  },
                  id: {
                    date_code: '17-0403',
                    language_code: 'ENG'
                  },
                },
              },
              {
                errors: [
                  'ID datecode is different from filename datecode',
                ],
                warnings: [],
              }
            ],
            [
              "Reports error if language code from id is missing (foreign only)",
              {
                has_id_titles: true,
                is_primary: false,
                exceptions: [],
                prepared: {
                  filename: {
                    date_code: '16-0403',
                    language_code: 'ENG'
                  },
                  id: {
                    date_code: '16-0403',
                    language_code: nil,
                  },
                },
              },
              {
                errors: [
                  "Language code from ID is missing",
                ],
                warnings: [],
              }
            ],
            [
              "Reports error if language codes from id and filename are different (foreign only)",
              {
                has_id_titles: true,
                is_primary: false,
                exceptions: [],
                prepared: {
                  filename: {
                    date_code: '16-0403',
                    language_code: 'ENG'
                  },
                  id: {
                    date_code: '16-0403',
                    language_code: 'SPN',
                  },
                },
              },
              {
                errors: [
                  "ID language code is different from filename language code",
                ],
                warnings: [],
              }
            ],
          ].each do |description, val_attrs, xpect|
            it description do
              validator, _logger, _reporter = build_validator_logger_and_reporter(
                TitleConsistency,
                primary_content_at_file
              )
              errors = []
              warnings = []
              validator.send(
                :compare_id_with_filename,
                primary_content_at_file,
                val_attrs,
                errors,
                warnings
              )
              errors.map { |e| e.details[0] }.must_equal(xpect[:errors])
              warnings.map { |e| e.details[0] }.must_equal(xpect[:warnings])
            end
          end
        end

      end
    end
  end
end
