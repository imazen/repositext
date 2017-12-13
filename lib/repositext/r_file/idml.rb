class Repositext
  class RFile

    # Represents an Idml file in repositext.
    class Idml < RFile

      include FollowsStandardFilenameConvention
      include HasCorrespondingContentAtFile
      include IsBinary

    end
  end
end
