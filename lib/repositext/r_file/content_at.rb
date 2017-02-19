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

      def corresponding_subtitle_export_en_txt_file
        return nil  if !File.exist?(corresponding_subtitle_export_en_txt_filename)
        RFile::Content.new(
          File.read(corresponding_subtitle_export_en_txt_filename),
          language,
          corresponding_subtitle_export_en_txt_filename,
          content_type
        )
      end

      def corresponding_subtitle_export_en_txt_filename
        filename.sub(/(?<=\/)[a-z]{3}(?=[\d]{2}-[\d]{4})/, '') # remove lang code
                .sub(/\/content\//, '/subtitle_export/') # update path
                .sub(/\.at\z/, '.en.txt') # update extension
      end

      def corresponding_subtitle_import_markers_file
        return nil  if !File.exist?(corresponding_subtitle_import_markers_filename)
        RFile::SubtitleMarkersCsv.new(
          File.read(corresponding_subtitle_import_markers_filename),
          language,
          corresponding_subtitle_import_markers_filename,
          content_type
        )
      end

      def corresponding_subtitle_import_markers_filename
        filename.sub(/(?<=\/)[a-z]{3}(?=[\d]{2}-[\d]{4})/, '') # remove lang code
                .sub(/\/content\//, '/subtitle_import/') # update path
                .sub(/\.at\z/, '.markers.txt') # update extension
      end

      def corresponding_subtitle_import_txt_file
        return nil  if !File.exist?(corresponding_subtitle_import_txt_filename)
        RFile::Text.new(
          File.read(corresponding_subtitle_import_txt_filename),
          language,
          corresponding_subtitle_import_txt_filename,
          content_type
        )
      end

      def corresponding_subtitle_import_txt_filename
        filename.sub(/(?<=\/)[a-z]{3}(?=[\d]{2}-[\d]{4})/, '') # remove lang code
                .sub(/\/content\//, '/subtitle_import/') # update path
                .sub(/\.at\z/, ".#{ language.code_2_chars }.txt") # update extension w/ lang code
      end
      # Returns the corresponding subtitle markers csv file or nil if it
      # doesn't exist
      def corresponding_subtitle_markers_csv_file
        return nil  if !File.exist?(corresponding_subtitle_markers_csv_filename)
        RFile::SubtitleMarkersCsv.new(
          File.read(corresponding_subtitle_markers_csv_filename),
          language,
          corresponding_subtitle_markers_csv_filename,
          content_type
        )
      end

      def corresponding_subtitle_markers_csv_filename
        filename.sub(/\.at\z/, '.subtitle_markers.csv')
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
      # @param with_content [Boolean, optional] defaults to false. If true,
      #     returned subtitles will have their content attribute populated.
      # @param subtitle_attrs_override [Array<Subtitle>, optional]
      # @return [Array<Subtitle>] with attrs and content
      def subtitles(with_content=false, subtitle_attrs_override=nil)
        subtitle_attrs = if subtitle_attrs_override
          subtitle_attrs_override
        elsif (csmcf = corresponding_subtitle_markers_csv_file)
          csmcf.subtitles
        else
          []
        end
        return []  if subtitle_attrs.empty?
        if with_content
          # merge content and attrs
          subtitle_attrs_pool = subtitle_attrs.dup
          contents.split(/(?<=\n\n)|(?=@)/).map { |e|
            if e =~ /\A@/
              # starts with subtitle_mark, merge content with next attrs
              s = subtitle_attrs_pool.shift
              s.content = e
              s
            else
              # Not inside a subtitle, add blank attrs
              Subtitle.new(content: e)
            end
          }
        else
          # return just attrs
          subtitle_attrs
        end
      end
    end
  end
end
