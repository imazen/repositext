# encoding UTF-8
class Repositext
  class Cli
    # This namespace provides utility methods.
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

      # Converts files from one format to another, keeping directory and file name
      # and just updating the file extension.
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

      # Copies files to another location
      # @param input_base_dir [String] the base_dir path
      # @param input_file_selector [String] the input file selector
      # @param input_file_extension [String] the input file extension
      # @param out_dir [String] the output base directory
      # @param file_filter [Trequal]
      # @param description [String]
      # @param options [Hash]
      # @param: See #process_files_helper below for param description
      def self.copy_files(input_base_dir, input_file_selector, input_file_extension, out_dir, file_filter, description, options)
        # Change output file path to destination, override in options if filename
        # needs to be changed, too.
        output_path_lambda = options[:output_path_lambda] || lambda do |input_filename|
          input_filename.gsub(input_base_dir, out_dir)
        end
        file_pattern = [input_base_dir, input_file_selector, input_file_extension].join
        move_files_helper(
          file_pattern, file_filter, output_path_lambda, description, options.merge(:move_or_copy => :copy)
        )
      end

      # Deletes files
      # @param input_base_dir [String] the base_dir path
      # @param input_file_selector [String] the input file selector
      # @param input_file_extension [String] the input file extension
      # @param file_filter [Trequal]
      # @param description [String]
      # @param options [Hash]
      # @param: See #process_files_helper below for param description
      def self.delete_files(input_base_dir, input_file_selector, input_file_extension, file_filter, description, options)
        file_pattern = [input_base_dir, input_file_selector, input_file_extension].join
        with_console_output(description, file_pattern) do |counts|
          Dir.glob(file_pattern).each do |filename|
            if file_filter && !(file_filter === filename) # file_filter has to be LHS of `===`
              $stderr.puts " - Skipping #{ filename } - doesn't match file_filter"
              next
            end

            begin
              $stderr.puts " - Deleting #{ filename }"
              counts[:success] += 1
              File.delete(filename)
              counts[:total] += 1
            end
          end
        end
      end

      # Exports files to another format and location
      # @param input_base_dir [String] the base_dir path
      # @param input_file_selector [String] the input file selector
      # @param input_file_extension [String] the input file extension
      # @param out_dir [String] the output base directory
      # @param file_filter [Trequal]
      # @param description [String]
      # @param options [Hash]
      # @param: See #process_files_helper below for param description
      def self.export_files(input_base_dir, input_file_selector, input_file_extension, out_dir, file_filter, description, options, &block)
        # Change output file path to destination
        output_path_lambda = options[:output_path_lambda] || lambda { |input_filename, output_file_attrs|
          replace_file_extension(
            input_filename.gsub(input_base_dir, out_dir),
            output_file_attrs[:extension]
          )
        }
        file_pattern = [input_base_dir, input_file_selector, input_file_extension].join
        process_files_helper(
          file_pattern, file_filter, output_path_lambda, description, options, &block
        )
      end

      # Moves files to another location
      # @param input_base_dir [String] the base_dir path
      # @param input_file_selector [String] the input file selector
      # @param input_file_extension [String] the input file extension
      # @param out_dir [String] the output base directory
      # @param file_filter [Trequal]
      # @param description [String]
      # @param options [Hash]
      # @param: See #process_files_helper below for param description
      def self.move_files(input_base_dir, input_file_selector, input_file_extension, out_dir, file_filter, description, options)
        # Change output file path to destination, override in options if filename
        # needs to be changed, too.
        output_path_lambda = options[:output_path_lambda] || lambda do |input_filename|
          input_filename.gsub(input_base_dir, out_dir)
        end
        file_pattern = [input_base_dir, input_file_selector, input_file_extension].join
        move_files_helper(
          file_pattern, file_filter, output_path_lambda, description, options
        )
      end

      # Reads files
      # @param: See #read_files_helper below for param description
      def self.read_files(file_pattern, file_filter, file_name_2_proc, description, options, &block)
        read_files_helper(
          file_pattern, file_filter, file_name_2_proc, description, options, &block
        )
      end

      # Renames files
      # @param input_base_dir [String] the base_dir path
      # @param input_file_selector [String] the input file selector
      # @param input_file_extension [String] the input file extension
      # @param file_rename_proc [Proc] proc that takes the current file path and returns the new one
      # @param file_filter [Trequal]
      # @param description [String]
      # @param options [Hash]
      # @param: See #process_files_helper below for param description
      def self.rename_files(input_base_dir, input_file_selector, input_file_extension, file_rename_proc, file_filter, description, options)
        # Change output filename
        file_pattern = [input_base_dir, input_file_selector, input_file_extension].join
        move_files_helper(
          file_pattern, file_filter, file_rename_proc, description, options
        )
      end

      # Does a dry-run of the process. Printing out all debug and logging info
      # but not saving any changes to disk.
      # @param: See #process_files_helper below for param description
      # @param [String] out_dir the output base directory
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
      # @param file_pattern [String] A Dir.glob file pattern that describes
      #     the file set to be operated on. This is typically provided by either
      #     Rtfile or as command line argument by the user.
      # @param file_filter [Trequal] Each file's name (and path) is compared with
      #     file_filter using ===. The file will be processed if the comparison
      #     evaluates to true. file_filter can be anything that responds to
      #     #===, e.g., a Regexp, a Proc, or a String.
      #     This is provided by the callling command, limiting the files to be
      #     operated on to valid file types.
      #     See here for more info on ===: http://ruby.about.com/od/control/a/The-Case-Equality-Operator.htm
      # @param output_path_lambda [Proc] A proc that computes the output file
      #     path as string. It is given the input file path and output file attrs.
      #     If output_path_lambda returns '' (empty string), no files will be written.
      # @param description [String] A description of the operation, used for logging.
      # @param options [Hash]
      #     :input_is_binary to force File.binread where required
      #     :output_is_binary
      #     :'changed-only'
      #     :repository
      #     :use_new_r_file_api
      # @param block [Proc] A Proc that performs the desired operation on each file.
      #     Arguments to the proc are each file's name and contents.
      #     Calling block is expected to return an Array of Outcome objects, one
      #     for each file, with the following attrs:
      #       * success:  Boolean
      #       * result:   A hash with :contents and :extension keys. Set contents
      #                   to nil to skip a file.
      #       * messages: An array of message strings.
      def self.process_files_helper(file_pattern, file_filter, output_path_lambda, description, options, &block)
        with_console_output(description, file_pattern) do |counts|
          changed_files = compute_list_of_changed_files(options[:'changed-only'])
          Parallel.each(
            Dir.glob(file_pattern),
            { in_processes: options[:parallel] ? Repositext::PARALLEL_CORES : 0 }
          ) do |filename|

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
              outcomes = if options[:use_new_r_file_api]
                # use new api
                # TODO: once all calls use new API, move assignment of repo and language out of loop
                content_type = options[:content_type]
                language = content_type.language
                block.call(
                  Repositext::RFile.get_class_for_filename(
                    filename
                  ).new(
                    contents, language, filename, content_type
                  )
                )
              else
                # use old api
                block.call(contents, filename)
              end

              outcomes.each do |outcome|
                if outcome.success
                  next  if outcome.result[:contents].nil? # skip any files where content is nil
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
                    write_file_unless_path_is_blank(new_path, new_contents, options[:output_is_binary])
                    counts[:created] += 1
                    $stderr.puts "  * Create: #{ new_path } #{ message }"
                  elsif(existing_contents != new_contents)
                    write_file_unless_path_is_blank(new_path, new_contents, options[:output_is_binary])
                    counts[:updated] += 1
                    $stderr.puts "  * Update: #{ new_path } #{ message }"
                  else
                    counts[:unchanged] += 1
                    $stderr.puts "    Leave as is: #{ new_path } #{ message }"
                  end

                  counts[:success] += 1
                else
                  $stderr.puts "  x  Error: #{ outcome.messages.join("\n") }".color(:red)
                  counts[:errors] += 1
                end
              end
            rescue StandardError => e
              counts[:errors] += 1
              $stderr.puts %(  x  Error: #{ e.class.name } - #{ e.message } - #{ e.backtrace.join("\n") }).color(:red)
            end
            counts[:total] += 1
          end
        end
      end

      # Moves files
      # @param [String] file_pattern A Dir.glob file pattern that describes
      #     the file set to be operated on. This is typically provided by either
      #     Rtfile or as command line argument by the user.
      # @param [Trequal] file_filter Each file's name (and path) is compared with
      #     file_filter using ===. The file will be processed if the comparison
      #     evaluates to true. file_filter can be anything that responds to
      #     #===, e.g., a Regexp, a Proc, or a String.
      #     This is provided by the callling command, limiting the files to be
      #     operated on to valid file types.
      #     See here for more info on ===: http://ruby.about.com/od/control/a/The-Case-Equality-Operator.htm
      # @param [Proc] output_path_lambda A proc that computes the output file
      #     path as string. It is given the input file path and output file attrs.
      #     If output_path_lambda returns '' (empty string), no files will be written.
      # @param [Hash] options
      #     :input_is_binary to force File.binread where required
      #     :output_is_binary
      #     :move_or_copy whether to move or copy the files, defaults to :move
      def self.move_files_helper(file_pattern, file_filter, output_path_lambda, description, options)
        options[:move_or_copy] ||= :move # options is a Thor::CoreExt::HashWithIndifferentAccess. Don't use merge!
        file_operation_method, verb = case options[:move_or_copy]
        when :copy
          [:copy_file_unless_path_is_blank, 'Copying']
        when :move
          [:move_file_unless_path_is_blank, 'Moving']
        else
          raise(ArgumentError.new("Invalid option :move_or_copy: #{ options[:move_or_copy].inspect }"))
        end
        with_console_output(description, file_pattern) do |counts|
          changed_files = compute_list_of_changed_files(options[:'changed-only'])
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
              $stderr.puts " - #{ verb } #{ filename }"

              new_path = output_path_lambda.call(filename)
              # new_path is either a file path or the empty string (in which
              # case we don't write anything to the file system).
              # NOTE: it's not enough to just check File.exist?(new_path) for
              # empty string in testing as FakeFS returns true. So I also
              # need to check for empty string separately to make tests work.
              exists_already = ('' != new_path && File.exist?(new_path))

              if exists_already
                self.send(file_operation_method, filename, new_path)
                counts[:updated] += 1
                $stderr.puts "  * Update: #{ new_path }"
              else
                FileUtils.mkdir_p(File.dirname(new_path))
                self.send(file_operation_method, filename, new_path)
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
      # @param [String] file_pattern A Dir.glob file pattern that describes
      #     the file set to be operated on. This is typically provided by either
      #     Rtfile or as command line argument by the user.
      # @param [Trequal] file_filter Each file's name (and path) is compared with
      #     file_filter using ===. The file will be processed if the comparison
      #     evaluates to true. file_filter can be anything that responds to
      #     #===, e.g., a Regexp, a Proc, or a String.
      #     This is provided by the callling command, limiting the files to be
      #     operated on to valid file types.
      #     See here for more info on ===: http://ruby.about.com/od/control/a/The-Case-Equality-Operator.htm
      # @param [Proc, nil] file_name_2_proc A proc that computes the filename of
      #     a paired file. It receives the name of the first filename as a single
      #     argument and is expected to return the full path to the second file.
      # @param [String] description A description of the operation, used for logging.
      # @param [Hash] options
      #     :input_is_binary to force File.binread where required
      #     :output_is_binary
      #     :'changed-only'
      #     :ignore_missing_file2 set to true if you quietly want to ignore missing file2, defaults to false
      #     :repository
      #     :use_new_r_file_api
      # @param [Proc] block A Proc that performs the desired operation on each file.
      #     Arguments to the proc are each file's name and contents.
      def self.read_files_helper(file_pattern, file_filter, file_name_2_proc, description, options, &block)

        with_console_output(description, file_pattern) do |counts|
          changed_files = compute_list_of_changed_files(options[:'changed-only'])
          ignore_missing_file2 = options[:ignore_missing_file2]
          Dir.glob(file_pattern).each do |filename_1|

            if file_filter && !(file_filter === filename_1) # file_filter has to be LHS of `===`
              $stderr.puts " - Skipping #{ filename_1 } - doesn't match file_filter"
              next
            end

            if changed_files && !changed_files.any? { |changed_file_rel_path|
              Regexp.new(changed_file_rel_path + "\\z") =~ filename_1
            }
              $stderr.puts " - Skipping #{ filename_1 } - has no changes"
              next
            end

            begin
              $stderr.puts " - Reading #{ filename_1 }"
              contents_1 = if options[:input_is_binary]
                File.binread(filename_1).freeze
              else
                File.read(filename_1).freeze
              end
              counts[:success] += 1
              if file_name_2_proc
                filename_2 = file_name_2_proc.call(filename_1)
                begin
                  contents_2 = if options[:input_is_binary]
                    File.binread(filename_2).freeze
                  else
                    File.read(filename_2).freeze
                  end
                  if options[:use_new_r_file_api]
                    # use new api
                    # TODO: once all calls use new API, move assignment of repo and language out of loop
                    repository = options[:repository]
                    language = content_type.language
                    block.call(
                      Repositext::RFile.get_class_for_filename(
                        filename_1
                      ).new(
                        contents_1, language, filename_1, repository
                      ),
                      Repositext::RFile.get_class_for_filename(
                        filename_2
                      ).new(
                        contents_2, language, filename_2, repository
                      ),
                    )
                  else
                    # use old api
                    block.call(contents_1, filename_1, contents_2, filename_2)
                  end
                rescue SystemCallError => e
                  # Error: Errno::ENOENT - No such file or directory
                  raise  unless ignore_missing_file2
                end
              else
                if options[:use_new_r_file_api]
                  # use new api
                  # TODO: once all calls use new API, move assignment of repo and language out of loop
                  content_type = options[:content_type]
                  language = content_type.language
                  block.call(
                    Repositext::RFile.get_class_for_filename(
                      filename_1
                    ).new(
                      contents_1, language, filename_1, content_type
                    )
                  )
                else
                  # use old api
                  block.call(contents_1, filename_1)
                end
              end
            rescue StandardError => e
              counts[:errors] += 1
              $stderr.puts(%(  x  Error: #{ e.class.name } - #{ e.message } - #{ e.backtrace.join("\n") }).color(:red))
            end

            counts[:total] += 1
          end
        end

      end


      # Wraps operations with log output
      # @param description [String] the text to print on the first line of console
      # @param file_pattern [String] the file pattern to print on first line of console
      # @param block [Block] the operation for which to print console output
      def self.with_console_output(description, file_pattern, &block)
        $stderr.puts ''
        $stderr.puts '-' * 80
        $stderr.puts "#{ description } at #{ file_pattern }"
        start_time = Time.now
        counts = Hash.new(0)

        yield(counts)

        file_pluralizer = lambda { |count| 1 == count ? 'file' : 'files' }

        $stderr.puts "Finished processing #{ counts[:success] } of #{ counts[:total] } #{ file_pluralizer.call(counts[:success]) } in #{ Time.now - start_time } seconds."
        $stderr.puts "* #{ counts[:created] } new #{ file_pluralizer.call(counts[:created]) } created"  if counts[:created] > 0
        $stderr.puts "* #{ counts[:updated] } existing #{ file_pluralizer.call(counts[:updated]) } updated"  if counts[:updated] > 0
        $stderr.puts "* #{ counts[:unchanged] } #{ file_pluralizer.call(counts[:unchanged]) } left unchanged"  if counts[:unchanged] > 0
        $stderr.puts "* #{ counts[:errors] } errors"  if counts[:errors] > 0
        $stderr.puts '-' * 80
      end

      # Replaces filename's extension with new_extension. If filename doesn't have
      # an extension, adds new_extension.
      # @param [String] filename the source filename with old extension
      # @param [String] new_extension the new extension to use, e.g., '.idml'
      # @return [String] filename with new_extension
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

      # Copies file_path to new_path. Overwrites existing files.
      # Doesn't copy file if file_path is blank (nil, empty string, or string
      # with only whitespace)
      # @param [String] file_path
      # @param [String] new_path
      # @return [Bool] true if it copied file, false if not.
      def self.copy_file_unless_path_is_blank(file_path, new_path)
        if '' == file_path.to_s.strip
          $stderr.puts %(  - Skip copying blank file_path)
          false
        else
          FileUtils.cp(file_path, new_path)
          true
        end
      end

      # Moves file_path to new_path. Overwrites existing files.
      # Doesn't move file if file_path is blank (nil, empty string, or string
      # with only whitespace)
      # @param [String] file_path
      # @param [String] new_path
      # @return [Bool] true if it moved file, false if not.
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
      # with only whitespace). Creates any missing folders in file_path.
      # @param [String] file_path
      # @param [String] file_contents
      # @return [Integer, Nil] the number of bytes written or false if nothing was written
      def self.write_file_unless_path_is_blank(file_path, file_contents, output_is_binary = false)
        if '' == file_path.to_s.strip
          $stderr.puts %(  - Skip writing "#{ file_contents.truncate_in_the_middle(60) }" to blank file_path)
          false
        else
          dir = File.dirname(file_path)
          unless File.directory?(dir)
            FileUtils.mkdir_p(dir)
          end
          if output_is_binary
            File.binwrite(file_path, file_contents)
          else
            File.write(file_path, file_contents)
          end
        end
      end

      # Returns a list of files that git considers changed:
      #     * modified or added
      #     * staged or unstaged
      # @param changed_only_flag [Boolean]
      # @param path [String, optional] limit scope to path. This is for testing.
      # @return [Array<String>, nil]
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
