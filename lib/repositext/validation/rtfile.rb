class Repositext
  class Validation

    # This Validation is different from the others. It doesn't write the
    # result to a file, but directly to the console.
    class Rtfile

      # @param [String] rtfile_base_dir the directory in which the rtfile is located
      # @param [Repositext::Cli::Config] config
      def initialize(rtfile_base_dir, config)
        @validated_rtfile_base_dir = rtfile_base_dir
        @validated_config = config
        # Load reference config from Rtfile template
        @reference_config = load_reference_config(
          File.expand_path("../../../../templates/Rtfile", __FILE__)
        )
      end

      def run
        $stderr.puts
        $stderr.puts '-' * 80
        $stderr.puts "Validating Rtfile at #{ @validated_rtfile_base_dir }"
        missing_keys = find_missing_keys
        extra_keys = find_extra_keys
        if missing_keys.any?
          $stderr.puts 'The following keys are missing:'
          missing_keys.each { |e|
            $stderr.puts " * #{ e }"
          }
        else
          $stderr.puts 'No keys are missing.'
        end
        if extra_keys.any?
          $stderr.puts 'The following extra keys were found:'
          extra_keys.each { |e|
            $stderr.puts " * #{ e }"
          }
        else
          $stderr.puts 'No extra keys found.'
        end
        $stderr.puts '-' * 80
      end

      # This is a method stub to satisfy the Repositext::Validation interface.
      def run_list; end

    private

      # @param [String] rtfile_path to the reference config (Rtfile template)
      # @return [Repositext::Cli::Config] a reference config
      def load_reference_config(rtfile_path)
        Repositext::Cli::Config.new(rtfile_path).tap(&:eval)
      end

      # Finds keys that are in @reference_config but not in @validated_config
      def find_missing_keys
        compute_keys_delta(@reference_config, @validated_config)
      end

      # Finds keys that are in @validated_config but not in @reference_config
      def find_extra_keys
        compute_keys_delta(@validated_config, @reference_config)
      end

      # Returns a list of keys that are in config_1 but not in config_2
      def compute_keys_delta(config_1, config_2)
        missing_keys = []
        %w[
          base_dirs
          file_extensions
          file_selectors
          kramdown_converter_methods
          kramdown_parsers
          settings
        ].each { |key_group|
          keys_1 = config_1.instance_variable_get("@#{ key_group }").keys
          keys_2 = config_2.instance_variable_get("@#{ key_group }").keys
          missing_keys += (keys_1 - keys_2).map { |e| "#{ key_group }: #{ e }"}
        }
        missing_keys
      end

    end
  end
end
