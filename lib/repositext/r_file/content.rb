class Repositext
  class RFile

    # Represents a generic content file. Check if a more specific class exists
    # before you use this class!
    class Content < RFile

      include FollowsStandardFilenameConvention
      include HasCorrespondingContentAtFile
      include HasCorrespondingPrimaryContentAtFile
      include HasCorrespondingPrimaryFile

    end
  end
end
