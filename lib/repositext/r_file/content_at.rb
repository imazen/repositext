class Repositext
  class RFile
    # Represents a content AT file in repositext.
    class ContentAt < RFile

      include FollowsStandardFilenameConvention
      include HasCorrespondingDataJsonFile
      include HasCorrespondingPrimaryFile

      # Returns an array of ContentAt files under repo_root_dir/content_type dir.
      # @param repo_root_dir [String]
      # @param content_type [Repositext::ContentType]
      def self.find_all(repo_root_dir, content_type)
        Dir.glob(File.join(repo_root_dir, "**/ct-#{ content_type.name }/content/**/*.at")).map { |path|
          RFile::ContentAt.new(
            File.read(path),
            content_type.language,
            path,
            content_type
          )
        }
      end

      def compute_similarity_with_corresponding_primary_file
        Kramdown::TreeStructuralSimilarity.new(
          corresponding_primary_file.kramdown_doc,
          kramdown_doc
        ).compute
      end

      def corresponding_st_autosplit_filename
        filename.sub(/\/content\//, '/autosplit_subtitles/') # update path
                .sub(/\.at\z/, '.txt') # update extension
      end

      # Returns the corresponding file while considering #as_of_git_commit_attrs.
      def corresponding_subtitle_export_en_txt_file
        return nil  if !File.exist?(corresponding_subtitle_export_en_txt_filename)
        r = RFile::Content.new(
          File.read(corresponding_subtitle_export_en_txt_filename),
          language,
          corresponding_subtitle_export_en_txt_filename,
          content_type
        )
        if as_of_git_commit_attrs
          r.as_of_git_commit(*as_of_git_commit_attrs)
        else
          r
        end
      end

      def corresponding_subtitle_export_en_txt_filename
        filename.sub(/(?<=\/)[a-z]{3}(?=[\d]{2}-[\d]{4})/, '') # remove lang code
                .sub(/\/content\//, '/subtitle_export/') # update path
                .sub(/\.at\z/, '.en.txt') # update extension
      end

      # Returns the corresponding file while considering #as_of_git_commit_attrs.
      def corresponding_subtitle_import_markers_file(respect_as_of_git_commit_attrs=true)
        return nil  if !File.exist?(corresponding_subtitle_import_markers_filename)
        r = RFile::SubtitleMarkersCsv.new(
          File.read(corresponding_subtitle_import_markers_filename),
          language,
          corresponding_subtitle_import_markers_filename,
          content_type
        )
        if respect_as_of_git_commit_attrs && as_of_git_commit_attrs
          r.as_of_git_commit(*as_of_git_commit_attrs)
        else
          r
        end
      end

      def corresponding_subtitle_import_markers_filename
        filename.sub(/(?<=\/)[a-z]{3}(?=[\d]{2}-[\d]{4})/, '') # remove lang code
                .sub(/\/content\//, '/subtitle_import/') # update path
                .sub(/\.at\z/, '.markers.txt') # update extension
      end

      # Returns the corresponding file while considering #as_of_git_commit_attrs.
      def corresponding_subtitle_import_txt_file
        return nil  if !File.exist?(corresponding_subtitle_import_txt_filename)
        r = RFile::Text.new(
          File.read(corresponding_subtitle_import_txt_filename),
          language,
          corresponding_subtitle_import_txt_filename,
          content_type
        )
        if as_of_git_commit_attrs
          r.as_of_git_commit(*as_of_git_commit_attrs)
        else
          r
        end
      end

      def corresponding_subtitle_import_txt_filename
        filename.sub(/(?<=\/)[a-z]{3}(?=[\d]{2}-[\d]{4})/, '') # remove lang code
                .sub(/\/content\//, '/subtitle_import/') # update path
                .sub(/\.at\z/, ".#{ language.code_2_chars }.txt") # update extension w/ lang code
      end

      # Returns the corresponding subtitle markers csv file or nil if it
      # doesn't exist.
      # This method considers #as_of_git_commit_attrs and also handles symlinked
      # foreign STM CSV file correctly.
      def corresponding_subtitle_markers_csv_file
        return nil  if !File.exist?(corresponding_subtitle_markers_csv_filename)

        r = RFile::SubtitleMarkersCsv.new(
          File.read(corresponding_subtitle_markers_csv_filename),
          language,
          corresponding_subtitle_markers_csv_filename,
          content_type
        )

        if as_of_git_commit_attrs
          ref_commit, relative_version = as_of_git_commit_attrs
          if is_primary?
            # We're staying in the same repo, just use as_of_git_commit_attrs as is.
            r.as_of_git_commit(ref_commit, relative_version)
          else
            # We're jumping from a foreign to the primary repo, so we have to
            # find the latest commit prior or equal to ref_commit in the primary
            # repo.
            foreign_symlinked_stm_csv_file = r

            # Compute ref_commit datetime
            foreign_ref_commit_obj = repository.lookup(ref_commit)
            foreign_ref_commit_datetime = foreign_ref_commit_obj.time.utc

            # Find latest commit for corresponding primary file
            primary_stm_csv_file_shell = foreign_symlinked_stm_csv_file.corresponding_primary_file
            corresponding_primary_ref_commit_obj = primary_stm_csv_file_shell.latest_git_commit(
              foreign_ref_commit_datetime
            )

            primary_stm_csv_file_as_of_git_commit = primary_stm_csv_file_shell.as_of_git_commit(
              corresponding_primary_ref_commit_obj.oid,
              :at_ref_or_raise
            )

            # Create new instance of STM CSV file with updated attrs
            r = RFile::SubtitleMarkersCsv.new(
              primary_stm_csv_file_as_of_git_commit.contents,
              language,
              corresponding_subtitle_markers_csv_filename,
              content_type
            )
            r.as_of_git_commit_attrs = as_of_git_commit_attrs
            # Return new file instance
            r
          end
        else
          r
        end
      end

      def corresponding_subtitle_markers_csv_filename
        filename.sub(/\.at\z/, '.subtitle_markers.csv')
      end

      # Returns the first level 1 header in the file. Does this by using the
      # first line in the plain_text_contents
      def extract_title
        plain_text_contents({}).split("\n").first.strip
      end

      def has_pending_subtitle_import?
        '' != read_file_level_data['exported_subtitles_at_st_sync_commit'].to_s.strip
      end

      # Returns true if contents contain subtitle_marks ('@')
      def has_subtitle_marks?
        !!contents.index('@')
      end

      # Returns true if corresponding_subtitle_markers_csv_file exists and has entries.
      def has_subtitles?
        subtitles.any?
      end

      # @param options [Hash]
      def kramdown_doc(options={})
        options = {
          is_primary_repositext_file: is_primary?,
          input: kramdown_parser,
          line_width: 100000, # set to very large value so that each para is on a single line
        }.merge(options)
        Kramdown::Document.new(contents, options)
      end

      def kramdown_parser
        'Kramdown'
      end

      def language_code_2_chars
        language.code_2_chars
      end

      def plain_text_contents(options)
        kramdown_doc(options).to_plain_text
      end

      def plain_text_for_st_autosplit_contents(options)
        kramdown_doc(options).to_plain_text_for_st_autosplit
      end

      def plain_text_with_subtitles_contents(options)
        kramdown_doc(options).to_plain_text_with_subtitles
      end

      # Returns count of subtitle_marks in self's content.
      # NOTE: This can return different results than #subtitles.count for foreign
      # files who don't have a symlink to the STM CSV file yet.
      # This method is based on subtitle_marks in content, #subtitles looks at
      # STM CSV file.
      def subtitle_marks_count
        contents.count('@')
      end

      # Returns subtitles based on content in self and attrs in corresponding
      # subtitle markers csv file, or subtitle_attrs_overrides if given.
      # @param options [Hash{Symbol => Object}] with the following keys:
      #   content_format [Symbol] one of :content_at, :plain_text. Defaults to :content_at
      #   subtitle_attrs_override [Array<Subtitle>, optional] if given will be
      #     used instead of attrs from stm_csv file.
      #   include_content_not_inside_a_subtitle [Boolean] if true will return
      #     all contents, even those not inside subtitles (e.g., record marks and headers)
      #     They will be wrapped inside a dummy Subtitle object.
      #   with_content [Boolean, optional] defaults to false. If true,
      #     returned subtitles will have their content attribute populated.
      # @return [Array<Subtitle>] with attrs and content
      def subtitles(options={})
        options = {
          content_format: :content_at,
          include_content_not_inside_a_subtitle: false,
          subtitle_attrs_override: nil,
          with_content: false,
        }.merge(options)

        subtitle_attrs = if options[:subtitle_attrs_override]
          options[:subtitle_attrs_override]
        elsif (csmcf = corresponding_subtitle_markers_csv_file)
          csmcf.subtitles
        else
          []
        end
        return []  if subtitle_attrs.empty?

        # Check that counts between content AT and subtitle_attrs match
        if contents.count('@') != subtitle_attrs.count
          raise "Mismatch in subtitle counts: content AT: #{ contents.count('@') }, subtitle_attrs: #{ subtitle_attrs.count }."
        end

        if options[:with_content]
          # merge content and attrs
          subtitle_attrs_pool = subtitle_attrs.dup
          case options[:content_format]
          when :content_at
            contents.split(/(?<=\n\n)|(?=@)/).map { |e|
              if e =~ /\A@/
                # starts with subtitle_mark, merge content with next attrs
                s = subtitle_attrs_pool.shift
                s.content = e
                s
              else
                # Not inside a subtitle, return nil, to be removed or subtitle shell
                if options[:include_content_not_inside_a_subtitle]
                  Subtitle.new(content: e)
                else
                  nil
                end
              end
            }.compact
          when :plain_text
            plain_text_with_subtitles_contents({}).split(/(?<=\n)|(?=@)/).map { |e|
              if e =~ /\A@/
                # starts with subtitle_mark, merge content with next attrs
                s = subtitle_attrs_pool.shift
                s.content = e
                s
              else
                # Not inside a subtitle, return nil, to be removed or subtitle shell
                if options[:include_content_not_inside_a_subtitle]
                  Subtitle.new(content: e)
                else
                  nil
                end
              end
            }.compact
          else
            raise "Handle this: #{ options[:content_format].inspect }"
          end
        else
          # return just attrs
          subtitle_attrs
        end
      end
    end
  end
end
