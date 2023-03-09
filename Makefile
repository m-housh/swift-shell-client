
test-linux:
	docker run -it --rm \
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
		--target Validations \
		--disable-indexing \
		--transform-for-static-hosting \
		--hosting-base-path swift-validations \
		--output-path ./docs
