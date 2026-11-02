#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
output_dir="$(mktemp -d /tmp/personal-universe-regression.XXXXXX)"
xcrun swiftc -parse-as-library -target "$(uname -m)-apple-macosx14.0" \
    PersonalUniverse/Galaxy/GalaxyStyle.swift \
    PersonalUniverse/Galaxy/GalaxyModels.swift \
    PersonalUniverse/Model/DayStatus.swift \
    PersonalUniverse/Model/ChallangeDay.swift \
    PersonalUniverse/Model/UniverseChallenge.swift \
    PersonalUniverse/Model/ChallengeMetadataEditor.swift \
    PersonalUniverse/Model/PersistentStoreLoader.swift \
    Tests/Day7Regression/main.swift -o "$output_dir/checks"
"$output_dir/checks"
