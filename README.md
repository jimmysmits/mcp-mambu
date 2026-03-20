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
```

This installs:
*   The `mmcp` native binary
*   The [nomic-embed-text-v1.5](https://huggingface.co/nomic-ai/nomic-embed-text-v1.5) ONNX embedding model (~550 MB)
*   The Mambu Banking Platform reference API catalog and OpenAPI specs

The install may take a few minutes due to the model download (~550 MB).

After installing, run setup to copy files to your user directory and build the search index:

```bash
mmcp setup --catalog $(brew --prefix)/share/mmcp/reference-apis/mambu/catalog.yaml
```

This only needs to be run once (or again when the catalog changes).

To update to the latest version:

```bash
brew update
brew upgrade mmcp
```


## Quick Start

After installation, configure your MCP client with your Mambu credentials.

The `MAMBU_API_KEY` and `MAMBU_BASE_URL` variables are resolved at runtime when API requests are made — they must be set in your MCP client configuration (not just in your shell).

### Configure your MCP client

Configure your AI client to launch `mmcp` with your Mambu credentials as environment variables. The `MAMBU_API_KEY` and `MAMBU_BASE_URL` variables are resolved at runtime when API requests are made — they must be set in your MCP client configuration (not just in your shell).

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
        "MAMBU_API_KEY": "your-api-key"
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
        "MAMBU_API_KEY": "your-api-key"
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
        "MAMBU_API_KEY": "your-api-key"
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
      "MAMBU_API_KEY": "your-api-key"
    }
  }
}
```

#### Other MCP Clients

For other MCP-compatible tools (Cursor, Windsurf, etc.), use the same pattern — point them at the `mmcp` binary with your Mambu credentials as environment variables.


## Security Considerations

### Credential Storage

Your Mambu credentials are stored in your MCP client's configuration file. Protect this file:

```bash
# macOS (Claude Desktop)
chmod 600 ~/Library/Application\ Support/Claude/claude_desktop_config.json
```

### Alternative: Environment Variables via Wrapper Script

For better security, you can use a wrapper script that loads credentials from a secure location:

```bash
#!/bin/bash
source ~/.mambu_credentials  # Contains MAMBU_API_KEY and MAMBU_BASE_URL
exec mmcp "$@"
```

Then point your MCP client at the wrapper script instead of `mmcp` directly.


## How It Works

When an AI agent needs to call an API, it follows a two-step workflow:

1.  **Search**: The agent calls the `search` tool with a natural language query like "list all clients" or "create a deposit account". MMCP returns matching operations ranked by relevance, including full parameter schemas and usage guidance.

2.  **Invoke**: The agent calls the `invoke` tool with the exact `label` from the search results, along with the required parameters and request body. MMCP executes the HTTP request and returns the response.

The search engine uses a hybrid approach combining keyword matching (BM25) and semantic similarity (ONNX embeddings) for accurate results even with varied phrasing.


## Catalog Configuration

Operations are controlled via `catalog.yaml`, not individual environment variables. Each API entry defines which operations are enabled:

```yaml
baseUrl: "${MAMBU_BASE_URL}"
apis:
  - id: "clients"
    specLocation: "json/clients_v2_swagger.json"
    headers:
      apiKey: "${MAMBU_API_KEY}"
      Accept: "application/vnd.mambu.v2+json"
    operations:
      - label: "clients/list"
        description: "Get clients"
        operationId: "getAll"
        enabled: true
      - label: "clients/create"
        description: "Create client"
        operationId: "create"
        enabled: ${CLIENTS_CREATE:false}
```

Key fields:

*   **`enabled`**: Controls which operations are exposed to AI agents. Supports `${ENV_VAR:default}` placeholders for runtime control.
*   **`headers`**: HTTP headers added to every request — use for authentication. Supports `${ENV_VAR}` placeholders.
*   **`baseUrl`** (optional): Overrides the server URL from the OpenAPI spec.

By default, read-only operations (GET) are enabled and mutating operations (POST, PUT, DELETE) are disabled. To enable a mutating operation, set the corresponding environment variable:

```bash
export CLIENTS_CREATE=true
```

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
*   Check that `MAMBU_API_KEY` is set in your MCP client configuration
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
