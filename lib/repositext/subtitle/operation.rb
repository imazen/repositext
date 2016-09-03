class Repositext
  class Subtitle

    # Represents a single Subtitle::Operation.
    #
    # Can be imported from and exported to hash
    #
    # @abstract
    #
    class Operation

      attr_accessor :affectedStids # [Array<Repositext::Subtitle>]

      ATTR_NAMES = [:operationId, :operationType, :afterStid]
      attr_accessor *ATTR_NAMES

      # Instantiates a new instance of self from a Hash
      # @param attrs [Hash]
      # @option attrs [String] :operationType
      # @option attrs [String] :operationId
      # @option attrs [Array<Hash>] :affectedStids
      # @return [Operation]
      def self.new_from_hash(attrs)
        new_attrs = attrs.dup
        class_name = case new_attrs[:operationType].to_sym
        when :delete
          'Delete'
        when :insert
          'Insert'
        when :merge
          'Merge'
        when :move_left
          'MoveLeft'
        when :move_right
          'MoveRight'
        when :split
          'Split'
        else
          raise "Invalid operationType: #{ new_attrs[:operationType.inspect] }"
        end
        new_attrs[:affectedStids] = new_attrs[:affectedStids].map { |hash_or_subtitle|
          case hash_or_subtitle
          when Hash
            Repositext::Subtitle.from_hash(hash_or_subtitle)
          when Repositext::Subtitle
            hash_or_subtitle
          else
            raise "Handle this: #{ hash_or_subtitle.inspect }"
          end
        }
        Object.const_get(
          ['Repositext', 'Subtitle', 'Operation', class_name].join('::')
        ).new(new_attrs)
      end

      # @param attrs [Hash] with keys
      # @option attrs [Array<Repositext::Subtitle>] :affectedStids
      # @option attrs [String] :operationId
      # @option attrs [Array<Hash>] :operationType
      def initialize(attrs)
        if(astid = attrs[:affectedStids].first) && !astid.is_a?(Repositext::Subtitle)
          raise ArgumentError.new("Invalid first affectedStid: #{ astid.inspect }")
        end
        ATTR_NAMES.each { |attr_name|
          self.send("#{ attr_name }=", attrs[attr_name])
        }
        self.affectedStids = attrs[:affectedStids]
      end

      # Returns true if other_obj has the same class, operationId, and affectedStids.
      # @param other_obj [Object]
      def ==(other_obj)
        other_obj.class == self.class &&
        other_obj.operationId == operationId &&
        other_obj.affectedStids == affectedStids
      end

      # Returns persistent ids of added subtitles. Temporary stids are combined
      # with the hunk index so that they are unique at the file scope.
      # Example: 'tmp-hunk_start+1' => '17-tmp-hunk_start+1'.
      # This is necessary so that when we tally up subtitles in
      # Subtitle::OperationsForFile#subtitles_count_delta we don't collapse
      # subtitles with same stid (e.g., 'tmp-hunk_start+1') from different hunks.
      # This would result in incorrect counts.
      # @return [Array<String>]
      def added_subtitle_ids
        return []  unless %w[insert split].include?(operationType)
        r = affectedStids.inject([]) { |m,e|
          before = e.tmp_before.to_s.strip
          pers_id = e.persistent_id.to_s
          if '' == before || before =~ /\A\^\^\^ {: \.rid/
            res = if pers_id.index('tmp-hunk_start')
              # add hunk index
              [hunk_index, pers_id].join('-')
            else
              # use as is
              pers_id
            end
            m << res
          end
          m
        }
      end

      # Returns true if self is an insert or delete
      def adds_or_removes_subtitle?
        %w[insert split delete merge].include?(operationType)
      end

      # Returns persistent ids of deleted subtitles
      # @return [Array<String>]
      def deleted_subtitle_ids
        return []  unless %w[delete merge].include?(operationType)
        r = affectedStids.inject([]) { |m,e|
          after = e.tmp_after.to_s.strip
          pers_id = e.persistent_id.to_s
          if '' == after || after =~ /\A\^\^\^ {: \.rid/
            res = if pers_id.index('tmp-hunk_start')
              # add hunk index
              [hunk_index, pers_id].join('-')
            else
              # use as is
              pers_id
            end
            m << res
          end
          m
        }
      end

      # Returns this operation's hunk index, i.e. the index of the generating
      # diff hunk in the file.
      # @return [String]
      def hunk_index
        # Get first part of '5-3' (first number is hunk index in file, second
        # number is subtitle index in hunk).
        operationId.split('-').first
      end

      # Returns the inverse operation of self
      # @return [Operation]
      def inverse_operation
        raise "Implement me in sub class"
      end

      # Returns nicely formatted representation of self as String.
      # NOTE: Don't call this method #pretty_print as it conflicts with pp
      def print_pretty
        PP.pp(to_hash, "")
      end

      # Returns the subtitle to be reviewed after self has been applied
      # @return [Subtitle]
      def salient_subtitle
        # TODO: handle deletes and inserts!
        if 'merge' == operationType
          affectedStids.first
        else
          affectedStids.last
        end
      end

      # Converts self to Hash
      # @return [Hash]
      def to_hash
        r = ATTR_NAMES.inject({}) { |m,e|
          m[e] = self.send(e)
          m
        }
        r[:affectedStids] = affectedStids.map { |e| e.to_hash }
        r
      end
    end
  end
end
