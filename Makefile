default: test
install:
	gem install xcpretty
test:
	mkdir -p .build
	rm -f .build/log
	touch .build/log
	swift test 2>&1 | tee -a .build/log 2>&1 | xcpretty
lint:
	pod lib lint
clean:
	swift package clean
	swift package reset
	pod cache clean --all