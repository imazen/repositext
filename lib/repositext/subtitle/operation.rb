class Repositext
  class Subtitle

    # Represents a single Subtitle::Operation.
    #
    # Can be imported from and exported to hash
    #
    # @abstract
    #
    class Operation

      attr_accessor :affectedStids

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
        when :moveLeft
          'MoveLeft'
        when :moveRight
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

      # Returns persistent ids of added subtitles
      # @return [Array<String>]
      def added_subtitle_ids
        return []  unless %w[insert split].include?(operationType)
        affectedStids.inject([]) { |m,e|
          m << e.persistent_id  if '' == e.tmp_before.to_s
          m
        }
      end

      # Returns persistent ids of deleted subtitles
      # @return [Array<String>]
      def deleted_subtitle_ids
        return []  unless %w[delete merge].include?(operationType)
        affectedStids.inject([]) { |m,e|
          m << e.persistent_id  if '' == e.tmp_after.to_s
          m
        }
      end

      # Returns the inverse operation of self
      # @return [Operation]
      def inverse_operation
        raise "Implement me in sub class"
      end

      # Returns true if self is an insert or delete
      def adds_or_removes_subtitle?
        %w[insert split delete merge].include?(operationType)
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
