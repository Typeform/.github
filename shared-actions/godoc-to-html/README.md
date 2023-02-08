**Godoc to HTML**

New action to generate HTML godocs from a Go repository.
It automatically searches the `go.mod` file, builds the go docs, and downloads all the pages, linking them properly.
It creates a new `godocs` directory in the GH workspace with all the documentation.

**Usage example**

In the `blocks` repository, we use the `godoc-to-html` action, deploy a preview with `surge.sh` and deploy the end version to GitHub pages, as you can see here: https://github.com/Typeform/blocks/pull/1340
The output: https://typeform.design/blocks/godocs/go.html
