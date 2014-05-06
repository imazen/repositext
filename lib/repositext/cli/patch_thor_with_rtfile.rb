class Thor
  module Invocation

    # Patch invoke_command to load the Rtfile
    def invoke_command(command, *args)
      current = @_invocations[self.class]

      unless current.include?(command.name)
        current << command.name

        # Added JH start
        # NOTE: `self` is an instance of Repositext::Cli
        if options['rtfile']
          eval_rtfile(options['rtfile'])
        end
        # Added JH end

        command.run(self, *args)
      end
    end

  end
end
