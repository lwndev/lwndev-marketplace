#!/usr/bin/env tsx
import { parseArgs } from 'node:util';
import { execSync } from 'node:child_process';
import { getSourcePlugins } from './lib/skill-utils.js';
import { readPluginManifest } from './lib/plugin-manifest.js';
import { isWorkingTreeClean, getCurrentBranch, tagExists } from './lib/git-utils.js';
import { printSuccess, printError, printInfo } from './lib/prompts.js';

function parseCliArgs(): { plugin?: string } {
  const { values } = parseArgs({
    options: {
      plugin: { type: 'string' },
    },
    strict: false,
  });
  return values as { plugin?: string };
}

async function selectPlugin(pluginFlag?: string): Promise<string> {
  const plugins = await getSourcePlugins();

  if (plugins.length === 0) {
    printError('No plugins found in plugins/');
    process.exit(1);
  }

  if (pluginFlag) {
    if (!plugins.includes(pluginFlag)) {
      printError(`Plugin "${pluginFlag}" not found. Available plugins: ${plugins.join(', ')}`);
      process.exit(1);
    }
    return pluginFlag;
  }

  if (plugins.length === 1) {
    printInfo(`Using plugin: ${plugins[0]}`);
    return plugins[0];
  }

  printError(
    `Multiple plugins found. Specify --plugin <name>. Available plugins: ${plugins.join(', ')}`
  );
  process.exit(1);
}

async function main(): Promise<void> {
  const args = parseCliArgs();

  // Verify on main branch
  const branch = getCurrentBranch();
  if (branch !== 'main') {
    printError(`Must be on main branch to tag a release. Current branch: ${branch}`);
    process.exit(1);
  }

  // Verify clean working tree
  if (!isWorkingTreeClean()) {
    printError('Working tree has uncommitted changes. Commit or stash them first.');
    process.exit(1);
  }

  // Select plugin
  const pluginName = await selectPlugin(args.plugin);

  // Read current version
  const manifest = await readPluginManifest(pluginName);
  const version = manifest.version;
  const tagName = `${pluginName}@${version}`;

  // Check tag doesn't already exist
  if (tagExists(tagName)) {
    printError(`Tag "${tagName}" already exists`);
    process.exit(1);
  }

  // Create annotated tag
  execSync(`git tag -a "${tagName}" -m "Release ${pluginName} v${version}"`);

  // Summary
  printSuccess(`Plugin:   ${pluginName}`);
  printSuccess(`Tag:      ${tagName}`);
  console.log('');
  console.log('To publish:');
  console.log('  git push --tags');
}

main().catch((err) => {
  printError(err.message);
  process.exit(1);
});
