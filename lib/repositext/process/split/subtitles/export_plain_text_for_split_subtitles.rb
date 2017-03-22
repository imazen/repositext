class Repositext
  class Process
    class Split
      class Subtitles

        # This name space provides methods for exporting plain text files that
        # will be used for autosplitting.
        module ExportPlainTextForSplitSubtitles

          # Exports plain text version of content_at_file to be used for
          # subtitle splitting.
          # @param content_at_file [RFile::ContentAt]
          def export_plain_text_for_split_subtitles(content_at_file)
            Repositext::Cli.start(
              [
                "export",
                "plain_text_for_st_autosplit",
                "--content-type-name", content_at_file.content_type_name,
                "--file-selector", "**/*#{ content_at_file.extract_date_code }*",
                "--rtfile", File.join(content_at_file.content_type_base_dir, 'Rtfile'),
                "-g",
              ]
            )
          end

        end
      end
    end
  end
end
