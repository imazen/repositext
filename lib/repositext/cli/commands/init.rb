class Repositext
  class Cli
    module Init

    private

      # Generates a default Rtfile in the current working directory
      # @param[Hash] options
      def generate_rtfile(options)
        rtfile_path = File.join(Dir.getwd, "Rtfile")
        if !File.exist?(rtfile_path) || options['force']
          template('cli/templates/Rtfile.erb', rtfile_path)
        else
          $stderr.puts "An Rtfile already exists in the given location. Use the --force flag to overwrite it."
        end
      end

      def init_test(options)
        # dummy method for testing
        puts 'init_test'
      end

    end
  end
end
