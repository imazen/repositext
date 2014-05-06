=begin

We want to log the following:

* who made a change
* when
* what command did they use
* proof that every change to repo is logged in command log
    * digest of salient files
    * can't execute new command if current repo state (or git commit)
      is not consistent with previously recorded hash.

=end
