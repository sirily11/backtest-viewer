# Write SPARKLE_KEY to sparkle.key
echo "$SPARKLE_KEY" > sparkle.key

echo "Generating appcast for version: $VERSION"

# Create a temporary release notes file if release notes exist
if [ -n "$RELEASE_NOTE" ]; then
  echo "$RELEASE_NOTE" > release_notes.md
else
 echo "No release notes provided"
fi

# Generate appcast.xml with optional release notes
./bin/generate_appcast ./\
 --ed-key-file sparkle.key \
 --link https://github.com/sirily11/backtest-viewer/releases \
 --download-url-prefix https://github.com/sirily11/backtest-viewer/releases/download/${VERSION}/

if [ -f "release_notes.md" ]; then
  python3 scripts/update-xml.py appcast.xml release_notes.md
fi