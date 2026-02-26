APP_NAME = MacPulse
BUILD_DIR = .build
BUNDLE_DIR = $(BUILD_DIR)/$(APP_NAME).app
CONTENTS_DIR = $(BUNDLE_DIR)/Contents
MACOS_DIR = $(CONTENTS_DIR)/MacOS

.PHONY: build bundle run install test clean

build:
	swift build -c release

bundle: build
	mkdir -p $(MACOS_DIR)
	cp $(BUILD_DIR)/release/$(APP_NAME) $(MACOS_DIR)/$(APP_NAME)
	cp Resources/Info.plist $(CONTENTS_DIR)/Info.plist
	codesign --force --sign - $(BUNDLE_DIR)

run: bundle
	open $(BUNDLE_DIR)

install: bundle
	cp -R $(BUNDLE_DIR) /Applications/$(APP_NAME).app

test:
	swift build
	$(BUILD_DIR)/debug/MacPulseTests

clean:
	swift package clean
	rm -rf $(BUNDLE_DIR)
