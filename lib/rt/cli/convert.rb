module Rt
  module Cli
    class Convert < Thor

      # include Rtfile

      # TODO: specify common options as class_option

      desc 'convert idml_to_kramdown', 'Convert IDML files to kramdown'
      long_desc %(
        Convert IDML files to kramdown. Defaults to the repo's 'import_idml'
        directory as input. Stores the generated AT files in the same directory
        as the source IDML files.

        Example:

        rt convert idml_to_kramdown -i='../import_idml/idml/**/*.idml'
      )
      method_option :input,
                    :type => :string,
                    :aliases => "-i",
                    :desc => "A glob pattern for the input file set, e.g., -i='../import_idml/idml/**/*.idml'"
      def idml_to_kramdown
        input_file_pattern = options[:input] || File.join(Dir.getwd, "import_idml/**/*.idml")
        Rt::Cli::Utils.convert_files(
          input_file_pattern,
          /\.idml\Z/i,
          "Converting IDML files into kramdown and json"
        ) do |contents, filename|
          doc = Kramdown::Parser::Idml.new(contents).parse
          [Outcome.new(true, { extension: 'at', contents: doc })]
        end
      end

    end
  end
end
