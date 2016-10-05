# Server: ExtractTextFromPdf

This server extracts text from PDF files. It runs as a jruby process and can be controlled via TCP sockets.

The server is controlled via TCP socket by the related client class inside MRI repositext: `repositext/services/extract_text_from_pdf`

This folder contains its own Ruby environment:

* jruby instead of MRI
* separate gemset

See bin/extract-text-from-pdf for details.

## How to update the Gems for this server process

    cd repositext/servers/extract_text_from_pdf
    bundle install
