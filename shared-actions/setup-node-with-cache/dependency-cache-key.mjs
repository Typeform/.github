#!/usr/bin/env node
// Prints a hash of the inputs that decide what `yarn install` / `pnpm install` puts in
// node_modules. Used as the dependency cache key by setup-node-with-cache.
//
// Usage: node dependency-cache-key.mjs <yarn|pnpm>   (run from the repository root)
//
// Unlike hashFiles('**/package.json'), it ignores the parts of package.json that do not
// change node_modules, so a release (changesets bumping `version` and internal ranges)
// keeps hitting the cache:
//   - `version`, `scripts` and every other non-dependency field are dropped;
//   - ranges of dependencies on packages that live in this repo (workspaces) are dropped.
//     If such a range stops matching the local package, the package manager resolves it
//     from the registry instead, which changes the lockfile and therefore the key.
// Ranges of external dependencies are kept, so a package.json edit without a lockfile
// update still misses and `install --frozen-lockfile` still fails loudly.
import { execFileSync } from 'node:child_process'
import { createHash } from 'node:crypto'
import { readFileSync, readdirSync } from 'node:fs'
import { basename, join } from 'node:path'

const packageManager = process.argv[2] === 'pnpm' ? 'pnpm' : 'yarn'
const LOCKFILES = packageManager === 'pnpm' ? ['pnpm-lock.yaml'] : ['yarn.lock']
const CONFIG_FILES = ['.npmrc', '.yarnrc', '.yarnrc.yml', 'pnpm-workspace.yaml', '.pnpmfile.cjs']
const WANTED = new Set([...LOCKFILES, ...CONFIG_FILES, 'package.json'])

const DEPENDENCY_FIELDS = ['dependencies', 'devDependencies', 'optionalDependencies', 'peerDependencies']
// Fields other than dependency ranges that change what ends up in node_modules.
const KEPT_FIELDS = [
  'name',
  'bin',
  'workspaces',
  'resolutions',
  'overrides',
  'pnpm',
  'packageManager',
  'dependenciesMeta',
  'peerDependenciesMeta',
  'bundleDependencies',
  'bundledDependencies',
]

const isWanted = (path) =>
  WANTED.has(basename(path)) && !path.split('/').includes('node_modules')

// Tracked files only, so files generated before this step (build output, downloaded
// artifacts) cannot change the key. Falls back to walking the tree outside a git checkout.
const listFiles = () => {
  try {
    const out = execFileSync('git', ['ls-files', '-z', '--cached'], {
      encoding: 'utf8',
      maxBuffer: 1024 * 1024 * 512,
      stdio: ['ignore', 'pipe', 'ignore'],
    })
    return out.split('\0').filter((path) => path && isWanted(path))
  } catch {
    const found = []
    const walk = (dir) => {
      for (const entry of readdirSync(dir, { withFileTypes: true })) {
        if (entry.name === 'node_modules' || entry.name === '.git') continue
        const path = dir === '.' ? entry.name : join(dir, entry.name)
        if (entry.isDirectory()) walk(path)
        else if (entry.isFile() && isWanted(path)) found.push(path)
      }
    }
    walk('.')
    return found
  }
}

const read = (path) => {
  try {
    return readFileSync(path, 'utf8')
  } catch {
    return '' // listed by git but deleted in the working tree
  }
}

const byCodeUnit = (a, b) => (a < b ? -1 : a > b ? 1 : 0)
const files = listFiles().sort(byCodeUnit)

const manifests = new Map()
for (const path of files.filter((path) => basename(path) === 'package.json')) {
  try {
    manifests.set(path, JSON.parse(read(path)))
  } catch {
    manifests.set(path, null) // invalid JSON (e.g. a test fixture): hash it verbatim
  }
}

const localNames = new Set()
for (const [path, manifest] of manifests) {
  if (path !== 'package.json' && manifest && typeof manifest.name === 'string') {
    localNames.add(manifest.name)
  }
}

const normalise = (manifest) => {
  const out = {}
  for (const field of KEPT_FIELDS) {
    if (manifest[field] !== undefined) out[field] = manifest[field]
  }
  for (const field of DEPENDENCY_FIELDS) {
    const deps = manifest[field]
    if (!deps || typeof deps !== 'object') continue
    out[field] = Object.keys(deps)
      .sort(byCodeUnit)
      .map((name) => [name, localNames.has(name) ? '<local>' : deps[name]])
  }
  return JSON.stringify(out)
}

const hash = createHash('sha256')
hash.update(`dependency-cache-key v1 ${packageManager}\0`)
for (const path of files) {
  const manifest = manifests.get(path)
  const content = manifests.has(path) && manifest ? normalise(manifest) : read(path)
  hash.update(`\0${path}\0${content}`)
}

process.stdout.write(hash.digest('hex'))
