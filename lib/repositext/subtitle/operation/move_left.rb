class Repositext
  class Subtitle
    class Operation

      # Represents a move left subtitle operation.
      class MoveLeft < Operation

        def inverse_operation
          Subtitle::Operation.new_from_hash(
            affected_stids: inverse_affected_stids,
            operation_id: '',
            operation_type: :move_right,
          )
        end

        # Returns affected stids for inverse operation
        def inverse_affected_stids
          affected_stids.map { |e|
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
