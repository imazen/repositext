class Repositext
  class Rt
    module Convert

    private

      # Convert IDML files in /import_idml to AT
      def convert_idml_to_at(options)
        # input_file_pattern = options[:input] || File.join(Dir.getwd, "import_idml/**/*.idml")
        # Repositext::Rt::Utils.convert_files(
        #   input_file_pattern,
        #   /\.idml\Z/i,
        #   "Converting IDML files into kramdown and json"
        # ) do |contents, filename|
        #   doc = Kramdown::Parser::Idml.new(contents).parse
        #   [Outcome.new(true, { extension: 'at', contents: doc })]
        # end
      end

    end
  end
end
