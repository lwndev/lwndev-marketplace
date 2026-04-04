import { describe, it, expect, beforeAll } from 'vitest';
import { readFile } from 'node:fs/promises';
import { join } from 'node:path';
import { validate, type DetailedValidateResult } from 'ai-skills-manager';

const SKILL_DIR = 'plugins/lwndev-sdlc/skills/managing-work-items';
const SKILL_MD_PATH = join(SKILL_DIR, 'SKILL.md');
const GITHUB_TEMPLATES_PATH = join(SKILL_DIR, 'references', 'github-templates.md');
const JIRA_TEMPLATES_PATH = join(SKILL_DIR, 'references', 'jira-templates.md');

describe('managing-work-items skill', () => {
  let skillMd: string;
  let githubTemplates: string;
  let jiraTemplates: string;

  beforeAll(async () => {
    skillMd = await readFile(SKILL_MD_PATH, 'utf-8');
    githubTemplates = await readFile(GITHUB_TEMPLATES_PATH, 'utf-8');
    jiraTemplates = await readFile(JIRA_TEMPLATES_PATH, 'utf-8');
  });

  describe('skill directory structure', () => {
    it('should have SKILL.md at the expected path', () => {
      expect(skillMd).toBeDefined();
      expect(skillMd.length).toBeGreaterThan(0);
    });

    it('should have references/github-templates.md', () => {
      expect(githubTemplates).toBeDefined();
      expect(githubTemplates.length).toBeGreaterThan(0);
    });

    it('should have references/jira-templates.md', () => {
      expect(jiraTemplates).toBeDefined();
      expect(jiraTemplates.length).toBeGreaterThan(0);
    });
  });

  describe('SKILL.md frontmatter', () => {
    it('should have frontmatter with name: managing-work-items', () => {
      expect(skillMd).toMatch(/^---\s*\n[\s\S]*?name:\s*managing-work-items[\s\S]*?---/);
    });

    it('should have frontmatter with non-empty description', () => {
      const match = skillMd.match(/^---\s*\n[\s\S]*?description:\s*(.+)[\s\S]*?---/);
      expect(match).not.toBeNull();
      expect(match![1].trim().length).toBeGreaterThan(0);
    });

    it('should have allowed-tools including Read, Write, Edit, Bash, Glob, Grep', () => {
      const frontmatter = skillMd.match(/^---\s*\n([\s\S]*?)---/)?.[1] ?? '';
      expect(frontmatter).toContain('- Read');
      expect(frontmatter).toContain('- Write');
      expect(frontmatter).toContain('- Edit');
      expect(frontmatter).toContain('- Bash');
      expect(frontmatter).toContain('- Glob');
      expect(frontmatter).toContain('- Grep');
    });

    it('should have argument-hint with operation and issue-ref', () => {
      const frontmatter = skillMd.match(/^---\s*\n([\s\S]*?)---/)?.[1] ?? '';
      expect(frontmatter).toContain('argument-hint:');
      expect(frontmatter).toMatch(/argument-hint:.*operation/);
    });
  });

  describe('SKILL.md content', () => {
    it('should document backend detection logic (FR-1)', () => {
      expect(skillMd).toContain('Backend Detection');
      expect(skillMd).toContain('#N');
      expect(skillMd).toContain('PROJ-123');
    });

    it('should document GitHub Issues backend operations (FR-2)', () => {
      expect(skillMd).toContain('GitHub Issues Backend');
      expect(skillMd).toContain('gh issue view');
      expect(skillMd).toContain('gh issue comment');
    });

    it('should document comment type routing (FR-5)', () => {
      expect(skillMd).toContain('Comment Type Routing');
      expect(skillMd).toContain('phase-start');
      expect(skillMd).toContain('phase-completion');
      expect(skillMd).toContain('work-start');
      expect(skillMd).toContain('work-complete');
      expect(skillMd).toContain('bug-start');
      expect(skillMd).toContain('bug-complete');
    });

    it('should document PR body issue link generation (FR-6)', () => {
      expect(skillMd).toContain('PR Body Issue Link');
      expect(skillMd).toContain('Closes #N');
    });

    it('should document issue reference extraction (FR-7)', () => {
      expect(skillMd).toContain('Issue Reference Extraction');
      expect(skillMd).toContain('## GitHub Issue');
    });

    it('should document graceful degradation (NFR-1)', () => {
      expect(skillMd).toContain('Graceful Degradation');
      expect(skillMd).toContain('never');
      expect(skillMd).toContain('block workflow');
    });

    it('should document error handling (NFR-2)', () => {
      expect(skillMd).toContain('Error Handling');
      expect(skillMd).toContain('gh auth login');
    });

    it('should document idempotency (NFR-3)', () => {
      expect(skillMd).toContain('Idempotency');
      expect(skillMd).toContain('safe to retry');
    });

    it('should document Jira tiered fallback (FR-3)', () => {
      expect(skillMd).toContain('Jira Backend');
      expect(skillMd).toContain('Rovo MCP');
      expect(skillMd).toContain('acli');
      expect(skillMd).toContain('Tier 1');
      expect(skillMd).toContain('Tier 2');
      expect(skillMd).toContain('Tier 3');
    });
  });

  describe('references/github-templates.md', () => {
    it('should contain phase-start comment template', () => {
      expect(githubTemplates).toContain('### phase-start');
      expect(githubTemplates).toMatch(/Starting Phase.*Phase Name/);
    });

    it('should contain phase-completion comment template', () => {
      expect(githubTemplates).toContain('### phase-completion');
      expect(githubTemplates).toMatch(/Completed Phase.*Phase Name/);
    });

    it('should contain work-start comment template', () => {
      expect(githubTemplates).toContain('### work-start');
      expect(githubTemplates).toContain('Starting work on CHORE-XXX');
    });

    it('should contain work-complete comment template', () => {
      expect(githubTemplates).toContain('### work-complete');
      expect(githubTemplates).toContain('Completed CHORE-XXX');
    });

    it('should contain bug-start comment template', () => {
      expect(githubTemplates).toContain('### bug-start');
      expect(githubTemplates).toContain('Starting work on BUG-XXX');
    });

    it('should contain bug-complete comment template', () => {
      expect(githubTemplates).toContain('### bug-complete');
      expect(githubTemplates).toContain('Completed BUG-XXX');
    });

    it('should contain commit message templates', () => {
      expect(githubTemplates).toContain('## Commit Messages');
      expect(githubTemplates).toContain('Feature Commits');
      expect(githubTemplates).toContain('Chore Commits');
      expect(githubTemplates).toContain('Bug Fix Commits');
    });

    it('should contain PR body templates', () => {
      expect(githubTemplates).toContain('## Pull Request Templates');
      expect(githubTemplates).toContain('Closes #N');
    });

    it('should contain issue creation templates', () => {
      expect(githubTemplates).toContain('## Creating New Issues');
      expect(githubTemplates).toContain('Chore Issue');
      expect(githubTemplates).toContain('Bug Issue');
    });
  });

  describe('references/jira-templates.md', () => {
    it('should exist with content', () => {
      expect(jiraTemplates).toBeDefined();
      expect(jiraTemplates.length).toBeGreaterThan(0);
    });

    it('should reference ADF specification', () => {
      expect(jiraTemplates).toContain(
        'https://developer.atlassian.com/cloud/jira/platform/apis/document/structure/'
      );
    });

    it('should contain placeholder templates for all six comment types', () => {
      expect(jiraTemplates).toContain('### phase-start');
      expect(jiraTemplates).toContain('### phase-completion');
      expect(jiraTemplates).toContain('### work-start');
      expect(jiraTemplates).toContain('### work-complete');
      expect(jiraTemplates).toContain('### bug-start');
      expect(jiraTemplates).toContain('### bug-complete');
    });

    it('should mark templates as Phase 2 TODO', () => {
      expect(jiraTemplates).toContain('TODO: Phase 2');
    });

    it('should contain ADF JSON structure in each template', () => {
      expect(jiraTemplates).toContain('"version": 1');
      expect(jiraTemplates).toContain('"type": "doc"');
      expect(jiraTemplates).toContain('"content"');
    });
  });

  describe('validation API', () => {
    it('should pass ai-skills-manager validation', async () => {
      const result: DetailedValidateResult = await validate(SKILL_DIR, {
        detailed: true,
      });
      expect(result.valid).toBe(true);
    });
  });
});
