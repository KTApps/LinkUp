# LinkUp

iOS app — processes and setup documentation.

---

## Purpose

This repo includes **repeatable processes and setup guides** for development tasks and tooling.

---

## Setup Guides

### [Firebase CLI & MCP](.cursor/docs/firebase-setup.md)
Guide for setting up Firebase CLI and MCP integration with Cursor.

- Installing Firebase CLI and authenticating
- Configuring MCP in Cursor
- Enabling AI agents to interact with Firebase

**Slash command:** `/setup-firebase`

### [XcodeBuildMCP](.cursor/docs/xcodebuild-mcp-setup.md)
Guide for setting up XcodeBuildMCP (Xcode, simulators, iOS builds via AI in Cursor).

- Node.js and Xcode developer path
- XcodeBuildMCP in Cursor
- Building, running, testing iOS apps and UI automation

**Slash command:** `/setup-xcodebuild-mcp`

---

## How to Use

- **Read the docs:** Open the guides in `.cursor/docs/` and follow the steps.
- **Slash commands:** In Cursor chat, use `/setup-firebase` or `/setup-xcodebuild-mcp` for interactive setup.

---

## Adding New Processes

1. Add documentation (e.g. in `.cursor/docs/`).
2. Add a slash command in `.cursor/commands/` if you want interactive setup.
3. Update this README with a link to the new guide.

---

**Last Updated:** February 2026
