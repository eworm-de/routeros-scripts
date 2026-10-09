"""Catalog and generated-artifact checks; RouterOS behavior is tested separately."""
import importlib.util
import json
from pathlib import Path
import re
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location('languages', ROOT / 'contrib/languages.py')
languages = importlib.util.module_from_spec(spec)
spec.loader.exec_module(languages)


class CatalogTests(unittest.TestCase):
    def setUp(self):
        self.english = languages.load(ROOT / 'languages/en/check-health.json')

    def test_generated_artifacts_match_catalogs(self):
        languages.render(check=True)

    def test_all_call_sites_have_english_defaults(self):
        messages = self.english['messages']
        used = set()
        for path in [ROOT / 'check-health.rsc', *sorted((ROOT / 'check-health.d').glob('*.rsc'))]:
            source = path.read_text(encoding='utf-8')
            used.update(re.findall(r'\$Translate "([^"]+)"', source))
        self.assertEqual(set(messages), used)

    def test_dictionary_function_arguments_are_parenthesized(self):
        # RouterOS rejects a bare dictionary following a positional argument.
        for path in [ROOT / 'check-health.rsc', ROOT / 'tests/languages.rsc',
                     *sorted((ROOT / 'check-health.d').glob('*.rsc'))]:
            with self.subTest(path=path.name):
                self.assertIsNone(re.search(r'\$Translate "[^"]+"\s+\{',
                                            path.read_text(encoding='utf-8')))

    def test_english_preserves_health_messages(self):
        self.assertEqual(self.english['messages']['check-health.cpu.warning.message'],
                         'The average CPU utilization on {identity} is at {percent}%!')
        self.assertEqual(self.english['messages']['check-health.voltage.jumped'],
                         'The {name} on {identity} jumped more than {percent}%.\n\n{details}')

    def test_routeros_quote_escapes_code_and_unicode(self):
        self.assertEqual(languages.quote('"$\\\n°'), '"\\22\\24\\5C\\0A\\C2\\B0"')

    def test_duplicate_json_keys_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'bad.json'
            path.write_text('{"a":1,"a":2}', encoding='utf-8')
            with self.assertRaisesRegex(ValueError, 'Duplicate key'):
                languages.load(path)

    def test_invalid_placeholders_are_rejected(self):
        for text in ('bad {identity', 'bad }', '{wrong-name}', '{{identity}}'):
            with self.subTest(text=text), self.assertRaises(ValueError):
                languages.tokens(text)

    def test_translator_can_reorder_and_repeat_placeholders(self):
        self.assertEqual(languages.tokens('{percent}%: {identity} ({identity})'),
                         languages.tokens('{identity}: {percent}%'))

    def test_mismatched_translation_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for locale in ('en', 'pt-BR'):
                (root / 'languages' / locale).mkdir(parents=True)
            (root / 'languages/en/check-health.json').write_text(
                json.dumps(self.english), encoding='utf-8')
            bad = {'language': 'pt-BR', 'messages': {'check-health.cpu.warning.message': '{wrong}'}}
            (root / 'languages/pt-BR/check-health.json').write_text(json.dumps(bad), encoding='utf-8')
            with patch.object(languages, 'ROOT', root), self.assertRaisesRegex(ValueError, 'Invalid translation'):
                languages.render()


if __name__ == '__main__':
    unittest.main()
