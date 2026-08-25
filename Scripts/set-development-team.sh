#!/bin/bash
# Usage: ./set-development-team.sh <TEAM_ID>
# Sets DEVELOPMENT_TEAM for all build configurations in EchoPet.xcodeproj

set -e

TEAM_ID="$1"

if [ -z "$TEAM_ID" ]; then
    echo "Usage: $0 <Apple Developer Team ID>"
    echo "Example: $0 ABCDE12345"
    exit 1
fi

PROJECT_FILE="$(dirname "$0")/../EchoPet.xcodeproj/project.pbxproj"

if [ ! -f "$PROJECT_FILE" ]; then
    echo "Error: project.pbxproj not found at $PROJECT_FILE"
    exit 1
fi

sed -i '' "s/DEVELOPMENT_TEAM = \"\";/DEVELOPMENT_TEAM = $TEAM_ID;/g" "$PROJECT_FILE"

echo "DEVELOPMENT_TEAM set to $TEAM_ID in all configurations."
