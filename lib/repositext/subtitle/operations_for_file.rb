class Repositext
  class Subtitle

    # Represents all Subtitle::Operations resulting from a single git diff for
    # a single file.
    #
    # Can be serialized to and from a JSON file
    #
    class OperationsForFile

      ATTR_NAMES = [:comments, :fromGitCommit, :toGitCommit]

      attr_accessor :content_at_file, :operations
      attr_accessor *ATTR_NAMES

      # Instantiates a new instance of self from json string
      # @param json [String]
      # @return [OperationsList]
      def self.from_json(json)
        data_structure = JSON.parse(json, symbolize_names: true)
        new_from_hash(data_structure)
      end

      # Instantiates a new instance of self from a Hash
      # @param attrs [Hash]
      def self.from_hash(attrs)
        ops = attrs.delete(:operations)
        new(attrs, ops)
      end

      # @param content_at_file [Repositext::RFile] at :fromGitCommit
      # @param attrs [Hash] with keys
      # @option attrs [String] :fromGitCommit
      # @option attrs [String] :toGitCommit
      # @option attrs [String] :comments for documentation
      # @param operations [Array<Subtitle::Operation>]
      def initialize(content_at_file, attrs, operations)
        @content_at_file = content_at_file
        ATTR_NAMES.each do |attr_name|
          self.send("#{ attr_name }=", attrs[attr_name])
        end
        # TODO Check for presence of fromGitCommit and toGitCommit
        if operations.nil?
          raise(ArgumentError.new("Nil operations given"))
        end
        self.operations = operations
      end

      def inverse!
        self.fromGitCommit, self.toGitCommit = [toGitCommit, fromGitCommit]
        self.operations = operations.map { |e| e.inverse_operation }
      end

      def product_identity_id
        @content_at_file.extract_product_identity_id
      end

      def lang_code_3_chars
        @content_at_file.lang_code_3
      end

      # Serializes self to json
      # @return [String]
      def to_json
        #JSON.fast_generate(to_hash)
        JSON.pretty_generate(to_hash)
      end

      # Converts self to Hash
      # @return [Hash]
      def to_hash
        r = ATTR_NAMES.inject({}) { |m,e|
          m[e] = self.send(e)
          m
        }
        r[:productIdentityId] = product_identity_id
        r[:langcode] = lang_code_3_chars
        r[:operations] = operations.map { |e| e.to_hash }
        r
      end

    end

  end
end
