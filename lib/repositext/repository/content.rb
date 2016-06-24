class Repositext
  class Repository

    # Represents a git content repository
    class Content < Repositext::Repository

      include Repository::HasDataJsonFile

    end
  end
end
