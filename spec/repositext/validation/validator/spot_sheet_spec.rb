require_relative '../../../helper'
require_relative 'shared_spec_behaviors'

class Repositext
  class Validation
    class Validator

      describe SpotSheet do

        include SharedSpecBehaviors

        describe 'validate_corrections_file' do

          let(:language) { Language::English.new }
          let(:default_date_code) { '16-0101' }
          let(:filename) { '/content/16/eng#{ default_date_code }-1234.at' }
          let(:path_to_repo) { Repository::Test.create!('rt-english').first }
          let(:content_type) { ContentType.new(File.join(path_to_repo, 'ct-general')) }
          let(:content_at_file) {
            get_r_file(
              contents: "# The title",
              filename: filename,
              content_type: true
            )
          }
          let(:corrections_file_preamble){
            [
              "ACCEPTED Corrections",
              "Title: The title",
              "Date: #{ default_date_code }",
              "Revision: 1a2b3c4d",
              "",
              "ACCEPTED CHANGES TO ENGLISH TEXT",
              "",
            ].join("\n")
          }

          [
            [
              'valid file',
              [0, nil]
            ],
            [
              'valid file with straight double quote inside IAL ^^^ {: .rid #rid-65040039 kpn="003"}',
              [0, nil]
            ],
            [
              'invalid file with EN DASH: –',
              [1, 'Contains invalid characters:']
            ],
            [
              'invalid file with straight double quote: "',
              [1, 'Contains invalid characters:']
            ],
            [
              'invalid file with straight single quote: \'',
              [1, 'Contains invalid characters:']
            ],
          ].each do |test_string, (num_errors, error_detail)|
            it "handles #{ test_string.inspect }" do
              validator, _logger, _reporter = build_validator_logger_and_reporter(
                SpotSheet,
                FileLikeStringIO.new('_path', '_txt'),
                nil,
                nil,
                { 'validate_or_merge' => 'validate' }
              )
              errors = []
              warnings = []

              corrections_file = RFile::Content.new(
                corrections_file_preamble + test_string,
                language,
                "path/to/#{ default_date_code }",
                content_type
              )

              validator.send(
                :validate_corrections_file,
                corrections_file,
                corrections_file_preamble + test_string,
                content_at_file,
                errors,
                warnings
              )
              errors.size.must_equal(num_errors)
              errors.all? { |e|
                e.details.first == error_detail
              }.must_equal true
            end
          end

          it "raises exception on error when part of `merge`" do
            corrections_file = RFile::Content.new(
              corrections_file_preamble + 'invalid file with straight double quote: "',
              language,
              "path/to/#{ default_date_code }",
              content_type
            )

            validator, _logger, _reporter = build_validator_logger_and_reporter(
              SpotSheet,
              FileLikeStringIO.new('_path', '_txt'),
              nil,
              nil,
              { 'validate_or_merge' => 'merge' }
            )
            errors = []
            warnings = []

            lambda {
              validator.send(
                :validate_corrections_file,
                corrections_file,
                corrections_file_preamble + 'invalid file with straight double quote: "',
                content_at_file,
                errors,
                warnings
              )
            }.must_raise(SpotSheet::InvalidCorrectionsFile)
          end

        end

        describe 'validate_corrections (`validate`)' do

          [
            [
              [
                {
                  :submitted => 'value_a',
                  :reads => 'value_b',
                  :correction_number => 'value',
                  :first_line => 'value',
                  :paragraph_number => 'value',
                }
              ],
              [0, nil],
            ],

            [
              [
                {
                  :submitted => 'va',
                  :reads => 'vb',
                  :correction_number => '1',
                  :first_line => 'value',
                  :paragraph_number => 'v',
                }, {
                  :submitted => 'va',
                  :reads => 'vb',
                  :correction_number => '2',
                  :first_line => 'value',
                  :paragraph_number => 'v',
                }, {
                  :submitted => 'va',
                  :reads => 'vb',
                  :correction_number => '2a',
                  :first_line => 'value',
                  :paragraph_number => 'v',
                }, {
                  :submitted => 'va',
                  :reads => 'vb',
                  :correction_number => '3',
                  :first_line => 'value',
                  :paragraph_number => 'v',
                },
              ],
              [0, nil],
            ],

            [
              [{ :reads => 'incomplete_attrs' }],
              [1, 'Missing attributes'],
            ],

            [
              [
                {
                  :submitted => 'va',
                  :reads => 'vb',
                  :correction_number => '1',
                  :first_line => 'value',
                  :paragraph_number => 'v',
                }, {
                  :submitted => 'va',
                  :reads => 'vb',
                  :correction_number => '3',
                  :first_line => 'value',
                  :paragraph_number => 'v',
                },
              ],
              [1, 'Non consecutive correction numbers:'],
            ],

            [
              [
                {
                  :submitted => 'va',
                  :reads => 'vb',
                  :correction_number => '2',
                  :first_line => 'value',
                  :paragraph_number => 'v',
                }, {
                  :submitted => 'va',
                  :reads => 'vb',
                  :correction_number => '1',
                  :first_line => 'value',
                  :paragraph_number => 'v',
                },
              ],
              [1, 'Non consecutive correction numbers:'],
            ],

            [
              [
                {
                  :submitted => 'va',
                  :reads => 'vb',
                  :correction_number => '2',
                  :first_line => 'value',
                  :paragraph_number => 'v',
                }, {
                  :submitted => 'va',
                  :reads => 'vb',
                  :correction_number => '3a',
                  :first_line => 'value',
                  :paragraph_number => 'v',
                },
              ],
              [1, 'Non consecutive correction numbers:'],
            ],

            [
              [
                {
                  :submitted => 'identical',
                  :reads => 'identical',
                  :correction_number => '1',
                  :first_line => 'v',
                  :paragraph_number => 'v',
                },
              ],
              [1, 'Identical `Reads` and (`Becomes` or `Submitted`):'],
            ],
          ].each do |corrections, (num_errors, error_detail)|
            it "handles #{ corrections.inspect }" do
              validator, _logger, _reporter = build_validator_logger_and_reporter(
                SpotSheet,
                FileLikeStringIO.new('_path', '_txt'),
                nil,
                nil,
                { 'validate_or_merge' => 'validate' }
              )
              errors = []
              warnings = []

              validator.send(
                :validate_corrections, corrections, errors, warnings
              )
              errors.size.must_equal(num_errors)
              errors.all? { |e|
                e.details.first == error_detail
              }.must_equal true
            end
          end

        end

        describe 'validate_corrections (`merge`)' do
          [
            [
              [
                {
                  :becomes => 'value_a',
                  :reads => 'value_b',
                  :correction_number => 'value',
                  :first_line => 'value',
                  :paragraph_number => 'value',
                }
              ],
              nil,
            ],

            [
              [
                {
                  :reads => 'value_b',
                  :no_change => true,
                  :correction_number => 'value',
                  :first_line => 'value',
                  :paragraph_number => 'value',
                }
              ],
              nil,
            ],

            [
              [
                {
                  :becomes => 'va',
                  :reads => 'vb',
                  :correction_number => '1',
                  :first_line => 'value',
                  :paragraph_number => 'v',
                }, {
                  :becomes => 'va',
                  :reads => 'vb',
                  :correction_number => '2',
                  :first_line => 'value',
                  :paragraph_number => 'v',
                },
              ],
              nil,
            ],

            [
              [{ :becomes => 'incomplete_attrs' }],
              'Missing attributes',
            ],

            [
              [
                {
                  :becomes => 'va',
                  :reads => 'vb',
                  :correction_number => '1',
                  :first_line => 'value',
                  :paragraph_number => 'v',
                }, {
                  :becomes => 'va',
                  :reads => 'vb',
                  :correction_number => '3',
                  :first_line => 'value',
                  :paragraph_number => 'v',
                },
              ],
              'Non consecutive correction numbers:',
            ],

            [
              [
                {
                  :becomes => 'identical',
                  :reads => 'identical',
                  :correction_number => '1',
                  :first_line => 'v',
                  :paragraph_number => 'v',
                },
              ],
              'Identical `Reads` and (`Becomes` or `Submitted`):',
            ],
          ].each do |corrections, xpect_error|
            it "handles #{ corrections.inspect }" do
              validator, _logger, _reporter = build_validator_logger_and_reporter(
                SpotSheet,
                FileLikeStringIO.new('_path', '_txt'),
                nil,
                nil,
                { 'validate_or_merge' => 'merge' }
              )
              errors = []
              warnings = []

              if xpect_error
                # Expect to raise error
                lambda {
                  validator.send(
                    :validate_corrections,
                    corrections,
                    errors,
                    warnings
                  )
                }.must_raise(SpotSheet::InvalidCorrection)
              else
                # Should not raise an error
                validator.send(
                  :validate_corrections,
                  corrections,
                  errors,
                  warnings
                )
                1.must_equal(1)
              end
            end
          end

        end

        describe 'validate_corrections_and_content_at (`validate`)' do
          [
            [
              {
                :becomes => 'text after',
                :reads => 'text before',
                :correction_number => '1',
                :first_line => 'v',
                :paragraph_number => 2,
              },
              %(the heading\n\nParagraph one without para num.\n\n*2*{: .pn} para 2 with text before\n\n),
              [0, nil]
            ],
            [
              {
                :becomes => 'text after',
                :reads => 'text before with subtitle_mark and gap_mark diff',
                :correction_number => '1',
                :first_line => 'v',
                :paragraph_number => 2,
              },
              %(the heading\n\nParagraph one without para num.\n\n*2*{: .pn} para 2 with text before with @subtitle_mark and %gap_mark diff\n\n),
              [0, nil]
            ],
            [
              {
                :becomes => 'text after',
                :reads => 'text before',
                :correction_number => '1',
                :first_line => 'v',
                :paragraph_number => 2,
              },
              %(the heading\n\nParagraph one without para num.\n\n*2*{: .pn} para 2 with text before and another text before\n\n),
              [1, 'Multiple instances of `Reads` found:']
            ],
            [
              {
                :becomes => 'text after',
                :reads => 'non existent',
                :correction_number => '1',
                :first_line => 'v',
                :paragraph_number => 2,
              },
              %(the heading\n\nParagraph one without para num.\n\n*2*{: .pn} para 2 without the expected text\n\n),
              [1, 'Corresponding content AT not found:']
            ],
          ].each do |correction, content_at, (num_errors, error_detail)|
            it "handles #{ content_at.inspect }" do
              validator, _logger, _reporter = build_validator_logger_and_reporter(
                SpotSheet,
                FileLikeStringIO.new('_path', '_txt'),
                nil,
                nil,
                { 'validate_or_merge' => 'validate' }
              )
              errors = []
              warnings = []

              validator.send(
                :validate_corrections_and_content_at,
                [correction],
                content_at,
                errors,
                warnings
              )
              errors.size.must_equal(num_errors)
              errors.all? { |e|
                e.details.first == error_detail
              }.must_equal true
            end
          end

        end

        describe 'validate_corrections_and_content_at (`merge`)' do
          # NOTE: We don't exercise this part in `merge` mode
        end

        describe '#santize_corrections_txt' do
          [
            [
              %(should not get modified),
              %(should not get modified),
            ],
            [
              %(normalizes newlines\rnext line),
              %(normalizes newlines\nnext line),
            ],
            [
              %(converts\ttabs\nto\tspaces),
              %(converts tabs\nto spaces),
            ],
            [
              %(converts    multiple    spaces   to  single  ones),
              %(converts multiple spaces to single ones),
            ],
            [
              %(  removes\n  leading\n   whitespace\nfor each line),
              %(removes\nleading\nwhitespace\nfor each line),
            ],
            [
              %(  and now\r  all\t  together),
              %(and now\nall together),
            ],
          ].each do |test_string, xpect|
            it "handles #{ test_string.inspect }" do
              validator, _logger, _reporter = build_validator_logger_and_reporter(
                SpotSheet,
                FileLikeStringIO.new('_path', '_txt'),
              )
              validator.send(:sanitize_corrections_txt,test_string).must_equal(xpect)
            end
          end

        end

      end

    end
  end
end
