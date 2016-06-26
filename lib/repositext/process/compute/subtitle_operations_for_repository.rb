class Repositext
  class Process
    class Compute

      # Computes subtitle operations for an entire repository. Going from
      # git commit `fromGitCommit` to git commit `toGitCommit`.
      class SubtitleOperationsForRepository

        # Initializes a new instance from high level objects.
        # @param content_type [Repositext::ContentType]
        # @param fromGitCommit [String]
        # @param toGitCommit [String]
        # @param file_list [Array<String>] path to files to include
        def initialize(content_type, fromGitCommit, toGitCommit, file_list)
          @content_type = content_type
          @repository = @content_type.repository
          @language = @content_type.language
          @fromGitCommit = fromGitCommit
          @toGitCommit = toGitCommit
          # Convert to repo relative paths
          @file_list = file_list.map { |e| e.sub!(@repository.base_dir, '') }
        end

        # @return [Repositext::Subtitle::OperationsForRepository]
        def compute
          puts " - Computing diff from #{ @fromGitCommit.first(10) } to #{ @toGitCommit.first(10) }"

          if @repository.latest_commit_sha_local != @toGitCommit
            raise ArgumentError.new(
              [
                "`toGitCommit` is not the latest commit in repo. We haven't confirmed that this works!",
                "Latest git commit: #{ @repository.latest_commit_sha_local.inspect }",
                "toGitCommit: #{ @toGitCommit.inspect }",
              ]
            )
          end

          diff = @repository.diff(@fromGitCommit, @toGitCommit, context_lines: 0)

          puts " - Processing content_at files"
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
            unless file_name =~ /\/content\/.+\d{4}\.at\z/
              raise "shouldn't get here"
            end

            # print "\r - processing #{ file_name }                                      "
            print "\033[1A"
            print "\033[K"
            puts "   - processing #{ file_name }"
            # We use the versions of content AT file and STM CSV file as they
            # existed at `fromGitCommit`.
            content_at_file_at_from_commit = Repositext::RFile::ContentAt.new(
              `git --no-pager show #{ @fromGitCommit }:#{ file_name }`,
              @language,
              File.join(@repository.base_dir, file_name),
              @content_type
            )

            stm_csv_filename = content_at_file_at_from_commit.corresponding_subtitle_markers_csv_file.repo_relative_path
            stm_csv_file_at_from_commit = Repositext::RFile::SubtitleMarkersCsv.new(
              `git --no-pager show #{ @fromGitCommit }:#{ stm_csv_filename }`,
              @language,
              stm_csv_filename,
              @content_type
            )
            soff = SubtitleOperationsForFile.new_from_content_at_file_and_patch(
              content_at_file_at_from_commit,
              stm_csv_file_at_from_commit,
              patch,
              @repository.base_dir
            ).compute

            # Return nil if no subtitle operations exist for this file
            soff.operations.any? ? soff : nil
          }.compact

          ofr = Repositext::Subtitle::OperationsForRepository.new(
            {
              repository: @repository.name,
              fromGitCommit: @fromGitCommit,
              toGitCommit: @toGitCommit,
            },
            operations_for_all_files
          )

          ofr
        end

      end

    end
  end
end
