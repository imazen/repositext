module Rt
  module Cli
    class Import < Thor

      desc 'import idml', 'Import IDML and merge into master'
      def idml
        # convert idml_to_at
        # merge record_marks_from_folio_at_into_idml_at
        # fix adjust_record_mark_positions
      end

    end
  end
end
