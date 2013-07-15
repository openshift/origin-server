# OpenShift Origin Manuals #

This repo contains AsciiDoc versions of the OpenShift Origin manuals. The manuals were initially based on the OpenShift Enterprise lab manual by [Grant Shipley](https://github.com/gshipley).

## Building the Manuals ##
The manuals themselves are .txt files written in [AsciiDoc](http://asciidoc.org/), so they are easily human-readable. For the purposes of developing different output options, a small build environment has been configured in Ruby using:

* [AsciiDoctor](http://asciidoctor.org/)
* [Guard](http://guardgem.org/)
* [LiveReload](http://livereload.com/)

To use the build environment, first install the necessary gems:

    bundle install

Then start the guard process:

    bundle exec guard

You will see output from the guard process as it monitors changes to the *.txt files and regenerates the HTML files.

If you are making changes to the manuals, you can get a live preview of changes as you make them by installing the LiveReload extension in your browser (Firefox, Chrome and Safari are supported).
 
## Old Manuals ##
The `archive` subdirectory contains older manuals that were written in Markdown. Over time, the contents of these files will be updated to AsciiDoc and assimilated into the documents in this directory.
