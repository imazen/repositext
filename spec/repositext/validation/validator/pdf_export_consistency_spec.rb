require_relative '../../../helper'
require_relative 'shared_spec_behaviors'

class Repositext
  class Validation
    class Validator

      describe PdfExportConsistency do

        include SharedSpecBehaviors

        let(:default_file_level_settings){ { } }

        describe '#validate_content_consistency ignores' do
          [
            [
              %(Missing horizontal rule\n* * * * * * *\nword word\n),
              %(Missing horizontal rule\nword word\n),
            ],
            [
              %(Missing space character\nWithin 80 characters of preceding eagle at beginning of line\n),
              %(Missing space character\nWithin 80 characters of precedingeagle at beginning of line\n),
            ],
            [
              %(MISSING SPACE IN TITLE WITH EXPLICIT LINE BREAK \nWORD WORD WORD WORD),
              %(MISSING SPACE IN TITLE WITH EXPLICIT LINE BREAK\nWORD WORD WORD WORD),
            ],
            [
              %(Change of space to newline word1 word2\n),
              %(Change of space to newline\nword1 word2\n),
            ],
            [
              %(Extra newline after elipsis…word1 word2\n),
              %(Extra newline after elipsis…\nword1 word2\n),
            ],
            [
              %(Extra newline after emdash—word1 word2\n),
              %(Extra newline after emdash—\nword1 word2\n),
            ],
            [
              %(Extra newline after hyphen-word1 word2\n),
              %(Extra newline after hyphen-\nword1 word2\n),
            ],
            [
              %(Extra newline before elipsis…word1 word2\n),
              %(Extra newline before elipsis\n…word1 word2\n),
            ],
            [
              %(Extra newline before emdash—word1 word2\n),
              %(Extra newline before emdash\n—word1 word2\n),
            ],
            [
              %(Extra newline before hyphen-word1 word2\n),
              %(Extra newline before hyphen\n-word1 word2\n),
            ],
            [
              %(Extra newline after eagle \nword1 word2\n),
              %(Extra newline after eagle \n\nword1 word2\n),
            ],
            [
              %(Extra space before exclamation mark! word1 word2\n),
              %(Extra space before exclamation mark ! word1 word2\n),
            ],
            [
              %(Extra space before question mark? word1 word2\n),
              %(Extra space before question mark ? word1 word2\n),
            ],
            [
              %(Extra space before closing single quote’ word1 word2\n),
              %(Extra space before closing single quote ’ word1 word2\n),
            ],
            [
              %(Extra space before closing double quote” word1 word2\n),
              %(Extra space before closing double quote ” word1 word2\n),
            ],
            [
              %(Extra space before period. word1 word2\n),
              %(Extra space before period . word1 word2\n),
            ],
            [
              %(Extra space before comma, word1 word2\n),
              %(Extra space before comma , word1 word2\n),
            ],
            [
              %(Extra space before semicolon; word1 word2\n),
              %(Extra space before semicolon ; word1 word2\n),
            ],
            [
              %(Extra space before colon: word1 word2\n),
              %(Extra space before colon : word1 word2\n),
            ],
            [
              %(Extra space before colon… word1 word2\n),
              %(Extra space before colon … word1 word2\n),
            ],
            [
              %(NO-BREAK SPACE\u00A0word1 word2\n),
              %(NO-BREAK SPACE word1 word2\n),
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
                warnings,
                default_file_level_settings
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
            [
              %(Missing space character\nMore than 80 characters of preceding eagle at beginning of line. word1 word2 word3 word4 word5 word6\n),
              %(Missing space character\nMore than 80 characters of preceding eagle at beginning of line. word1 word2 word3 word4 word5word6\n),
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
                warnings,
                default_file_level_settings
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
            ],
            [
              %(changes period after word with extra space at end of line .\nword),
              %(changes period after word with extra space at end of line.\nword\n),
            ],
            [
              %(doesn't change newline at end of sequence of periods . . . . .\nword),
              %(doesn't change newline at end of sequence of periods . . . . .\nword\n),
            ],
            [
              %(handles edge case where space is inserted before exclamation mark !\nand newline after),
              %(handles edge case where space is inserted before exclamation mark!\nand newline after\n),
            ],
            [%(removes {123}gap_mark indexes), %(removes gap_mark indexes\n)],
            [
              %(removes record id lines\nRecord id: rid-60281179\nword word),
              %(removes record id lines\nword word\n)
            ],
            [
              %(Converts NO-BREAK SPACE\u00A0to regular space),
              %(Converts NO-BREAK SPACE to regular space\n)
            ],
            [
              %(Converts NARROW NO-BREAK SPACE\u202Fto regular space),
              %(Converts NARROW NO-BREAK SPACE to regular space\n)
            ],
            [
              %(Converts ZERO WIDTH NO-BREAK SPACE\uFEFFto regular space),
              %(Converts ZERO WIDTH NO-BREAK SPACE to regular space\n)
            ],
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
            [%(plain text), %(plain text\n)],
            [%(  strips surrounding space  ), %(strips surrounding space\n)],
            [
              %(Converts NO-BREAK SPACE\u00A0to regular space),
              %(Converts NO-BREAK SPACE to regular space\n)
            ],
            [
              %(Converts NARROW NO-BREAK SPACE\u202Fto regular space),
              %(Converts NARROW NO-BREAK SPACE to regular space\n)
            ],
            [
              %(Converts ZERO WIDTH NO-BREAK SPACE\uFEFFto regular space),
              %(Converts ZERO WIDTH NO-BREAK SPACE to regular space\n)
            ],
          ].each do |pdf_raw_text, xpect|
            it "handles #{ pdf_raw_text.inspect }" do
              validator, logger, reporter = build_validator_logger_and_reporter(
                PdfExportConsistency,
                [
                  FileLikeStringIO.new('_path', '_txt'),
                  FileLikeStringIO.new('_path', '_txt'),
                ]
              )
              validator.send(:sanitize_content_at_plain_text, pdf_raw_text).must_equal(xpect)
            end
          end
        end

      end

    end
  end
end
