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

All 15 locales contain the same 693 messages:

| Language | `ScriptLanguage` |
| --- | --- |
| English (default) | `en` |
| Mandarin Chinese (Simplified) | `zh-CN` |
| Hindi | `hi` |
| Spanish | `es` |
| Modern Standard Arabic | `ar` |
| French | `fr` |
| Bengali | `bn` |
| Brazilian Portuguese | `pt-BR` |
| Indonesian | `id` |
| Urdu | `ur` |
| Russian | `ru` |
| German | `de` |
| Japanese | `ja` |
| Nigerian Pidgin | `pcm` |
| Egyptian Arabic | `ar-EG` |

Locale codes use two or three lowercase letters, optionally followed by a
hyphen and two uppercase region letters. For example, set
`:global ScriptLanguage "pcm";` and reload configuration to select Pidgin.

The 13 newly added locales are initial assisted translations. Nigerian Pidgin
and Egyptian Arabic include manual drafting and dialect adaptation. Native
speakers should review terminology and naturalness before treating these
catalogs as final. Technical validation checks coverage, UTF-8, schemas and
parameters; it does not establish linguistic accuracy. Keep script names,
configuration identifiers and `{parameters}` unchanged when reviewing texts.

The migrated scripts translate `check-health` notifications and diagnostics
(including state, temperature, and voltage plugins), the four backup scripts,
certificate checks and local issuance, perpetual-license checks, LTE firmware
checks, RouterOS and package updates, RouterBOARD firmware upgrades, and rolling
CAPsMAN upgrades. GRE and tunnelbroker updates, IPv6 updates, DNS/DoH management,
DHCP-to-DNS and IPSec-to-DNS synchronization, DHCP lease dispatchers and comments,
and PPP hooks are also translated. Wireless access-list duplicate prompts,
device collection, CAPsMAN package downloads, and OSPF-to-LED diagnostics are
translated as well. Ntfy/Gotify queue messages and SSH-key import diagnostics
have also been migrated. Coverage also includes Email/Matrix/Telegram modules,
log forwarding, Netwatch, SMS actions/forwarding, Telegram chat, bridge/VLAN
modules, IP calculations, variable inspection, one-time script execution, PSKs,
Hotspot and button actions, GPS, shared helpers, installer diagnostics,
configuration loading, startup guards, and change notifications.
RouterOS-generated errors,
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
no downloads. The fetched changelog registers its own temporary catalog before
rendering change notifications. Installing or updating a translated script reloads the schema
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

Add `--catalogs --locale <code>` to check every message in a locale on RouterOS,
including accented characters, multiline text, numeric parameters, and literal
braces in parameter values. Each message is checked with both JSON parameters
and native dictionary literals:

```sh
python3 contrib/language-test.py --catalogs --locale ja > /tmp/language-tests.rsc
```

Repeat generation and import for each locale in the table above. Repeat
`--locale` to combine selected locales. Omitting it builds one bundle for all
locales, currently about 9 MB; the test VM restarted during that import.
Use one locale per import on devices with limited memory. This size belongs to
the development fixtures; individual production catalogs are below 17 KB.

Add `--notifications` to exercise queue guards and the email log-forwarding loop
filter. Add `--netwatch` to exercise actual Netwatch state transitions with
simulated hosts, a local notification sink, parent suppression, and invalid
hooks. Add `--messaging` to exercise SMS grouping and Telegram authorization
with simulated inboxes, or `--network` for firewall list diagnostics and
bridge/VLAN DHCP guards with simulated reads. These tests do not send notifications, execute chat
commands, delete real SMS, or change Netwatch entries:

```sh
python3 contrib/language-test.py --notifications --netwatch --messaging --network > /tmp/language-tests.rsc
```

`--utilities` checks IP calculation output and unchanged return values, recursive
variable inspection, and script-run URL/download/syntax guards. Script fetches
are replaced with local fixtures; no downloaded code runs.

`--standalone` checks the generated local renderers used by early-starting
scripts, with the global translation helper unavailable. It tests both locales
without running button actions, Hotspot login changes, or LTE upgrades.

`--reload` exercises the real configuration and installer refresh hooks with
both RouterOS function types (`array` for `do={...}`, `code` for `:parse`). The
configuration hook runs only after the shared functions are ready. Fixtures
replace the updater; installed scripts and configuration are not reloaded.

`--core` runs the required-module bootstrap with isolated globals and a temporary
`LanguageTestCoreExtra` script. Fetch responses are simulated. It covers missing
dependencies, offline/CRLF startup, stale APIs, incomplete downloads, invalid
syntax, and missing exports, then removes the temporary script.
It also tests shared diagnostics, device-info labels, locally administered MAC
labels, duplicate-log suppression, and firewall crash detection across language
changes. Device reads are simulated and logs are captured locally.

The shared helpers are split between `global-functions.rsc` and the required
`global-functions.d/core-extra.rsc` to leave room below RouterOS's Fetch size
limit. Initial setup installs both. Upgrading an older installation downloads
the missing dependency from the configured script source with certificate
verification, validates its header/API/syntax/exports, and loads it before
optional modules. Subsequent offline startups use its installed source. The
core remains unready if this dependency cannot initialize.

