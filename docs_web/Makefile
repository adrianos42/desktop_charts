page:
	rm -rf ../docs/*
	mkdir -p ../docs
	flutter build web -v
	cp -r -v build/web/* ../docs

android:
	flutter build apk
	flutter install --use-application-binary=build/app/outputs/flutter-apk/app-release.apk

linux:
	flutter build linux --verbose --release
	rm -rf ~/opt/desktop_charts
	mkdir -p ~/opt/desktop_charts
	cp -r build/linux/x64/release/bundle/* ~/opt/desktop_charts/
	cp assets/icon_transparent.svg ~/opt/desktop_charts/icon.svg
	rm -f ~/.local/share/applications/desktop_charts.desktop
	@echo "#!/usr/bin/env xdg-open" >> ~/.local/share/applications/desktop_charts.desktop
	@echo "" >> ~/.local/share/applications/desktop_charts.desktop
	@echo "[Desktop Entry]" >> ~/.local/share/applications/desktop_charts.desktop
	@echo "Version=1.0" >> ~/.local/share/applications/desktop_charts.desktop
	@echo "Terminal=false" >> ~/.local/share/applications/desktop_charts.desktop
	@echo "Type=Application" >> ~/.local/share/applications/desktop_charts.desktop
	@echo "Name=Desktop Charts" >> ~/.local/share/applications/desktop_charts.desktop
	@echo "" >> ~/.local/share/applications/desktop_charts.desktop
	@echo "Exec=${HOME}/opt/desktop_charts/desktop_charts" >> ~/.local/share/applications/desktop_charts.desktop
	@echo "Icon=${HOME}/opt/desktop_charts/icon.svg" >> ~/.local/share/applications/desktop_charts.desktop

.PHONY: linux android