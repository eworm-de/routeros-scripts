# Languages

English is the default and is embedded in the installed scripts. It works
without internet access or extra language files on the router.

## Select a language

Add this to `global-config-overlay` to select Brazilian Portuguese:

```routeros
:global ScriptLanguage "pt-BR";
```

Reload configuration and functions:

```routeros
/system/script/run global-config;
```

The loader downloads JSON catalogs from
`$ScriptUpdatesBaseUrl/languages/pt-BR/`, preserving `ScriptUpdatesUrlSuffix`.
Use a source/branch containing this feature; the upstream distribution will
not have these files until it publishes them. The configured base URL must
use HTTPS. Certificate verification is always enabled.

Downloads happen in the background after functions load and during script
updates, never while formatting a notification. To refresh manually:

```routeros
:global LanguageUpdate; $LanguageUpdate;
```

Missing translations and invalid placeholders fall back to English. Compatible
cached catalogs are retained when a download fails. Cache files are named
`language-pt-BR-check-health.json`, under `flash/` when that directory exists,
otherwise at the file-system root. On devices with volatile root storage,
those root files do not survive reboot; English remains available. Unchanged
downloads do not rewrite the cache. Set `ScriptLanguage` back to `"en"` and
reload to return to English without downloading any catalog.

## Current coverage

The initial phase translates `check-health` notifications and diagnostics,
including the state, temperature, and voltage plugins. Other scripts and
bootstrap diagnostics still use English. RouterOS-generated errors, sensor
names, API fields, and units retain their original values.

## Contribute a translation

Catalogs live in `languages/<locale>/<feature>.json`. Copy the English catalog
and change `language` and message values. Preserve message keys and named
placeholders such as `{identity}`; their order may change. Partial catalogs
are supported. Do not put RouterOS expressions in translations: catalog text
is parsed only as JSON and is never executed.

English catalogs are the editable source of truth. `contrib/languages.py`
embeds their defaults in generated blocks inside the scripts, along with
schema identifiers. Do not edit those blocks directly.

```sh
python3 contrib/languages.py
python3 contrib/languages.py --check
python3 -m unittest discover -s tests -p 'test_languages.py'
```

`make languages` and `make check-languages` provide the same workflow.
The generator enforces matching placeholders, unique JSON keys, catalog size,
and a conservative size budget for `global-functions.rsc`. The schema changes
when English messages change; outdated catalogs are rejected until regenerated.

## Validation on RouterOS

Use a test device running the repository's minimum supported RouterOS version.
`tests/languages.rsc` tests formatting and fallback after loading the runtime
in an isolated environment; it changes translation globals and must not run
against a production script environment. Python tests do not execute RouterOS.

Before expanding coverage, also check downloaded and cached catalogs, malformed
JSON, schema mismatch, unsupported locales, offline reboot, and English output
parity. Exercise notifications using a test recipient and record the RouterOS
version and results in the pull request.

To prepare a test bundle that uses separate `LanguageTest*` globals and clears
them after success or failure:

```sh
python3 contrib/language-test.py > /tmp/language-tests.rsc
```

Import that file on the test device. It tests the translation helper without
running health checks or changing the installed configuration.
