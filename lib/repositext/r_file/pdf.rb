class Repositext
  class RFile

    # Represents a PDF file in repositext.
    class Pdf < RFile

      include FollowsStandardFilenameConvention
      include HasCorrespondingContentAtFile
      include HasCorrespondingPrimaryContentAtFile
      include HasCorrespondingPrimaryFile
      include IsBinary

    end
  end
end
