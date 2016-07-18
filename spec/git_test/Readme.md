# Test git repos

See `Repositext::Repository::Test` for details.

To work on the content of the repos, follow these steps:

* Convert `dot_git` folders to `.git` folders.
  Run this command in the repositext folder:
      `mv spec/git_test/repo_images/rt-english/dot_git spec/git_test/repo_images/rt-english/.git`
* Make content changes
* Commit changes in test repository
* Convert `.git` folders back to `dot_git` folders.
      `mv spec/git_test/repo_images/rt-english/.git spec/git_test/repo_images/rt-english/dot_git`
* Commit changes in repositext
