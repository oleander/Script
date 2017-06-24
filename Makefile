export TESTS=1

default: test
install:
	gem install xcpretty
test:
	swift test 2>&1 | xcpretty
lint:
	pod lib lint
clean:
	swift package clean
	swift package reset
	pod cache clean --all