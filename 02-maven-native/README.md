# Part 1 — Native Maven "go-offline" blind spot

This shows that Maven's own offline-prep tooling is not enough for a
hermetic build, because it only sees dependencies declared in the POM
graph. It cannot see artifacts that plugins resolve dynamically, at
execution time, based on what's on the classpath.

## Note: `.mvn/extensions.xml` needs network too

`01-project/.mvn/extensions.xml` registers `maven-lockfile` as a Maven
**core extension**, so every `mvn` invocation below (including
`dependency:go-offline` itself) loads it at bootstrap, before anything
else runs. If it isn't already cached in `~/.m2/repository`, the very
first command needs network access to fetch it — unrelated to the actual
blind spot being demonstrated, but a good pre-flight check if a command
fails immediately with an "Extension ... could not be resolved" error.

## Steps

Run these from `02-maven-native/` (this directory), so the sandbox repo
stays inside it — don't `cd` into `01-project` first, or `-Dmaven.repo.local`
will resolve relative to the wrong directory.

1. Point Maven at a fresh, empty local repo and prefetch everything
   Maven's dependency plugin can see (run with network access):

   ```sh
   mvn -f ../01-project/pom.xml -Dmaven.repo.local=$(pwd)/sandbox dependency:go-offline
   ```

   This resolves and downloads the declared dependency graph — for this
   project, JUnit Jupiter 6.1.3 and its transitive deps (9 jars).

2. Now try to run the tests fully offline, using only that repo:

   ```sh
   mvn -o -f ../01-project/pom.xml -Dmaven.repo.local=$(pwd)/sandbox test
   ```

## Expected result: BUILD FAILURE

```
[INFO] --- surefire:3.5.6:test (default-test) @ dynamic-resolution-capture ---
[INFO] Using auto detected provider org.apache.maven.surefire.junitplatform.JUnitPlatformProvider
[WARNING] The POM for org.apache.maven.surefire:surefire-junit-platform:jar:3.5.6 is missing, no dependency information available
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-surefire-plugin:3.5.6:test (default-test)
on project dynamic-resolution-capture: The following artifacts could not be resolved:
org.apache.maven.surefire:surefire-junit-platform:jar:3.5.6 (absent): Cannot access central
(https://repo.maven.apache.org/maven2) in offline mode and the artifact
org.apache.maven.surefire:surefire-junit-platform:jar:3.5.6 has not been downloaded from it before.
```

## Why

`maven-surefire-plugin` inspects the test classpath at execution time to
pick a test provider. Because this project uses JUnit Platform
(`junit-platform-commons` on the classpath), surefire dynamically resolves
`org.apache.maven.surefire:surefire-junit-platform` — an artifact with
**no edge in the POM's dependency graph**. `dependency:go-offline` (and
`dependency:tree`, `dependency:resolve-plugins`) only walk declared POM
edges, so they never see it. The build is only "offline-ready" until you
actually run the phase that needs it.

See: https://chains.proj.kth.se/maven-hermetic-builds-blind-spot.html
