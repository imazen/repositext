class Repositext
  class Subtitle

    # Represents a single Subtitle::Operation.
    #
    # Can be imported from and exported to hash
    #
    # @abstract
    class Operation

      attr_accessor :affected_stids # [Array<Repositext::Subtitle>]

      ATTR_NAMES = [:after_stid, :operation_id, :operation_type]
      attr_accessor(*ATTR_NAMES)

      # Instantiates a new instance of self from a Hash
      # @param attrs [Hash]
      # @option attrs [String] :operation_type
      # @option attrs [String] :operation_id
      # @option attrs [Array<Hash>] :affected_stids
      # @return [Operation]
      def self.new_from_hash(attrs)
        new_attrs = attrs.dup
        class_name = case new_attrs[:operation_type].to_sym
        when :content_change
          'ContentChange'
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
        when :record_id_change
          'RecordIdChange'
        when :split
          'Split'
        else
          raise "Invalid operation_type: #{ new_attrs[:operation_type.inspect] }"
        end
        new_attrs[:affected_stids] = new_attrs[:affected_stids].map { |hash_or_subtitle|
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
      # @option attrs [Array<Repositext::Subtitle>] :affected_stids
      # @option attrs [String] :operation_id
      # @option attrs [Array<Hash>] :operation_type
      def initialize(attrs)
        if(astid = attrs[:affected_stids].first) && !astid.is_a?(Repositext::Subtitle)
          raise ArgumentError.new("Invalid first affectedStid: #{ astid.inspect }")
        end
        ATTR_NAMES.each { |attr_name|
          self.send("#{ attr_name }=", attrs[attr_name])
        }
        self.affected_stids = attrs[:affected_stids]
      end

      # Returns true if other_obj has the same class, operation_id, and affected_stids.
      # @param other_obj [Object]
      def ==(other_obj)
        other_obj.class == self.class &&
        other_obj.operation_id == operation_id &&
        other_obj.affected_stids == affected_stids
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
        return []  unless %w[insert split].include?(operation_type)
        r = affected_stids.inject([]) { |m,e|
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
        %w[insert split delete merge].include?(operation_type)
      end

      # Returns persistent ids of deleted subtitles
      # @return [Array<String>]
      def deleted_subtitle_ids
        return []  unless %w[delete merge].include?(operation_type)
        r = affected_stids.inject([]) { |m,e|
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
        operation_id.split('-').first
      end

      # Returns the inverse operation of self
      # @return [Operation]
      def inverse_operation
        raise "Implement me in sub class"
      end

      # Returns nicely formatted representation of self as String.
      # NOTE: Don't call this method #pretty_print as it conflicts with pp
      def print_pretty
        to_hash.ai(indent: -2)
      end

      # Returns the subtitle to be reviewed after self has been applied
      # @return [Subtitle]
      def salient_subtitle
        # TODO: handle deletes and inserts!
        if 'merge' == operation_type
          affected_stids.first
        else
          affected_stids.last
        end
      end

      # Converts self to Hash
      # @return [Hash]
      def to_hash
        r = ATTR_NAMES.inject({}) { |m,e|
          # Record :after_stid only if it's not null
          if :after_stid != e || self.send(e)
            m[e] = self.send(e)
          end
          m
        }
        r[:affected_stids] = affected_stids.map { |e| e.to_hash }
        r
      end
    end
  end
end
