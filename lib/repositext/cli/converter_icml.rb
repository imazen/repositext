# Implements the command line interface for the ICML converter.
$stdout.sync = true

require 'optparse'

class Repositext
  class Cli
    class ConverterIcml

      attr_accessor :options

      # See method 'compute_options' for details, or type `kramdown_to_icml -h`
      # on command line for help info.
      # @param[Command line arguments] argv
      def initialize(argv)
        @file_pattern = argv.shift
        @options = compute_options(argv)
      end

      # Runs validations
      def run
        STDERR.puts "Batch importing all kramdown files at #{ @file_pattern }."
        STDERR.puts '-' * 80
        start_time = Time.now
        total_count = 0
        success_count = 0
        errors_count = 0

        Dir.glob(@file_pattern).find_all{ |e| e =~ /\.(at|md)$/ }.each do |kramdown_file_name|
          STDERR.puts " - importing  #{ kramdown_file_name }"
          begin
            icml_file_name = kramdown_file_name.gsub(/\.[^\.]+$/, '.icml')
            STDERR.puts "   writing to #{ icml_file_name }"
            Kramdown::Document.new(
              File.read(kramdown_file_name),
              {
                :input => :repositext,
                :output_file => File.new(icml_file_name, 'w'),
                :template_file => File.new(@options[:template_path], 'r')
              }
            ).to_icml
            success_count += 1
          end
          total_count += 1
        end

        STDERR.puts '-' * 80
        STDERR.puts "Finished converting #{ success_count } of #{ total_count } kramdown files in #{ Time.now - start_time } seconds. There were #{ errors_count } errors."
      end

    private

      # Computes options based on ARGV
      # @param[ARGV] as given on command line
      # @return[Hash] the options as hash (symbolized keys)
      def compute_options(argv)
        # Set defaults
        opts = {
          :template_path => File.expand_path("../../../../data/icml_template.erb", __FILE__)
        }

        @parser = OptionParser.new do |o|
          o.banner = "Usage: kramdown_to_icml <file pattern> [options]"
          o.separator ""
          o.separator "Specific options:"

          o.on '-t', '--template TEMPLATE', "path to the ICML template to use. Has reasonable default." do |arg|
            opts[:template_path] = arg
          end
        end

        @parser.on_tail "-h", "--help", "Show help and exit." do
          puts @parser
          exit(1)
        end
        @parser.parse!(argv)

        opts[:template_path] = File.expand_path(opts[:template_path])

        opts
      end

    end
  end
end
