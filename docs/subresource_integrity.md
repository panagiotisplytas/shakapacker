# Subresource integrity

TL;DR It's a hash that helps browsers check that the served js or css file has not been tampered in any way.

More: https://developer.mozilla.org/en-US/docs/Web/Security/Subresource_Integrity

## Important notes
 - If you somehow modify the file after the hash was generated, it will automatically be considered as tampered, and the browser will not allow it to be executed.
 - Enabling subresource integrity generation, will change the structure of `manifest.json`. Keep that in mind if you utilize this file in any other custom implementation.

Before:
```json
{
  "application.js": "/path_to_asset"
}
```

After:
```json
{
  "application.js": {
    "src": "/path_to_asset",
    "integrity": "sha256-some-hash sha512-some-other-hash"
  }
}
```

## Configuration

By default, this setting is disabled, to ensure backwards compatibility, and let developers adapt at their own pace.
This may change in the future, as it is a very nice security feature, and it should be enabled by default.

To enable it just add this in `shakapacker.yml`
```yml
default: &default
  ...
  integrity: true
  ...
```

This will utilize under the hood webpack-subresource-integrity plugin and will modify `manifest.json` to include integrity hashes.
