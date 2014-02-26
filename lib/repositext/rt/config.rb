# Manages configuration of Rt instance (via Rtfile)
class Repositext
  class Rt
    class Config

      # @param[Repositext::Rt] rt_instance
      def initialize(rt_instance)
        @rt_instance = rt_instance
        @file_patterns = {}
      end

      def add_file_pattern(name, block)
        @file_patterns[name.to_sym] = block
      end

    end
  end
end
