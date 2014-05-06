# encoding UTF-8
class Repositext
  class Cli
    module Utils

      # Utils module provides methods commonly used by the rt commands

      # Changes files in place, updating their contents
      # @param: See #process_files_helper below for param description
      def self.change_files_in_place(file_pattern, file_filter, description, options, &block)
        # Use input file path
        output_path_lambda = lambda do |input_filename, output_file_attrs|
          input_filename
        end
        process_files_helper(
          file_pattern, file_filter, output_path_lambda, description, options, &block
        )
      end

      # Converts files from one format to another
      # @param: See #process_files_helper below for param description
      def self.convert_files(file_pattern, file_filter, description, options, &block)
        # Change file extension only.
        output_path_lambda = lambda do |input_filename, output_file_attrs|
          replace_file_extension(input_filename, output_file_attrs[:extension])
        end

        process_files_helper(
          file_pattern, file_filter, output_path_lambda, description, options, &block
        )
      end

      # Exports files to another format and location
      # @param[String] input_base_dir the base_dir path
      # @param[String] input_file_pattern the input file pattern
      # @param[String] out_dir the output base directory
      # @param: See #process_files_helper below for param description
      def self.export_files(input_base_dir, input_file_pattern, out_dir, file_filter, description, options, &block)
        # Change output file path to destination
        output_path_lambda = lambda do |input_filename, output_file_attrs|
          replace_file_extension(
            input_filename.gsub(input_base_dir, out_dir),
            output_file_attrs[:extension]
          )
        end
        file_pattern = input_base_dir + input_file_pattern

        process_files_helper(
          file_pattern, file_filter, output_path_lambda, description, options, &block
        )
      end

      # Moves files to another location
      # @param[String] input_base_dir the base_dir path
      # @param[String] input_file_pattern the input file pattern
      # @param[String] out_dir the output base directory
      # @param: See #process_files_helper below for param description
      def self.move_files(input_base_dir, input_file_pattern, out_dir, file_filter, description, options)
        # Change output file path to destination
        output_path_lambda = lambda do |input_filename|
          input_filename.gsub(input_base_dir, out_dir)
        end
        file_pattern = input_base_dir + input_file_pattern

        move_files_helper(
          file_pattern, file_filter, output_path_lambda, description, options
        )
      end

      # Reads files
      # @param[String] input_base_dir the base_dir path
      # @param[String] input_file_pattern the input file pattern
      # @param: See #process_files_helper below for param description
      def self.read_files(file_pattern, file_filter, description, options, &block)
        read_files_helper(
          file_pattern, file_filter, description, options, &block
        )
      end

      # Does a dry-run of the process. Printing out all debug and logging info
      # but not saving any changes to disk.
      # @param: See #process_files_helper below for param description
      # @param[String] out_dir the output base directory
      def self.dry_run_process(file_pattern, file_filter, out_dir, description, options, &block)
        # Always return empty string to skip writing to disk
        output_path_lambda = lambda do |input_filename, output_file_attrs|
          ''
        end

        process_files_helper(
          file_pattern, file_filter, output_path_lambda, description, options, &block
        )
      end

      # Processes files
      # @param[String] file_pattern A Dir.glob file pattern that describes
      #     the file set to be operated on. This is typically provided by either
      #     Rtfile or as command line argument by the user.
      # @param[Trequal] file_filter Each file's name (and path) is compared with
      #     file_filter using ===. The file will be processed if the comparison
      #     evaluates to true. file_filter can be anything that responds to
      #     #===, e.g., a Regexp, a Proc, or a String.
      #     This is provided by the callling command, limiting the files to be
      #     operated on to valid file types.
      #     See here for more info on ===: http://ruby.about.com/od/control/a/The-Case-Equality-Operator.htm
      # @param[Proc] output_path_lambda A proc that computes the output file
      #     path as string. It is given the input file path and output file attrs.
      #     If output_path_lambda returns '' (empty string), no files will be written.
      # @param[String] description A description of the operation, used for logging.
      # @param[Hash] options
      #     :input_is_binary to force File.binread where required
      #     :output_is_binary
      #     :changed_only
      # @param[Proc] block A Proc that performs the desired operation on each file.
      #     Arguments to the proc are each file's name and contents.
      #     Calling block is expected to return an Array of Outcome objects, one
      #     for each file, with the following attrs:
      #       * success:  Boolean
      #       * result:   A hash with :contents and :extension keys
      #       * messages: An array of message strings.
      # TODO: the following naming may reveal intent more clearly:
      #     output_path_lambda => out_filename_proc (transforms output file path)
      #     block              => out_contents_proc (transforms output file contents)
      def self.process_files_helper(file_pattern, file_filter, output_path_lambda, description, options, &block)
        with_console_output(description, file_pattern) do |counts|
          changed_files = compute_list_of_changed_files(options[:changed_only])
          Dir.glob(file_pattern).each do |filename|

            if file_filter && !(file_filter === filename) # file_filter has to be LHS of `===`
              $stderr.puts " - Skipping #{ filename } - doesn't match file_filter"
              next
            end

            if changed_files && !changed_files.any? { |changed_file_rel_path|
              Regexp.new(changed_file_rel_path + "\\z") =~ filename
            }
              $stderr.puts " - Skipping #{ filename } - has no changes"
              next
            end

            begin
              $stderr.puts " - Processing #{ filename }"
              contents = if options[:input_is_binary]
                File.binread(filename).freeze
              else
                File.read(filename).freeze
              end
              outcomes = block.call(contents, filename)

              outcomes.each do |outcome|
                if outcome.success
                  output_file_attrs = outcome.result
                  new_path = output_path_lambda.call(filename, output_file_attrs)
                  # new_path is either a file path or the empty string (in which
                  # case we don't write anything to the file system).
                  # NOTE: it's not enough to just check File.exist?(new_path) for
                  # empty string in testing as FakeFS returns true. So I also
                  # need to check for empty string separately to make tests work.
                  existing_contents = if ('' != new_path && File.exist?(new_path))
                    options[:output_is_binary] ? File.binread(new_path) : File.read(new_path)
                  else
                    nil
                  end
                  new_contents = output_file_attrs[:contents]
                  message = outcome.messages.join("\n")

                  if(nil == existing_contents)
                    write_file_unless_path_is_blank(new_path, new_contents)
                    counts[:created] += 1
                    $stderr.puts "  * Create: #{ new_path } #{ message }"
                  elsif(existing_contents != new_contents)
                    write_file_unless_path_is_blank(new_path, new_contents)
                    counts[:updated] += 1
                    $stderr.puts "  * Update: #{ new_path } #{ message }"
                  else
                    counts[:unchanged] += 1
                    $stderr.puts "    Leave as is: #{ new_path } #{ message }"
                  end

                  counts[:success] += 1
                else
                  $stderr.puts "  x  Error: #{ message }"
                  counts[:errors] += 1
                end
              end
            rescue StandardError => e
              counts[:errors] += 1
              $stderr.puts %(  x  Error: #{ e.class.name } - #{ e.message } - #{ e.backtrace.join("\n") })
            end
            counts[:total] += 1
          end
        end
      end

      # Moves files
      # @param[String] file_pattern A Dir.glob file pattern that describes
      #     the file set to be operated on. This is typically provided by either
      #     Rtfile or as command line argument by the user.
      # @param[Trequal] file_filter Each file's name (and path) is compared with
      #     file_filter using ===. The file will be processed if the comparison
      #     evaluates to true. file_filter can be anything that responds to
      #     #===, e.g., a Regexp, a Proc, or a String.
      #     This is provided by the callling command, limiting the files to be
      #     operated on to valid file types.
      #     See here for more info on ===: http://ruby.about.com/od/control/a/The-Case-Equality-Operator.htm
      # @param[Proc] output_path_lambda A proc that computes the output file
      #     path as string. It is given the input file path and output file attrs.
      #     If output_path_lambda returns '' (empty string), no files will be written.
      # @param[Hash] options
      #     :input_is_binary to force File.binread where required
      #     :output_is_binary
      def self.move_files_helper(file_pattern, file_filter, output_path_lambda, description, options)

        with_console_output(description, file_pattern) do |counts|
          changed_files = compute_list_of_changed_files(options[:changed_only])
          Dir.glob(file_pattern).each do |filename|

            if file_filter && !(file_filter === filename) # file_filter has to be LHS of `===`
              $stderr.puts " - Skipping #{ filename } - doesn't match file_filter"
              next
            end

            if changed_files && !changed_files.any? { |changed_file_rel_path|
              Regexp.new(changed_file_rel_path + "\\z") =~ filename
            }
              $stderr.puts " - Skipping #{ filename } - has no changes"
              next
            end

            begin
              $stderr.puts " - Moving #{ filename }"

              new_path = output_path_lambda.call(filename)

              # new_path is either a file path or the empty string (in which
              # case we don't write anything to the file system).
              # NOTE: it's not enough to just check File.exist?(new_path) for
              # empty string in testing as FakeFS returns true. So I also
              # need to check for empty string separately to make tests work.
              exists_already = ('' != new_path && File.exist?(new_path))

              if exists_already
                move_file_unless_path_is_blank(filename, new_path)
                counts[:updated] += 1
                $stderr.puts "  * Update: #{ new_path }"
              else
                move_file_unless_path_is_blank(filename, new_path)
                counts[:created] += 1
                $stderr.puts "  * Create: #{ new_path }"
              end

              counts[:success] += 1
            rescue StandardError => e
              counts[:errors] += 1
              $stderr.puts %(  x  Error: #{ e.class.name } - #{ e.message } - #{ e.backtrace.join("\n") })
            end

            counts[:total] += 1
          end
        end
      end

      # Reads files
      # @param[String] file_pattern A Dir.glob file pattern that describes
      #     the file set to be operated on. This is typically provided by either
      #     Rtfile or as command line argument by the user.
      # @param[Trequal] file_filter Each file's name (and path) is compared with
      #     file_filter using ===. The file will be processed if the comparison
      #     evaluates to true. file_filter can be anything that responds to
      #     #===, e.g., a Regexp, a Proc, or a String.
      #     This is provided by the callling command, limiting the files to be
      #     operated on to valid file types.
      #     See here for more info on ===: http://ruby.about.com/od/control/a/The-Case-Equality-Operator.htm
      # @param[String] description A description of the operation, used for logging.
      # @param[Hash] options
      #     :input_is_binary to force File.binread where required
      #     :output_is_binary
      #     :changed_only
      # @param[Proc] block A Proc that performs the desired operation on each file.
      #     Arguments to the proc are each file's name and contents.
      def self.read_files_helper(file_pattern, file_filter, description, options, &block)

        with_console_output(description, file_pattern) do |counts|
          changed_files = compute_list_of_changed_files(options[:changed_only])
          Dir.glob(file_pattern).each do |filename|

            if file_filter && !(file_filter === filename) # file_filter has to be LHS of `===`
              $stderr.puts " - Skipping #{ filename } - doesn't match file_filter"
              next
            end

            if changed_files && !changed_files.any? { |changed_file_rel_path|
              Regexp.new(changed_file_rel_path + "\\z") =~ filename
            }
              $stderr.puts " - Skipping #{ filename } - has no changes"
              next
            end

            begin
              $stderr.puts " - Reading #{ filename }"
              contents = if options[:input_is_binary]
                File.binread(filename).freeze
              else
                File.read(filename).freeze
              end
              counts[:success] += 1
              block.call(contents, filename)
            rescue StandardError => e
              counts[:errors] += 1
              $stderr.puts %(  x  Error: #{ e.class.name } - #{ e.message } - #{ e.backtrace.join("\n") })
            end

            counts[:total] += 1
          end
        end
      end


      # Wraps operations with log output
      # @param[String] description the text to print on the first line of console
      # @param[String] file_pattern the file pattern to print on first line of console
      # @param[Block] the operation for which to print console output
      def self.with_console_output(description, file_pattern, &block)
        $stderr.puts "#{ description } at #{ file_pattern }."
        $stderr.puts '-' * 80
        start_time = Time.now
        counts = Hash.new(0)

        yield(counts)

        $stderr.puts '-' * 80
        $stderr.puts "Finished processing #{ counts[:success] } of #{ counts[:total] } files in #{ Time.now - start_time } seconds."
        $stderr.puts "* #{ counts[:created] } new files created"  if counts[:created] > 0
        $stderr.puts "* #{ counts[:updated] } existing files updated"  if counts[:updated] > 0
        $stderr.puts "* #{ counts[:unchanged] } files left unchanged"  if counts[:unchanged] > 0
        $stderr.puts "* #{ counts[:errors] } errors"  if counts[:errors] > 0
      end

      # Replaces filename's extension with new_extension. If filename doesn't have
      # an extension, adds new_extension.
      # @param[String] filename the source filename with old extension
      # @param[String] new_extension the new extension to use, e.g., '.idml'
      # @return[String] filename with new_extension
      def self.replace_file_extension(filename, new_extension)
        filename = filename.gsub(/\.\z/, '') # remove dot at end if filename ends with dot
        existing_ext = File.extname(filename)
        basepath = if '' == existing_ext
          filename
        else
          filename[0...-existing_ext.length]
        end
        new_extension = '.' + new_extension.sub(/\A\./, '')
        basepath + new_extension
      end

      # Moves file_path to new_path. Overwrites existing files.
      # Doesn't move file if file_path is blank (nil, empty string, or string
      # with only whitespace)
      # @param[String] file_path
      # @param[String] new_path
      # @return[Bool] true if it moved file, false if not.
      def self.move_file_unless_path_is_blank(file_path, new_path)
        if '' == file_path.to_s.strip
          $stderr.puts %(  - Skip moving blank file_path)
          false
        else
          FileUtils.move(file_path, new_path)
          true
        end
      end

      # Writes file_contents to file at file_path. Overwrites existing file.
      # Doesn't write to file if file_path is blank (nil, empty string, or string
      # with only whitespace)
      # @param[String] file_path
      # @param[String] file_contents
      # @return[Integer, Nil] the number of bytes written or false if nothing was written
      def self.write_file_unless_path_is_blank(file_path, file_contents)
        if '' == file_path.to_s.strip
          $stderr.puts %(  - Skip writing "#{ file_contents.truncate_in_the_middle(60) }" to blank file_path)
          false
        else
          dir = File.dirname(file_path)
          unless File.directory?(dir)
            FileUtils.mkdir_p(dir)
          end
          # TODO: we may need to look at the :output_is_binary option and write
          # differently if required
          File.write(file_path, file_contents)
        end
      end

      # Returns a list of files that git considers changed:
      #     * modified or added
      #     * staged or unstaged
      # @param[Boolean] changed_only_flag
      # @param[String, optional] limit scope to path. This is for testing.
      # @return[Array<String>, nil]
      def self.compute_list_of_changed_files(changed_only_flag, path = '')
        if changed_only_flag
          base_dir = `git rev-parse --show-toplevel`.strip
          r = []
          if '' == path
            # Scope: entire git repo
            # Add staged and unstaged modified files, and staged new files
            r += `git diff --name-only --diff-filter=AM HEAD`.split("\n")
            # Add unstaged new files (in working tree, not staged yet)
            r += `git ls-files --others --exclude-standard --full-name`.split("\n")
          else
            # Scope: path only (good for testing)
            # Add staged and unstaged modified files, and staged new files
            r += `git diff --name-only --diff-filter=AM HEAD -- #{ path }`.split("\n")
            Dir.chdir(path) do
              # Add unstaged new files (in working tree, not staged yet)
              r += `git ls-files --others --exclude-standard --full-name`.split("\n")
            end
          end
          r = r.uniq.compact.map { |e| File.join(base_dir, e) }
          r
        else
          nil
        end
      end

    end
  end
end
