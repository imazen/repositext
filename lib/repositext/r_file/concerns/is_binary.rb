class Repositext
  class RFile
    module IsBinary

      extend ActiveSupport::Concern

      def is_binary
        true
      end

    end
  end
end
