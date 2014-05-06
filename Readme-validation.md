Repositext Validation
=====================

A command-line tool to validate repositext documents.

Installation (while in development)
-----------------------------------

* Install Ruby 2.0 using rbenv or rvm.
* Install the bundler gem: `gem install bundler`
* Clone the repository from github.com
* Switch into the repositext-validation directory: `cd repositext-validation`
* Install the required gems: `bundle install`

Concepts
--------

### Validator

A validator checks a File or a FileSet for certain qualities. There are two
types of Validators:

* Validator - validates single files, e.g., file encoding, syntax and contents.
* FileSetValidator - validates file sets, e.g., consistency between files, and
  presence of expected files.

### File and FileSet

Validators operate either on single files or file sets. E.g., a File can be
validated for UTF8 encoding, or a File Set can consist of an IDML import source
file and the resulting kramdown file. A File Set Validator would then validate
that both files are consistent.

### Profile

A Profile is used to define the validation run-list. A Profile determines:

* Which Files or FileSets are being validated.
* Which Validators are applied.
* How those validators are configured.

There are two types of Profiles:

* FileProfile - defines validation workflows for single Files.
* FileSetProfile - defines validation workflows for FileSets.

Given a FilePattern, repositext-validation tries to find a default Profile to
use for validation. The Profile used can be overridden via a command line param.
If FilePattern describes a ...

* single file, then a FileProfile will be applied.
* set of files, then a FileSetProfile will be applied.

### FilePattern

You can use file patterns to select which files you want to validate. You can
use all features of [Ruby's Dir.glob method](http://ruby-doc.org/core-2.0.0/Dir.html#method-c-glob).

When providing a relative file pattern, the current directory will be used as
base directory.

**IMPORTANT NOTE**: When using glob patterns, it is important that you surround
the pattern with quotes. Otherwise the shell will evaluate the pattern and you
will likely only validate a single file (the first one that matches the pattern).




Usage
-----

### The simplest way to use repositext-validation:

Validate all documents in the current directory:

    repositext-validation


### Command line options overview

You can use the following command line options to configure repositext-validation:

|Short| Long                       |Description|
|-----|----------------------------|-----------|
| -f  | --file_pattern PATTERN     | a file pattern that describes which files should be validated; optional, has reasonable defaults based on current directory. |
| -p  | --profile_override PROFILE | which profile to use; optional, has reasonable defaults based on scope and file_pattern. |
| -V  | --version                  | Print version and exit. Please note that this is an upper case 'V'. |
| -h  | --help                     | Show help and exit. |


### FilePattern command line option

#### Examples

Validate a single file:

    bundle exec repositext-validation -f ../docs/a_document.at

Validate all files in a directory:

    bundle exec repositext-validation -f '../docs/*'

Validate all AT files in a directory:

    bundle exec repositext-validation -f '../docs/*.at'

Recursively validate all json files starting at the top level directory:

    bundle exec repositext-validation -f '../docs/**/*.json'

Validate all AT and PT files in a directory:

    bundle exec repositext-validation -f '../docs/*.{at,md}'

#### File pattern reference

| Pattern | Example        | Description |
|---------|----------------|-------------|
| *       | docs/*         | Matches any file. Can be restricted by other values in the glob. * will match all files; c* will match all files beginning with c; *c will match all files ending with c; and *c* will match all files that have c in them (including at the beginning or end). Equivalent to / .* /x in regexp. Note, this will not match Unix-like hidden files (dotfiles). In order to include those in the match results, you must use something like "{*,.*}". |
| **      | docs/**/*      | Matches directories recursively. This will walk all sub-directories of the directory tree. |
| ?       | doc_?.at       | Matches any one character. Equivalent to /.{1}/ in regexp. |
| [set]   | doc_[ab].*     | Matches any one character in set. Behaves exactly like character sets in Regexp, including set negation ([^a-z]). |
| {p,q}   | *.{at,md}      | Matches either literal p or literal q. Matching literals may be more than one character in length. More than two literals may be specified. Equivalent to pattern alternation in regexp. |
| \       | question\?.txt | Escapes the next metacharacter. Note that this means you cannot use backslash in windows as part of a glob, i.e. Dir["c:\foo*"] will not work, use Dir["c:/foo*"] instead. |

See [Ruby Dir.glob documentation](http://ruby-doc.org/core-2.0.0/Dir.html#method-c-glob) for more info.

### Profile override command line option

When overriding the profile, just provide the name of the subclass without any
namespaces. Example: for `Repositext::Validation::FileProfile::TxtDefault` just
provide `TxtDefault`.

#### Example

Provide a profile override

    bundle exec repositext-validation -f ../docs/*.at -p CustomAtProfile


### Other command line options

#### Example

Get the version

    bundle exec repositext-validation -V

Get help

    bundle exec repositext-validation -h



### Custom Profiles

Repositext-validation comes with reasonable defaults for the common use cases.
If you want to customize a profile, follow these steps:

1. Determine the scope of the Profile: `File` or `FileSet`.
2. Duplicate one of the existing profiles in the scope you picked.
3. Change the name and customize the following methods:
      * `def self.can_handle_file_pattern?` - this class method
        returns `true` for any file patterns it can handle.
      * `def run` - this instance method invokes all validations that will be
        run for this profile.
4. When using the command-line tool, provide your custom profile as a profile
   override.

There is no need to register the new profile. It will be detected automatically
by the FileProfile or FileSetProfile class via the `inherited` callback.

### Custom Validations

Follow these steps to create a custom validation:

1. Determine the scope of the Validation: `File` or `FileSet`.
2. Duplicate one of the existing validations in the scope you picked.
3. Change the name and customize the following methods:
      * `def run` - this instance method invokes all validation helper methods
        and adds any errors or warnings to the profile's error collector.
4. Create a custom profile that will invoke the new custom validation.

Specs
-----

Run the entire spec suite:

    bundle exec rake

Run a single spec file:

    bundle exec ruby spec/file_validator/encoding_utf8_spec.rb


