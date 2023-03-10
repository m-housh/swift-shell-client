DOCC_TARGET ?= ShellClient
DOCC_BASE_PATH = $(shell basename "$(PWD)")

test-library:
	swift run -c release test-library

test-linux:
	docker run --rm \
		-v "$(PWD):$(PWD)" \
		-w "$(PWD)" \
		swift:5.7-focal \
		swift test

run-version-linux:
	docker run -it --rm \
		-v "$(PWD):$(PWD)" \
		-w "$(PWD)" \
		swift:5.7-focal \
		swift run version

clean:
	rm -rf ./.build

format:
	swift format \
		--ignore-unparsable-files \
		--in-place \
		--recursive \
		./Package.swift \
		./Sources

lint:
	swift format lint \
		--ignore-unparsable-files \
		--recursive \
		./Sources

build-documentation:
	swift package \
		--allow-writing-to-directory ./docs \
		generate-documentation \
		--target "$(DOCC_TARGET)" \
		--disable-indexing \
		--transform-for-static-hosting \
		--hosting-base-path "$(DOCC_BASE_PATH)" \
		--output-path ./docs

preview-documentation:
	swift package \
		--disable-sandbox \
		preview-documentation \
		--target "$(DOCC_TARGET)"
