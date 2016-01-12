class Repositext
  class Subtitle

    # Represents all Subtitle::Operations resulting from a single git diff for
    # all files in a repository.
    #
    # Can be serialized to and from a JSON file
    #
    class OperationsForRepository

      ATTR_NAMES = [:fromGitCommit, :repository, :toGitCommit]

      attr_accessor :operations_for_files
      attr_accessor *ATTR_NAMES

      # @param attrs [Hash]
      #   {
      #     repository: 'english',
      #     fromGitCommit: '1234',
      #     toGitCommit: '2345',
      #   }
      # @param operations_for_files [Array<Repositext::Subtitle::OperationsForFile>]
      def initialize(attrs, operations_for_files)
        ATTR_NAMES.each do |attr_name|
          self.send("#{ attr_name }=", attrs[attr_name])
        end
        self.operations_for_files = operations_for_files
      end

      def inverse!
        self.fromGitCommit, self.toGitCommit = [toGitCommit, fromGitCommit]
        self.operations_for_files = operations_for_files.map { |e| e.inverse!; e }
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
        r[:files] = operations_for_files.map { |e| e.to_hash }
        r
      end

    end

  end
end
