.SILENT:
  .DEFAULT_GOAL := help

.PHONY: help
help:
	$(info blue-rook.github.io:)
	$(info -> run                         Serves website at http://localhost:1313/)
	$(info -> run-drafts                  Serves website including draft posts)
	$(info -> build                       Builds deployable version to public/)
	$(info -> clean                       Removes build artifacts)
	$(info -> new name=[slug]             Creates a new blog post)
	$(info -> update                      Updates Hugo modules)

.PHONY: run
run:
	hugo server

.PHONY: run-drafts
run-drafts:
	hugo server -D

.PHONY: build
build:
	hugo --gc --minify

.PHONY: clean
clean:
	rm -rf public/ resources/_gen/

.PHONY: new
new:
	hugo new content/blog/$(name)/index.md

.PHONY: update
update:
	hugo mod get -u
	hugo mod tidy
