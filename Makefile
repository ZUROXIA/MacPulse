APP_NAME = MacPulse
BUILD_DIR = .build
BUNDLE_DIR = $(BUILD_DIR)/$(APP_NAME).app
CONTENTS_DIR = $(BUNDLE_DIR)/Contents
MACOS_DIR = $(CONTENTS_DIR)/MacOS
RESOURCES_DIR = $(CONTENTS_DIR)/Resources
DMG_DIR = $(BUILD_DIR)/dmg
DMG_FILE = $(BUILD_DIR)/$(APP_NAME).dmg
VERSION = 1.0.0

.PHONY: build bundle run install test clean icon dmg

build:
	swift build -c release

icon:
	mkdir -p $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)/AppIcon.iconset
	cp Resources/AppIcon.appiconset/icon_16.png $(BUILD_DIR)/AppIcon.iconset/icon_16x16.png
	cp Resources/AppIcon.appiconset/icon_32.png $(BUILD_DIR)/AppIcon.iconset/icon_16x16@2x.png
	cp Resources/AppIcon.appiconset/icon_32.png $(BUILD_DIR)/AppIcon.iconset/icon_32x32.png
	cp Resources/AppIcon.appiconset/icon_64.png $(BUILD_DIR)/AppIcon.iconset/icon_32x32@2x.png
	cp Resources/AppIcon.appiconset/icon_128.png $(BUILD_DIR)/AppIcon.iconset/icon_128x128.png
	cp Resources/AppIcon.appiconset/icon_256.png $(BUILD_DIR)/AppIcon.iconset/icon_128x128@2x.png
	cp Resources/AppIcon.appiconset/icon_256.png $(BUILD_DIR)/AppIcon.iconset/icon_256x256.png
	cp Resources/AppIcon.appiconset/icon_512.png $(BUILD_DIR)/AppIcon.iconset/icon_256x256@2x.png
	cp Resources/AppIcon.appiconset/icon_512.png $(BUILD_DIR)/AppIcon.iconset/icon_512x512.png
	cp Resources/AppIcon.appiconset/icon_1024.png $(BUILD_DIR)/AppIcon.iconset/icon_512x512@2x.png
	iconutil -c icns $(BUILD_DIR)/AppIcon.iconset -o $(BUILD_DIR)/AppIcon.icns

bundle: build icon
	mkdir -p $(MACOS_DIR)
	mkdir -p $(RESOURCES_DIR)
	cp $(BUILD_DIR)/release/$(APP_NAME) $(MACOS_DIR)/$(APP_NAME)
	cp Resources/Info.plist $(CONTENTS_DIR)/Info.plist
	cp $(BUILD_DIR)/AppIcon.icns $(RESOURCES_DIR)/AppIcon.icns
	codesign --force --sign - $(BUNDLE_DIR)

run: bundle
	open $(BUNDLE_DIR)

install: bundle
	cp -R $(BUNDLE_DIR) /Applications/$(APP_NAME).app

test:
	swift build
	$(BUILD_DIR)/debug/MacPulseTests

dmg: bundle
	mkdir -p $(DMG_DIR)
	cp -R $(BUNDLE_DIR) $(DMG_DIR)/
	ln -sf /Applications $(DMG_DIR)/Applications
	hdiutil create -volname "$(APP_NAME) $(VERSION)" -srcfolder $(DMG_DIR) -ov -format UDZO $(DMG_FILE)
	rm -rf $(DMG_DIR)
	@echo "DMG created at $(DMG_FILE)"

clean:
	swift package clean
	rm -rf $(BUNDLE_DIR) $(BUILD_DIR)/AppIcon.* $(DMG_DIR) $(DMG_FILE)
