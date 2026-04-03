#!/usr/bin/env node

"use strict";

const fs = require("fs");
const os = require("os");
const path = require("path");
const { execFileSync } = require("child_process");

const cwdArg = process.argv[2] || "";
const cacheFile = path.join(os.tmpdir(), "wezterm-ai-usage-cache.json");
const cacheTtlMs = 60 * 1000;

function safeRead(filePath, encoding = "utf8") {
  try {
    return fs.readFileSync(filePath, encoding);
  } catch {
    return null;
  }
}

function safeReadJson(filePath) {
  const content = safeRead(filePath);
  if (!content) {
    return null;
  }

  try {
    return JSON.parse(content);
  } catch {
    return null;
  }
}

function safeStat(filePath) {
  try {
    return fs.statSync(filePath);
  } catch {
    return null;
  }
}

function fileExists(filePath) {
  try {
    fs.accessSync(filePath, fs.constants.R_OK);
    return true;
  } catch {
    return false;
  }
}

function readCache() {
  const cache = safeReadJson(cacheFile);
  if (!cache || cache.cwd !== cwdArg) {
    return null;
  }

  if (Date.now() - cache.timestamp > cacheTtlMs) {
    return null;
  }

  return cache.data || null;
}

function writeCache(data) {
  try {
    fs.writeFileSync(
      cacheFile,
      JSON.stringify({
        timestamp: Date.now(),
        cwd: cwdArg,
        data,
      })
    );
  } catch {}
}

function walkFiles(rootDir, matcher) {
  const matches = [];
  const stack = [rootDir];

  while (stack.length > 0) {
    const current = stack.pop();
    let entries;
    try {
      entries = fs.readdirSync(current, { withFileTypes: true });
    } catch {
      continue;
    }

    for (const entry of entries) {
      const fullPath = path.join(current, entry.name);
      if (entry.isDirectory()) {
        stack.push(fullPath);
        continue;
      }

      if (matcher(fullPath, entry)) {
        matches.push(fullPath);
      }
    }
  }

  return matches;
}

function findLatestFile(rootDir, matcher) {
  const files = walkFiles(rootDir, matcher);
  let latestPath = null;
  let latestMtime = 0;

  for (const filePath of files) {
    const stat = safeStat(filePath);
    if (!stat) {
      continue;
    }

    if (stat.mtimeMs >= latestMtime) {
      latestMtime = stat.mtimeMs;
      latestPath = filePath;
    }
  }

  return latestPath;
}

function readTail(filePath, maxBytes = 1024 * 1024) {
  const stat = safeStat(filePath);
  if (!stat) {
    return "";
  }

  const size = stat.size;
  const start = Math.max(0, size - maxBytes);
  const length = size - start;
  const buffer = Buffer.alloc(length);
  const fd = fs.openSync(filePath, "r");

  try {
    fs.readSync(fd, buffer, 0, length, start);
  } finally {
    fs.closeSync(fd);
  }

  return buffer.toString("utf8");
}

function findLastMatchingLine(filePath, matcher) {
  const tail = readTail(filePath);
  if (!tail) {
    return null;
  }

  const lines = tail.trim().split("\n");
  for (let index = lines.length - 1; index >= 0; index -= 1) {
    if (matcher(lines[index])) {
      return lines[index];
    }
  }

  return null;
}

function getCodexUsage() {
  const sessionsDir = path.join(os.homedir(), ".codex", "sessions");
  const latestSession = findLatestFile(sessionsDir, (filePath) => filePath.endsWith(".jsonl"));
  if (!latestSession) {
    return null;
  }

  const line = findLastMatchingLine(
    latestSession,
    (candidate) => candidate.includes('"type":"event_msg"') && candidate.includes('"type":"token_count"')
  );
  if (!line) {
    return null;
  }

  try {
    const event = JSON.parse(line);
    const rateLimits = event.payload && event.payload.rate_limits ? event.payload.rate_limits : {};
    const primary = rateLimits.primary && Number.isFinite(rateLimits.primary.used_percent)
      ? Math.round(rateLimits.primary.used_percent)
      : null;
    const secondary = rateLimits.secondary && Number.isFinite(rateLimits.secondary.used_percent)
      ? Math.round(rateLimits.secondary.used_percent)
      : null;

    let value = null;
    if (primary !== null && secondary !== null) {
      value = `${primary}%/${secondary}%`;
    } else if (primary !== null) {
      value = `${primary}%`;
    } else if (secondary !== null) {
      value = `${secondary}%`;
    }

    if (!value) {
      return null;
    }

    return {
      available: true,
      label: "Codex",
      mode: "rate_limits",
      value,
    };
  } catch {
    return null;
  }
}

