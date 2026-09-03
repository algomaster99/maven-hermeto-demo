# Maven Hermetic Builds Demo

Live demo for
["Maven-Lockfile: Locking Down the JVM Supply Chain for Hermetic Builds"](https://osselceu2026.sched.com/event/2RadG).
Shows the dynamic-resolution blind spot in native Maven
tooling, then closes it with maven-lockfile + hermeto.

Reference: https://chains.proj.kth.se/maven-hermetic-builds-blind-spot.html

## Folders

1. **`01-project/`** — the demo Maven project (`dynamic-resolution-capture`).
   Declares a single test dependency (JUnit Jupiter). Registers
   `maven-lockfile` as a `.mvn/extensions.xml` core extension. Includes the
   already-generated `lockfile.json`.

2. **`02-maven-native/`** — shows that `mvn dependency:go-offline` is not
   enough: it prefetches the declared graph, but `mvn -o test` still fails
   because surefire dynamically resolves `surefire-junit-platform` at
   test-run time, outside the POM graph.

3. **`03-hermeto/`** — shows hermeto prefetching everything
   `maven-lockfile` captured (including the dynamic artifact), checksum
   verified, and `mvn -o test` succeeding fully offline.

## Run order for the talk

```sh
cd 02-maven-native && <run README steps, show BUILD FAILURE>
cd ../03-hermeto    && <run README steps, show BUILD SUCCESS>
```
