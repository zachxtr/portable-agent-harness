---
name: query-local-user-agent-workspace
description: Query the local MinIO instance to inspect the PolicyCommand agent workspace bucket. Use when verifying S3 writes, checking navigation history, annotations, briefs, policy profiles, or any agent workspace data. Use when the user asks to check, verify, or inspect what's in the agents bucket, MinIO storage, or any path under accounts/{accountId}/users/{userId}/.
---

# Query Local User Agent Workspace

Inspect the PolicyCommand `agents` bucket on the local MinIO instance using the AWS CLI pointed at `localhost:9000`.

## Connection Details

| Field | Value |
|---|---|
| Endpoint | `http://localhost:9000` |
| Bucket | `agents` |
| Key ID | `minioadmin` |
| Secret | `minioadmin` |
| Dev user path | `accounts/0/users/1/` |

## Base command alias

Every command uses this prefix — copy it:

```bash
AWS_ACCESS_KEY_ID=minioadmin AWS_SECRET_ACCESS_KEY=minioadmin aws s3 \
  --endpoint-url http://localhost:9000
```

## Common queries

**List top-level workspace folders for the dev user:**
```bash
AWS_ACCESS_KEY_ID=minioadmin AWS_SECRET_ACCESS_KEY=minioadmin \
  aws s3 ls s3://agents/accounts/0/users/1/ --endpoint-url http://localhost:9000
```

**List a specific folder (e.g. navigation-history, annotations, briefs):**
```bash
AWS_ACCESS_KEY_ID=minioadmin AWS_SECRET_ACCESS_KEY=minioadmin \
  aws s3 ls s3://agents/accounts/0/users/1/<folder>/ --endpoint-url http://localhost:9000
```

**Read a specific file:**
```bash
AWS_ACCESS_KEY_ID=minioadmin AWS_SECRET_ACCESS_KEY=minioadmin \
  aws s3 cp s3://agents/<key> - --endpoint-url http://localhost:9000
```

**Recursive list of a folder (shows full key tree + sizes):**
```bash
AWS_ACCESS_KEY_ID=minioadmin AWS_SECRET_ACCESS_KEY=minioadmin \
  aws s3 ls s3://agents/accounts/0/users/1/<folder>/ --recursive --endpoint-url http://localhost:9000
```

**List all buckets:**
```bash
AWS_ACCESS_KEY_ID=minioadmin AWS_SECRET_ACCESS_KEY=minioadmin \
  aws s3 ls --endpoint-url http://localhost:9000
```

## Workspace folder map

| Folder | Contents |
|---|---|
| `agent-workspace.json` | Workspace manifest (name, avatar, setup status) |
| `navigation-history/` | `{dt}__{sessionId}__{device}__{section}.txt` — URL as body |
| `annotations/` | Per-bill subfolder → `{dt}__highlight/tag/note/drawing__{id}.json` |
| `briefs/` | `{dt}__{traceId}__{briefType}__{tok}tok.json` |
| `policy-profiles/` | `{uuid}.json` per profile |
| `chat/` | `conv/{convId}/` — turn records + summary doc |
| `user-profile.json` | User profile document |
| `_system/` | Agent persona templates (identity, soul, wakeup, etc.) |

## Key naming conventions

- `__` separates filename segments
- `{dt}` = `YYYYMMDDHHMMSS` timestamp
- `tok{n}tok` = token count embedded in filename
- Segment values are sanitized: only `[a-zA-Z0-9._-]` kept, others replaced with `-`

See `UserAgentWorkspaceLayout.ts` in `packages/shared/storage-client/src/` for the full key-construction functions.
