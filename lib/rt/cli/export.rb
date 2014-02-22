module Rt
  module Cli
    class Export < Thor

      # desc "to_icml", "Export from master .at to export_icml"
      # def to_icml
      #   Rt::Cli::Utils.export_files("master/**/*.at", "export_icml", /\.(at|pt)\Z/i, "Converting kramdown to icml") do |text|
      #     doc = Kramdown::Document.new(text, :input => 'KramdownVgr')
      #     [{extension: "icml",
      #       contents: doc.to_icml_vgr}]
      #   end
      # end

    end
  end
end
