# -*- coding: utf-8 -*-
module Kramdown

  # Responsibilities
  # * Extracts kramdown_doc's structure (records, paragraphs, subtitles, etc.)
  # Collaborators
  # * Kramdown::Document
  class TreeStructureExtractor

    # @param kramdown_doc [Kramdown::Document]
    def initialize(kramdown_doc)
      @kramdown_doc = kramdown_doc
    end

    # Returns a Hash with the various metrics
    # :paragraph_numbers and :record_ids are hashes with the value and line info
    def extract
      {
        character_count: compute_character_count(@kramdown_doc),
        paragraph_count: compute_paragraph_count(@kramdown_doc),
        paragraph_numbers: compute_paragraph_numbers(@kramdown_doc),
        record_count: compute_record_count(@kramdown_doc),
        record_ids: compute_record_ids(@kramdown_doc),
        subtitle_count: compute_subtitle_count(@kramdown_doc),
      }
    end

    # Returns all elements relevant for record splitting as array
    def compute_sequence_for_record_splitting
      sequence_for_record_splitting_extractor(@kramdown_doc.root, [])
    end

  private

    def compute_character_count(doc)
      doc.to_kramdown_repositext.length
    end

    def compute_paragraph_count(doc)
      paragraph_counter(doc.root, 0)
    end

    def compute_paragraph_numbers(doc)
      paragraph_numbers_extractor(doc.root, [])
    end

    def compute_record_count(doc)
      record_counter(doc.root, 0)
    end

    def compute_record_ids(doc)
      record_id_extractor(doc.root, [])
    end

    def compute_subtitle_count(doc)
      doc.to_kramdown_repositext.count('@')
    end

    def paragraph_counter(tree, count)
      if :p == tree.type
        return count + 1
      else
        tree.children.each { |child| count = paragraph_counter(child, count) }
      end
      count
    end

    def paragraph_numbers_extractor(tree, paragraph_numbers)
      case tree.type
      when :p
        if (pn = pn_extractor(tree)) !~ /\A-/
          return paragraph_numbers << { paragraph_number: pn, line: tree.options[:location] }
        else
          return paragraph_numbers << { paragraph_number: 'no_number', line: tree.options[:location] }
        end
      when :header
        return paragraph_numbers << { paragraph_number: 'header', line: tree.options[:location] }
      when :hr
        return paragraph_numbers << { paragraph_number: 'horizontal_rule', line: tree.options[:location] }
      else
        tree.children.each { |child|
          paragraph_numbers_extractor(child, paragraph_numbers)
        }
      end
      paragraph_numbers
    end

    # @param tree [Kramdown::Element] the paragraph element with an em.pn child
    def pn_extractor(tree)
      em = tree.children.detect { |e| :em == e.type && e.has_class?('pn') }
      return '- no pn'  if em.nil?
      txt = em.children.detect { |e| :text == e.type }
      return '- empty pn'  if txt.nil?
      txt.value
    end

    def record_counter(tree, count)
      if :record_mark == tree.type
        return count + 1
      else
        tree.children.each { |child| count = record_counter(child, count) }
      end
      count
    end

    def record_id_extractor(tree, record_ids)
      if :record_mark == tree.type
        return record_ids << { record_id: tree.attr['id'], line: tree.options[:location] }
      else
        tree.children.each { |child| record_id_extractor(child, record_ids) }
      end
      record_ids
    end

    def sequence_for_record_splitting_extractor(tree, sequence)
      case tree.type
      when :header
        return sequence << { type: 'header', key: nil, line: tree.options[:location] }
      when :hr
        return sequence << { type: 'horizontal_rule', key: nil, line: tree.options[:location] }
      when :p
        if (pn = pn_extractor(tree)) !~ /\A-/
          return sequence << { type: 'paragraph', key: pn, line: tree.options[:location] }
        else
          return sequence << { type: 'paragraph', key: nil, line: tree.options[:location] }
        end
      when :record_mark
        return sequence << { type: 'record_mark', key: tree.attr['id'], line: tree.options[:location] }
      when :subtitle_mark
        return sequence << { type: 'subtitle_mark', key: nil, line: tree.options[:location] }
      else
      end
      tree.children.each { |child|
        sequence_for_record_splitting_extractor(child, sequence)
      }
      sequence
    end

  end
end
