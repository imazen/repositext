class Repositext
  class RFile
    # Include this module in any RFile subclass that uses a binary file format.
    module IsBinary

      extend ActiveSupport::Concern

      def is_binary
        true
      end

    end
  end
end
