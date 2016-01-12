class Repositext
  class Subtitle

    # Represents all Subtitle::IndexToIdMappings at the to-end of a single git
    # diff for all files in a repository.
    #
    # Can be serialized to and from a JSON file
    #
    class IndexToIdMappingsForRepository

      ATTR_NAMES = [:fromGitCommit, :repository, :toGitCommit]

      attr_accessor :mappings_for_files
      attr_accessor *ATTR_NAMES

      # @param attrs [Hash]
      #   {
      #     repository: 'english',
      #     fromGitCommit: '1234',
      #     toGitCommit: '2345',
      #   }
      # @param mappings_for_files [Array<Repositext::Subtitle::IndexToIdMappingsForFile>]
      def initialize(attrs, mappings_for_files)
        ATTR_NAMES.each do |attr_name|
          self.send("#{ attr_name }=", attrs[attr_name])
        end
        self.mappings_for_files = mappings_for_files
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
        r[:files] = mappings_for_files.map { |e| e.to_hash }
        r
      end

    end

  end
end
