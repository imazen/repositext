require_relative '../../../helper'
require_relative 'shared_spec_behaviors'

class Repositext
  class Validation
    class Validator

      describe KramdownSyntaxAt do

        include SharedSpecBehaviors

        describe '#run' do

          it 'reports no errors for valid kramdown AT' do
            validator, _logger, reporter = build_validator_logger_and_reporter(
              KramdownSyntaxAt,
              get_r_file
            )
            validator.run
            reporter.errors.must_be(:empty?)
          end

          it 'reports errors for invalid kramdown AT' do
            validator, _logger, reporter = build_validator_logger_and_reporter(
              KramdownSyntaxAt,
              get_r_file(contents: 'invalid kramdown AT with gap_mark in%side a word')
            )
            validator.run
            reporter.errors.wont_be(:empty?)
          end

        end

        describe '#valid_kramdown_syntax?' do
          [
            ["paragraph followed by single newline\n{: .normal}\nnext para", false],
            ["paragraph followed by two newlines\n{: .normal}\n\nnext para", true],
            ["paragraph followed by three newlines\n{: .normal}\n\n\nnext para", false],
            ["paragraph followed by ten newlines\n{: .normal}\n\n\n\n\n\n\n\n\n\nnext para", false],
            ["line break inside a paragraph\nparagraph continued", false],
            ["line break at end of file }\n", true],
          ].each do |test_string, xpect|
            it "handles #{ test_string.inspect }" do
              r_file = get_r_file(contents: test_string)
              validator, _logger, _reporter = build_validator_logger_and_reporter(
                KramdownSyntaxAt,
                r_file
              )
              validator.valid_kramdown_syntax?(r_file).success.must_equal(xpect)
            end
          end
        end

        describe '#valid_syntax_at?' do
          [
            ["valid kramdown AT", true],
            ["record_mark not preceded by blank line\n^^^", false],
            ["escaped bracket \\[", false],
          ].each do |test_string, xpect|
            it "handles #{ test_string.inspect }" do
              r_file = get_r_file(contents: test_string)
              validator, _logger, _reporter = build_validator_logger_and_reporter(
                KramdownSyntaxAt,
                r_file
              )
              validator.valid_syntax_at?(r_file).success.must_equal(xpect)
            end
          end
        end

        describe '#validate_source' do
          [
            ["valid kramdown AT", 0],
            ["Disconnected IAL and trailing whitespace \n\n{: .normal}\n\n", 2],
            ["gap_mark at invalid position (inside word) word%word", 1],
            ["gap_mark at invalid position (after asterisk) *%word", 1],
            ["gap_mark at invalid position (after quote) *%word", 1],
            ["gap_mark at invalid position (after quote) \"%word", 1],
            ["gap_mark at invalid position (after quote) “%word", 1],
            ["gap_mark at invalid position (after quote) ”%word", 1],
            ["gap_mark at invalid position (after quote) '%word", 1],
            ["gap_mark at invalid position (after quote) ‘%word", 1],
            ["gap_mark at invalid position (after quote) ’%word", 1],
            ["gap_mark at invalid position (after parens) (%word", 1],
            ["gap_mark at invalid position (after opening bracket) [%word", 1],
            ["gap_mark NOT at invalid position (if followed by …?…) word%…?…", 0],
            ["subtitle_mark at invalid position (inside word) word@word", 1],
            ["subtitle_mark at invalid position (after asterisk) *@word", 1],
            ["subtitle_mark at invalid position (after quote) *@word", 1],
            ["subtitle_mark at invalid position (after quote) \"@word", 1],
            ["subtitle_mark at invalid position (after quote) “@word", 1],
            ["subtitle_mark at invalid position (after quote) ”@word", 1],
            ["subtitle_mark at invalid position (after quote) '@word", 1],
            ["subtitle_mark at invalid position (after quote) ‘@word", 1],
            ["subtitle_mark at invalid position (after quote) ’@word", 1],
            ["subtitle_mark at invalid position (after parens) (@word", 1],
            ["subtitle_mark at invalid position (after opening bracket) [@word", 1],
            ["subtitle_mark NOT at invalid position (if followed by …?…) word@…?…", 0],
            ["subtitle_mark NOT at invalid position (if preced by …*) …*@word", 0],
            ["subtitle_mark NOT at invalid position (if followed by —) word@—", 0],
            ["Paragraph not followed by exactly two newlines and trailing whitespace \n{: .normal}\nNext para", 3],
            ["Paragraph not followed by exactly two newlines and trailing whitespace \n{: .normal}\n\n", 1],
            ["Paragraph not followed by exactly two newlines and trailing whitespace \n{: .normal}\n\n\n", 2],
            ["Multiple adjacent  spaces", 1],
            ["Trailing whitespace character \n{: .normal}\n\n", 1],
            ["Trailing whitespace character\u00A0\n{: .normal}\n\n", 1],
            ["Trailing whitespace character\u202F\n{: .normal}\n\n", 1],
            ["Trailing whitespace character\uFEFF\n{: .normal}\n\n", 1],
            ["Invalid elipsis 1 ...", 1],
            ["Invalid elipsis 2 . . .", 1],
            ["Invalid horizontal rule (prefix)\n\nx * * *\n", 1],
            ["Invalid horizontal rule (suffix)\n\n* * *x\n", 1],
          ].each do |test_string, xpect|
            it "handles #{ test_string.inspect }" do
              r_file = get_r_file(contents: test_string)
              validator, _logger, _reporter = build_validator_logger_and_reporter(
                KramdownSyntaxAt,
                r_file
              )
              errors = []
              warnings = []
              validator.send(
                :validate_source, r_file, errors, warnings
              )
              errors.size.must_equal(xpect)
            end
          end
        end

        describe '#validate_record_mark_syntax' do
          [
            ["valid kramdown AT", 0],
            ["record_mark preceded by blank line\n\n^^^\n\nnext line", 0],
            ["^^^\n\nfirst record_mark doesn't need to be preceded by blank line", 0],
            ["record_mark not preceded by blank line\n^^^\n\nnext line", 1],
            ["^^^\n\nrecord_marks with text between them\n\n^^^\n\nnext line", 0],
            ["record_marks with no text between them\n\n^^^\n\n^^^\n\nnext line", 1],
            ["record_marks with no text between them\n\n^^^\n\n  \n\n^^^\n\nnext line", 1],
            ["record_mark followed by two newlines\n\n^^^\n\nnext line", 0],
            ["record_mark followed by one newline\n\n^^^\nnext line", 1],
            ["record_mark followed by three newlines\n\n^^^\n\n\nnext line", 1],
          ].each do |test_string, xpect|
            it "handles #{ test_string.inspect }" do
              r_file = get_r_file(contents: test_string)
              validator, _logger, _reporter = build_validator_logger_and_reporter(
                KramdownSyntaxAt,
                r_file
              )
              errors = []
              warnings = []
              validator.send(
                :validate_record_mark_syntax, r_file, errors, warnings
              )
              errors.size.must_equal(xpect)
            end
          end
        end

        describe '#validation_hook_on_element' do
          # Block level elements
          [
            ["^^^ {: .rid #rid-12340009}\n\nsong para right after record mark\n{: .song}", 1],
            ["*1*{: .pn} p.normal_pn with pn\n{: .normal_pn}", 0],
            ["p.normal_pn without pn\n{: .normal_pn}", 1],
            ["*1*{: .pn} p.normal with pn\n{: .normal}", 1],
            ["p.normal without pn\n{: .normal}", 0],
          ].each do |test_string, xpect|
            it "handles #{ test_string.inspect }" do
              r_file = get_r_file(contents: test_string)
              validator, _logger, _reporter = build_validator_logger_and_reporter(
                KramdownSyntaxAt,
                r_file
              )
              errors = []
              warnings = []
              kramdown_doc = Kramdown::Document.new(test_string, { :input => 'KramdownRepositext' })
              validator.send(
                :validation_hook_on_element,
                r_file,
                kramdown_doc.root.children.first,
                [],
                errors,
                warnings
              )
              errors.size.must_equal(xpect)
            end
          end

          # Span elements
          scenarios = []
          # ImplementationTag #punctuation_characters
          # NOTE: It seems like I can't test the single space. It won't parse '* *' as a span.
          %(!()+,-./:;?[]—‘’“”…).chars.each { |c|
            scenarios << ["*#{ c }*", [], 1]
            scenarios << ["**#{ c }**", [], 1]
          }
          # .scr exception (only elipsis and space)
          scenarios << ["*…*", [::Kramdown::Element.new(:p, nil, 'class' => 'scr')], 1]
          scenarios << ["*.*", [::Kramdown::Element.new(:p, nil, 'class' => 'scr')], 0]
          # .line_break exception
          scenarios << ["*.*{: .line_break}", [], 0]

          scenarios.each do |test_string, el_stack, xpect|
            it "handles #{ test_string.inspect }" do
              r_file = get_r_file(contents: test_string)
              validator, _logger, _reporter = build_validator_logger_and_reporter(
                KramdownSyntaxAt,
                r_file
              )
              errors = []
              warnings = []
              kramdown_doc = Kramdown::Document.new(test_string, { :input => 'KramdownRepositext' })
              validator.send(
                :validation_hook_on_element,
                r_file,
                kramdown_doc.root.children.first.children.first,
                el_stack,
                errors,
                warnings
              )
              errors.size.must_equal(xpect)
            end
          end
        end


      end

    end
  end
end
