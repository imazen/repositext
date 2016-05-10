class Repositext
  class Process
    class Compute

      # Computes subtitle operations for an entire repository. Going from
      # git commit `fromGitCommit` to git commit `toGitCommit`.
      class SubtitleOperationsForRepository

        # Initializes a new instance from high level objects.
        # @param repository [Repositext::Repository::Content]
        # @param fromGitCommit [String]
        # @param toGitCommit [String]
        # @param file_list [Array<String>] path to files to include
        def initialize(repository, fromGitCommit, toGitCommit, file_list)
          @repository = repository
          @fromGitCommit = fromGitCommit
          @toGitCommit = toGitCommit
          # Convert to repo relative paths
          @file_list = file_list.map { |e| e.gsub!(@repository.base_dir, '') }
        end

        # @return [Repositext::Subtitle::OperationsForRepository]
        def compute
          puts " - Computing diff from #{ @fromGitCommit.first(10) } to #{ @toGitCommit.first(10) }"
          diff = @repository.diff(@fromGitCommit, @toGitCommit, context_lines: 0)
          puts " - Processing content files"
          puts # to move cursor down one line because we'll move it back up further down
          operations_for_all_files = diff.patches.map { |patch|
            file_name = patch.delta.old_file[:path]
            if !@file_list.include?(file_name)
              # print "\r - skipping #{ file_name }                                      "
              print "\033[1A"
              print "\033[K"
              puts "   - skipping #{ file_name }"
              next nil
            end
            # Skip non content_at files
            unless file_name =~ /\Acontent\/.+\d{4}\.at\z/
              raise "shouldn't get here"
            end
            # print "\r - processing #{ file_name }                                      "
            print "\033[1A"
            print "\033[K"
            puts "   - processing #{ file_name }"
            file_path = File.join(@repository.base_dir, file_name)
            content_at_file = Repositext::RFile::ContentAt.new(
              File.read(file_path),
              @content_type.language,
              file_path,
              @repository
            )
            SubtitleOperationsForFile.new_from_content_at_file_and_patch(
              content_at_file,
              patch
            ).compute
          }.compact

          Repositext::Subtitle::OperationsForRepository.new(
            {
              repository: @repository.name,
              fromGitCommit: @fromGitCommit,
              toGitCommit: @toGitCommit,
            },
            operations_for_all_files
          )
        end

      end

    end
  end
end
