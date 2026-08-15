#!/usr/bin/env python3
"""Inject fixed release signingConfig into auto-generated android/app/build.gradle.

Reads android/app/build.gradle (created by `flutter create .`), injects:
  1. keystoreProperties loading block
  2. signingConfigs { release { ... } } block
  3. points release buildType to signingConfigs.release

This guarantees every CI build produces APKs with the same signing fingerprint.
"""
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
BUILD_GRADLE = ROOT / 'android' / 'app' / 'build.gradle'
KEY_PROPERTIES = ROOT / 'android' / 'key.properties'

TARGET_KEYSTORE = '../../signing/debug.keystore'
KEY_ALIAS = 'androiddebugkey'
KEY_PASSWORD = 'android'
STORE_PASSWORD = 'android'


def main():
    if not BUILD_GRADLE.exists():
        print(f'ERROR: {BUILD_GRADLE} not found', file=sys.stderr)
        sys.exit(1)

    s = BUILD_GRADLE.read_text()

    # 1. keystoreProperties header (inject once)
    if 'keystoreProperties' not in s:
        header = (
            "def keystoreProperties = new Properties()\n"
            "def keystorePropertiesFile = rootProject.file('key.properties')\n"
            "if (keystorePropertiesFile.exists()) {\n"
            "    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))\n"
            "}\n\n"
        )
        s = header + s

    # 2. signingConfigs.release block (inject once)
    injected_release = False
    if 'signingConfigs {' not in s:
        sc = (
            "    signingConfigs {\n"
            "        release {\n"
            f"            keyAlias '{KEY_ALIAS}'\n"
            f"            keyPassword '{KEY_PASSWORD}'\n"
            f"            storeFile file('{TARGET_KEYSTORE}')\n"
            f"            storePassword '{STORE_PASSWORD}'\n"
            "        }\n"
            "    }\n"
        )
        if '    buildTypes {' in s:
            s = s.replace('    buildTypes {', sc + '    buildTypes {', 1)
            injected_release = True
        else:
            print('WARNING: buildTypes block not found in build.gradle', file=sys.stderr)

    # 3. Point release buildType to fixed signingConfig
    if injected_release and 'signingConfig signingConfigs.debug' in s:
        s = s.replace(
            'signingConfig signingConfigs.debug',
            'signingConfig signingConfigs.release',
        )

    BUILD_GRADLE.write_text(s)
    print(f'=== Patched {BUILD_GRADLE} ===')
    print(f'release signingConfig injected: {injected_release}')

    # Also write key.properties for Gradle's own resolution
    if not KEY_PROPERTIES.exists():
        KEY_PROPERTIES.write_text(
            f'storePassword={STORE_PASSWORD}\n'
            f'keyPassword={KEY_PASSWORD}\n'
            f'keyAlias={KEY_ALIAS}\n'
            f'storeFile={TARGET_KEYSTORE}\n'
        )
        print(f'=== Wrote {KEY_PROPERTIES} ===')


if __name__ == '__main__':
    main()
