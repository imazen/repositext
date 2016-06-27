class Repositext
  class Subtitle

    # Represents all Subtitle::Operations resulting from a single git diff for
    # a single file.
    #
    # Can be serialized to and from a JSON file
    #
    class OperationsForFile

      include CanBeAppliedToSubtitles

      ATTR_NAMES = [:file_path]

      attr_accessor :content_at_file, :operations
      attr_accessor *ATTR_NAMES

      # Instantiates a new instance of self from json string
      # @param content_at_file [RFile::ContentAt]
      # @param json [String]
      # @return [OperationsForFile]
      def self.from_json(content_at_file, json)
        hash = JSON.parse(json, symbolize_names: true)
        new_from_hash(content_at_file, hash)
      end

      # Instantiates a new instance of self from a Hash
      # @param content_at_file [RFile::ContentAt]
      # @param hash [Hash]
      # @return [OperationsForFile]
      def self.from_hash(content_at_file, hash)
        ops = hash.delete(:operations)
        new(
          content_at_file,
          hash,
          ops.map { |op_hash|
            Operation.new_from_hash(op_hash)
          }
        )
      end

      # @param content_at_file [Repositext::RFile::ContentAt] at :fromGitCommit
      # @param attrs [Hash] with keys
      # @option attrs [String] :fromGitCommit
      # @option attrs [String] :toGitCommit
      # @option attrs [String] :file_path
      # @param operations [Array<Subtitle::Operation>]
      def initialize(content_at_file, attrs, operations)
        if !content_at_file.is_a?(Repositext::RFile::ContentAt)
          raise ArgumentError.new("Invalid content_at_file: #{ content_at_file.inspect }")
        end
        if(st_op = operations.first) && !st_op.is_a?(Repositext::Subtitle::Operation)
          raise ArgumentError.new("Invalid first operation: #{ st_op.inspect }")
        end
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

      # Returns true if self contains any inserts or deletes
      def adds_or_removes_subtitles?
        operations.any? { |st_op| st_op.adds_or_removes_subtitle? }
      end

      # Returns all insert and split operations for self
      def insert_and_split_ops
        operations.find_all{ |op|
          %w[insert split].include?(op.operationType)
        }
      end

      def invert!
        # NOTE: We're not reverting `from` and `to` git commit as they are not
        # used in this context at all.
        self.operations = operations.map { |e| e.inverse_operation }
      end

      def lang_code_3_chars
        @content_at_file.lang_code_3
      end

      def product_identity_id
        @content_at_file.extract_product_identity_id
      end

      # Returns delta by how much subtitle count changes
      # @return [Integer]
      def subtitles_count_delta
        # We need to get each added/deleted subtitle's identity since each subtitle
        # may appear in affectedSubtitles of multiple operations.
        all_ids = operations.inject({ deleted: [], added: []}) { |m,e|
          m[:added] += e.added_subtitle_ids
          m[:deleted] += e.deleted_subtitle_ids
          m
        }
        all_ids[:added].uniq.length - all_ids[:deleted].uniq.length
      end

      # Converts self to Hash
      # @return [Hash]
      def to_hash
        r = ATTR_NAMES.inject({}) { |m,e|
          m[e] = self.send(e)
          m
        }
        r[:productIdentityId] = product_identity_id
        r[:language] = lang_code_3_chars
        r[:operations] = operations.map { |e| e.to_hash }
        r
      end

      # Serializes self to json
      # @return [String]
      def to_json
        #JSON.fast_generate(to_hash)
        JSON.pretty_generate(to_hash)
      end

    end
  end
end
