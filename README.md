# blog

A personal blog generated with [Hugo][hugo-main]. Check out the blog live [here][blog].

[hugo-main]: https://gohugo.io/
[blog]: https://keeler.github.io/posts

## Running Locally

Running `make` or `make drafts` will host the site locally at [http://localhost:1313/](http://localhost:1313/).

Changes to the posts, styling, etc. should be reloaded automatically.

## Deploying

First, run `make live` to host the site locally at [http://localhost:1313/](http://localhost:1313/) without draft posts; this is what the site will look like live.

When you're ready to publish run `make publish` to build and deploy to the live site.

In particular, `make publish` does the following:

1. Build the site as a set of static files in the `public/` subdirectory.
2. Push the updates in `public/` to the [GitHub page repo][github-page-repo]. (`public/` is a git submodule pointing at the GitHub page repo).
3. Update this repo's submodule reference to account for the update.

This is based on the guidance outlined in the [Hugo docs for hosting on Github][hugo-github-pages].

Note, you can build the site without deploying it by running `make build`.

[hugo-github-pages]: https://gohugo.io/hosting-and-deployment/hosting-on-github/#github-user-or-organization-pages
[github-page-repo]: https://github.com/keeler/keeler.github.io
