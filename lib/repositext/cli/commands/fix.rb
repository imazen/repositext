class Repositext
  class Cli
    module Fix

    private

      def fix_adjust_merged_record_mark_positions(options)
        # Specify regexes
        ald_any_chars_rx = /\\\}|[^\}]/
        ial_rx = /\{:#{ ald_any_chars_rx }*?\}/
        # TODO: record_mark_rx only matches :record_marks with IALs. Check if there are
        # :record_marks without IALs.
        record_mark_rx = /\n\^\^\^\s#{ ial_rx }\n/

        input_file_spec = options[:input] || 'staging_dir.at_files'
        Repositext::Cli::Utils.change_files_in_place(
          config.compute_glob_pattern(input_file_spec),
          /\.at\z/i,
          "Adjusting merged :record_mark positions",
          options
        ) do |contents, filename|
          # prepend \n\n to satisfy two leading \n for :record_mark on first line in file
          old_at = "\n\n" + contents
          new_at = ''

          state = 'idle'
          invalid_record_mark = nil

          s = StringScanner.new(old_at)
          while !s.eos? do
            case state
            when 'idle'
              # Match up until the next invalid record_mark, excluding the record mark itself
              contents = s.scan(/.*?[^\n](?=#{ record_mark_rx })/m)
              if contents
                # Found an invalid record_mark
                new_at << contents
                state = 'capture_invalid_record_mark'
              else
                # No invalid record_mark found
                new_at << s.rest
                state = 'idle'
                s.terminate
              end
            when 'capture_invalid_record_mark'
              invalid_record_mark = s.scan(record_mark_rx)
              if invalid_record_mark
                state = 'capture_chars_until_next_para'
              else
                raise "No invalid record_mark found: ...#{ new_at[-30..-1].inspect } - #{ s.rest[0..30].inspect }"
              end
            when 'capture_chars_until_next_para'
              # capture text until next para or end of string
              contents = s.scan(/.*?\n(?=\*?\w)/m)
              if contents
                new_at << contents
              else
                new_at << s.rest
              end
              new_at << invalid_record_mark
              state = 'idle'
            else
              raise "Invalid state: #{ state.inspect }"
            end
          end
          new_at.gsub!(/\A\n\n/, '') # remove temporary leading \n
          [Outcome.new(
            true,
            { contents: new_at },
            []
          )]
        end
      end

      # Convert -- and ... and " to typographically correct characters
      def fix_folio_typographical_chars(options)
        input_file_spec = options[:input] || 'import_folio_xml_dir.at_files'
        Repositext::Cli::Utils.change_files_in_place(
          config.compute_glob_pattern(input_file_spec),
          /\.(at|pt|txt)\z/i,
          "Changing typographical characters in files",
          options
        ) do |contents, filename|
          text, message = Vgr::FolioConvertTypographicalMarks.new.convert(contents)
          [Outcome.new(
            true,
            { contents: text },
            [message]
          )]
        end
      end

      def fix_test(options)
        # dummy method for testing
        puts 'fix_test'
      end

    end
  end
end
