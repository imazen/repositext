class Repositext
  class Process
    class Compute

=begin

Data types used in this file
----------------------------

* SubtitleAttrs
      {
        content: "Word1, 'word2' Word3.",
        content_sim: "word1 word2 word3",
        persistent_id: "1234567",
        record_id: "123123123",
        first_in_para: true,
        last_in_para: false,
        subtitle_count: 0,
        index: 23,
      }
  Gaps have an empty string as content.

* AlignedSubtitlePair: A hash describing two aligned subtitles in the file.
      {
        type: <:left_aligned|:right_aligned|:st_added...>
        subtitle_object: <# Repositext::Subtitle ...>
        sim_left: [sim<Float>, conf<Float>]
        sim_right: [sim<Float>, conf<Float>]
        sim_abs: [sim<Float>, conf<Float>]
        content_length_change: <Integer from del to add>
        subtitle_count_change: <Integer from del to add>
        from: [SubtitleAttrs]
        to: [SubtitleAttrs]
        index: <Integer> index of aligned st pair in file
        first_in_para: Boolean, true if asp is first in paragraph
        last_in_para: Boolean, true if aps is last in paragraph
      }

=end

      # Computes subtitle operations for a file and patch.
      class SubtitleOperationsForFile

        include AlignSubtitlePairs
        include ComputeSubtitleAttrs

        # Returns a data structure for all text lines in content_at_file
        # with their subtitles.
        # @param content_at_file [Repositext::RFile::ContentAt]
        # @param content_at_file [Repositext::RFile::SubtitleMarkersCsv]
        # @return [Array<Hash>] with keys :content, :line_no, :subtitles
        def self.compute_content_at_lines_with_subtitles(content_at_file, stm_csv_file)
          r = []
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

        # @param content_at_file [Repositext::RFile::ContentAt]
        # @param stm_csv_file [Repositext::RFile::SubtitleMarkersCsv]
        # @param repo_base_dir [String]
        # @param options [Hash] with keys :from_git_commit and :to_git_commit
        def initialize(content_at_file_to, repo_base_dir, options)
          @content_at_file_to = content_at_file_to
          @repo_base_dir = repo_base_dir
          @options = options
        end

        # @return [Repositext::Subtitle::OperationsForFile]
        def compute
          print "       - compute st attrs"

          if debug
            puts ('-' * 80).color(:red)
            puts "content_at_from"
            puts @content_at_file_to.as_of_git_commit(@options[:from_git_commit]).contents

            puts ('-' * 80).color(:red)
            puts "content_at_to"
            puts @content_at_file_to.contents
          end

          subtitle_attrs_from = compute_subtitle_attrs_from(
            @content_at_file_to,
            @options[:from_git_commit],
          )
          if debug
            puts ('-' * 80).color(:red)
            puts "subtitle_attrs_from"
            pp subtitle_attrs_from
          end

          subtitle_attrs_to = compute_subtitle_attrs_to(
            @content_at_file_to
          )
          if debug
            puts ('-' * 80).color(:red)
            puts "subtitle_attrs_to"
            pp subtitle_attrs_to
          end

          print " - align st pairs"
          aligned_subtitle_pairs = align_subtitle_pairs(
            subtitle_attrs_from,
            subtitle_attrs_to
          )
          if debug
            puts ('-' * 80).color(:red)
            puts "aligned_subtitle_pairs"
            pp aligned_subtitle_pairs
          end

          puts " - extract ops"
          operations = OperationExtractor.new(aligned_subtitle_pairs).extract
          if debug
            puts ('-' * 80).color(:red)
            puts "operations"
            pp operations.map { |e| e.to_hash }
          end

          Repositext::Subtitle::OperationsForFile.new(
            @content_at_file_to,
            {
              file_path: @content_at_file_to.filename.sub(@repo_base_dir, ''),
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
