#!/usr/bin/env python3
"""Print a RouterOS test bundle with globals isolated from installed scripts."""
from pathlib import Path
import argparse
import re
import sys
from languages import load, quote

root = Path(__file__).resolve().parent.parent
runtime = (root / 'languages/runtime.rsc').read_text(encoding='utf-8')
tests = (root / 'tests/languages.rsc').read_text(encoding='utf-8')
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--base-url', help='HTTPS distribution URL; also run catalog download/cache tests')
args = parser.parse_args()
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
