module Kramdown

  # Computes the structural similarity of two kramdown trees.
  class TreeStructuralSimilarity

    # @param ref_doc [Kramdown::Document]
    # @param other_doc [Kramdown::Document]
    def initialize(ref_doc, other_doc)
      @ref_doc = ref_doc
      @other_doc = other_doc
    end

    # @return [Hash{Symbol: Float}]
    def compute
      @ref_structure = TreeStructureExtractor.new(@ref_doc).extract
      @other_structure = TreeStructureExtractor.new(@other_doc).extract
      {
        character_count_similarity: character_count_similarity,
        paragraph_count_similarity: paragraph_count_similarity,
        paragraph_numbers_similarity: paragraph_numbers_similarity,
        record_count_similarity: record_count_similarity,
        record_ids_similarity: record_ids_similarity,
        subtitle_count_similarity: subtitle_count_similarity,
      }
    end

    # Similarity computations
    def character_count_similarity
      compute_count_similarity(
        @ref_structure[:character_count],
        @other_structure[:character_count],
      )
    end

    def paragraph_count_similarity
      compute_count_similarity(
        @ref_structure[:paragraph_count],
        @other_structure[:paragraph_count],
      )
    end

    def paragraph_numbers_similarity
      compute_sequence_similarity(
        @ref_structure[:paragraph_numbers].map { |e| e[:paragraph_number] },
        @other_structure[:paragraph_numbers].map { |e| e[:paragraph_number] },
      )
    end

    def record_count_similarity
      compute_count_similarity(
        @ref_structure[:record_count],
        @other_structure[:record_count],
      )
    end

    def record_ids_similarity
      compute_sequence_similarity(
        @ref_structure[:record_ids].map { |e| e[:record_id] },
        @other_structure[:record_ids].map { |e| e[:record_id] },
      )
    end

    def subtitle_count_similarity
      compute_count_similarity(
        @ref_structure[:subtitle_count],
        @other_structure[:subtitle_count],
      )
    end

  private

    # Returns 1.0 if both counts are identical.
    # Returns < 1.0 if counts are different.
    # It doesn't matter which one is larger.
    # Later stages require similarity to be between 0 and 1.
    def compute_count_similarity(ref_count, other_count)
      return 1.0  if ref_count == other_count
      return 0  if 0 == ref_count.to_f
      delta = (ref_count - other_count).abs
      1 - (delta / ref_count.to_f)
    end

    # Returns 1.0 if both sequences are identical
    # Returns < 1.0 if sequences are different
    # Uses Jaccard index to compute similarity
    # http://en.wikipedia.org/wiki/Jaccard_index
    def compute_sequence_similarity(ref_sequence, other_sequence)
      total = Repositext::Utils::ArrayDiffer.diff(ref_sequence, other_sequence)
      same = total.find_all { |e| '=' == e.action }
      return 1.0  if same.length == total.length
      return 0.0  if 0 == total.length
      same.length / total.length.to_f
    end

    # # Returns 1.0 if both sets are identical
    # # Returns < 1.0 if sets are different
    # # Uses Jaccard index to compute similarity
    # # http://en.wikipedia.org/wiki/Jaccard_index
    # def compute_set_similarity(ref_set, other_set)
    #   return 1.0  if ref_set == other_set
    #   (ref_set & other_set).length / (ref_set | other_set).length.to_f
    # end

  end
end
