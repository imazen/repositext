class Repositext
  class Rt
    module Init

    private

      # Generates a default Rtfile in the current working directory
      # @param[Hash] options
      def generate_rtfile(options)
        rtfile_path = File.join(Dir.getwd, "Rtfile")
        if !File.exist?(rtfile_path) || options['force']
          template('rt/rtfile_template.erb', rtfile_path)
        else
          STDERR.puts "An Rtfile already exists in the given location. Use the -f flag to force overwriting it."
        end
      end

    end
  end
end
