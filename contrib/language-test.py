#!/usr/bin/env python3
"""Print a RouterOS test bundle with globals isolated from installed scripts."""
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parent.parent
runtime = (root / 'languages/runtime.rsc').read_text(encoding='utf-8')
tests = (root / 'tests/languages.rsc').read_text(encoding='utf-8')
variables = sorted(set(re.findall(r':global ([A-Za-z][A-Za-z0-9]*)', runtime + tests)))
source = runtime + '\n' + tests
for name in sorted(variables, key=len, reverse=True):
    source = re.sub(r'\b' + re.escape(name) + r'\b', 'LanguageTest' + name, source)
cleanup = '\n'.join(f':global LanguageTest{name}; :set LanguageTest{name};' for name in variables)
sys.stdout.buffer.write((':onerror TestError {\n' + source + '\n' + cleanup +
                        '\n} do={\n' + cleanup + '\n:error $TestError;\n}\n').encode('utf-8'))
