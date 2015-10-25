# Test git repos

We have to do a little dance to create test git repos inside the `repositext`
git repo (since git doesn't allow nested independent repos).

So here is what we do:

* We `.gitignore` the `spec/git_test/repos` directory. This gives us a place
  where we can have nested independent repos without interfering with the
  parent `repositext` repo.
* We create test repos inside `spec/git_test/repos` from templates stored in
  `spec/git_test/repo_templates`.
* We track the test repo templates under the main `repositext` git repo. This
  is possible because we renamed the test repos' `.git` directory to `dot_git`.
  This gives us a snapshot of a git repo with all the git binary files without
  it actually being a git repo.
* In order to create a test git repo from a template, we copy all the files
  from the `test_repo_templates` folder to the `test_repos` folder and then
  rename the `dot_git` directory to `.git`. This creates a valid git repo
  inside a `.gitignore`d folder.

This process allows us to have the test git repos under version control for
cloning and distribution, and it gives us nested working git repos for testing.
