# Test git repos

We have to do some extra steps to create test git repos inside the `repositext`
git repo since git doesn't allow nested independent repos.

So here is what we do:

* We `.gitignore` the `spec/git_test/repos` directory. This gives us a place
  where we can have nested independent repos without interfering with the
  parent `repositext` repo.
* We create test repos inside `spec/git_test/repos` from images stored in
  `spec/git_test/repo_images`.
* We track the test repo images under the main `repositext` git repo. This
  is possible because we rename the test repos' `.git` directory to `dot_git`.
  This gives us an image of a git repo with all the git binary files without
  it actually being a git repo.
* In order to create a test git repo from an image, we copy all the files
  from the `test_images` folder to the `repos` folder and then rename the 
  `dot_git` directory to `.git`. This creates a valid git repo inside a 
  `.gitignore`d folder.

This process allows us to have the test git repos under version control for
cloning and distribution, and it gives us nested working git repos for testing.

To initialize all test git repos from their respective images:

    Repositext::Repository::Test.initialize

To initialize a single test git repo:

    Repositext::Repository::Test.initialize('rt-english')
