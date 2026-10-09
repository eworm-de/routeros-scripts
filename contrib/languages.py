#!/usr/bin/env python3
"""Validate catalogs and embed offline English defaults (Python standard library)."""
import argparse
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent.parent
BEGIN = "# BEGIN GENERATED LANGUAGE DATA"
END = "# END GENERATED LANGUAGE DATA"
TOKEN = re.compile(r"\{([a-z][a-z0-9_]*)\}")


def tokens(text):
    remainder = TOKEN.sub("", text)
    if "{" in remainder or "}" in remainder:
        raise ValueError(f"Invalid placeholder in {text!r}")
    return set(TOKEN.findall(text))


def quote(text):
    # RouterOS string escapes operate on UTF-8 bytes.
    return '"' + ''.join(chr(b) if 32 <= b < 127 and chr(b) not in '\\"$' else
                         f"\\{b:02X}" for b in text.encode('utf-8')) + '"'


def load(path):
    def unique(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise ValueError(f"Duplicate key {key} in {path}")
            result[key] = value
        return result
    return json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=unique)


def render(check=False):
    schemas = {}
    outputs = {}
    for path in sorted((ROOT / 'languages/en').glob('*.json')):
        group = path.stem
        english = load(path)
        if english['language'] != 'en':
            raise ValueError(f"Wrong locale: {path}")
        messages = english['messages']
        for key, value in messages.items():
            if not key.startswith(group + '.') or not isinstance(value, str):
                raise ValueError(f"Invalid message: {key}")
            tokens(value)
        schema = hashlib.sha256(json.dumps(messages, sort_keys=True, ensure_ascii=True).encode()).hexdigest()
        schemas[group] = schema
        for locale in sorted((ROOT / 'languages').iterdir()):
            translated = locale / path.name
            if not locale.is_dir() or not translated.exists():
                continue
            catalog = load(translated)
            if catalog['language'] != locale.name:
                raise ValueError(f"Wrong locale: {translated}")
            for key, text in catalog['messages'].items():
                if key not in messages or not isinstance(text, str) or tokens(text) != tokens(messages[key]):
                    raise ValueError(f"Invalid translation: {translated}: {key}")
            catalog['schema'] = schema
            body = json.dumps(catalog, ensure_ascii=False, indent=2) + '\n'
            if len(body.encode('utf-8')) > 50000:
                raise ValueError(f"Catalog too large: {translated}")
            outputs[translated] = body
        block = BEGIN + f'\n# language, name={group}, schema={schema}\n:global LanguageEnglish;\n'
        block += ':if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }\n'
        for key, text in sorted(messages.items()):
            block += f':set ($LanguageEnglish->{quote(key)}) {quote(text)};\n'
        block += END
        target = ROOT / (group + '.rsc')
        source = target.read_text(encoding='utf-8')
        if BEGIN in source:
            source = re.sub(re.escape(BEGIN) + r'.*?' + re.escape(END), lambda _: block, source, flags=re.S)
        else:
            pos = source.index('\n:onerror')
            source = source[:pos] + '\n' + block + '\n' + source[pos:]
        outputs[target] = source
    runtime = (ROOT / 'languages/runtime.rsc').read_text(encoding='utf-8')
    block = BEGIN + '''
# Discover catalog schemas from installed scripts, so unused features need no downloads.
:global LanguageSchemas ({});
:foreach Script in=[ /system/script/find ] do={
  :local Info [ $ParseKeyValueStore [ $Grep [ /system/script/get $Script source ] "# language, " ] ];
  :if ([ :len ($Info->"schema") ] = 64 && ($Info->"name") ~ "^[a-z0-9-]+\\$") do={
    :set ($LanguageSchemas->($Info->"name")) ($Info->"schema");
  }
}
''' + runtime + END
    core = ROOT / 'global-functions.rsc'
    source = core.read_text(encoding='utf-8')
    if BEGIN in source:
        source = re.sub(re.escape(BEGIN) + r'.*?' + re.escape(END), lambda _: block, source, flags=re.S)
    else:
        source = source.replace('# load modules\n', block + '\n\n# load modules\n')
    if len(source.encode('utf-8')) >= 64000:
        raise ValueError('global-functions exceeds conservative Fetch size budget')
    outputs[core] = source
    stale = [str(path.relative_to(ROOT)) for path, text in outputs.items()
             if path.read_text(encoding='utf-8') != text]
    if check and stale:
        raise ValueError('Regenerate language data: ' + ', '.join(stale))
    if not check:
        for path, text in outputs.items():
            if path.read_text(encoding='utf-8') != text:
                path.write_text(text, encoding='utf-8', newline='\n')
    return schemas


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    render(parser.parse_args().check)
