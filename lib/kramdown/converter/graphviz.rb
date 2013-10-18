# -*- coding: utf-8 -*-
require 'kramdown/converter'
require 'ruby-graphviz'

module Kramdown
  module Converter
    class Graphviz < Base

      # Create a Graphviz converter with the given options.
      # @param[Kramdown::Element] root
      # @param[Hash, optional] options
      def initialize(root, options = {})
        super
        @options = {
          :graphviz_output_file => "kramdown_parse_tree.png",
          :max_children => 20,
          :max_value_length => 20
        }.merge(options)
        @graph = GraphViz::new('Kramdown Document Tree', { :nodesep => 0.1, :ranksep => 1.0 })
      end

      def convert(el)
        # Convert all elements to graph
        @obj_counter = 0
        convert_element(el)
        # Generate output image
        @graph.output(:png => @options[:graphviz_output_file])
      end

    protected

      # Converts el to a graph node, connects parents and children via edges
      # @param[Kramdown::Element] el
      # @param[Graphviz::Node, optional] parent_node
      def convert_element(el, parent_node = nil)
        @obj_counter += 1
        el_value = el.value || ''
        if el_value.length > @options[:max_value_length]
          # long string, truncate in the middle, preserve start and end.
          half_len = @options[:max_value_length]/2
          el_value = "#{ el_value[0..half_len] }...#{ el_value[(-1 * half_len)..-1] }"
        end
        el_value = el_value.length > 0 ? el_value.inspect : nil
        node_label = [
          ":#{el.type}",
          (el.attr.inspect  if el.attr && el.attr.any?),
          (el.options.inspect  if el.options && el.options.any?),
          el_value
        ].compact.join("\n")
        current_node = @graph.add_nodes("node #{@obj_counter}", :label => node_label, :shape => 'box')
        @graph.add_edges(parent_node, current_node)  if parent_node
        # limit recursion to keep PNG file manageable.
        el.children[0..(@options[:max_children] - 1)].each do |child|
          convert_element(child, current_node)
        end
      end

    end
  end
end
