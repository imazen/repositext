class Repositext
  class Subtitle
    class Operation

      # Represents a record_id change operation (not really a subtitle operation!)
      # We need to track record id changes as operations so that we can update
      # record_ids in the STM CSV file via the st-ops file.
      #
      class RecordIdChange < Operation

        def inverse_operation
          raise "Implement me!"
        end

        # Returns affected stids for inverse operation
        def inverse_affected_stids
          raise "Implement me!"
        end

      end
    end
  end
end
