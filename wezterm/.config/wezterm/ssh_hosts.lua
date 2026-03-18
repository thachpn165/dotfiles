-- Host classification for ops ergonomics (tab/title colors via SERVER_TYPE).
-- Matching is substring-based (case-sensitive).
--
-- Example:
--   production = { "prod-", "azproxyroot" }
--   staging    = { "staging-", "stg-" }
--
-- Anything not matching falls back to "default".
return {
  production = {
    "azproxyroot",
  },
  staging = {
  },
}

