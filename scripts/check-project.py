#!/usr/bin/env python3
"""Validate documentation links, language resources and repository invariants."""
import json
from pathlib import Path
import re
import subprocess
import sys
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parent.parent
errors = []

def fail(path, message):
    errors.append(f'{path.relative_to(ROOT)}: {message}')


def anchors(text):
    result = set()
    counts = {}
    for heading in re.findall(r'^#{1,6}\s+(.+)$', text, re.M):
        heading = re.sub(r'[`*]', '', heading).lower()
        heading = re.sub(r'[^\w\-\s]', '', heading).replace(' ', '-')
        suffix = counts.get(heading, 0)
        counts[heading] = suffix + 1
        result.add(heading if not suffix else f'{heading}-{suffix}')
    return result


paths = [ROOT / 'README.md', *sorted((ROOT / 'doc').rglob('*.md'))]
names = set()
for path in paths:
    text = path.read_text(encoding='utf-8')
    if len(re.findall(r'^# ', text, re.M)) != 1:
        fail(path, 'expected exactly one H1')
    if path.name == 'README.md':
        if text.startswith('---\n'):
            fail(path, 'README must not have frontmatter')
    else:
        front = re.match(r'^---\n(.*?)\n---\n', text, re.S)
        if not front:
            fail(path, 'missing frontmatter')
        else:
            fields = re.findall(r'^([a-z]+):', front[1], re.M)
            if fields != ['name', 'description', 'metadata']:
                fail(path, 'invalid frontmatter fields')
            name = re.search(r'^name: ([a-z0-9-]{1,64})$', front[1], re.M)
            if not name or name[1] in names:
                fail(path, 'invalid or duplicate document name')
            if name:
                names.add(name[1])
            if not re.search(r'^  version: "\d+\.\d+\.\d+"$', front[1], re.M):
                fail(path, 'metadata.version must be quoted semver')
    # Inline links in code examples are not document links.
    prose = re.sub(r'```[\s\S]*?```', '', text)
    for target in re.findall(r'!?\[[^\]]*\]\(([^)]+)\)', prose):
        target = target.split(' "', 1)[0].strip('<>')
        if re.match(r'[a-z]+:', target):
            continue
        file, _, fragment = unquote(target).partition('#')
        resolved = (path.parent / file).resolve() if file else path
        if not resolved.exists():
            fail(path, f'broken link: {target}')
        elif fragment and resolved.suffix == '.md' and fragment.lower() not in anchors(resolved.read_text()):
            fail(path, f'broken anchor: {target}')

core = ('README', 'DESIGN', 'LOG', 'HISTORY', 'CHANGELOG', 'THIRD_PARTY_NOTICES')
for lang in ('zh-CN', 'en', 'es'):
    folder = ROOT / 'doc' if lang == 'zh-CN' else ROOT / 'doc' / lang
    for name in core:
        path = ROOT / 'README.md' if name == 'README' and lang == 'zh-CN' else folder / (name + '.md')
        if not path.is_file():
            fail(path, 'missing core document')

catalogs = {p.stem: json.loads(p.read_text()) for p in (ROOT / 'lang/web').glob('*.json')}
source_keys = set(catalogs['en'])
for lang, strings in catalogs.items():
    missing = source_keys - strings.keys()
    extra = strings.keys() - source_keys
    if missing or extra:
        fail(ROOT / 'lang/web' / (lang + '.json'), f'language keys differ: missing={sorted(missing)}, extra={sorted(extra)}')
    if any(not isinstance(value, str) or not value for value in strings.values()):
        fail(ROOT / 'lang/web' / (lang + '.json'), 'empty/non-string translation')
for key in re.findall(r"""\bt\(["']([^"']+)["']\)""", (ROOT / 'src/web/src/App.vue').read_text()):
    if key not in source_keys:
        fail(ROOT / 'src/web/src/App.vue', f'missing translation: {key}')

package = json.loads((ROOT / 'src/web/package.json').read_text())
lock = json.loads((ROOT / 'src/web/package-lock.json').read_text())
for field in ('version', 'dependencies', 'devDependencies', 'engines'):
    if lock['packages'][''].get(field) != package.get(field):
        fail(ROOT / 'src/web/package-lock.json', f'{field} differs from package.json')
for language in catalogs:
    path = ROOT / 'doc' / ('' if language == 'zh-CN' else language) / 'CHANGELOG.md'
    if not path.exists():
        fail(path, 'UI language has no changelog')
    elif not re.search(r'^### v4\.1\.0\b', path.read_text(), re.M):
        fail(path, 'latest released version absent')

tracked = subprocess.check_output(['git', 'ls-files'], cwd=ROOT, text=True).splitlines()
for file in tracked:
    # Files removed during migration are intentionally absent before staging.
    if (ROOT / file).exists() and (file.startswith(('.local/', 'dist/', 'node_modules/')) or '/node_modules/' in file):
        fail(ROOT / file, 'private/generated file tracked by Git')
for excluded in ('.local/check', '.env', 'dist/web/index.html'):
    if subprocess.run(['git', 'check-ignore', '-q', excluded], cwd=ROOT).returncode:
        fail(ROOT / '.gitignore', f'not ignored: {excluded}')
if errors:
    print('\n'.join(errors), file=sys.stderr)
    sys.exit(1)
print(f'project: {len(paths)} documents, {len(catalogs)} catalogs, links and lockfile passed')
