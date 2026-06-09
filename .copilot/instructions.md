# Global Copilot Instructions

## Git Identity & Credential Hygiene

**CRITICAL — always enforce these rules when making git commits:**

1. **Never add a Co-authored-by trailer** to any commit. Do not include
   `Co-authored-by: Copilot <...>` or any other co-author line unless the
   user explicitly requests it.

2. **Verify git identity before committing.** Before any `git commit`, run
   `git config user.email` and confirm the result is appropriate for the
   target repository:
   - Personal repos (e.g. `~/.cfg` bare repo, any `github-personal` remote):
     must use `wmeger14@gmail.com`
   - Work repos: must use `william.meger@crunchyroll.com`
   - If the email is wrong, abort and alert the user — do NOT commit.

3. **Never commit secrets, tokens, or credentials** to any repository.
   Scan staged diffs for API keys, tokens, passwords, and private keys
   before committing.

4. **Never expose work identity in personal repos** (or vice versa). This
   includes author/committer email, internal hostnames, project names, or
   any information that links the two identities.
