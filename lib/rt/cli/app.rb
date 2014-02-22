module Rt
  module Cli
    class App < Thor

      #desc "Manage a repositext repository"
      #require_relative('Rtfile') if File.exist?('Rtfile')

      # basic commands
      desc "compare [command]", "Desc. TBD"
      subcommand "compare", Compare

      desc "convert [command]", "Desc. TBD"
      subcommand "convert", Convert

      desc "fix [command]", "Desc. TBD"
      subcommand "fix", Fix

      desc "merge [command]", "Desc. TBD"
      subcommand "merge", Merge

      desc "sync [command]", "Desc. TBD"
      subcommand "sync", Sync

      desc "validate [command]", "Desc. TBD"
      subcommand "validate", Validate

      # Higher level commands
      desc "export [command]", "Desc. TBD"
      subcommand "export", Export

      desc "import [command]", "Desc. TBD"
      subcommand "import", Import

    end
  end
end
