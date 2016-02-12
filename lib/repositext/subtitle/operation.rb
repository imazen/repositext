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
        class_name = case attrs[:operationType].to_sym
        when :contentChange
          'ContentChange'
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
          raise "Invalid operationType: #{ attrs[:operationType.inspect] }"
        end
        Object.const_get(
          ['Repositext', 'Subtitle', 'Operation', class_name].join('::')
        ).new(attrs)
      end

      # @param attrs [Hash] with keys
      # @option attrs [Array<Repositext::Subtitle>] :affectedStids
      # @option attrs [String] :operationId
      # @option attrs [Array<Hash>] :operationType
      def initialize(attrs)
        ATTR_NAMES.each { |attr_name|
          self.send("#{ attr_name }=", attrs[attr_name])
        }
        self.affectedStids = attrs[:affectedStids]
      end

      # Returns the inverse operation of self
      # @return [Operation]
      def inverse_operation
        raise "Implement me in sub class"
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
