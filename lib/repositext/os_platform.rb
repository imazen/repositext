# Detects what OS repositext is running on: :linux and :mac_os
class Repositext

  # Represents the operating system repositext is running on.
  # Currently supported:
  # * :mac_os
  # * :linux
  class OsPlatform

    # Returns id of operating system.
    # @return [Symbol] one of :mac_os or :linux
    def self.id
      if OS.mac?
        :mac_os
      elsif OS.linux?
        :linux
      else
        raise "Handle this: \n\n#{ OS.report }"
      end
    end
  end
end
