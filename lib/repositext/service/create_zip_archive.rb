class Repositext
  class Service
    # Recursively generates a zip file from the contents of input_dir. The
    # directory itself is not included in the archive, just its contents.
    #
    # Usage:
    #   Repositext::Service::CreateZipArchive.call(
    #     input_dir: "/tmp/input",
    #     output_file: "/path/to/out.zip"
    #   )
    class CreateZipArchive

      # @param attrs [Hash{Symbol => Object}]
      # @option attrs [String] :input_dir absolute path to containing dir, will not be included.
      # @option attrs [String] :output_file absolute path to resulting ZIP archive.
      # @option attrs [Regexp] :reject_filenames_regex any filenames matching this won't be included.
      # @return [Hash{success: Boolean, messages: Array<String>}]
      def self.call(attrs)
        new(attrs).write
      end

      # Initialize with the directory to zip and the location of the output archive.
      def initialize(attrs)
        @input_dir = attrs[:input_dir]
        @output_file = attrs[:output_file]
        @reject_filenames_regex = attrs[:reject_filenames_regex]
      end

      # Zip the input directory.
      def write
        entries = Dir.entries(@input_dir) - %w(. ..)

        ::Zip::File.open(@output_file, ::Zip::File::CREATE) do |io|
          write_entries(entries, '', io)
        end
      end

    protected

      # A helper method to make the recursion work.
      def write_entries(entries, path, io)
        entries.each do |e|
          zip_file_path = path == '' ? e : File.join(path, e)
          disk_file_path = File.join(@input_dir, zip_file_path)
          if File.directory?(disk_file_path)
            recursively_deflate_directory(disk_file_path, io, zip_file_path)
          elsif include_filename?(zip_file_path)
            put_into_archive(disk_file_path, io, zip_file_path)
          end
        end
      end

      def include_filename?(filename)
        @reject_filenames_regex.nil? || filename !~ @reject_filenames_regex
      end

      def recursively_deflate_directory(disk_file_path, io, zip_file_path)
        io.mkdir(zip_file_path)
        subdir = Dir.entries(disk_file_path) - %w(. ..)
        write_entries(subdir, zip_file_path, io)
      end

      def put_into_archive(disk_file_path, io, zip_file_path)
        io.get_output_stream(zip_file_path) do |f|
          f.write(File.open(disk_file_path, 'rb').read)
        end
      end
    end
  end
end
