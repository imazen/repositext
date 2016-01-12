Sometimes we want to replace client specific text with placeholder text, esp. for automated testing.

Here is an example:

“This is some example text that will be replaced with placeholder text”

is converted to

“Word word word word word word word word word word word word”

Here is how to do it in sublime text:

* Select the text to be replaced
* Press <Alt> + <Command> + F
* Enter this into `Find What:`  [a-zÀ-ÿ]+
* Enter this into `Replace With:` word
* Select
    * Regular Expression
    * Case insensitive
    * In selection
    * Preserve case
* Select `Replace All`
