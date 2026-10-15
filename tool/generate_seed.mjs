// Regenerates assets/seed.json — the offline snapshot bundled with the APK.
//
// Run after the stack is up and seeded:
//   node tool/generate_seed.mjs [baseUrl]
//
// The APK ships this file so a first launch with no network still shows real
// content instead of an empty screen. It is a cache seed, not a source of
// truth: the app refreshes from /api/v1 as soon as it can reach the API.

import fs from "node:fs";
import path from "node:path";

const base = (process.argv[2] ?? "http://localhost:8023").replace(/\/+$/, "");

async function get(pathname) {
  const response = await fetch(`${base}${pathname}`, {
    headers: { Accept: "application/json" },
  });
  if (!response.ok) {
    throw new Error(`${pathname} -> HTTP ${response.status}`);
  }
  return response.json();
}

const [meta, profile, experiences, projects, skills] = await Promise.all([
  get("/api/v1/meta"),
  get("/api/v1/profile"),
  get("/api/v1/experiences"),
  get("/api/v1/projects"),
  get("/api/v1/skills"),
]);

const snapshot = {
  profile: profile.profile,
  experiences: experiences.fullTime ?? [],
  partTimeExperiences: experiences.partTime ?? [],
  projects: projects.projects ?? [],
  skillGroups: skills.groups ?? [],
  contentHash: meta.contentHash ?? "",
  fetchedAt: new Date().toISOString(),
};

const outPath = path.resolve("assets/seed.json");
fs.mkdirSync(path.dirname(outPath), { recursive: true });
fs.writeFileSync(outPath, JSON.stringify(snapshot, null, 1) + "\n", "utf8");

const size = fs.statSync(outPath).size;
console.log(`wrote ${outPath}`);
console.log(`  ${size} bytes`);
console.log(`  contentHash ${snapshot.contentHash.slice(0, 16)}...`);
console.log(
  `  profile 1 · experiences ${snapshot.experiences.length} + ${snapshot.partTimeExperiences.length} part-time · ` +
    `projects ${snapshot.projects.length} · skill groups ${snapshot.skillGroups.length}`,
);
