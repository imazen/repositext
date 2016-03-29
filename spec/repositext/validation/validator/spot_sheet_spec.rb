require_relative '../../../helper'
require_relative 'shared_spec_behaviors'

class Repositext
  class Validation
    class Validator

      describe SpotSheet do

        include SharedSpecBehaviors

        describe 'validate_corrections_file' do
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
              validator, logger, reporter = build_validator_logger_and_reporter(
                SpotSheet,
                FileLikeStringIO.new('_path', '_txt'),
              )
              errors = []
              warnings = []

              validator.send(
                :validate_corrections_file, test_string, errors, warnings
              )
              errors.size.must_equal(num_errors)
              errors.all? { |e|
                e.details.first == error_detail
              }.must_equal true
            end
          end

          it "raises exception on error when part of `merge`" do
            validator, logger, reporter = build_validator_logger_and_reporter(
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
                'invalid file with straight double quote: "',
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
              validator, logger, reporter = build_validator_logger_and_reporter(
                SpotSheet,
                FileLikeStringIO.new('_path', '_txt'),
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
              validator, logger, reporter = build_validator_logger_and_reporter(
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

        describe 'validate_corrections_and_content_at' do
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
              validator, logger, reporter = build_validator_logger_and_reporter(
                SpotSheet,
                FileLikeStringIO.new('_path', '_txt'),
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

          it "raises exception on error when part of `merge`" do
            validator, logger, reporter = build_validator_logger_and_reporter(
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
                :validate_corrections_and_content_at,
                [
                  {
                    :becomes => 'text after',
                    :reads => 'text before',
                    :correction_number => '1',
                    :first_line => 'v',
                    :paragraph_number => 2,
                  }
                ],
                %(the heading\n\nParagraph one without para num.\n\n*2*{: .pn} para 2 with text before and another text before\n\n),
                errors,
                warnings
              )
            }.must_raise(SpotSheet::InvalidCorrectionAndContentAt)
          end

        end

      end

    end
  end
end
