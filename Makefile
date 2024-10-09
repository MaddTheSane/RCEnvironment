all:
	xcodebuild

clean:
	xcodebuild clean

install:
	xcodebuild install


PACKAGE_VERSION := $(shell grep -A1 CFBundleShortVersion Info.plist | tail -1 | sed 's/.*>\([0-9][.0-9]*\).*/\1/g' )

distpackage:
	./makedistpkg $(PACKAGE_VERSION)

sourcepackage:
	./makedistpkg -s $(PACKAGE_VERSION)
