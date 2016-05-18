class Repositext
  class RFile

    # Represents a Subtitle marker CSV file in repositext.
    class SubtitleMarkersCsv < RFile

      include FollowsStandardFilenameConvention
      include HasCorrespondingContentAtFile
      include HasCorrespondingPrimaryContentAtFile
      include HasCorrespondingPrimaryFile

    end
  end
end
