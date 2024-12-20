DOCC_TARGET ?= ShellClient
DOCC_BASE_PATH = $(shell basename "$(PWD)")
SWIFT_DOCKER_VERSION ?= "5.10"

test-library:
	swift test

test-linux:
	docker run --rm \
		-v "$(PWD):$(PWD)" \
		-w "$(PWD)" \
		"swift:$(SWIFT_DOCKER_VERSION)" \
		swift test

run-version-linux:
	docker run -it --rm \
		-v "$(PWD):$(PWD)" \
		-w "$(PWD)" \
		"swift:$(SWIFT_DOCKER_VERSION)" \
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
