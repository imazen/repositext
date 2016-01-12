class Repositext
  class Subtitle
    class Operation

      # Represents a delete subtitle operation.
      #
      class Delete < Operation

        def inverse_operation
          Subtitle::Operation.new_from_hash(
            affectedStids: inverse_affected_stids,
            operationId: '',
            operationType: :insert,
          )
        end

        # Returns affected stids for inverse operation
        def inverse_affected_stids
          affectedStids.map { |e|
            before, after = e.tmp_attrs[:after], e.tmp_attrs[:before]
            e.tmp_attrs[:before] = before
            e.tmp_attrs[:after] = after
            e
          }
        end

      end

    end
  end
end
