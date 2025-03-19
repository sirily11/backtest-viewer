# Write SPARKLE_KEY to sparkle.key
echo "$SPARKLE_KEY" > sparkle.key

echo "Generating appcast for version: $VERSION"

# Generate appcast.xml
./bin/generate_appcast ./\
 --ed-key-file sparkle.key \
 --link https://github.com/sirily11/backtest-viewer/releases \
 --download-url-prefix https://github.com/sirily11/backtest-viewer/releases/download/${VERSION}/