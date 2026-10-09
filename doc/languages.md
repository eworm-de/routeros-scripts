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

The migrated scripts translate `check-health` notifications and diagnostics
(including state, temperature, and voltage plugins), the four backup scripts,
certificate checks and local issuance, perpetual-license checks, LTE firmware
checks, RouterOS and package updates, RouterBOARD firmware upgrades, and rolling
CAPsMAN upgrades. GRE and tunnelbroker updates, IPv6 updates, DNS/DoH management,
DHCP-to-DNS and IPSec-to-DNS synchronization, DHCP lease dispatchers and comments,
and PPP hooks are also translated. Wireless access-list duplicate prompts,
device collection, CAPsMAN package downloads, and OSPF-to-LED diagnostics are
translated as well. Ntfy/Gotify queue messages and SSH-key import diagnostics
have also been migrated. Other
scripts and bootstrap diagnostics still use English. RouterOS-generated errors,
sensor names, API fields, file paths, and internal status sentinels retain their
original values. Interactive confirmations retain `[y/N]` because their key
handling still expects the original responses.

## Contribute a translation

Catalogs live in `languages/<locale>/<feature>.json`. Copy the English catalog
and change `language` and message values. Preserve message keys and named
placeholders such as `{identity}`; their order may change. Partial catalogs
are supported. Do not put RouterOS expressions in translations: catalog text
is parsed only as JSON and is never executed.

English catalogs are the editable source of truth. Root scripts, templates,
and `mod/` modules use catalogs named after their feature. `contrib/languages.py`
embeds their defaults in generated blocks inside the scripts, along with
schema identifiers. Do not edit those blocks directly. The loader discovers
catalog schemas from installed script headers, so uninstalled features require
no downloads. Installing or updating a translated script reloads the schema
index through the existing installer.

For template families, defaults are embedded in `*.template.rsc`; regenerate
the platform variants with `make rsc` after updating catalogs. Both CAPsMAN
variants share the `capsman-rolling-upgrade` catalog.

Pass parameters as parenthesized dictionaries, for example
`[ $Translate "feature.message" ({ name=$Name }) ]`. Omit a trailing semicolon
inside these dictionaries: on the tested RouterOS version, a single-entry
dictionary with that semicolon and surrounding spaces can evaluate as empty
inside a block. The native tests cover this case separately from JSON rendering.

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

Add `--catalogs` to check every message in every available locale on RouterOS,
including accented characters, multiline text, numeric parameters, and literal
braces in parameter values. Each message is checked with both JSON parameters
and native dictionary literals:

```sh
python3 contrib/language-test.py --catalogs > /tmp/language-tests.rsc
```

Add `--notifications` to exercise queue guards and the email log-forwarding loop
filter. Add `--netwatch` to exercise actual Netwatch state transitions with
simulated hosts, a local notification sink, parent suppression, and invalid
hooks. These tests do not send notifications or change Netwatch entries:

```sh
python3 contrib/language-test.py --catalogs --notifications --netwatch > /tmp/language-tests.rsc
```

To also test actual downloads, compatible caches, offline fallback, malformed
JSON, stale schemas, and invalid language selections, supply the HTTPS base URL
of a published branch containing these catalogs:

```sh
python3 contrib/language-test.py --base-url https://example.com/scripts/ > /tmp/language-tests.rsc
```

The download test temporarily creates `language-pt-BR-check-health.json`, removes
it afterwards, and refuses to overwrite an existing cache. It never executes
downloaded catalog text or sends notifications.

### Initial validation

The translation helper and download/cache tests passed on RouterOS 7.24.5
(x86 VMware VM). All changed RouterOS sources parsed successfully. Running
`check-health` with an isolated notification sink produced the expected CPU
warning subjects and bodies in English and Brazilian Portuguese, including
accented characters. No external notifications were sent.

The three translated backup scripts parsed successfully and their guarded
failure diagnostics passed in both languages with isolated globals. These
tests stopped before creating backups, sending mail, or uploading files.
Catalog discovery was also tested against a temporary installed script; all
temporary scripts, files, and globals were removed afterwards.

The partition, license, LTE, and certificate-check sources also parsed on the
VM. All 144 catalog messages passed rendering checks in English and Brazilian
Portuguese (288 checks). These rendering tests exercise the RouterOS helper;
they do not perform certificate renewal, partition copies, or firmware upgrades.

The update and issuance phase parsed successfully on the VM, including the
CAPsMAN variant supported by its wireless package. All 201 messages passed
rendering in both locales (402 checks). RouterOS and package-update scripts
also produced the expected backup-partition refusal diagnostics in both
languages with isolated globals and a temporary disabled scheduler. Tests
did not install packages, reboot, renew certificates, or upgrade CAPs. The
WiFi variant still requires validation on a device with the WiFi package.

The network and DHCP phase brought coverage to 260 messages (520 rendering
checks). Its sources and supported generated variants parsed on the VM.
Guarded DHCP, IPv6, PPP, and tunnelbroker diagnostics passed in both locales
using isolated globals; no network configuration was changed. Optional IPv6
display fields are converted to strings so absent values render as empty text.

The wireless and OSPF phase brought coverage to 287 messages. All 574 locale
rendering checks and 574 native dictionary checks passed. The local-wireless
and CAPsMAN variants parsed on the VM; WiFi variants require the WiFi package.
Tests did not remove access-list entries, collect clients, download RouterOS
packages, or change LEDs.

The first module phase brought coverage to 308 messages. All 616 locale
rendering checks and 616 native dictionary checks passed, and the three modules
parsed on the VM. Ntfy/Gotify offline queue guards and SSH import argument guards
produced the expected diagnostics in both locales with isolated globals. These
tests did not send notifications or import SSH keys.

The remaining notification modules, log forwarding, and Netwatch brought
coverage to 379 messages. All 758 locale rendering checks and 758 native
dictionary checks passed on the VM, together with syntax checks for the five
sources. Email filtering recognized translated and historical encoded subjects,
including punctuation and Unicode, and rejected unrelated subjects. Netwatch
thresholds, duplicate suppression, recovery, parent suppression, and invalid
hooks passed in both languages using simulated host reads. Notification queue
guards passed without sending messages. Matrix HTML delivery, DNS-driven
Netwatch updates, and real notification services still require integration
validation.

### Remaining migration

The full migration is still in progress. Next groups include unattended LTE
upgrades, remaining network scripts and wireless templates, SMS and Telegram
output, and shared helper diagnostics. Bootstrap
messages and machine-readable strings
need individual classification before changes. One upstream pull request will
be opened after the full migration and its validation are complete.

The minimum supported version (7.22), hardware sensor paths, and persistence
across an actual reboot still need validation. Clearing the translation globals
and loading from a compatible on-device cache was tested.
