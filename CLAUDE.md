# Swimset — Claude Code Notes

## Releasing a new version

When bumping the version number, **two files must be updated together**:

1. `manifest.xml` — `version` attribute on `<iq:application>` (used by the Connect IQ store)
2. `resources/strings.xml` — `AppVersion` string (displayed in the app's settings screen)

Both must stay in sync. Format is `MAJOR.MINOR.PATCH`.
