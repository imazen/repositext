class Repositext
  class RFile

    # Represents a collection of RFiles. Instead of subclassing Array, we
    # compose it based on this blog post:
    # http://words.steveklabnik.com/beware-subclassing-ruby-core-classes
    # coll is expected to be an Array of RFiles that mix in FollowStandardFilenameConvention
    class Collection

      extend Forwardable
      # Methods can safely delegate to @coll (instance of Array)
      # There may be methods we have to define here, e.g., #reverse like so:
      #   def reverse
      #     Collection.new(@coll.reverse)
      #   end
      # So that it returns an instance of Collection, and not Array.
      def_delegators :@coll, :count

      # Initialize new instance of self for content_type, file_selector, and
      # date_codes. Collection is the intersection of file_selector and date_codes.
      # @param content_type [ContentType]
      # @param file_selector [String]
      # @param limit_to_piids [Array<String>] An array of product_identity ids
      #   to limit the collection to. This would typically come from ERP.
      #   piids don't have leading zeroes.
      def self.from_content_type_and_file_selector_and_piids(
        content_type,
        file_selector,
        limit_to_piids
      )
        effective_file_selector = if '' == file_selector.to_s.strip
          '**/*.at'
        else
          # guarantee that file selector ends with '.at'
          file_selector.sub(/\.at\z/, '') + '.at'
        end

        # Add leading zeroes where they don't exist yet
        piids = limit_to_piids.map { |piid| piid.rjust(4, '0') }.sort
        # Optimize: This is O(N^2)
        filtered_filenames = Dir.glob(
          File.join(
            content_type.repository.base_dir,
            "ct-#{ content_type.name }",
            'content',
            effective_file_selector
          )
        ).find_all { |filename|
          piids.any? { |piid|
            # Use rindex for better performance
            filename.rindex("_#{ piid }.")
          }
        }

        new(
          filtered_filenames.map { |filename|
            RFile::ContentAt.new(
              File.read(filename),
              content_type.language,
              filename,
              content_type
            )
          }
        )
      end

      def initialize(coll = [])
        @coll = coll
      end

      def basenames
        @coll.map { |e| e.basename }
      end

      def date_codes
        @coll.map { |e| e.extract_date_code }
      end

      # @param options [Hash]
      # @option options [String] :extension to limit the file selector to given
      #   extension. Must contain preceding period, example: extension: '.at'
      def to_file_selector(options={})
        if date_codes.any?
          # Create glob pattern containing all included date_codes
          [
            "**/*{",
            date_codes.join(','),
            "}*",
            options[:extension]
          ].compact.join
        else
          # Create glob pattern that won't match anything
          %(*____this_should_not_match_anything____*)
        end
      end

    end
  end
end

module AwesomePrint
  module RFileCollection
    def self.included(base)
      base.send :alias_method, :cast_without_r_file_collection, :cast
      base.send :alias_method, :cast, :cast_with_r_file_collection
    end

    def cast_with_r_file_collection(object, type)
      cast = cast_without_r_file_collection(object, type)
      if (defined?(::Repositext::RFile::Collection)) && (object.is_a?(::Repositext::RFile::Collection))
        cast = :r_file_collection_instance
      end
      cast
    end

    def awesome_r_file_collection_instance(object)
      "<#{object.class} with #{ object.count } #{ 1 == object.count ? 'entry' : 'entries' }>"
    end
  end
end

AwesomePrint::Formatter.send(:include, AwesomePrint::RFileCollection)
