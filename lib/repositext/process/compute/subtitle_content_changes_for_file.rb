class Repositext
  class Process
    class Compute

      # Computes content_changes to subtitles in content_at_file between
      # from_git_commit and to_git_commit.
      class SubtitleContentChangesForFile

        # @param content_at_file_shell [RFile::ContentAt] the contents of this
        #   file will be reset to from_git_commit and to_git_commit.
        # @param from_git_commit [String]
        # @param to_git_commit [String]
        def initialize(content_at_file_shell, from_git_commit, to_git_commit)
          @content_at_file_shell = content_at_file_shell
          @from_git_commit = from_git_commit
          @to_git_commit = to_git_commit
        end

        # @return [Hash{String => Object}, Nil]
        #   {
        #     "file_path": "ct-sermons/content/47/spn47-0412_0002.at",
        #     "product_identity_id": "0002",
        #     "subtitles": [
        #       {
        #         "stid": "1054463",
        #         "before": "And said, “…?… every…?… Christian…?… that stands on what…?… some kind…?… ",
        #         "after": "or something that will kill your fellowman.” ",
        #         "record_id": "47010099",
        #         "index": 77
        #       },
        def compute
          content_at_file_from = @content_at_file_shell.as_of_git_commit(@from_git_commit)
          # Early return if this is a new file and it didn't exist at from_git_commit.
          return nil  if content_at_file_from.nil?
          # Early return if content_at_file_from doesn't have any subtitle marks
          # (they were split some time between from and to git commit)
          return nil  if !content_at_file_from.has_subtitle_marks?
          subtitles_from = content_at_file_from.subtitles(
            with_content: true,
            content_format: :plain_text
          )

          content_at_file_to = @content_at_file_shell.as_of_git_commit(@to_git_commit)
          subtitles_to = content_at_file_to.subtitles(
            with_content: true,
            content_format: :plain_text
          )
          asps = align_subtitle_pairs(subtitles_from, subtitles_to)
          sts_with_changes = []
          asps.each { |(st_from, st_to)|
            st_changes = diff_subtitles_pair(st_from, st_to)
            next  if st_changes.nil?
            sts_with_changes << st_changes
          }
          {
            "file_path" => @content_at_file_shell.repo_relative_path,
            "product_identity_id" => @content_at_file_shell.extract_product_identity_id,
            "subtitles" => sts_with_changes
          }
        end

      protected

        # Aligns subtitles_from and subtitles_to based on stid.
        # @param subtitles_from [Array]
        # @param subtitles_to [Array]
        # @return [Array<Array>]
        def align_subtitle_pairs(subtitles_from, subtitles_to)
          total_subtitle_count_change = subtitles_to.length - subtitles_from.length
          diagonal_band_range = [
            (total_subtitle_count_change.abs * 1.2).round,
            25
          ].max
          aligner = SubtitleContentChangesForFile::SubtitleAligner.new(
            subtitles_from,
            subtitles_to,
            { diagonal_band_range: diagonal_band_range }
          )

          aligned_subtitles_from, aligned_subtitles_to = aligner.get_optimal_alignment
          aligned_subtitles_from.map { |st_from|
            st_to = aligned_subtitles_to.shift
            [st_from, st_to]
          }
        end

        # Returns a diff object if subtitle_from is different from subtitle_to.
        # Otherwise returns nil.
        # @param subtitle_from [Repositext::Subtitle]
        # @param subtitle_to [Repositext::Subtitle]
        # @return [Hash, Nil]
        #   {
        #     "stid": "1054463",
        #     "before": "And said, “…?… every…?… Christian…?… that stands on what…?… some kind…?… ",
        #     "after": "or something that will kill your fellowman.” ",
        #     "record_id": "47010099",
        #     "index": 77
        #   }
        def diff_subtitles_pair(subtitle_from, subtitle_to)
          if subtitle_from && subtitle_to
            # Both exist
            if(
              (subtitle_from.content != subtitle_to.content) ||
              (subtitle_from.record_id != subtitle_to.record_id)
            )
              # They are different, return diff object
              {
                "stid": subtitle_from.persistent_id,
                "before": subtitle_from.content.sub(/\A@/, ''),
                "after": subtitle_to.content.sub(/\A@/, ''),
                "record_id": subtitle_to.record_id,
                "index": subtitle_to.tmp_attrs[:index],
                "subtitle_change_type": 'update',
              }
            else
              # They are identical, return nil
              nil
            end
          elsif subtitle_from
            # subtitle_from was removed, leave index and record_id empty
            {
              "stid": subtitle_from.persistent_id,
              "before": subtitle_from.content.sub(/\A@/, ''),
              "after": '',
              "record_id": nil,
              "index": nil,
              "subtitle_change_type": 'remove',
            }
          elsif subtitle_to
            # subtitle_to was added
            {
              "stid": subtitle_to.persistent_id,
              "before": '',
              "after": subtitle_to.content.sub(/\A@/, ''),
              "record_id": subtitle_to.record_id,
              "index": subtitle_to.tmp_attrs[:index],
              "subtitle_change_type": 'add',
            }
          else
            raise "Handle this: #{ [subtitle_from, subtitle_to].inspect }"
          end
        end

      end
    end
  end
end