To also test actual downloads, compatible caches, offline fallback, malformed
JSON, stale schemas, and invalid language selections, supply the HTTPS base URL
of a published branch containing these catalogs:

```sh
python3 contrib/language-test.py --base-url https://example.com/scripts/ > /tmp/language-tests.rsc
```

The download test fetches and renders `check-health` in every non-English locale,
temporarily creates each `language-<locale>-check-health.json` cache, and removes
it afterwards. It refuses to overwrite existing caches. It never executes
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

SMS forwarding, SMS actions, and Telegram chat brought coverage to 418
messages. All 836 locale rendering checks and 836 native dictionary checks
passed, and the three sources parsed on the VM. Simulated inbox tests verified
singular/plural SMS grouping, literal braces in message content, Telegram
activation/deactivation, replies, command syntax rejection, untrusted-contact
rejection, and update offsets in both languages. They did not contact Telegram,
execute received commands, or delete SMS from a device. LTE hardware paths and
successful command/hook execution still require integration validation.

Firewall lists and bridge/VLAN modules brought coverage to 446 messages. All
892 locale rendering checks and 892 native dictionary checks passed, and the
three sources parsed on the VM. Simulated firewall reads verified certificate
failure and empty-list summaries; bridge/VLAN fixtures verified missing and
duplicate DHCP-client diagnostics. No firewall entries, bridge ports, VLANs,
or DHCP clients were changed. The shared helper migration subsequently made
crash warnings translatable while retaining detection of legacy English logs
and warnings emitted before a language change.

The IP calculator, variable inspector, and script-run-once modules brought
coverage to 461 messages. All 922 locale rendering checks and 922 native
dictionary checks passed. The modules parsed on the VM; their behavioral tests
verified translated output, IPv4/IPv6 calculations, recursive inspection, and
script-run failure guards in both languages. Return keys and RouterOS type
names were preserved.

Daily PSKs, Hotspot-to-WPA, mode buttons, and unattended LTE scheduling brought
coverage to 488 messages. All 976 locale rendering checks and 976 native
dictionary checks passed. Supported CAPsMAN/local variants and the button/LTE
sources parsed on the VM; regenerated WiFi variants need a WiFi device. Four
generated local renderers passed in both locales with the global renderer
unavailable, including the deferred LTE scheduler copy. These standalone entry
points retain offline English during initialization. Tests did not change PSKs,
Hotspot leases, button schedulers, or LTE firmware.

GPS tracking brought coverage to 491 messages. Its source parsed on the VM,
and all 982 rendering checks and 982 native dictionary checks passed. The
invalid-data diagnostic passed in both locales with simulated GPS reads;
coordinates were not uploaded. Valid GPS hardware and HTTP delivery still
require integration validation.

Shared helpers, the installer, language-loader diagnostics, and configuration
notifications brought coverage to 628 messages. All 1,256 rendering checks and
1,256 native dictionary checks passed on RouterOS 7.24.5, together with the full
behavioral suite above. Core/configuration sources parsed; five local renderer
copies passed without the global helper. Tests did not download packages,
execute migration code, send notifications, or modify device settings.

The final text migration brought coverage to 693 messages, including the newly
added upstream Signalgrid module. Startup guards use
a shared translated variable, with generated English defaults available before
the renderer starts. Historical change notifications register their catalog
when fetched and retain the original migration code. Configuration version 147
announces the language option and required shared module. Native tests cover
conditional donation/storage notices and the deferred partition warning, which
captures the selected language and safely encodes its text for startup.

Final validation on RouterOS 7.24.5 (x86_64, VMware; routeros and wireless)
parsed 72 supported sources and ran the complete behavioral suite. All 1,386
locale rendering checks and 1,386 native parameter checks passed. Real HTTPS
downloads verified the published core module byte-for-byte, shared catalogs,
configuration diagnostics, and the transient changelog catalog. Offline cache,
English reset, malformed JSON, stale schemas, and invalid locale tests passed.
Temporary globals, files, scripts, and schedulers were removed. Ten Python
checks and generated-artifact checks passed; platform variants were regenerated
with the repository's shell scripts. Full `make` was unavailable because GNU
Make and the documentation prerequisites are absent from this environment.

Human-facing runtime notifications, diagnostics, and display labels are now
catalog-backed. Comments, documentation examples, password word lists, received
commands, API fields/statuses, certificate names, configuration identifiers, and
native RouterOS log/error patterns retain their original values.

The expansion to 15 locales passed 10,395 rendering checks and 10,395 native
dictionary checks on the same RouterOS 7.24.5 VM, importing one locale per
bundle. Real verified HTTPS downloads and health-message rendering passed for
all 14 non-English locales. The complete behavioral suite, cache/fallback tests,
locale validation (including `pcm`), and 12 Python checks passed. All temporary
test globals, files, scripts and schedulers were removed. Native linguistic
review remains pending for the new assisted translations.

The minimum supported version (7.22), hardware sensor paths, and persistence
across an actual reboot still need validation. Clearing the translation globals
and loading from a compatible on-device cache was tested.
