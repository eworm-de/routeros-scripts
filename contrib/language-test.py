#!/usr/bin/env python3
"""Print a RouterOS test bundle with globals isolated from installed scripts."""
from pathlib import Path
import argparse
import json
import re
import sys
from languages import load, quote, TOKEN, tokens, BEGIN, END, LOCAL_BEGIN, LOCAL_END, source_path

root = Path(__file__).resolve().parent.parent
runtime = (root / 'languages/runtime.rsc').read_text(encoding='utf-8')
tests = (root / 'tests/languages.rsc').read_text(encoding='utf-8')
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--base-url', help='HTTPS distribution URL; also run catalog download/cache tests')
parser.add_argument('--catalogs', action='store_true', help='Test every catalog message on RouterOS')
parser.add_argument('--notifications', action='store_true', help='Test notification guards and the email loop filter without sending')
parser.add_argument('--netwatch', action='store_true', help='Test Netwatch state transitions with simulated hosts and a local notification sink')
parser.add_argument('--messaging', action='store_true', help='Test SMS forwarding and Telegram chat with simulated inboxes')
parser.add_argument('--network', action='store_true', help='Test firewall list diagnostics and bridge guards with simulated reads')
parser.add_argument('--utilities', action='store_true', help='Test translated IP calculations, variable inspection and script-run guards')
parser.add_argument('--standalone', action='store_true', help='Test generated local renderers with the global renderer unavailable')
args = parser.parse_args()
if args.notifications:
    core = (root / 'global-functions.rsc').read_text(encoding='utf-8')
    modules = ':global NotificationFunctions ({});\n'
    for name in ('CharacterMultiply', 'EscapeForRegEx'):
        start = core.index(':set ' + name + ' do={')
        end = core.index('\n}\n', start) + 3
        modules += ':global ' + name + ';\n' + core[start:end] + '\n'
    translated = {}
    for name in ('notification-email', 'notification-matrix', 'notification-telegram'):
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
    for group in ('mode-button', 'hotspot-to-wpa', 'unattended-lte-firmware-upgrade'):
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
if args.catalogs:
    sample = {'identity': 'test-router', 'name': 'test-sensor', 'date': '2026-10-09',
              'percent': 75, 'value': 120, 'error': 'test-error', 'interface': 'lte1',
              'version': '7.24.5', 'device': 'device\ninfo', 'details': 'details {identity}\nnext line'}
    count = 0
    for path in sorted((root / 'languages/en').glob('*.json')):
        english = load(path)['messages']
        tests += '\n:set LanguageEnglish ([:deserialize from=json options=json.no-string-conversion ' + quote(json.dumps(english, ensure_ascii=False)) + ']);\n'
        for locale in sorted((root / 'languages').iterdir()):
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
    tests += '\n:global LanguageEnglish ({});\n'
    tests += ''.join(f':set ($LanguageEnglish->{quote(key)}) {quote(text)};\n'
                     for key, text in catalog['messages'].items())
    tests += ':global LanguageSchemas { "check-health"=' + quote(catalog['schema']) + ' };\n'
    tests += ':global ScriptUpdatesBaseUrl ' + quote(args.base_url) + ';\n'
    tests += ':global ScriptUpdatesUrlSuffix "";\n'
    tests += (root / 'tests/language-loader.rsc').read_text(encoding='utf-8')
variables = sorted(set(re.findall(r':global ([A-Za-z][A-Za-z0-9]*)', runtime + tests)))
source = runtime + '\n' + tests
for name in sorted(variables, key=len, reverse=True):
    source = re.sub(r'\b' + re.escape(name) + r'\b', 'LanguageTest' + name, source)
cleanup = '\n'.join(f':global LanguageTest{name}; :set LanguageTest{name};' for name in variables)
sys.stdout.buffer.write((':onerror TestError {\n' + source + '\n' + cleanup +
                        '\n} do={\n' + cleanup + '\n:error $TestError;\n}\n').encode('utf-8'))
