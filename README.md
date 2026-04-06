# MMCP — Mambu MCP Server

A [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) server that enables AI agents to discover and execute REST API operations described by OpenAPI specifications. Includes a complete catalog for the [Mambu Banking Platform](https://mambu.com/) V2 API.

## Overview

MMCP acts as a bridge between AI systems and any REST API documented with OpenAPI. It provides:

*   **Intelligent Search**: Natural language search powered by semantic embeddings and NLP
*   **Any OpenAPI API**: Works with any REST API that has OpenAPI/Swagger specs
*   **Minimal Tool Surface**: Just two MCP tools (`search` and `invoke`) for AI agents to learn
*   **Per-API Configuration**: Authentication headers, base URLs, and access control per API
*   **High Performance**: Pre-built search index with hybrid keyword + semantic search

### MCP Tools

| Tool | Description |
|---|---|
| `search` | Takes a natural language query (e.g. "list all clients") and returns matching API operations with their full parameter schemas, request body schemas, and usage guidance. |
| `invoke` | Executes an API operation discovered via `search`. Takes the exact `label` from search results, path/query/header `params`, and an optional request `body`. Returns the HTTP response. |


## Installation

Connect to the tap and install MMCP:

```bash
brew tap mambu-gmbh/mmcp-brew https://github.com/mambu-gmbh/mmcp-brew
brew install mmcp
mmcp setup --catalog $(brew --prefix)/share/mmcp/reference-apis/mambu/catalog.yaml
```

This installs:
*   The `mmcp` native binary
*   The [nomic-embed-text-v1.5](https://huggingface.co/nomic-ai/nomic-embed-text-v1.5) ONNX embedding model (~550 MB)
*   The Mambu Banking Platform reference API catalog and OpenAPI specs

The install may take a few minutes due to the model download (~550 MB). The `mmcp setup` command copies files to your user directory and builds the search index — it only needs to be run once (or again when the catalog changes).

To update to the latest version:

```bash
brew update
brew upgrade mmcp
```


## Quick Start

After installation, configure your MCP client with your Mambu credentials. The `MAMBU_AUTH_API_KEY` and `MAMBU_BASE_URL` variables are resolved at runtime when API requests are made — they must be set in your MCP client configuration (not just in your shell).

By default, only read operations (list, get, search, download, find) are enabled. To allow write operations, add `ACCESS_INCLUDE` with the labels you need (see [Access Control](#access-control)).

### Configure your MCP client

#### Claude Desktop

Edit your Claude Desktop configuration file:

*   **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
*   **Linux**: `~/.config/Claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "mambu": {
      "command": "mmcp",
      "env": {
        "MAMBU_BASE_URL": "https://your-tenant.mambu.com/api",
        "MAMBU_AUTH_API_KEY": "your-api-key",
        "ACCESS_INCLUDE": "clients/create,clients/update"
      }
    }
  }
}
```

#### Claude Code

Add to your `.mcp.json`:

```json
{
  "mcpServers": {
    "mambu": {
      "command": "mmcp",
      "env": {
        "MAMBU_BASE_URL": "https://your-tenant.mambu.com/api",
        "MAMBU_AUTH_API_KEY": "your-api-key",
        "ACCESS_INCLUDE": "clients/create,clients/update"
      }
    }
  }
}
```

#### Junie CLI

Edit your Junie MCP configuration file:

```json
{
  "mcpServers": {
    "mambu": {
      "type": "com.intellij.ml.llm.matterhorn.core.mcp.McpServerConfiguration.McpServerCommand",
      "name": "mambu",
      "command": "mmcp",
      "env": {
        "MAMBU_BASE_URL": "https://your-tenant.mambu.com/api",
        "MAMBU_AUTH_API_KEY": "your-api-key",
        "ACCESS_INCLUDE": "clients/create,clients/update"
      },
      "sourcePath": "~/.junie/mcp/mcp.json",
      "enabled": "true"
    }
  }
}
```

#### Cline (VS Code Extension)

In VS Code, open Cline settings and add to your MCP servers configuration:

```json
{
  "mambu": {
    "command": "mmcp",
    "env": {
      "MAMBU_BASE_URL": "https://your-tenant.mambu.com/api",
      "MAMBU_AUTH_API_KEY": "your-api-key",
      "ACCESS_INCLUDE": "clients/create,clients/update"
    }
  }
}
```

#### Other MCP Clients

For other MCP-compatible tools (Cursor, Windsurf, etc.), use the same pattern — point them at the `mmcp` binary with your Mambu credentials and optional access control as environment variables.

> **Note**: The `ACCESS_INCLUDE` variable is optional. Without it, only read operations are available. See [Access Control](#access-control) for the full set of environment variables.


## How It Works

When an AI agent needs to call an API, it follows a two-step workflow:

1.  **Search**: The agent calls the `search` tool with a natural language query like "list all clients" or "create a deposit account". MMCP returns matching operations ranked by relevance, including full parameter schemas and usage guidance.

2.  **Invoke**: The agent calls the `invoke` tool with the exact `label` from the search results, along with the required parameters and request body. MMCP executes the HTTP request and returns the response.

The search engine uses a hybrid approach combining keyword matching (BM25) and semantic similarity (ONNX embeddings) for accurate results even with varied phrasing.


## Access Control

Operations are gated by a top-level `access` block in `catalog.yaml` using glob patterns. The bundled Mambu catalog ships with a **deny-by-default** policy that allows only read operations:

```yaml
access:
  default: deny
  include:
    - "*/list"
    - "*/get"
    - "*/get_*"
    - "*/search_*"
    - "*/download_*"
    - "*/find_*"
  exclude:
    - "archive_*/*"
    - "database_backup/*"
```

### Evaluation rules

Patterns are evaluated in this order (exclude always wins):

1.  If the label matches any **exclude** pattern &rarr; **denied**
2.  If the label matches any **include** pattern &rarr; **allowed**
3.  Otherwise &rarr; the **default** policy applies (`allow` or `deny`)

### Glob syntax

Patterns use `*` as a wildcard within a single path segment. Labels follow the format `apiId/operation`:

| Pattern | Matches |
|---|---|
| `*/list` | `clients/list`, `branches/list`, etc. |
| `clients/*` | All operations under the clients API |
| `clients/create` | Exactly `clients/create` |
| `*/get_*` | `clients/get_by_id`, `loans/get_schedule`, etc. |

### Environment variable overrides

Three environment variables merge with the YAML config, allowing runtime customization without editing `catalog.yaml`:

| Variable | Description | Example |
|---|---|---|
| `ACCESS_DEFAULT` | Override the default policy | `allow` or `deny` |
| `ACCESS_INCLUDE` | Comma-separated include globs (added to YAML includes) | `clients/create,loans/create` |
| `ACCESS_EXCLUDE` | Comma-separated exclude globs (added to YAML excludes) | `*/delete,api_key_rotation/*` |

Environment variable patterns are **merged** with YAML patterns, not replaced.

### Common examples

**Allow a few specific write operations** (add to your MCP client `env`):

```
ACCESS_INCLUDE=clients/create,clients/update,loans/create
```

**Allow all operations** (override the default policy):

```
ACCESS_DEFAULT=allow
```

**Block a specific API entirely**:

```
ACCESS_EXCLUDE=api_key_rotation/*,database_backup/*
```

## Catalog Configuration

Each API entry in `catalog.yaml` defines its spec location, authentication headers, and operations:

```yaml
baseUrl: "${MAMBU_BASE_URL}"
apis:
  - id: "clients"
    specLocation: "json/clients_v2_swagger.json"
    headers:
      apiKey: "${MAMBU_AUTH_API_KEY}"
      Accept: "application/vnd.mambu.v2+json"
    operations:
      - label: "clients/list"
        description: "Get clients"
        operationId: "getAll"
      - label: "clients/create"
        description: "Create client"
        operationId: "create"
```

Key fields:

*   **`headers`**: HTTP headers added to every request — use for authentication. Supports `${ENV_VAR}` placeholders.
*   **`baseUrl`** (optional per API): Overrides the server URL from the OpenAPI spec.
*   **`access`**: Controls which operations are exposed to AI agents (see [Access Control](#access-control) above).

To update your catalog after changes:

```bash
mmcp setup --catalog /path/to/updated/catalog.yaml
```

This rebuilds the search index. Restart the server afterwards.


## File Locations

After running `mmcp setup`, configuration and data files are stored in platform-default directories:

### macOS

```
~/Library/Application Support/mmcp/
├── catalog.yaml
├── specs/
├── index/
└── models/
    ├── model.onnx
    └── tokenizer.json
```

### Linux

```
~/.config/mmcp/
├── catalog.yaml
└── specs/

~/.local/share/mmcp/
├── index/
└── models/
    ├── model.onnx
    └── tokenizer.json
```


## Running as a Server

By default, MMCP communicates over stdio. To start an SSE and streamable HTTP server:

```bash
mmcp -Dquarkus.http.host-enabled=true
```

The server listens on port 8080.


## Troubleshooting

### Setup Fails

*   Verify the catalog path exists: `ls $(brew --prefix)/share/mmcp/reference-apis/mambu/catalog.yaml`
*   Check that the embedding model was installed: `ls $(brew --prefix)/share/mmcp/models/model.onnx`
*   Re-run setup: `mmcp setup --catalog /path/to/catalog.yaml`

### Server Won't Start

*   Verify `mmcp` is in your PATH: `which mmcp`
*   Check that setup has been run (index directory should exist)
*   Review error messages — they include specific guidance

### Authentication Errors

*   Verify `MAMBU_BASE_URL` includes `/api` at the end
*   Check that `MAMBU_AUTH_API_KEY` is set in your MCP client configuration
*   Ensure your API key has the required permissions

### Connection Issues

*   Verify network connectivity to your Mambu instance
*   Check if your Mambu instance requires VPN or IP whitelisting


## Uninstallation

To remove MMCP:

```bash
brew uninstall mmcp
brew untap mambu-gmbh/mmcp-brew
```

To also remove configuration and data files:

```bash
# macOS
rm -rf ~/Library/Application\ Support/mmcp/

# Linux
rm -rf ~/.config/mmcp/ ~/.local/share/mmcp/
```


## License

Apache 2.0. Maintained by Mambu Tech B.V.
