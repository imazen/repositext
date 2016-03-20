require_relative '../../../helper'
require_relative 'shared_spec_behaviors'

class Repositext
  class Validation
    class Validator

      describe PdfExportConsistency do

        include SharedSpecBehaviors

        describe '#validate_content_consistency ignores' do
          [
            [
              %(horizontal rule differences\n* * * * * * *\nword word\n),
              %(horizontal rule differences\nword word\n),
            ],
            [
              %(change of space to newline word1 word2\n),
              %(change of space to newline\nword1 word2\n),
            ],
            [
              %(insertion of newline after elipsis…word1 word2\n),
              %(insertion of newline after elipsis…\nword1 word2\n),
            ],
            [
              %(insertion of newline after emdash—word1 word2\n),
              %(insertion of newline after emdash—\nword1 word2\n),
            ],
            [
              %(insertion of newline after hyphen-word1 word2\n),
              %(insertion of newline after hyphen-\nword1 word2\n),
            ],
            [
              %(insertion of space before exclamation mark! word1 word2\n),
              %(insertion of space before exclamation mark ! word1 word2\n),
            ],
            [
              %(insertion of space before question mark? word1 word2\n),
              %(insertion of space before question mark ? word1 word2\n),
            ],
            [
              %(insertion of space before closing single quote’ word1 word2\n),
              %(insertion of space before closing single quote ’ word1 word2\n),
            ],
            [
              %(insertion of space before closing double quote” word1 word2\n),
              %(insertion of space before closing double quote ” word1 word2\n),
            ],
          ].each do |content_at_plain_text, pdf_raw_text|
            it "handles #{ pdf_raw_text.inspect }" do
              validator, logger, reporter = build_validator_logger_and_reporter(
                PdfExportConsistency,
                [
                  FileLikeStringIO.new('_path', '_txt'),
                  FileLikeStringIO.new('_path', '_txt'),
                ]
              )
              errors = []
              warnings = []
              validator.send(
                :validate_content_consistency,
                pdf_raw_text,
                content_at_plain_text,
                errors,
                warnings
              )
              errors.count.must_equal(0)
            end
          end
        end

        describe '#validate_content_consistency errors' do
          [
            [
              %(text added\n),
              %(text added word\n),
            ],
            [
              %(text removed word\n),
              %(text removed\n),
            ],
            [
              %(text changed word1\n),
              %(text changed word2\n),
            ],
          ].each do |content_at_plain_text, pdf_raw_text|
            it "handles #{ pdf_raw_text.inspect }" do
              validator, logger, reporter = build_validator_logger_and_reporter(
                PdfExportConsistency,
                [
                  FileLikeStringIO.new('_path', '_txt'),
                  FileLikeStringIO.new('_path', '_txt'),
                ]
              )
              errors = []
              warnings = []
              validator.send(
                :validate_content_consistency,
                pdf_raw_text,
                content_at_plain_text,
                errors,
                warnings
              )
              errors.count.must_equal(1)
            end
          end
        end

        describe '#sanitize_pdf_raw_text' do
          [
            [%(plain text), %(plain text\n) ],
            [%(  strips surrounding space  ), %(strips surrounding space\n) ],
            [%(word word Revision Information Date word word), %(word word\n)],
            [
              %(handles edge case where space is inserted before questionmark ?\nand newline after),
              %(handles edge case where space is inserted before questionmark?\nand newline after\n),
            ]
          ].each do |pdf_raw_text, xpect|
            it "handles #{ pdf_raw_text.inspect }" do
              validator, logger, reporter = build_validator_logger_and_reporter(
                PdfExportConsistency,
                [
                  FileLikeStringIO.new('_path', '_txt'),
                  FileLikeStringIO.new('_path', '_txt'),
                ]
              )
              validator.send(:sanitize_pdf_raw_text, pdf_raw_text).must_equal(xpect)
            end
          end
        end

        describe '#sanitize_content_at_plain_text' do
          [
            [%(plain text), %(plain text\n) ],
            [%(  strips surrounding space  ), %(strips surrounding space\n) ],
          ].each do |pdf_raw_text, xpect|
            it "handles #{ pdf_raw_text.inspect }" do
              validator, logger, reporter = build_validator_logger_and_reporter(
                PdfExportConsistency,
                [
                  FileLikeStringIO.new('_path', '_txt'),
                  FileLikeStringIO.new('_path', '_txt'),
                ]
              )
              validator.send(:sanitize_pdf_raw_text, pdf_raw_text).must_equal(xpect)
            end
          end
        end

      end

    end
  end
end
