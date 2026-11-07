# realm-dev-vocabulary

The words software teams use for their work, whatever forge or tracker keeps it.

This realm fetches nothing and answers nothing. It declares eight parent types — a repository,
an issue, a change request, a comment, a review, a commit, a file change, a build — and the
rules a child type agrees to when it claims one of them as a parent. Realms over real products
do the rest.

## Why it exists

A view that says `MATCH (i:GitHubIssue)` stops working the day the tracker is replaced, and
never worked for the team whose issues are in Jira and whose code is on GitLab. A view that
says `MATCH (i:Issue)` does both, because a realm's labels are global and a child carries its
parents' labels physically:

```yaml
# in realm-github                       # in realm-gitlab                    # in realm-jira
- name: GitHubIssue                     - name: GitLabIssue                  - name: JiraIssue
  parents: [Issue]                        parents: [Issue]                     parents: [Issue]
```

```cypher
MATCH (i:Issue) WHERE i.status = 'open' RETURN i          // whichever trackers are installed
MATCH (i:GitHub:Issue) RETURN i                           // one product, by its realm label
```

Anything built on the parents — views, DERIVE rules, natural-language questions, apps — is
written once and names no vendor.

## The question it is built to ask

Every record here says **who wrote it**, and `authorKind` says what that author was:

| | |
|---|---|
| `human` | an account the source knows to be a person |
| `bot` | an account the source marks as a machine: Dependabot, Renovate, a CI commenter |
| `agent` | a coding agent under its own identity: a login naming Copilot, Claude, Devin, Codex, Cursor, Aider, Jules, Sweep |
| `assisted` | a person's record that declares an agent's hand: a `Co-Authored-By` trailer naming an agent, a description that says an agent generated it |
| `unknown` | the source does not say |

So "what share of review comments are machine-written", "do agent-opened change requests
draw more human review", "are humans or machines more likely to break the build" are each
one `GROUP BY authorKind`, over every installed forge at once. The honest limit, which any
view over this must repeat: a person who pastes an agent's text with no trailer and no marker
is `human` here. The field reports what the record declares, never a guess about its prose.

`authorRole` is the other axis — owner, member, collaborator, contributor, first-timer,
outsider — the inside of a project against the outside.

## What a child agrees to

Inheriting the property names is the easy half. The contract is that they MEAN the same thing.
It is stated in full at the top of `types/vocabulary.yml`; in short:

| | |
|---|---|
| `repositoryKey` | `<host>/<owner>/<name>`, lower case. The join key between issues, changes, commits, builds, and the source the code realms read. Empty for a tracker with no repository. |
| `key` | a record's own key across trackers: `<repositoryKey>#<number>` on a forge, the tracker's key (`SHOP-123`) elsewhere. What a Comment or Review names as its subject. Never a numeric id. |
| `projectKey` on a Commit | `https://<host>/<owner>/<name>@<sha>` — the key realm-java-project and its siblings pin a project by, so a commit reaches its own source, parsed at that commit |
| timestamps | ISO-8601 with the time, UTC, the event's time as the source records it |
| enumerations | exactly the listed words, lower case, hyphenated; a source with more states folds them in |
| counts | integers; absent where the source's list endpoint does not carry them, never zero in that case |
| `sourceUrl` | opens this record in its own product |

No parent has an identity. Identity is the child's, because only the product knows what makes
its records unique, and two products' ids must never be compared.

## Relationship names

Part of the vocabulary, though nothing here declares them: a product realm contributes its own
joins, and uses these names so that a traversal reads the same over any product.

| From | Relationship | To |
|---|---|---|
| `Repository` | `HAS_ISSUE` | `Issue` |
| `Repository` | `HAS_CHANGE_REQUEST` | `ChangeRequest` |
| `Repository` | `HAS_COMMIT` | `Commit` |
| `Repository` | `HAS_BUILD` | `Build` |
| `Issue` | `HAS_COMMENT` | `Comment` |
| `ChangeRequest` | `HAS_COMMENT` | `Comment` |
| `ChangeRequest` | `HAS_REVIEW` | `Review` |
| `ChangeRequest` | `HAS_COMMIT` | `Commit` |
| `ChangeRequest` | `CHANGED` | `FileChange` |
| `Commit` | `CHANGED` | `FileChange` |
| `Build` | `BUILT` | `Commit` |

## Closed value domains

Every enumeration in the contract is declared as a closed `values:` list on its property —
`authorKind`, both `status`es, `subjectKind`, `kind`, `verdict`, the file change's `status`, the
build's `status` and `trigger`. The text-to-Cypher generator is then told to use one of them
EXACTLY, and the host refuses a generated query that compares the property with any other
literal, so a question about "merged" change requests cannot be answered with
`status = 'MERGED'` or `'ChangeRequest'` where `'change-request'` was meant. The properties
that are legitimately empty (`resolution`, `kind` on an issue, `authorRole`, a build's
`conclusion` until it completes) are described but not closed, because an empty string is a
real value there.

## Depending on it

A realm cannot yet declare that it needs another realm (embabel/me#495, #1168). Until it can:
install this realm first. A child whose parent is not installed is a type with a parent the
world has never heard of.

## Children

- [realm-github](https://github.com/embabel-worlds/realm-github) — `GitHubIssue` is an `Issue`,
  `GitHubPullRequest` a `ChangeRequest`, `GitHubComment` a `Comment`, `GitHubReview` a `Review`,
  `GitHubCommit` a `Commit` and `GitHubFileChange` a `FileChange`; its `views/vocabulary.yml`
  answers the authorship questions above.
- [realm-github-actions](https://github.com/embabel-worlds/realm-github-actions) — a
  `WorkflowRun` is a `Build`, and the commit a run built is a `Commit`.
