require_relative '../../../helper'

class Repositext
  class Validation
    class Validator

      describe DocxImportWorkflow do

        before do
          # Redirect console output for clean test logs
          # NOTE: use STDOUT.puts if you want to print something to the test output
          @stderr = $stderr = StringIO.new
          @stdout = $stdout = StringIO.new
        end

        let(:logger) { LoggerTest.new(nil, nil, nil, nil, nil) }
        let(:reporter) { ReporterTest.new(nil, nil, nil, nil) }

        describe '#validate_correct_file_name' do
          [
            ["eng56-0101_0297.docx", true],
            ["norcab_01_-_title_1386.docx", true],
            ["some_other_name.docx", false],
          ].each do |file_name, xpect_valid|
            it "validates #{ file_name.inspect }" do
              validator = DocxImportWorkflow.new(
                FileLikeStringIO.new('/_', '_'),
                logger,
                reporter,
                {}
              )
              if xpect_valid
                validator.send(:validate_correct_file_name, file_name, [], [])
                1.must_equal 1
              else
                lambda {
                  validator.send(
                    :validate_correct_file_name,
                    file_name,
                    [],
                    []
                  )
                }.must_raise(DocxImportWorkflow::InvalidFileNameError)
              end
            end
          end
        end

        describe '#validate_document_styles_not_modified' do

          let(:styles_xml_prefix) {
            %(
              <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
              <w:styles mc:Ignorable="w14" xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml">
            )
          }
          let(:styles_xml_suffix) { %(</w:styles>) }

          valid_styles = {
            'Normal' => %(
              <w:style w:default="1" w:styleId="Normal" w:type="paragraph">
                <w:name w:val="Normal"/>
                <w:rsid w:val="0007621A"/>
                <w:pPr>
                  <w:tabs>
                    <w:tab w:pos="360" w:val="left"/>
                  </w:tabs>
                  <w:spacing w:after="0" w:before="60" w:line="240" w:lineRule="auto"/>
                  <w:jc w:val="both"/>
                </w:pPr>
                <w:rPr>
                  <w:rFonts w:ascii="V-Excelsior LT Std" w:hAnsi="V-Excelsior LT Std"/>
                  <w:color w:themeColor="text1" w:val="000000"/>
                  <w:sz w:val="20"/>
                </w:rPr>
              </w:style>
            ),
            'Heading1' => %(
              <w:style w:styleId="Heading1" w:type="paragraph">
                <w:name w:val="heading 1"/>
                <w:basedOn w:val="Normal"/>
                <w:next w:val="Normal"/>
                <w:link w:val="Heading1Char"/>
                <w:uiPriority w:val="9"/>
                <w:rsid w:val="00A06EAA"/>
                <w:pPr>
                  <w:keepNext/>
                  <w:keepLines/>
                  <w:spacing w:before="480"/>
                  <w:outlineLvl w:val="0"/>
                </w:pPr>
                <w:rPr>
                  <w:rFonts w:asciiTheme="majorHAnsi" w:cstheme="majorBidi" w:eastAsiaTheme="majorEastAsia" w:hAnsiTheme="majorHAnsi"/>
                  <w:b/>
                  <w:bCs/>
                  <w:color w:themeColor="accent1" w:themeShade="B5" w:val="345A8A"/>
                  <w:sz w:val="32"/>
                  <w:szCs w:val="32"/>
                </w:rPr>
              </w:style>
            )
          }

          [
            [
              'Correct style attrs',
              valid_styles['Heading1'],
              [],
            ],
            [
              'Incorrect basedOn',
              valid_styles['Heading1'].sub(%(<w:basedOn w:val="Normal"/>), %(<w:basedOn w:val="Incorrect"/>)),
              [["Unexpected modification of document styles", "Style: Heading1, expected basedOn to be \"Normal\", got \"Incorrect\""]],
            ],
            [
              'Missing basedOn',
              valid_styles['Heading1'].sub(%(<w:basedOn w:val="Normal"/>), %()),
              [["Unexpected modification of document styles", "Style: Heading1, expected basedOn to be \"Normal\", got nil"]],
            ],
            [
              'Unexpected basedOn',
              valid_styles['Normal'].sub(%(<w:name w:val="Normal"/>), %(<w:name w:val="Normal"/><w:basedOn w:val="Unexpected"/>)),
              [["Unexpected modification of document styles", "Style: Normal, expected basedOn to be nil, got \"Unexpected\""]],
            ],
            [
              'Incorrect pPr (added attr)',
              valid_styles['Normal'].sub(%(<w:jc w:val="both"/>), %(<w:jc w:val="both"/><w:keepNext/>)),
              [["Unexpected modification of document styles", "Style: Normal, expected pPr to contain the following attrs: [\"jc\", \"spacing\", \"tabs\"], got [\"jc\", \"keepNext\", \"spacing\", \"tabs\"]"]],
            ],
            [
              'Incorrect pPr (removed attr)',
              valid_styles['Normal'].sub(%(<w:jc w:val="both"/>), %()),
              [["Unexpected modification of document styles", "Style: Normal, expected pPr to contain the following attrs: [\"jc\", \"spacing\", \"tabs\"], got [\"spacing\", \"tabs\"]"]],
            ],
            [
              'Missing pPr',
              valid_styles['Normal'].gsub("w:pPr", 'w:pPrX'),
              [["Unexpected modification of document styles", "Style: Normal, expected pPr to contain the following attrs: [\"jc\", \"spacing\", \"tabs\"], got []"]],
            ],
            [
              'Incorrect rPr (added attr)',
              valid_styles['Normal'].sub(%(<w:sz w:val="20"/>), %(<w:sz w:val="20"/><w:keepNext/>)),
              [["Unexpected modification of document styles", "Style: Normal, expected pPr to contain the following attrs: [\"color\", \"rFonts\", \"sz\"], got [\"color\", \"keepNext\", \"rFonts\", \"sz\"]"]],
            ],
            [
              'Incorrect rPr (removed attr)',
              valid_styles['Normal'].sub(%(<w:sz w:val="20"/>), %()),
              [["Unexpected modification of document styles", "Style: Normal, expected pPr to contain the following attrs: [\"color\", \"rFonts\", \"sz\"], got [\"color\", \"rFonts\"]"]],
            ],
            [
              'Missing rPr',
              valid_styles['Normal'].gsub("w:rPr", 'w:rPrX'),
              [["Unexpected modification of document styles", "Style: Normal, expected pPr to contain the following attrs: [\"color\", \"rFonts\", \"sz\"], got []"]],
            ],
          ].each do |desc, style_entries, xpect|
            it "handles #{ desc }" do
              validator = DocxImportWorkflow.new(
                FileLikeStringIO.new('/_', '_'),
                logger,
                reporter,
                {}
              )
              styles_xml_contents = [styles_xml_prefix, style_entries, styles_xml_suffix].join
              errors = []
              warnings = []
              validator.send(
                :validate_document_styles_not_modified,
                styles_xml_contents,
                errors,
                warnings
              )
              errors.map { |e| e.details }.must_equal(xpect)
            end
          end
        end

      end

    end
  end
end
