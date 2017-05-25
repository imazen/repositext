class Repositext
  class Process
    class Compute

      # Computes subtitle operations for a file and patch based on
      # `options[:from_git_commit]` and `options[:to_git_commit]` reference
      # commits. Note that we may use different actual commits since the reference
      # commits don't include the changes effected by an st_sync, however the
      # next child commit does.
      #
      # Data types used in this file
      #
      # * SubtitleAttrs
      #       {
      #         content: "Word1, 'word2' Word3.",
      #         content_sim: "word1 word2 word3",
      #         persistent_id: "1234567",
      #         record_id: "123123123",
      #         para_index: 0,
      #         first_in_para: true,
      #         last_in_para: false,
      #         subtitle_count: 0,
      #         index: 23,
      #         repetitions: { 'repeated phrase' => [23, 56](start positions) },
      #       }
      #   Gaps have an empty string as content.
      #
      # * AlignedSubtitlePair: A hash describing two aligned subtitles in the file.
      #       {
      #         type: <:left_aligned|:right_aligned|:st_added...>
      #         subtitle_object: <# Repositext::Subtitle ...>
      #         sim_left: [sim<Float>, conf<Float>]
      #         sim_right: [sim<Float>, conf<Float>]
      #         sim_abs: [sim<Float>, conf<Float>]
      #         content_length_change: <Integer from del to add>
      #         subtitle_count_change: <Integer from del to add>
      #         from: [SubtitleAttrs]
      #         to: [SubtitleAttrs]
      #         index: <Integer> index of aligned st pair in file
      #         first_in_para: Boolean, true if asp is first in paragraph
      #         last_in_para: Boolean, true if aps is last in paragraph
      #       }
      class SubtitleOperationsForFile

        include AlignSubtitlePairs
        include ComputeSubtitleAttrs

        # Returns a data structure for all text lines in content_at_file
        # with their subtitles.
        # @param content_at_file [Repositext::RFile::ContentAt]
        # @param stm_csv_file [Repositext::RFile::SubtitleMarkersCsv]
        # @return [Array<Hash>] with keys :content, :line_no, :subtitles
        def self.compute_content_at_lines_with_subtitles(content_at_file, stm_csv_file)
          r = []
          # Note: RFile::StmCsv#subtitles uses the current #contents and doesn't
          # reload from disk. That's a good thing when we work with #as_of_git_commit.
          subtitles = stm_csv_file.subtitles
          content_at_file.contents
                         .split("\n")
                         .each_with_index { |content_at_line, idx|
            r << {
              content: content_at_line,
              line_no: idx + 1,
              subtitles: subtitles.shift(content_at_line.count('@')),
            }
          }
          r
        end

        # @param content_at_file_to [Repositext::RFile::ContentAt] with contents
        #   set to what they were after the `to` git commit.
        # @param repo_base_dir [String]
        # @param options [Hash] with keys
        #   :from_git_commit (SHA1 string),
        #   :to_git_commit (SHA1 string),
        #   :prev_last_operation_id (Integer)
        #   :execution_context (one of :compute_new_st_ops or :recompute_existing_st_ops)
        def initialize(content_at_file_to, repo_base_dir, options)
          @content_at_file_to = content_at_file_to
          @file_date_code = @content_at_file_to.extract_date_code
          @repo_base_dir = repo_base_dir
          @options = options
          @logger = Repositext::Utils::CommandLogger.new
        end

        # @return [Repositext::Subtitle::OperationsForFile]
        def compute
          if debug
            puts ('-' * 80).color(:red)
            puts "content_at_from"
            puts(
              @content_at_file_to.as_of_git_commit(
                @options[:from_git_commit],
                :at_child_or_ref
              ).contents
            )

            puts ('-' * 80).color(:red)
            puts "content_at_to"
            puts(
              @content_at_file_to.as_of_git_commit(
                @options[:to_git_commit],
                :at_child_or_ref
              ).contents
            )
          end

          print "       - compute st attrs"
          subtitle_attrs_from = compute_subtitle_attrs_from(
            @content_at_file_to,
            @options[:from_git_commit],
          )
          if debug
            puts ('-' * 80).color(:red)
            puts "subtitle_attrs_from"
            puts subtitle_attrs_from.ai(indent: -2)
          end

          subtitle_attrs_to = compute_subtitle_attrs_to(
            @content_at_file_to,
            @options[:to_git_commit],
            @options[:execution_context]
          )
          if debug
            puts ('-' * 80).color(:red)
            puts "subtitle_attrs_to"
            puts subtitle_attrs_to.ai(indent: -2)
          end

          print " - align st pairs"
          aligned_subtitle_pairs = align_subtitle_pairs(
            subtitle_attrs_from,
            subtitle_attrs_to
          )
          if debug
            puts ('-' * 80).color(:red)
            puts "aligned_subtitle_pairs"
            puts aligned_subtitle_pairs.ai(indent: -2)
          end

          puts "       - extract ops"
          operations = OperationsExtractor.new(
            aligned_subtitle_pairs,
            @file_date_code,
            @options[:prev_last_operation_id]
          ).extract
          if debug
            puts ('-' * 80).color(:red)
            puts "operations"
            puts operations.map { |e| e.to_hash }.ai(indent: -2)
          end

          Repositext::Subtitle::OperationsForFile.new(
            @content_at_file_to,
            {
              file_path: @content_at_file_to.repo_relative_path,
              from_git_commit: @options[:from_git_commit],
              to_git_commit: @options[:to_git_commit],
            },
            operations
          )
        end

        def debug
          false
        end
      end
    end
  end
end
