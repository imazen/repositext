Repositextx instructions
========================

Imports
-------

* Import all
    bundle exec rt import all --changed-only=false
* Import folio
    bundle exec rt import folio_xml --changed-only=false
* Import idml
    bundle exec rt import idml --changed-only=false

Exports
-------

* Export ICML
    bundle exec rt export icml --changed-only=false

Plaintext compare scripts
-------------------------

These haven't been ported to the new thor based CLI yet.

bundle exec compare_content_create
bundle exec compare_content_prepare
bundle exec compare_content_diff

bundle exec compare_folio_create
bundle exec compare_folio_prepare
bundle exec compare_folio_diff

bundle exec compare_idml_create
bundle exec compare_idml_prepare
bundle exec compare_idml_diff

Side by side record id proofing
-------------------------------

bundle exec rt compare record_id_and_paragraph_alignment --changed-only=false

Generate quote reports
----------------------

bundle exec rt report quotes_summary --changed-only=false
bundle exec rt report quotes_details --changed-only=false
bundle exec rt report invalid_typographic_quotes --changed-only=false
