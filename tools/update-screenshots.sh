#!/bin/sh

OUT_DIR="docs/screenshots"

flutter test integration_test/screenshot_home.dart     --dart-define=testing_mode=true --update-goldens || exit 1
flutter test integration_test/screenshot_input.dart    --dart-define=testing_mode=true --update-goldens || exit 1
flutter test integration_test/screenshot_settings.dart --dart-define=testing_mode=true --update-goldens || exit 1
flutter test integration_test/screenshot_stats.dart    --dart-define=testing_mode=true --update-goldens || exit 1

cd integration_test/screenshots || exit 1
# remove top 80 px and resize to 2:1 ratio
find . -maxdepth 1 -iname "*.png" | xargs -L1 -I{} magick "{}" -crop 1080x2074+0+80 +repage -resize 1000x2000! "../../$OUT_DIR/{}"