# Part 2 — hermeto: actually hermetic

hermeto is lockfile-driven: it never resolves dependencies itself, it only
reads what `maven-lockfile` already captured — including the artifacts
`maven-surefire-plugin` resolved dynamically at test-run time — and
prefetches + checksum-verifies every one of them up front.

## Prerequisite

`../01-project/lockfile.json` was generated (from `01-project/`) with:

```sh
mvn test io.github.chains-project:maven-lockfile:5.18.3:generate \
  -Dhermetic -DchecksumMode=local
```

- `-Dhermetic` captures the full set needed for a hermetic build:
  declared dependencies, plugin dependencies, build extensions
  (`.mvn/extensions.xml`), and BOMs — not just the declared POM graph.
- `-DchecksumMode=local` computes checksums locally instead of trusting
  Maven Central's checksum endpoint, which doesn't publish a SHA-256 for
  every artifact (notably: dynamically-pulled ones like
  `surefire-junit-platform` itself). Without this, hermeto's checksum
  verification correctly refuses to accept an artifact with no checksum
  to verify against, and the whole fetch aborts.

Note: `.mvn/extensions.xml` registers `maven-lockfile` as a core
extension, so this command (like any `mvn` command in `01-project/`)
needs network access to fetch it first if it isn't already cached in
`~/.m2/repository`.

## Run the prefetch

Run this from `03-hermeto/` (this directory), so output stays isolated
here:

```sh
hermeto fetch-deps \
  --source ../01-project \
  --output ./output \
  '{"type": "x-maven", "path": "."}'
```

This downloads every artifact from `lockfile.json` — including
`org.apache.maven.surefire:surefire-junit-platform` — into
`./output/deps/maven`, verifies each against its lockfile checksum, and
prepares `./output/settings.xml` pointing Maven's local repo at that
directory with `<offline>true</offline>`.

## Materialize the settings file and run fully offline

```sh
hermeto inject-files --output ./output   # writes settings.xml
mvn -o -s ./output/settings.xml -f ../01-project/pom.xml test
```

## Expected result: BUILD SUCCESS, test runs, zero network access

This is the payoff: the same dynamically-resolved artifact that broke
Part 1 is already sitting in the local repo, checksum-verified, before
Maven ever asks for it.

## Known flakiness (not a hermeto bug)

Maven Central's own CDN (`repo.maven.apache.org` / `repo1.maven.org`) has
been intermittently returning genuine, non-cached 404s for real,
published artifacts from this network — confirmed via `search.maven.org`
and an independent Google-hosted mirror serving the same coordinates
fine. If the fetch fails with `FetchError: Could not download ...`, it's
very likely this — just retry.
