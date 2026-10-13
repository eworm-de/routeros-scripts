#!/usr/bin/env python3
"""Print a RouterOS test bundle with globals isolated from installed scripts."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import sys
from languages import load, quote, TOKEN, tokens, BEGIN, END, LOCAL_BEGIN, LOCAL_END, source_path

root = Path(__file__).resolve().parent.parent
runtime = (root / 'languages/runtime.rsc').read_text(encoding='utf-8')
tests = (root / 'tests/languages.rsc').read_text(encoding='utf-8')
payloads = []
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--base-url', help='HTTPS distribution URL; also run catalog download/cache tests')
parser.add_argument('--catalogs', action='store_true', help='Test every catalog message on RouterOS')
parser.add_argument('--locale', action='append', help='Limit catalog rendering to this locale; repeat to select several (requires --catalogs)')
parser.add_argument('--notifications', action='store_true', help='Test notification guards and the email loop filter without sending')
parser.add_argument('--netwatch', action='store_true', help='Test Netwatch state transitions with simulated hosts and a local notification sink')
parser.add_argument('--messaging', action='store_true', help='Test SMS forwarding and Telegram chat with simulated inboxes')
parser.add_argument('--network', action='store_true', help='Test firewall list diagnostics and bridge guards with simulated reads')
parser.add_argument('--utilities', action='store_true', help='Test translated IP calculations, variable inspection and script-run guards')
parser.add_argument('--standalone', action='store_true', help='Test generated local renderers with the global renderer unavailable')
parser.add_argument('--reload', action='store_true', help='Test actual configuration and installer language-refresh hooks')
parser.add_argument('--core', action='store_true', help='Test required core-module bootstrap with isolated scripts and simulated downloads')
args = parser.parse_args()
if args.locale:
    if not args.catalogs:
        parser.error('--locale requires --catalogs')
    for locale in args.locale:
        if locale not in {path.name for path in (root / 'languages').iterdir() if path.is_dir()}:
            parser.error('Unknown locale: ' + locale)
if args.notifications:
    core = (root / 'global-functions.rsc').read_text(encoding='utf-8')
    modules = ':global NotificationFunctions ({});\n'
    for name in ('CharacterMultiply', 'EscapeForRegEx'):
        start = core.index(':set ' + name + ' do={')
        end = core.index('\n}\n', start) + 3
        modules += ':global ' + name + ';\n' + core[start:end] + '\n'
    translated = {}
    for name in ('notification-email', 'notification-matrix', 'notification-telegram', 'notification-signalgrid'):
        modules += (root / 'mod' / (name + '.rsc')).read_text(encoding='utf-8') + '\n'
        translated.update(load(root / 'languages/pt-BR' / (name + '.json'))['messages'])
    tests += '\n' + modules
    tests += ':set LanguageMessages ([:deserialize from=json options=json.no-string-conversion ' + quote(json.dumps(translated, ensure_ascii=False)) + ']);\n'
    tests += (root / 'tests/language-notifications.rsc').read_text(encoding='utf-8')
if args.netwatch:
    core = (root / 'global-functions.rsc').read_text(encoding='utf-8')
    for name in ('EitherOr', 'IfThenElse'):
        start = core.index(':set ' + name + ' do={')
        end = core.index('\n}\n', start) + 3
        tests += ':global ' + name + ';\n' + core[start:end] + '\n'
    feature = (root / 'netwatch-notify.rsc').read_text(encoding='utf-8')
    # Replace only device reads; the actual state and rendering logic runs intact.
    replacements = {
        '[ /tool/netwatch/find where comment~"\\\\bnotify\\\\b" !disabled status!="unknown" ]': '{ "fixture" }',
        '[ /tool/netwatch/get $Host ]': '$NetwatchFixtureHost',
        '[ $ParseKeyValueStore ($HostVal->"comment") ]': '$NetwatchFixtureInfo',
    }
    for old, new in replacements.items():
        if feature.count(old) != 1:
            raise ValueError('Netwatch fixture read no longer matches: ' + old)
        feature = feature.replace(old, new)
    tests += ':global NetwatchFixtureRun do={\n:global NetwatchFixtureHost; :global NetwatchFixtureInfo;\n' + feature + '\n};\n'
    translated = load(root / 'languages/pt-BR/netwatch-notify.json')['messages']
    tests += ':set LanguageMessages ([:deserialize from=json options=json.no-string-conversion ' + quote(json.dumps(translated, ensure_ascii=False)) + ']);\n'
    tests += ':global NetwatchFixtureTest do={\n' + (root / 'tests/language-netwatch.rsc').read_text(encoding='utf-8') + '\n};\n$NetwatchFixtureTest;\n'
if args.messaging:
    core = (root / 'global-functions.rsc').read_text(encoding='utf-8')
    for name in ('EitherOr', 'IfThenElse', 'CharacterMultiply', 'EscapeForRegEx', 'MAX', 'MIN'):
        start = core.index(':set ' + name + ' do={')
        end = core.index('\n}\n', start) + 3
        tests += ':global ' + name + ';\n' + core[start:end] + '\n'
    feature = (root / 'telegram-chat.rsc').read_text(encoding='utf-8')
    start = feature.index('      :set Data ([ /tool/fetch')
    end = feature.index('\n      :set TelegramRandomDelay', start)
    feature = feature[:start] + '      :set Data [ :serialize to=json $ChatFixtureUpdates ];' + feature[end:]
    tests += ':global ChatFixtureRun do={\n:global ChatFixtureUpdates;\n' + feature + '\n};\n'
    feature = (root / 'sms-forward.rsc').read_text(encoding='utf-8')
    replacements = {
        '[ /tool/sms/get receive-enabled ]': 'true',
        '[ /tool/sms/get ]': '$SmsFixtureSettings',
        '[ /interface/lte/get ($Settings->"port") running ]': 'true',
        '[ /tool/sms/inbox/find ]': '$SmsFixtureIds',
        '[ /tool/sms/inbox/get ([ find ]->0) phone ]': '"test-phone"',
        '[ /tool/sms/inbox/find where phone=$Phone ]': '$SmsFixtureIds',
        '[ /tool/sms/inbox/get $Sms ]': '($SmsFixtureMessages->$Sms)',
        '/tool/sms/inbox/remove $Sms;': ':set SmsFixtureIds [ :pick $SmsFixtureIds 1 [ :len $SmsFixtureIds ] ];',
    }
    for old, new in replacements.items():
        if old not in feature:
            raise ValueError('SMS fixture read no longer matches: ' + old)
        feature = feature.replace(old, new)
    if '/tool/sms/' in feature or '/tool/sms/get' in feature or '/interface/lte/get' in feature:
        raise ValueError('An SMS fixture still accesses the device')
    tests += ':global SmsFixtureRun do={\n:global SmsFixtureSettings; :global SmsFixtureIds; :global SmsFixtureMessages;\n' + feature + '\n};\n'
    translated = {}
    for name in ('sms-forward', 'telegram-chat'):
        translated.update(load(root / 'languages/pt-BR' / (name + '.json'))['messages'])
    tests += ':set LanguageMessages ([:deserialize from=json options=json.no-string-conversion ' + quote(json.dumps(translated, ensure_ascii=False)) + ']);\n'
    tests += ':global MessagingFixtureTest do={\n' + (root / 'tests/language-messaging.rsc').read_text(encoding='utf-8') + '\n};\n$MessagingFixtureTest;\n'
if args.network:
    core = (root / 'global-functions.rsc').read_text(encoding='utf-8')
    for name in ('EitherOr', 'IfThenElse', 'HumanReadableNum'):
        start = core.index(':set ' + name + ' do={')
        end = core.index('\n}\n', start) + 3
        tests += ':global ' + name + ';\n' + core[start:end] + '\n'
    translated = {}
    for name in ('bridge-port-to', 'bridge-port-vlan'):
        feature = (root / 'mod' / (name + '.rsc')).read_text(encoding='utf-8')
        replacements = {
            '[ /interface/bridge/port/find where !(comment=[]) ]': '{ "fixture" }',
            '[ /interface/bridge/port/get $BridgePort ]': '$BridgeFixturePort',
            '[ /ip/dhcp-client/find where interface=$BridgePortVal->"interface" comment="toggle with bridge port" ]': '$BridgeFixtureClients',
        }
        for old, new in replacements.items():
            if feature.count(old) != 1:
                raise ValueError('Bridge fixture read no longer matches: ' + old)
            feature = feature.replace(old, new)
        # Fixture config always selects DHCP-client mode; guards return before writes.
        feature = feature.replace(':global ParseKeyValueStore;', ':global ParseKeyValueStore;\n  :global BridgeFixturePort; :global BridgeFixtureClients;')
        tests += feature + '\n'
        translated.update(load(root / 'languages/pt-BR' / (name + '.json'))['messages'])
    feature = (root / 'fw-addr-lists.rsc').read_text(encoding='utf-8')
    feature, count = re.subn(r'\[ /log/find where.*?\]', '( {})', feature, flags=re.S)
    if count != 1:
        raise ValueError('Firewall crash-marker fixture no longer matches')
    feature, count = re.subn(r'\[ /(?:ip|ipv6)/firewall/address-list/find where\s+\\\s+list=\$FwListName comment=\$ListComment \]', '( {})', feature)
    if count != 2:
        raise ValueError('Firewall fixture reads no longer match')
    tests += ':global FirewallFixtureRun do={\n' + feature + '\n};\n'
    translated.update(load(root / 'languages/pt-BR/fw-addr-lists.json')['messages'])
    tests += ':set LanguageMessages ([:deserialize from=json options=json.no-string-conversion ' + quote(json.dumps(translated, ensure_ascii=False)) + ']);\n'
    tests += ':global NetworkFixtureTest do={\n' + (root / 'tests/language-network.rsc').read_text(encoding='utf-8') + '\n};\n$NetworkFixtureTest;\n'
if args.utilities:
    core = (root / 'global-functions.rsc').read_text(encoding='utf-8')
    for name in ('CharacterMultiply', 'CharacterReplace', 'EitherOr', 'IfThenElse', 'FormatLine', 'NetMask4', 'NetMask6'):
        start = core.index(':set ' + name + ' do={')
        end = core.index('\n}\n', start) + 3
        tests += ':global ' + name + ';\n' + core[start:end] + '\n'
    translated = {}
    for name in ('ipcalc', 'inspectvar', 'scriptrunonce'):
        feature = (root / 'mod' / (name + '.rsc')).read_text(encoding='utf-8')
        if name == 'ipcalc':
            if feature.count(':put ') != 1:
                raise ValueError('IP calculation output fixture no longer matches')
            feature = feature.replace(':put ', ':global UtilityFixtureOutput; :set UtilityFixtureOutput ')
        tests += feature + '\n'
        translated.update(load(root / 'languages/pt-BR' / (name + '.json'))['messages'])
    feature = (root / 'gps-track.rsc').read_text(encoding='utf-8')
    for old, new in {'[ /system/gps/get coordinate-format ]': '"dd"',
                     '[ /system/gps/monitor once as-value ]': '{ "valid"=false }'}.items():
        if feature.count(old) != 1:
            raise ValueError('GPS fixture read no longer matches: ' + old)
        feature = feature.replace(old, new)
    tests += ':global UtilityFixtureGpsRun do={\n' + feature + '\n};\n'
    translated.update(load(root / 'languages/pt-BR/gps-track.json')['messages'])
    tests += ':set LanguageMessages ([:deserialize from=json options=json.no-string-conversion ' + quote(json.dumps(translated, ensure_ascii=False)) + ']);\n'
    tests += ':global UtilityFixtureTest do={\n' + (root / 'tests/language-utilities.rsc').read_text(encoding='utf-8') + '\n};\n$UtilityFixtureTest;\n'
if args.standalone:
    tests += ':local SavedTranslate $Translate; :set Translate;\n'
    count = 0
    for group in ('global-config', 'mode-button', 'hotspot-to-wpa', 'unattended-lte-firmware-upgrade'):
        feature = source_path(group).read_text(encoding='utf-8')
        defaults = re.search(re.escape(BEGIN) + r'.*?' + re.escape(END), feature, re.S)[0]
        english = load(root / 'languages/en' / (group + '.json'))['messages']
        translated = load(root / 'languages/pt-BR' / (group + '.json'))['messages']
        # Test both top-level and deferred scheduler copies of the local renderer.
        for renderer in re.findall(re.escape(LOCAL_BEGIN) + r'.*?' + re.escape(LOCAL_END), feature, re.S):
            key = sorted(english)[0]
            params = {name: 'fixture-value' for name in tokens(english[key])}
            native = '({ ' + '; '.join(quote(name) + '=' + quote(value) for name, value in sorted(params.items())) + ' })'
            name = 'StandaloneFixture' + str(count)
            tests += ':global ' + name + ' do={\n' + defaults + '\n' + renderer + '\n:return [ $Translate ' + quote(key) + ' ' + native + ' ];\n};\n'
            tests += ':set LanguageMessages ([:deserialize from=json options=json.no-string-conversion ' + quote(json.dumps(translated, ensure_ascii=False)) + ']);\n'
            for locale, text in (('en', english[key]), ('pt-BR', translated[key])):
                expected = TOKEN.sub(lambda m: params[m.group(1)], text)
                tests += ':set ScriptLanguage ' + quote(locale) + '; :set LanguageActive "pt-BR";\n'
                tests += ':if ([ $' + name + ' ] != ' + quote(expected) + ') do={ :error "Standalone local renderer failed"; };\n'
            count += 1
    tests += ':set Translate $SavedTranslate;\n:put ' + quote(f'{count} standalone renderers passed in both languages without global helpers.') + ';\n'
    backup = (root / 'backup-partition.rsc').read_text(encoding='utf-8')
    defaults = re.search(re.escape(BEGIN) + r'.*?' + re.escape(END), backup, re.S)[0]
    start = backup.index('        on-event=(') + len('        on-event=')
    expression = backup[start:backup.index(';\n    /partitions/save-config-to', start)]
    expression = expression.replace(':local Name [ /partitions/get [ find where running ] name ];',
                                    ':global BackupFixtureName; :local Name \\$BackupFixtureName;')
    expression = expression.replace(':log warning', ':return')
    tests += ':global BackupFixtureBuild do={\n:global Translate;\n' + defaults + '\n:return ' + expression + ';\n};\n'
    translated = load(root / 'languages/pt-BR/backup-partition.json')['messages']
    tests += ':set LanguageMessages ([:deserialize from=json options=json.no-string-conversion ' + quote(json.dumps(translated, ensure_ascii=False)) + ']);\n'
    tests += ':global BackupFixtureName "backup \\22partition\\22 {name}";\n'
    tests += ':foreach Locale in={ "en"; "pt-BR" } do={\n:set ScriptLanguage $Locale; :set LanguageActive "pt-BR";\n'
    tests += ':local Code [ $BackupFixtureBuild ]; :local Expected "Running from partition \'backup \\22partition\\22 {name}\'!";\n'
    tests += ':if ($Locale = "pt-BR") do={ :set Expected ' + quote("Executando a partir da partição 'backup \"partition\" {name}'!") + '; };\n'
    tests += ':if ([[ :parse $Code ]] != $Expected) do={ :error "Deferred partition message failed"; };\n}\n'
    tests += ':put "Deferred backup-partition warning passed without core helpers.";\n'
if args.reload:
    config = (root / 'global-config.rsc').read_text(encoding='utf-8')
    hook = config[config.index('# Apply language changes when an already initialized installation reloads config.'):]
    core = (root / 'global-functions.d/core-extra.rsc').read_text(encoding='utf-8')
    start = core.index('  # Refresh translations even when no RouterOS script changed.')
    installer_hook = core[start:core.index('\n} do={', start)]
    tests += ':global ReloadFixtureConfig do={\n' + hook + '\n};\n'
    tests += ':global ReloadFixtureInstaller do={\n:global LanguageUpdate;\n' + installer_hook + '\n};\n'
    tests += ':global ReloadFixtureTest do={\n' + (root / 'tests/language-reload.rsc').read_text(encoding='utf-8') + '\n};\n$ReloadFixtureTest;\n'
if args.core:
    core = (root / 'global-functions.rsc').read_text(encoding='utf-8')
    extra = (root / 'global-functions.d/core-extra.rsc').read_text(encoding='utf-8')
    for group in ('global-functions', 'core-extra'):
        source = source_path(group).read_text(encoding='utf-8')
        tests += re.search(re.escape(BEGIN) + r'.*?' + re.escape(END), source, re.S)[0] + '\n'
    for name, source in (('LogPrintOnce', core), ('DeviceInfo', extra), ('GetMacVendor', extra)):
        start = source.index(':set ' + name + ' do={')
        body = source[start:source.index('\n}\n', start) + 3]
        if name == 'LogPrintOnce':
            body = body.replace('[ /log/find where message=($Name . ": " . $Message) ]', '{ "existing" }')
        if name == 'DeviceInfo':
            for old, new in {'[ /system/license/get ]': '{ "level"="1" }',
                             '[ /system/resource/get ]': '{ "board-name"="VM"; "architecture-name"="x86_64" }',
                             '[[ :parse "/system/routerboard/get" ]]': '{ "routerboard"=false }',
                             '[ /snmp/get ]': '{ "location"="Lab"; "contact"="Admin" }',
                             '[ /system/package/update/get ]': '{ "channel"="stable"; "installed-version"="7.24.5" }'}.items():
                body = body.replace(old, new)
        tests += ':global ' + name + ';\n' + body + '\n'
    fw = (root / 'fw-addr-lists.rsc').read_text(encoding='utf-8')
    guard = fw[fw.index('  # Include legacy English logs'):fw.index('  :if ($CrashDetected = true)')]
    guard = re.sub(r'\[ /log/find where.*?\]', '[ $SharedFixtureFind ("\\$LogPrintOnce: " . $Alert) ]', guard, flags=re.S)
    tests += ':global SharedFixtureDetect do={\n:global LanguageEnglish; :global LogPrintOnceCrashMessages; :global SharedFixtureFind;\n' + guard + '\n:return $CrashDetected;\n};\n'
    translated = {}
    for group in ('global-functions', 'core-extra'):
        translated.update(load(root / 'languages/pt-BR' / (group + '.json'))['messages'])
    tests += ':global SharedFixturePortuguese ([:deserialize from=json options=json.no-string-conversion ' + quote(json.dumps(translated, ensure_ascii=False)) + ']);\n'
    tests += ':global SharedFixtureTest do={\n' + (root / 'tests/language-shared.rsc').read_text(encoding='utf-8') + '\n};\n$SharedFixtureTest;\n'
    feature = (root / 'global-functions.rsc').read_text(encoding='utf-8')
    feature = ':global CoreFixtureFetch;\n' + feature
    for name in ('DeviceInfo', 'DownloadPackage', 'GetMacVendor', 'ScriptInstallUpdate',
                 'SymbolByUnicodeName', 'SymbolForNotification'):
        feature = feature.replace('"' + name + '"', '"LanguageTest' + name + '"')
    feature = feature.replace('"global-functions.d/core-extra"', '"LanguageTestCoreExtra"')
    old = '[ /tool/fetch check-certificate=yes-without-crl output=user url=$Url as-value ]'
    if feature.count(old) != 1:
        raise ValueError('Core-module fetch fixture no longer matches')
    feature = feature.replace(old, '[ $CoreFixtureFetch $Url ]')
    # Optional modules and the boot scheduler belong to the installed device.
    feature, count = re.subn(r'\[ /system/script/find where name ~ "\^\(global-functions.*?name!=\$CoreModuleName \]', '( {})', feature)
    if count != 1:
        raise ValueError('Optional module fixture no longer matches')
    start = feature.index('# add (and fix) global scripts scheduler')
    end = feature.index('# Log success', start)
    feature = feature[:start] + feature[end:]
    payloads.extend([('__CORE_FIXTURE_SOURCE__', feature),
                     ('__EXTRA_FIXTURE_SOURCE__', (root / 'global-functions.d/core-extra.rsc').read_text(encoding='utf-8'))])
    tests += ':global CoreFixtureSource __CORE_FIXTURE_SOURCE__;\n:global CoreFixtureModuleSource __EXTRA_FIXTURE_SOURCE__;\n'
    if args.base_url:
        tests += ':global CoreFixtureLiveUrl ' + quote(args.base_url + 'global-functions.d/core-extra.rsc') + ';\n'
        digest = hashlib.md5((root / 'global-functions.d/core-extra.rsc').read_text(encoding='utf-8').encode('utf-8')).hexdigest()
        tests += ':global CoreFixtureLiveDigest ' + quote(digest) + ';\n'
    tests += ':global CoreFixtureTest do={\n' + (root / 'tests/language-core.rsc').read_text(encoding='utf-8') + '\n};\n$CoreFixtureTest;\n'
    news = (root / 'news-and-changes.rsc').read_text(encoding='utf-8')
    news = news[:news.index('# Migration steps to be applied')]
    news = news.replace('[ /system/resource/get ]', '$NewsFixtureResource')
    tests += ':global NewsFixtureRun do={\n:global NewsFixtureResource;\n' + news + '\n};\n'
    translated = load(root / 'languages/pt-BR/news-and-changes.json')['messages']
    tests += ':global NewsFixturePortuguese ([:deserialize from=json options=json.no-string-conversion ' + quote(json.dumps(translated, ensure_ascii=False)) + ']);\n'
    tests += ':global NewsFixtureTest do={\n' + (root / 'tests/language-news.rsc').read_text(encoding='utf-8') + '\n};\n$NewsFixtureTest;\n'
if args.catalogs:
    sample = {'identity': 'test-router', 'name': 'test-sensor', 'date': '2026-10-09',
              'percent': 75, 'value': 120, 'error': 'test-error', 'interface': 'lte1',
              'version': '7.24.5', 'device': 'device\ninfo', 'details': 'details {identity}\nnext line'}
    count = 0
    for path in sorted((root / 'languages/en').glob('*.json')):
        english = load(path)['messages']
        tests += '\n:set LanguageEnglish ([:deserialize from=json options=json.no-string-conversion ' + quote(json.dumps(english, ensure_ascii=False)) + ']);\n'
        for locale in sorted((root / 'languages').iterdir()):
            if args.locale and locale.name not in args.locale:
                continue
            if not locale.is_dir() or not (locale / path.name).exists():
                continue
            translated = load(locale / path.name)['messages']
            tests += ':set ScriptLanguage ' + quote(locale.name) + '; :set LanguageActive ' + quote(locale.name) + ';\n'
            tests += ':set LanguageMessages ([:deserialize from=json options=json.no-string-conversion ' + quote(json.dumps(translated, ensure_ascii=False)) + ']);\n'
            for key, default in sorted(english.items()):
                params = {name: sample.get(name, 'test-value') for name in tokens(default)}
                text = translated.get(key, default)
                expected = TOKEN.sub(lambda m: str(params[m.group(1)]), text)
                tests += ':if ([ $Translate ' + quote(key) + ' ([:deserialize from=json options=json.no-string-conversion ' + quote(json.dumps(params)) + ']) ] != ' + quote(expected) + ') do={ :error ' + quote(locale.name + ': ' + key) + '; };\n'
                # Exercise the literal dictionary syntax used by feature scripts,
                # as well as JSON. A trailing semicolon can discard a single item.
                native = '({ ' + '; '.join(quote(name) + '=' + quote(str(value))
                                            for name, value in sorted(params.items())) + ' })'
                tests += ':if ([ $Translate ' + quote(key) + ' ' + native + ' ] != ' + quote(expected) + ') do={ :error ' + quote(locale.name + ': native parameters: ' + key) + '; };\n'
                count += 1
    tests += ':put ' + quote(f'{count} catalog rendering tests passed.') + ';\n'
    tests += ':put ' + quote(f'{count} native parameter dictionary tests passed.') + ';\n'
if args.base_url:
    if not args.base_url.startswith('https://') or not args.base_url.endswith('/'):
        parser.error('--base-url must be an HTTPS URL ending with /')
    catalog = load(root / 'languages/en/check-health.json')
    diagnostics = load(root / 'languages/en/global-functions.json')['messages']
    diagnostics.update(load(root / 'languages/en/global-config.json')['messages'])
    tests += '\n:global LanguageEnglish ({});\n'
    tests += ''.join(f':set ($LanguageEnglish->{quote(key)}) {quote(text)};\n'
                     for key, text in (catalog['messages'] | diagnostics).items())
    tests += ':global LanguageSchemas { "check-health"=' + quote(catalog['schema']) + ' };\n'
    tests += ':global ScriptUpdatesBaseUrl ' + quote(args.base_url) + ';\n'
    tests += ':global ScriptUpdatesUrlSuffix "";\n'
    groups = ('global-config', 'global-functions', 'core-extra', 'news-and-changes')
    extra_schemas = {group: load(root / 'languages/en' / (group + '.json'))['schema'] for group in groups}
    tests += ':global LoaderFixtureSchemas ([:deserialize from=json options=json.no-string-conversion ' + quote(json.dumps(extra_schemas)) + ']);\n'
    expected = {}
    for directory in sorted((root / 'languages').iterdir()):
        if directory.is_dir() and directory.name != 'en':
            messages = load(directory / 'check-health.json')['messages']
            expected[directory.name] = {
                'subject': messages['check-health.cpu.warning.subject'],
                'message': messages['check-health.cpu.warning.message'].replace('{identity}', 'test-router').replace('{percent}', '75'),
            }
    tests += ':global LoaderFixtureLocales ([:deserialize from=json options=json.no-string-conversion ' + quote(json.dumps(expected, ensure_ascii=False)) + ']);\n'
    tests += ':global LoaderFixtureHealthSchema ' + quote(catalog['schema']) + ';\n'
    for group in groups:
        for key, text in load(root / 'languages/en' / (group + '.json'))['messages'].items():
            tests += f':set ($LanguageEnglish->{quote(key)}) {quote(text)};\n'
    tests += (root / 'tests/language-loader.rsc').read_text(encoding='utf-8')
variables = sorted(set(re.findall(r':global ([A-Za-z][A-Za-z0-9]*)', runtime + tests + ''.join(body for _, body in payloads))))
def namespace(body):
    for name in sorted(variables, key=len, reverse=True):
        # Rename executable references and declarations, preserving text that
        # happens to mention a configuration identifier (e.g. ScriptLanguage).
        body = re.sub(r'(?:(?<=\$)|(?<=:global )|(?<=:local )|(?<=:set ))' + re.escape(name) + r'\b',
                      'LanguageTest' + name, body)
    return body
source = runtime + '\n' + tests
source = namespace(source)
for marker, body in payloads:
    # Namespace executable payloads before quoting; \24 escapes otherwise hide
    # variable boundaries from the isolation pass.
    body = namespace(body)
    source = source.replace(marker, quote(body))
cleanup = '\n'.join(f':global LanguageTest{name}; :set LanguageTest{name};' for name in variables)
sys.stdout.buffer.write((':onerror TestError {\n' + source + '\n' + cleanup +
                        '\n} do={\n' + cleanup + '\n:error $TestError;\n}\n').encode('utf-8'))
