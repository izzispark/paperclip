# GitHub Auth via Infisical

Use this runbook when you need to push Paperclip changes to GitHub and the shell does not already have `GITHUB_TOKEN` or `GH_TOKEN`.

## When To Use

- `git push` prompts for credentials or fails with `could not read Username`
- `gh auth status` shows no logged-in host
- The GitHub token is stored in Infisical for the current Paperclip project

## Inputs

- `INFISICAL_MACHINE_CLIENT_ID`
- `INFISICAL_MACHINE_CLIENT_SECRET`
- `INFISICAL_PROJECT_ID`
- `INFISICAL_SECRET_ENV`, usually `prod`
- `INFISICAL_API_URL`

## Secret Location

- Secret path: `/github`
- Secret key: `GITHUB_TOKEN`

## Procedure

1. Log in to Infisical with the machine identity.

```bash
LOGIN_TOKEN=$(
  curl -sS -X POST "$INFISICAL_API_URL/v1/auth/universal-auth/login" \
    -H 'Content-Type: application/json' \
    -d "{\"clientId\":\"$INFISICAL_MACHINE_CLIENT_ID\",\"clientSecret\":\"$INFISICAL_MACHINE_CLIENT_SECRET\"}" \
  | jq -r .accessToken
)
```

2. Read the GitHub token from Infisical.

```bash
GITHUB_TOKEN=$(
  curl -sS "$INFISICAL_API_URL/v4/secrets?projectId=$INFISICAL_PROJECT_ID&environment=$INFISICAL_SECRET_ENV&secretPath=/github&recursive=false&viewSecretValue=true&includeImports=true" \
    -H "Authorization: Bearer $LOGIN_TOKEN" \
  | jq -r '.secrets[] | select(.secretKey=="GITHUB_TOKEN") | .secretValue' \
  | head -n1
)
```

3. Push with a tokenized HTTPS URL.

```bash
git push -u "https://x-access-token:${GITHUB_TOKEN}@github.com/izzispark/paperclip.git" master
```

4. Normalize the upstream tracking ref back to the plain remote name.

```bash
git branch --set-upstream-to=origin/master master
```

5. Confirm the checkout is clean and the branch tracks `origin/master`.

```bash
git status --short
git remote -v
git branch -vv
```

## Notes

- This token may be good for Git pushes even if `gh auth login` rejects it for missing `read:org`.
- Use the direct push path first. Only bother with `gh auth login` if you specifically need GitHub CLI features and the token has the required scopes.
- Do not write the token into a file or commit it to the repo.

## If The Push Is Rejected

- If GitHub says `fetch first`, rebase onto the current remote head.

```bash
git fetch origin master
git rebase origin/master
git push -u "https://x-access-token:${GITHUB_TOKEN}@github.com/izzispark/paperclip.git" master
```

- If the token is missing from Infisical, check the `/github` secret in the same project/environment pair used by the runtime.
