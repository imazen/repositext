require_relative '../../helper'

module Kramdown
  module Converter
    describe DocxObject do

      # NOTE: This spec tests behavior of Kramdown::Converter::Docx.
      # DocxObject is a subclass that returns objects instead of writing files,
      # which makes it more suitable for testing.

      # Extracts all block level elements in docx to remove boilerplate code.
      # @param docx [Caracal::Document]
      # @return [Array<Nokogiri::Xml::Node>] the block level elements in document.xml
      def extract_block_els_in_docx(docx)
        full_xml = Caracal::Renderers::DocumentRenderer.render(docx)
        xml_doc = Nokogiri::XML.parse(full_xml)
        xml_doc.remove_namespaces!
        xml_doc.at_css('body').children.find_all { |e| 'sectPr' != e.name } #.tap{ |e| p e }
      end

      # Checks for each path in attrs whether it exists identically in xml_nodes.
      # NOTE: The `:children` key has special meaning.
      # @param xml_nodes [Array<Xml::Node>]
      # @param attrs [Array<Hash>]
      # @param mismatches [Array, optional] optional collector for mismatches
      # @return [Array<Hash>] An array with any mismatches
      def xml_nodes_match_attrs(xml_nodes, attrs, mismatches = [])
        attrs.each_with_index.each { |attr_set, idx|
          xn = xml_nodes[idx]
          attr_set.each { |(attr_key, attr_val)|
            # Either call method, or hash key, or recurse on children
            # p.name vs. p[:name]
            if :children == attr_key
              # recurse over children
              xml_nodes_match_attrs(xn.children, attr_val, mismatches)
            else
              # compare attrs
              xn_val = xn.methods.include?(attr_key) ? xn.send(attr_key) : xn[attr_key]
              if xn_val != attr_val
                mismatches << { node: xn.name_and_class_path, attr: "#{ attr_key }: expected #{ attr_val.inspect }, got #{ xn_val.inspect }" }
              end
            end
          }
        }
        mismatches
      end

      describe 'test helpers' do

        it "extracts block els" do
          doc = Document.new("the text", :input => 'KramdownRepositext')
          extract_block_els_in_docx(doc.to_docx_object).map(&:name).must_equal(['p'])
        end

        describe 'match xml_nodes with attrs' do

          it 'recognizes differences' do
            xml_fragment = Nokogiri::XML::DocumentFragment.parse(%(<p val="theVal">inner text</p>))
            xml_nodes = xml_fragment.replace(xml_fragment.children) # reparent block els from parent `#document-fragment` node
            attrs = [{ name: 'span', val: 'notTheVal', inner_text: 'different inner text' }]
            xml_nodes_match_attrs(xml_nodes, attrs).must_equal([
              { node: "p", attr: %(name: expected "span", got "p") },
              { node: "p", attr: %(val: expected "notTheVal", got "theVal") },
              { node: "p", attr: %(inner_text: expected "different inner text", got "inner text") }
            ])
          end

          it 'recognizes identical' do
            xml_nodes = Nokogiri::XML::DocumentFragment.parse(%(<p val="theVal">inner text</p>))
            xml_nodes = xml_nodes.replace(xml_nodes.children) # reparent block els from parent `#document-fragment` node
            attrs = [{ name: 'p', val: 'theVal', inner_text: 'inner text' }]
            xml_nodes_match_attrs(xml_nodes, attrs).must_be(:empty?)
          end

        end

        it "compares xml_nodes with attrs" do
          doc = Document.new("the text", :input => 'KramdownRepositext')
          extract_block_els_in_docx(doc.to_docx_object).map(&:name).must_equal(['p'])
        end

      end

      describe '#convert_em' do

        [
          [
            'Without IAL',
            '*plain*',
            [
              {
                name: 'p',
                children: [
                  { name: 'pPr' },
                  { name: 'r' },
                  {
                    name: 'r',
                    children: [
                      {
                        name: 'rPr',
                        children: [{ name: 'i', val: '1' }]
                      }
                    ],
                    inner_text: 'plain',
                  },
                ]
              }
            ]
          ],
        ].each do |test_attrs|
          desc, test_string, expect = *test_attrs
          it desc do
            doc = Document.new(test_string, :input => 'KramdownRepositext')
            xml_nodes_match_attrs(
              extract_block_els_in_docx(doc.to_docx_object),
              expect
            ).must_be(:empty?)
          end
        end

      end

      describe '#convert_entity' do

        [
          [
            'non breaking space',
            'word&nbsp;word',
            [
              {
                name: 'p',
                children: [
                  { name: 'pPr' },
                  { name: 'r' },
                  {
                    name: 'r',
                    inner_text: 'word',
                  },
                  {
                    name: 'r',
                    inner_text: '&nbsp;',
                  },
                  {
                    name: 'r',
                    inner_text: 'word',
                  },
                ]
              }
            ]
          ],
        ].each do |test_attrs|
          desc, test_string, expect = *test_attrs
          it desc do
            doc = Document.new(test_string, :input => 'KramdownRepositext')
            xml_nodes_match_attrs(
              extract_block_els_in_docx(doc.to_docx_object),
              expect
            ).must_be(:empty?)
          end
        end

      end

      describe '#convert_gap_mark' do

        [
          [
            'Should get dropped',
            'word %word',
            [
              {
                name: 'p',
                children: [
                  { name: 'pPr' },
                  { name: 'r' },
                  {
                    name: 'r',
                    inner_text: 'word ',
                  },
                  {
                    name: 'r',
                    inner_text: 'word',
                  },
                ]
              }
            ]
          ],
        ].each do |test_attrs|
          desc, test_string, expect = *test_attrs
          it desc do
            doc = Document.new(test_string, :input => 'KramdownRepositext')
            xml_nodes_match_attrs(
              extract_block_els_in_docx(doc.to_docx_object),
              expect
            ).must_be(:empty?)
          end
        end

      end

      describe '#convert_header' do

        [
          [
            'Converts level 1',
            '# header text',
            [
              {
                name: 'p',
                children: [
                  {
                    name: 'pPr',
                    children: [
                      {
                        name: 'pStyle',
                        val: DocxObject.paragraph_style_mappings['header-1'][:id]
                      },
                    ]
                  },
                  { name: 'r' },
                  {
                    name: 'r',
                    inner_text: 'header text',
                  },
                ]
              }
            ]
          ],
          [
            'Converts level 2',
            '## header text',
            [
              {
                name: 'p',
                children: [
                  {
                    name: 'pPr',
                    children: [
                      {
                        name: 'pStyle',
                        val: DocxObject.paragraph_style_mappings['header-2'][:id]
                      },
                    ]
                  },
                  { name: 'r' },
                  {
                    name: 'r',
                    inner_text: 'header text',
                  },
                ]
              }
            ]
          ],
          [
            'Converts level 3',
            '### header text',
            [
              {
                name: 'p',
                children: [
                  {
                    name: 'pPr',
                    children: [
                      {
                        name: 'pStyle',
                        val: DocxObject.paragraph_style_mappings['header-3'][:id]
                      },
                    ]
                  },
                  { name: 'r' },
                  {
                    name: 'r',
                    inner_text: 'header text',
                  },
                ]
              }
            ]
          ],
        ].each do |test_attrs|
          desc, test_string, expect = *test_attrs
          it desc do
            doc = Document.new(test_string, :input => 'KramdownRepositext')
            xml_nodes_match_attrs(
              extract_block_els_in_docx(doc.to_docx_object),
              expect
            ).must_be(:empty?)
          end
        end

        it "Raises on header level 4" do
          doc = Document.new("#### header level 4", :input => 'KramdownRepositext')
          proc{
            doc.to_docx_object
          }.must_raise Docx::InvalidElementException
        end

      end

      describe '#convert_hr' do

        [
          [
            'Regular hr',
            "* * *",
            [
              {
                name: 'p',
                children: [
                  {
                    name: 'pPr',
                    children: [
                      {
                        name: 'pStyle',
                        val: DocxObject.paragraph_style_mappings['hr'][:id]
                      },
                    ]
                  },
                ]
              }
            ]
          ],
        ].each do |test_attrs|
          desc, test_string, expect = *test_attrs
          it desc do
            doc = Document.new(test_string, :input => 'KramdownRepositext')
            xml_nodes_match_attrs(
              extract_block_els_in_docx(doc.to_docx_object),
              expect
            ).must_be(:empty?)
          end
        end

      end

      describe '#convert_p' do

        [
          [
            'Without IAL',
            'paragraph text',
            [
              {
                name: 'p',
                children: [
                  {
                    name: 'pPr',
                    children: [
                      { name: 'contextualSpacing', val: "0" },
                    ]
                  },
                  { name: 'r' },
                  {
                    name: 'r',
                    inner_text: 'paragraph text',
                  },
                ]
              }
            ]
          ],
          [
            'With IAL',
            "paragraph text\n{: .test}",
            [
              {
                name: 'p',
                children: [
                  {
                    name: 'pPr',
                    children: [
                      {
                        name: 'pStyle',
                        val: DocxObject.paragraph_style_mappings['p.test'][:id]
                      },
                    ]
                  },
                  { name: 'r' },
                  {
                    name: 'r',
                    inner_text: 'paragraph text',
                  },
                ]
              }
            ]
          ],
        ].each do |test_attrs|
          desc, test_string, expect = *test_attrs
          it desc do
            doc = Document.new(test_string, :input => 'KramdownRepositext')
            xml_nodes_match_attrs(
              extract_block_els_in_docx(doc.to_docx_object),
              expect
            ).must_be(:empty?)
          end
        end

        it "Raises on invalid para class" do
          doc = Document.new("word\n{: .invalid_class}", :input => 'KramdownRepositext')
          proc{
            doc.to_docx_object
          }.must_raise Docx::InvalidElementException
        end

      end

      describe '#convert_record_mark' do

        [
          [
            'Record marks are dropped',
            "^^^{: .rid}\n\nword\n\n",
            [
              {
                name: 'p',
                children: [
                  { name: 'pPr' },
                  { name: 'r' },
                  {
                    name: 'r',
                    inner_text: 'word',
                  },
                ]
              }
            ]
          ],
        ].each do |test_attrs|
          desc, test_string, expect = *test_attrs
          it desc do
            doc = Document.new(test_string, :input => 'KramdownRepositext')
            xml_nodes_match_attrs(
              extract_block_els_in_docx(doc.to_docx_object),
              expect
            ).must_be(:empty?)
          end
        end

        it "Raises on invalid para class" do
          doc = Document.new("word\n{: .invalid_class}", :input => 'KramdownRepositext')
          proc{
            doc.to_docx_object
          }.must_raise Docx::InvalidElementException
        end

      end

      describe '#convert_strong' do

        [
          [
            'Without IAL',
            '**strong**',
            [
              {
                name: 'p',
                children: [
                  { name: 'pPr' },
                  { name: 'r' },
                  {
                    name: 'r',
                    children: [
                      {
                        name: 'rPr',
                        children: [{ name: 'b', val: '1' }]
                      }
                    ],
                    inner_text: 'strong',
                  },
                ]
              }
            ]
          ],
        ].each do |test_attrs|
          desc, test_string, expect = *test_attrs
          it desc do
            doc = Document.new(test_string, :input => 'KramdownRepositext')
            xml_nodes_match_attrs(
              extract_block_els_in_docx(doc.to_docx_object),
              expect
            ).must_be(:empty?)
          end
        end

      end

      describe '#convert_subtitle_mark' do

        [
          [
            'Should get dropped',
            'word @word',
            [
              {
                name: 'p',
                children: [
                  { name: 'pPr' },
                  { name: 'r' },
                  {
                    name: 'r',
                    inner_text: 'word ',
                  },
                  {
                    name: 'r',
                    inner_text: 'word',
                  },
                ]
              }
            ]
          ],
        ].each do |test_attrs|
          desc, test_string, expect = *test_attrs
          it desc do
            doc = Document.new(test_string, :input => 'KramdownRepositext')
            xml_nodes_match_attrs(
              extract_block_els_in_docx(doc.to_docx_object),
              expect
            ).must_be(:empty?)
          end
        end

      end

    end
  end
end
