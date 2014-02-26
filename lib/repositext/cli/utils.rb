class Repositext
  class Cli
    module Utils

      # Utils module provides methods commonly used by the rt commands

      # Changes files in place, updating their contents
      # @param: See #process_files below for param description
      def self.change_files_in_place(file_pattern, file_filter, description, &block)
        # Use input file path
        output_path_lambda = lambda do |input_filename, output_file_attrs|
          input_filename
        end
        process_files(file_pattern, file_filter, description, output_path_lambda, &block)
      end

      # Converts files from one format to another
      # @param: See #process_files below for param description
      def self.convert_files(file_pattern, file_filter, description, &block)
        # Change file extension only.
        output_path_lambda = lambda do |input_filename, output_file_attrs|
          replace_file_extension(input_filename, output_file_attrs[:extension])
        end

        process_files(file_pattern, file_filter, description, output_path_lambda, &block)
      end

      # Exports files to another format and location
      # @param: See #process_files below for param description
      # @param[String] out_dir the output base directory
      def self.export_files(file_pattern, out_dir, file_filter, description, &block)
        # Change output file path
        output_path_lambda = lambda do |input_filename, output_file_attrs|
          File.join(
            out_dir,
            File.basename(input_filename, File.extname(input_filename)) + "." + output_file_attrs[:extension]
          )
        end

        process_files(file_pattern, file_filter, description, output_path_lambda, &block)
      end

      # Does a dry-run of the process. Printing out all debug and logging info
      # but not saving any changes to disk.
      # @param: See #process_files below for param description
      # @param[String] out_dir the output base directory
      def self.inspect_process(file_pattern, out_dir, file_filter, description, &block)
        # Always return empty string to skip writing to disk
        output_path_lambda = lambda do |input_filename, output_file_attrs|
          ''
        end

        process_files(file_pattern, file_filter, description, output_path_lambda, &block)
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
      # @param[String] description A description of the operation, used for logging.
      # @param[Proc] output_path_lambda A proc that computes the output file
      #     path as string. It is given the input file path and output file attrs.
      #     If output_path_lambda returns '' (empty string), no files will be written.
      # @param[Proc] block A Proc that performs the desired operation on each file.
      #     Arguments to the proc are each file's name and contents.
      #     Calling block is expected to return an Outcome object with
      #       * success:  Boolean
      #       * result:   A hash with :contents and :extension keys
      #       * messages: An array of message strings.
      def self.process_files(file_pattern, file_filter, description, output_path_lambda, &block)
        STDERR.puts "#{ description } at #{ file_pattern }."
        STDERR.puts '-' * 80
        start_time = Time.now
        total_count = 0
        success_count = 0
        updated_count = 0
        unchanged_count = 0
        created_count = 0
        errors_count = 0

        Dir.glob(file_pattern).each do |filename|

          if file_filter && !(file_filter === filename) # file_filter has to be LHS of `===`
            STDERR.puts " - Skipping #{ filename }"
            next
          end

          begin
            STDERR.puts " - Processing #{ filename }"
            contents = File.binread(filename).freeze
            outcomes = block.call(contents, filename)

            outcomes.each do |outcome|
              if outcome.success
                output_file_attrs = outcome.result
                new_path = output_path_lambda.call(filename, output_file_attrs)
                # new_path is either a file path or the empty string (in which
                # case we don't write anything to the file system).
                existing_contents = File.exist?(new_path) ? File.read(new_path) : nil
                new_contents = output_file_attrs[:contents]
                message = outcome.messages.join("\n")

                if(nil == existing_contents)
                  write_file_unless_path_is_blank(new_path, new_contents)
                  created_count += 1
                  STDERR.puts " * Created #{ new_path } #{ message }"
                elsif(existing_contents != new_contents)
                  write_file_unless_path_is_blank(new_path, new_contents)
                  updated_count += 1
                  STDERR.puts " * Changed #{ new_path } #{ message }"
                else
                  unchanged_count += 1
                  STDERR.puts "   No change #{ new_path } #{ message }"
                end
                success_count += 1
              else
                STDERR.puts " x  Error: #{ message }"
                errors_count += 1
              end
            end
          rescue => e
            STDERR.puts " x  Error: #{ e.class.name } - #{ e.message } - #{errors_count == 0 ? e.backtrace : ''}"
            errors_count += 1
          end
          total_count += 1
        end

        STDERR.puts '-' * 80
        STDERR.puts "Finished processing #{ success_count } of #{ total_count } files in #{ Time.now - start_time } seconds."
        STDERR.puts "* #{ created_count } files created"  if created_count > 0
        STDERR.puts "* #{ updated_count } files updated"  if updated_count > 0
        STDERR.puts "* #{ unchanged_count } files left unchanged"  if unchanged_count > 0
        STDERR.puts "* #{ errors_count } errors"  if errors_count > 0
      end

      # Replaces filename's extension with new_extension
      # @param[String] filename the source filename with old extension
      # @param[String] new_extension the new extension to use, e.g., '.idml'
      # @return[String] filename with new_extension
      def self.replace_file_extension(filename, new_extension)
        basepath = filename[0...-File.extname(filename).length]
        new_extension = '.' + new_extension.sub(/\A\./, '')
        basepath + new_extension
      end

      # Writes file_contents to file at file_path. Overwrites existing file.
      # Doesn't write to file if file_path is blank (nil, empty string, or string
      # with only whitespace)
      # @param[String] file_path
      # @param[String] file_contents
      def self.write_file_unless_path_is_blank(file_path, file_contents)
        if '' == file_path.to_s.strip
          STDERR.puts "- skip writing #{ file_contents.size } bytes to #{ file_path }"
        else
          File.write(file_path, file_contents)
        end
      end

    end
  end
end
