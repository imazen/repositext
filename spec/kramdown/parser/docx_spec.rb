require_relative '../../helper'

module Kramdown
  module Parser
    describe Docx do

      # Converts kramdown to docx
      # @param kramdown [String]
      # @return [Caracal::Document]
      #     This can be rendered to individual XML strings via
      #     `Caracal::Renderer::DocumentRenderer.render(docx)`
      def kramdown_as_docx_xml_string(kramdown)
        doc = Document.new(kramdown, :input => 'KramdownRepositext')
        Caracal::Renderers::DocumentRenderer.render(doc.to_docx_object)
      end

      describe 'test helpers' do

        describe '#kramdown_as_docx_xml_string' do

          it 'converts kramdown to document.xml string' do
            kramdown_as_docx_xml_string('word').must_equal(
              %(<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<w:document xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:w10="urn:schemas-microsoft-com:office:word" xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml" xmlns:sl="http://schemas.openxmlformats.org/schemaLibrary/2006/main" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture" xmlns:c="http://schemas.openxmlformats.org/drawingml/2006/chart" xmlns:lc="http://schemas.openxmlformats.org/drawingml/2006/lockedCanvas" xmlns:dgm="http://schemas.openxmlformats.org/drawingml/2006/diagram"><w:background w:color="FFFFFF"/><w:body><w:p><w:pPr><w:contextualSpacing w:val="0"/></w:pPr><w:r><w:rPr><w:rtl w:val="0"/></w:rPr><w:t xml:space="preserve"/></w:r><w:r><w:rPr><w:rtl w:val="0"/></w:rPr><w:t xml:space="preserve">word</w:t></w:r></w:p><w:sectPr><w:pgSz w:w="12240" w:h="15840"/><w:pgMar w:top="1440" w:bottom="1440" w:left="1440" w:right="1440"/></w:sectPr></w:body></w:document>\n)
            )
          end

        end

      end

      describe '#process_node_p' do

        [
          ['Normal para', %(word word\n{: .normal}\n\n)],
          ['Header 1', %(# header 1\n\n)],
          ['Header 2', %(## header 2\n\n)],
          ['Header 3', %(### header 3\n\n)],
        ].each do |(description, test_string, xpect)|
          it "handles #{ description }" do
            docx_xml_string = kramdown_as_docx_xml_string(test_string)
            kramdown_doc = Document.new(docx_xml_string, { :input => 'Docx' })
            kramdown_doc.to_kramdown_repositext.must_equal(xpect || test_string)
          end
        end

        it "raises on header level 4" do
          docx_xml_string = %(<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<w:document xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:w10="urn:schemas-microsoft-com:office:word" xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml" xmlns:sl="http://schemas.openxmlformats.org/schemaLibrary/2006/main" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture" xmlns:c="http://schemas.openxmlformats.org/drawingml/2006/chart" xmlns:lc="http://schemas.openxmlformats.org/drawingml/2006/lockedCanvas" xmlns:dgm="http://schemas.openxmlformats.org/drawingml/2006/diagram"><w:background w:color="FFFFFF"/><w:body><w:p><w:pPr><w:pStyle w:val="header4"/><w:contextualSpacing w:val="0"/></w:pPr><w:r><w:rPr><w:rtl w:val="0"/></w:rPr><w:t xml:space="preserve"/></w:r><w:r><w:rPr><w:rtl w:val="0"/></w:rPr><w:t xml:space="preserve">header 4</w:t></w:r></w:p><w:sectPr><w:pgSz w:w="12240" w:h="15840"/><w:pgMar w:top="1440" w:bottom="1440" w:left="1440" w:right="1440"/></w:sectPr></w:body></w:document>\n)
          proc{
            kramdown_doc = Document.new(docx_xml_string, { :input => 'Docx' })
            kramdown_doc.to_kramdown_repositext
          }.must_raise Docx::InvalidElementException
        end

        it "raises on unknown paragraph class" do
          docx_xml_string = %(<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<w:document xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:w10="urn:schemas-microsoft-com:office:word" xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml" xmlns:sl="http://schemas.openxmlformats.org/schemaLibrary/2006/main" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture" xmlns:c="http://schemas.openxmlformats.org/drawingml/2006/chart" xmlns:lc="http://schemas.openxmlformats.org/drawingml/2006/lockedCanvas" xmlns:dgm="http://schemas.openxmlformats.org/drawingml/2006/diagram"><w:background w:color="FFFFFF"/><w:body><w:p><w:pPr><w:pStyle w:val="invalidParaClass"/><w:contextualSpacing w:val="0"/></w:pPr><w:r><w:rPr><w:rtl w:val="0"/></w:rPr><w:t xml:space="preserve"/></w:r><w:r><w:rPr><w:rtl w:val="0"/></w:rPr><w:t xml:space="preserve">word</w:t></w:r></w:p><w:sectPr><w:pgSz w:w="12240" w:h="15840"/><w:pgMar w:top="1440" w:bottom="1440" w:left="1440" w:right="1440"/></w:sectPr></w:body></w:document>\n)
          proc{
            kramdown_doc = Document.new(docx_xml_string, { :input => 'Docx' })
            kramdown_doc.to_kramdown_repositext
          }.must_raise Docx::InvalidElementException
        end

      end

      describe '#process_node_r' do

        [
          ['em with no class', %(word *italic*\n{: .normal}\n\n)],
          ['Strong', %(word **strong**\n{: .normal}\n\n)],
          [
            'em.italic',
            %(word1 *word2*{: .italic}\n{: .normal}\n\n),
            %(word1 *word2*\n{: .normal}\n\n),
          ],
          [
            'Bold via em class',
            %(word *bold*{: .bold}\n{: .normal}\n\n),
            %(word **bold**\n{: .normal}\n\n),
          ],
          ['em.bold.italic', %(word1 *word2*{: .bold .italic}\n{: .normal}\n\n)],
          ['em.smcaps', %(word1 *word2*{: .smcaps}\n{: .normal}\n\n)],
          ['em.underline', %(word1 *word2*{: .underline}\n{: .normal}\n\n)],
          ['em.subscript', %(word1 *word2*{: .subscript}\n{: .normal}\n\n)],
          ['em.superscript', %(word1 *word2*{: .superscript}\n{: .normal}\n\n)],
        ].each do |(description, test_string, xpect)|
          it "handles #{ description }" do
            docx_xml_string = kramdown_as_docx_xml_string(test_string)
            kramdown_doc = Document.new(docx_xml_string, { :input => 'Docx' })
            kramdown_doc.to_kramdown_repositext.must_equal(xpect || test_string)
          end
        end

      end

    end
  end
end
