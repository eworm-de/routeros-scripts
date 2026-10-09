#!/usr/bin/env python3
"""Print a RouterOS test bundle with globals isolated from installed scripts."""
from pathlib import Path
import argparse
import json
import re
import sys
from languages import load, quote, TOKEN, tokens

root = Path(__file__).resolve().parent.parent
runtime = (root / 'languages/runtime.rsc').read_text(encoding='utf-8')
tests = (root / 'tests/languages.rsc').read_text(encoding='utf-8')
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--base-url', help='HTTPS distribution URL; also run catalog download/cache tests')
parser.add_argument('--catalogs', action='store_true', help='Test every catalog message on RouterOS')
parser.add_argument('--notifications', action='store_true', help='Test notification guards and the email loop filter without sending')
parser.add_argument('--netwatch', action='store_true', help='Test Netwatch state transitions with simulated hosts and a local notification sink')
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
