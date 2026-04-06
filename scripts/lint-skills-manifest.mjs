#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(scriptDir, "..");

const errors = [];

function readFile(relPath) {
  return fs.readFileSync(path.join(repoRoot, relPath), "utf8");
}

function section(text, startMarker, endMarkers) {
  const start = text.indexOf(startMarker);
  if (start === -1) {
    errors.push(`Missing section start: "${startMarker}"`);
    return "";
  }

  let end = text.length;
  for (const marker of endMarkers) {
    const idx = text.indexOf(marker, start + startMarker.length);
    if (idx !== -1 && idx < end) {
      end = idx;
    }
  }
  return text.slice(start, end);
}

function extractByRegex(text, regex) {
  const out = [];
  for (const match of text.matchAll(regex)) {
    out.push(match[1]);
  }
  return out;
}

function compareList(label, actual, expected) {
  const actualJson = JSON.stringify(actual);
  const expectedJson = JSON.stringify(expected);
  if (actualJson !== expectedJson) {
    errors.push(
      `${label} mismatch.\n  expected: ${expectedJson}\n  actual:   ${actualJson}`
    );
  }
}

function assertIncludedSkillPaths(includedSkills) {
  for (const skill of includedSkills) {
    const skillPath = path.join(repoRoot, skill, "SKILL.md");
    if (!fs.existsSync(skillPath)) {
      errors.push(`Included skill missing SKILL.md: ${skill}/SKILL.md`);
    }
  }
}

const manifest = JSON.parse(readFile("skills-manifest.json"));
const readme = readFile("README.md");
const repoModes = readFile("REPO_MODES.md");
const workflowCompass = readFile("route-workflow/SKILL.md");
const externalAddons = readFile("EXTERNAL_ADDONS.md");

const readmeIncluded = section(readme, "## Included Skills", ["## External Add-Ons"]);
const readmeCore = extractByRegex(readmeIncluded, /^-\s+`([^`]+)`/gm);

const externalCoreSection = section(
  externalAddons,
  "## Core Pack (always available)",
  ["## Add-On: coreyhaines marketing ecosystem (optional)"]
);
const externalCore = extractByRegex(externalCoreSection, /^-\s+`([^`]+)`/gm);

const externalCoreySection = section(
  externalAddons,
  "Use these only when installed:",
  ["Recommended integration point:"]
);
const externalCorey = extractByRegex(externalCoreySection, /^-\s+`([^`]+)`/gm);

const workflowCoreSection = section(
  workflowCompass,
  "### Core Pack (always available in svc)",
  ["### External Add-On Packs (optional)"]
);
const workflowCore = extractByRegex(workflowCoreSection, /^-\s+`([^`]+)`/gm);

const workflowCoreySection = section(
  workflowCompass,
  "- **coreyhaines-marketing-pack (optional):**",
  ["- **planning add-on (optional):**"]
);
const workflowCorey = extractByRegex(workflowCoreySection, /`([^`]+)`/g);

const bootstrapSequenceSection = section(repoModes, "Default greenfield sequence:", ["### Convert Mode"]);
const bootstrapSequence = extractByRegex(
  bootstrapSequenceSection,
  /^\s*\d+\.\s+`([^`]+)`/gm
);

compareList("README included skills", readmeCore, manifest.includedSkills);
compareList("EXTERNAL_ADDONS core pack", externalCore, manifest.includedSkills);
compareList(
  "route-workflow core pack for routing",
  workflowCore,
  manifest.corePackForRouting
);
compareList(
  "EXTERNAL_ADDONS coreyhaines pack",
  externalCorey,
  manifest.externalAddOns["coreyhaines-marketing-pack"]
);
compareList(
  "route-workflow coreyhaines pack",
  workflowCorey,
  manifest.externalAddOns["coreyhaines-marketing-pack"]
);
compareList(
  "REPO_MODES bootstrap sequence",
  bootstrapSequence,
  manifest.bootstrapStartSequence
);

assertIncludedSkillPaths(manifest.includedSkills);
if (errors.length > 0) {
  console.error("skills-manifest lint failed:");
  for (const err of errors) {
    console.error(`- ${err}`);
  }
  process.exit(1);
}

console.log("skills-manifest lint passed");
console.log(`- included skills: ${manifest.includedSkills.length}`);
console.log(`- routing core skills: ${manifest.corePackForRouting.length}`);
console.log(
  `- coreyhaines add-on skills: ${manifest.externalAddOns["coreyhaines-marketing-pack"].length}`
);