function getClaudeToken() {
  if (os.platform() === "darwin") {
    try {
      const raw = execFileSync(
        "security",
        ["find-generic-password", "-s", "Claude Code-credentials", "-w"],
        {
          encoding: "utf8",
          timeout: 5000,
          stdio: ["ignore", "pipe", "ignore"],
        }
      ).trim();
      const parsed = JSON.parse(raw);
      if (parsed.claudeAiOauth && parsed.claudeAiOauth.accessToken) {
        return parsed.claudeAiOauth.accessToken;
      }
    } catch {}
  }

  const credentials = safeReadJson(path.join(os.homedir(), ".claude", ".credentials.json"));
  return credentials && credentials.claudeAiOauth ? credentials.claudeAiOauth.accessToken || null : null;
}

async function fetchClaudeUsage() {
  const token = getClaudeToken();
  if (!token) {
    return null;
  }

  try {
    const response = await fetch("https://api.anthropic.com/api/oauth/usage", {
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`,
        "anthropic-beta": "oauth-2025-04-20",
        "User-Agent": "wezterm-status/1.0",
      },
      signal: AbortSignal.timeout(4000),
    });

    if (!response.ok) {
      return null;
    }

    const data = await response.json();
    const fiveHour = data.five_hour && Number.isFinite(data.five_hour.utilization)
      ? Math.round(data.five_hour.utilization)
      : null;
    const sevenDay = data.seven_day && Number.isFinite(data.seven_day.utilization)
      ? Math.round(data.seven_day.utilization)
      : null;

    let value = null;
    if (fiveHour !== null && sevenDay !== null) {
      value = `${fiveHour}%/${sevenDay}%`;
    } else if (fiveHour !== null) {
      value = `${fiveHour}%`;
    } else if (sevenDay !== null) {
      value = `${sevenDay}%`;
    }

    if (!value) {
      return null;
    }

    return {
      available: true,
      label: "Claude",
      mode: "oauth_usage",
      value,
    };
  } catch {
    return null;
  }
}

function getClaudeDebugUsage() {
  const debugDir = path.join(os.homedir(), ".claude", "debug");
  let latestDebug = path.join(debugDir, "latest");
  if (!fileExists(latestDebug)) {
    latestDebug = findLatestFile(debugDir, (filePath) => filePath.endsWith(".txt"));
  }
  if (!latestDebug) {
    return null;
  }

  const line = findLastMatchingLine(latestDebug, (candidate) => candidate.includes("autocompact: tokens="));
  if (!line) {
    return null;
  }

  const match = line.match(/tokens=(\d+)\s+threshold=(\d+)/);
  if (!match) {
    return null;
  }

  const tokens = Number(match[1]);
  const threshold = Number(match[2]);
  if (!Number.isFinite(tokens) || !Number.isFinite(threshold) || threshold <= 0) {
    return null;
  }

  return {
    available: true,
    label: "Claude",
    mode: "context",
    value: `${Math.round((tokens / threshold) * 100)}%`,
  };
}

async function main() {
  const cached = readCache();
  if (cached) {
    process.stdout.write(JSON.stringify(cached));
    return;
  }

  const data = {
    codex: getCodexUsage(),
    claude: (await fetchClaudeUsage()) || getClaudeDebugUsage(),
  };

  writeCache(data);
  process.stdout.write(JSON.stringify(data));
}

main().catch(() => {
  const fallback = readCache() || {};
  process.stdout.write(JSON.stringify(fallback));
});
