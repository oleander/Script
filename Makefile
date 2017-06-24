default: test
install:
	gem install xcpretty
test:
	swift test 2>&1 | xcpretty
lint:
	pod lib lint