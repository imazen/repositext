class Repositext
  class Process
    class Delete
      class DirectoryContents

        # Deletes all contents inside of directory_path
        # @param directory_path [String] path to the containing directory.
        #   This will not get deleted.
        def self.delete(directory_path)
          raise ":directory_path option is required"  if directory_path.nil?
          puts "Deleting all files under #{ directory_path }"
          FileUtils.rm_rf(
            Dir.glob("#{ directory_path }/*"),
            secure: true
          )
        end
      end
    end
  end
end
