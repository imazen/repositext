class Repositext
  class Service
    # Computes the alignment score for two subtitles using their stid.
    #
    # Usage:
    #   Repositext::Service::ScoreSubtitleAlignmentUsingStid.call(
    #     left_stid: "1234",
    #     right_stid: "2345",
    #     default_gap_penalty: -10
    #   )[:result]
    class ScoreSubtitleAlignmentUsingStid

      # @param attrs [Hash{Symbol => Object}]
      # @option attrs [String] :left_stid
      # @option attrs [String] :right_stid
      # @option attrs [Numeric] :default_gap_penalty
      # @return [Hash{result: Numeric}]
      def self.call(attrs)
        # A mismatch scores worse than a gap!
        s = if attrs[:left_stid] == attrs[:right_stid]
          10
        else
          attrs[:default_gap_penalty] * 1.1
        end
        { result: s }
      end

    end
  end
end
