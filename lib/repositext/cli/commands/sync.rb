class Repositext
  class Cli
    module Sync

    private

      # Syncs updates from AT to PT in /content
      def sync_from_at(options)
        input_file_spec = options['input'] || 'content_dir/at_files'
        Repositext::Cli::Utils.convert_files(
          config.compute_glob_pattern(input_file_spec),
          /\.at\Z/i,
          "Synching AT files to PT",
          options
        ) do |contents, filename|
          # Remove AT specific tokens
          pt = Suspension::TokenRemover.new(
            contents,
            Suspension::AT_SPECIFIC_TOKENS
          ).remove
          [Outcome.new(true, { contents: pt, extension: '.md' })]
        end
      end

      def sync_test(options)
        # dummy method for testing
        puts 'sync_test'
      end

    end
  end
end
