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

### Configure your MCP client (stdio)

In stdio mode, your MCP client launches `mmcp` as a subprocess and communicates over stdin/stdout. This is the default and requires no network configuration.

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

### Access control by deployment mode

The `access` block in `catalog.yaml` is always read at startup. Environment variables merge on top, allowing runtime customization without editing the catalog.

**Stdio mode** — set env vars in your MCP client's JSON configuration:

```json
{
  "mcpServers": {
    "mambu": {
      "command": "mmcp",
      "env": {
        "MAMBU_BASE_URL": "https://your-tenant.mambu.com/api",
        "MAMBU_AUTH_API_KEY": "your-api-key",
        "ACCESS_INCLUDE": "clients/create,loans/create"
      }
    }
  }
}
```

**HTTP server mode** — set env vars in the shell or pass as `-D` flags:

```bash
export MAMBU_BASE_URL="https://your-tenant.mambu.com/api"
export MAMBU_AUTH_API_KEY="your-api-key"
export ACCESS_INCLUDE="clients/create,loans/create"
mmcp -Dquarkus.http.host-enabled=true
```

### Security recommendations

*   **Use `default: deny` in production.** The bundled Mambu catalog ships with this default — only read operations (list, get, search, download, find) are allowed out of the box.
*   **Exclude dangerous operations.** The bundled catalog excludes `archive_*/*`, `database_backup/*`, and specific high-risk operations. Consider also excluding delete operations (`*/delete`), key rotation (`api_key_rotation/*`), and system configuration APIs (`configuration_*/*`) unless specifically needed.
*   **Prefer include patterns over `default: allow`.** Even if you need broad access, an include list with targeted excludes is safer than allowing everything.

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
*   **`access`**: Controls which operations are exposed to MCP clients (see [Access Control](#access-control) above).

To update your catalog after changes:

```bash
mmcp setup --catalog /path/to/updated/catalog.yaml
```

This rebuilds the search index. Restart the server afterwards.

For the complete list of available operations, see [Mambu API Reference](#mambu-api-reference).


## Mambu API Reference

The bundled catalog includes the complete Mambu Banking Platform V2 API — 84 API groups with over 375 operations. The default access policy is deny-by-default with read-only operations included (see [Access Control](#access-control)).

| Label | Description |
|---|---|
| `accounting_interest_accrual/search` | Allows search of interest accrual breakdown entries by various criteria |
| `accounting_reports/create` | Create  accounting report |
| `accounting_reports/get` | Get accounting reports |
| `api_key_rotation/rotate_key` | Rotate API key |
| `application_status/get` | Allows you to retrieve the state of application data access |
| `archive_deposits_transactions_custom_fields/get_by_id` | Get archived deposit transaction |
| `archive_deposits_transactions_custom_fields/search` | Search Archived Deposit Transactions |
| `background_process/get_latest_by_type` | Get the latest manual or automatic end of day (EOD) process by specifying the type |
| `background_process/update` | Cancel manual or automatic end of day (EOD) processes using the encoded key |
| `branches/list` | Get branches |
| `branches/create` | Create branch |
| `branches/get_by_id` | Get branch |
| `bulks/get_bulk_status` | Allow retrieval the status of a bulk process via key |
| `cards/create_authorization_hold` | Create an authorization hold corresponding to a given card |
| `cards/reverse_authorization_hold` | Reverse a card authorization hold |
| `cards/get_authorization_hold_by_id` | Get card authorization hold |
| `cards/patch_authorization_hold` | Partially update an authorization hold |
| `cards/decrease_authorization_hold` | Decreases the amount of an authorization hold. If the amount is greater or equal to the authorization hold amount, th... |
| `cards/increase_authorization_hold` | Increase authorization hold amount |
| `cards/create_bulk_authorization_holds` | Create bulk authorization holds corresponding to a given card |
| `cards/get_account_balances` | Get account balances using card tokens |
| `cards/create_card_transaction` | Create a financial transaction corresponding to a given card |
| `cards/get_card_transaction` | Get card transaction |
| `cards/reverse_card_transaction` | Reverse card transaction |
| `centres/list` | Get centres |
| `centres/get_by_id` | Get centre |
| `clients_documents/get_client_document_file_by_id` | Download client document |
| `clients_documents/get_client_document_by_id` | Get client document |
| `clients_documents/create_document` | Create client document |
| `clients_documents/get_documents_by_client_id` | Get all client documents |
| `clients/list` | Get clients |
| `clients/create` | Create client |
| `clients/delete` | Delete client |
| `clients/get_by_id` | Get client |
| `clients/patch` | Partially update client |
| `clients/update` | Update client |
| `clients/get_credit_arrangements_by_client_id_or_key` | Credit arrangements list returned |
| `clients/get_role_by_client_id` | Get client role for client |
| `clients/search` | Search clients |
| `comments/get_comments` | Get comments for an entity |
| `comments/create_comment` | Create a new comment for an entity |
| `communications_messages/send` | Send communication message |
| `communications_messages/get_by_encoded_key` | Get communication message |
| `communications_messages/resend` | Resend failed communication message(s) |
| `communications_messages/enqueue_by_date` | Resend failed communication message(s) asynchronously by date |
| `communications_messages/enqueue_by_keys` | Resend failed communication message(s) asynchronously using keys |
| `communications_messages/search` | Searching communication messages |
| `communications_messages/search_sorted` | Searching sorted communication messages |
| `configuration_accounting_rules_yaml/get` | Retrieve accounting rules configuration |
| `configuration_accounting_rules_yaml/update` | Update the current accounting rules configuration |
| `configuration_authorization_holds_yaml/get` | Get authorization holds configuration |
| `configuration_authorization_holds_yaml/update` | Update authorization holds configuration |
| `configuration_branches_yaml/get` | Get branches configuration |
| `configuration_branches_yaml/update` | Update branch configuration |
| `configuration_centres_yaml/get` | Get centres configuration |
| `configuration_centres_yaml/update` | Update centres configuration |
| `configuration_client_roles_yaml/get` | Get client roles configuration |
| `configuration_client_roles_yaml/update` | Update client roles configuration |
| `configuration_currencies_yaml/get` | Get currencies configuration |
| `configuration_currencies_yaml/update` | Update currencies configuration |
| `configuration_custom_fields/get` | Get custom field definitions configuration |
| `configuration_custom_fields/update` | Update custom field definitions configuration |
| `configuration_custom_fields/get_template` | Get custom field definitions configuration |
| `configuration_deposit_products_yaml/get` | Get configuration for all deposit products |
| `configuration_deposit_products_yaml/update` | Update all deposit products configuration |
| `configuration_end_of_day_processing_yaml/get` | Get end of day processing configuration |
| `configuration_end_of_day_processing_yaml/update` | Update end of day processing configuration |
| `configuration_group_role_names_yaml/get` | Get group role names configuration |
| `configuration_group_role_names_yaml/update` | Update group role names configuration |
| `configuration_holidays_yaml/get` | Get holidays configuration |
| `configuration_holidays_yaml/update` | Update holidays configuration |
| `configuration_id_document_templates_yaml/get` | Get ID templates configuration |
| `configuration_id_document_templates_yaml/update` | Update ID templates configuration |
| `configuration_index_rates_yaml/get` | Get index rates configuration |
| `configuration_index_rates_yaml/update` | Update index rates configuration |
| `configuration_internal_controls_yaml/get` | Get internal controls configuration |
| `configuration_internal_controls_yaml/update` | Update internal controls configuration |
| `configuration_labels_yaml/get` | Get object labels configuration |
| `configuration_labels_yaml/update` | Update object labels configuration |
| `configuration_loan_products_yaml/get` | Allows you to get or update the loan products configuration |
| `configuration_loan_products_yaml/update` | Update loan products configuration |
| `configuration_loan_risk_levels_yaml/get` | Get loan risk levels configuration |
| `configuration_loan_risk_levels_yaml/update` | Update loan risk levels configuration |
| `configuration_organization/get` | Get organization details configuration |
| `configuration_organization/update` | Update organization details configuration |
| `configuration_organization/getTemplate` | Get organization details configuration template |
| `configuration_transaction_channels_yaml/get` | Get transaction channels configuration |
| `configuration_transaction_channels_yaml/update` | Update transaction channels configuration |
| `configuration_user_roles/get` | Get user roles configuration |
| `configuration_user_roles/update` | Update user roles configuration |
| `configuration_user_roles/getTemplate` | Get user roles configuration template |
| `consumers/list` | Get all API consumers |
| `consumers/create` | Create API consumer |
| `consumers/delete` | Delete API consumer |
| `consumers/get_by_id` | Get API consumer |
| `consumers/patch` | Partially update API consumer |
| `consumers/update` | Update API consumer |
| `consumers/create_api_key_for_consumer` | Create API key |
| `consumers/delete_api_key_for_consumer` | Delete API key |
| `consumers/get_keys_by_consumer_id` | Get API keys |
| `consumers/create_secret_key_for_consumer` | Create secret key |
| `credit_arrangements/list` | Get credit arrangements |
| `credit_arrangements/create` | Create credit arrangement |
| `credit_arrangements/delete` | Delete credit arrangement |
| `credit_arrangements/get_by_id` | Get credit arrangement |
| `credit_arrangements/patch` | Partially update credit arrangement |
| `credit_arrangements/update` | Update credit arrangement |
| `credit_arrangements/list_accounts` | Get all loan and deposit accounts linked to credit arrangement |
| `credit_arrangements/get_schedule` | Get credit arrangement schedule |
| `credit_arrangements/add_account` | Add account to credit arrangement |
| `credit_arrangements/change_state` | Change credit arrangement state |
| `credit_arrangements/remove_account` | Remove account from credit arrangement |
| `credit_arrangements/search` | Search credit arrangements |
| `crons_early_eod/run_earlier_hourly_and_end_of_day_crons` | Trigger hourly and end of day Processing earlier, on the current day |
| `crons_eod/run_hourly_and_end_of_day_crons` | Trigger hourly and end of day Processing on the previous day |
| `currencies_accounting_rates/list` | Get accounting rates |
| `currencies_accounting_rates/create` | Create accounting rates |
| `currencies_rates/list` | Get exchange rates for a specific currency |
| `currencies_rates/create` | Post exchange rates for a specific currency |
| `currencies/list` | Get all currencies |
| `currencies/create` | Create currency |
| `currencies/delete` | Delete currency by code |
| `currencies/get` | Get currency by code |
| `currencies/update` | Update currency by code |
| `custom_fields/get_by_id` | Get custom field definition |
| `custom_field_sets/list` | Get custom field sets |
| `custom_field_sets/list_by_set_id` | Get custom field definitions by custom field set |
| `data_import/data_import` | Allows you to import data |
| `data_import/action` | Allows you to approve or reject a data import event |
| `data_import/get_import` | Allows you to retrieve a data import response |
| `database_backup/trigger_backup` | Trigger database backup |
| `database_backup/download_backup` | Download database backup |
| `deposit_products/list` | Get deposit products |
| `deposit_products/create` | Create deposit product |
| `deposit_products/delete` | Delete deposit product |
| `deposit_products/get_by_id` | Get deposit product |
| `deposit_products/patch` | Partially update deposit product |
| `deposit_products/update` | Update deposit product |
| `deposit_products/batch_update` | Perform a batch update action on the specified deposit product |
| `deposits_balance_summary/search` | Search deposit account balance summary |
| `deposits_balance_summary/list` | Get balance summary for the deposit account |
| `deposits_download/search_file_download` | Search deposit accounts |
| `deposits_transactions/make_bulk_deposits` | Create bulk deposit transactions |
| `deposits_transactions/get_by_id` | Get deposit transaction |
| `deposits_transactions/edit_transaction_details` | Edit custom information or notes for deposit transaction |
| `deposits_transactions/get_deposit_transaction_document` | Get deposit transaction document |
| `deposits_transactions/adjust` | Adjust a deposit transaction, which may bulk adjust multiple transactions |
| `deposits_transactions/search` | Search deposit transactions for deposit accounts by various criteria |
| `deposits_transactions/make_deposit` | Create deposit transaction |
| `deposits_transactions/apply_fee` | Apply a fee on a deposit account |
| `deposits_transactions/make_seizure` | Seize a block amount on a deposit account |
| `deposits_transactions/list` | Get deposit transactions |
| `deposits_transactions/make_deposit_async` | Create deposit transaction |
| `deposits_transactions/make_withdrawal_async` | Create withdrawal transaction |
| `deposits_transactions/make_transfer` | Create transfer transaction |
| `deposits_transactions/make_withdrawal` | Create withdrawal transaction |
| `deposits_transactions/adjust_interest` | Adjust interest on a deposit account |
| `deposits/list` | Get deposit accounts |
| `deposits/create` | Create deposit account |
| `deposits/bulk_update_product_keys` | Bulk update deposit account product types |
| `deposits/bulk_update_accounts` | Bulk update deposit accounts |
| `deposits/make_bulk_interest_account_settings_availabilities` | Create Interest Availabilities for a group of accounts |
| `deposits/migrate` | Migrate deposit accounts |
| `deposits/delete` | Delete inactive deposit account |
| `deposits/get_by_id` | Get deposit account |
| `deposits/patch` | Partially update deposit account |
| `deposits/update` | Update deposit account |
| `deposits/list_authorization_holds` | Get authorization holds related to a deposit account, ordered from newest to oldest by creation date |
| `deposits/create_authorization_hold` | Create an authorization hold corresponding to a given account |
| `deposits/reverse_authorization_hold` | Reverse account authorization hold |
| `deposits/get_authorization_hold_by_id` | Get account authorization hold |
| `deposits/list_blocks` | Get all block funds for a deposit account |
| `deposits/create_block_fund` | Create a block fund for the account |
| `deposits/unblock_fund` | Unblock a previously blocked fund for a deposit account |
| `deposits/patch_block_fund` | Updates the amount of an existing blocked fund on a deposit account. If the new amount equals the seized amount the b... |
| `deposits/list_cards` | Get cards associated with an account |
| `deposits/create_card` | Represents the information needed to create and associate a new card to an account |
| `deposits/delete_card` | Represents the information needed to delete a card associated to an account using its reference token |
| `deposits/get_funded_loans` | Get all loan accounts funded by the deposit account with the given ID or encoded key |
| `deposits/get_schedule_for_funded_account` | Allows retrieval of the loan account schedule for a loan account with the given id or encodedKey and funded by the de... |
| `deposits/get_interest_availabilities_list` | Get Interest Availabilities |
| `deposits/create_interest_availability` | Create Interest Availability |
| `deposits/delete_interest_availability` | Delete Interest Availability |
| `deposits/get_interest_availability_by_id` | Get Interest Availability |
| `deposits/update_interest_availability` | Update Interest Availability |
| `deposits/get_deposit_account_document` | Get deposit account document |
| `deposits/get_pdf_document` | Download deposit account document PDF |
| `deposits/make_multiple_transactions_async` | Create multiple transactions for an account |
| `deposits/get_withholding_tax_history` | Get deposit account withholding tax history |
| `deposits/apply_interest` | Represents information to apply accrued interest |
| `deposits/change_interest_rate` | Change deposit account interest rate |
| `deposits/change_state` | Represents the information to post an action, such as approving a deposit account |
| `deposits/change_withholding_tax` | Change deposit account withholding tax rate |
| `deposits/reopen` | Reopen a deposit account |
| `deposits/start_maturity` | Represents the information to post an action, such as approving a deposit account |
| `deposits/transfer_ownership` | Transfer the account ownership from current account holder to a new one (client/group) |
| `deposits/undo_maturity` | Represents the action to undo the maturity period for the specified deposit account |
| `deposits/get_balances` | Get historical balances for the deposit account |
| `deposits/search` | Search deposit accounts |
| `documents/create_document` | Create document |
| `documents/get_documents_by_entity_id` | Get all documents' metadata |
| `documents/delete_document_by_id` | Delete document |
| `documents/download_document_by_id` | Download document |
| `extension_points/list` | Get all extension points |
| `extension_points/get_process_definitions` | Get process definitions for extension point phases |
| `extension_points/store_process_definitions` | Attach process definitions to extension point phases |
| `funding_sources/sell` | Performs the sell of a funding share owned by an investor. Investors can sell the total share or only a part of the i... |
| `gl_accounts/list` | Get general ledger accounts |
| `gl_accounts/create` | Create general ledger account |
| `gl_accounts/get_by_id` | Get general ledger account |
| `gl_accounts/patch` | Partially update an existing general ledger account |
| `gl_journal_entries/list` | Get general ledger journal entries |
| `gl_journal_entries/create` | Create general ledger journal entries |
| `gl_journal_entries/search` | Search for general ledger journal entries |
| `groups/list` | Get groups |
| `groups/create` | Create group |
| `groups/delete` | Delete group |
| `groups/get_by_id` | Get group |
| `groups/patch` | Partially update group |
| `groups/update` | Update group |
| `groups/get_credit_arrangements_by_group_id_or_key` | Credit arrangements list returned |
| `groups/search` | Search groups |
| `index_rate_sources/list_index_rate_sources` | Get index rate sources |
| `index_rate_sources/create_index_rate_source` | Create index rate source |
| `index_rate_sources/delete_index_rate_source` | Delete index rate source |
| `index_rate_sources/get_index_rate_source_by_id` | Get index rate sources |
| `index_rate_sources/list_index_rates` | Get index rates for a source |
| `index_rate_sources/create_index_rate` | Create index rate |
| `index_rate_sources/delete_index_rate` | Delete index rate |
| `installments/list` | Get installments for `ACTIVE` or `ACTIVE_IN_ARREARS` loan accounts |
| `loan_products/list` | Get loan products |
| `loan_products/create` | Create loan product |
| `loan_products/delete` | Delete loan product |
| `loan_products/get_by_id` | Get loan product |
| `loan_products/patch` | Partially update loan product |
| `loan_products/update` | Update loan product |
| `loans_download/search_file_download` | Search loan accounts |
| `loans_download/search_ranges` | Get search ranges for parallel file-download streams |
| `loans_schedule/preview_schedule` | Preview loan account schedule for non-existent loan account |
| `loans_schedule/get_schedule_for_loan_account` | Get loan account schedule |
| `loans_schedule/edit_schedule` | Update loan account schedule |
| `loans_schedule/preview_process_pmt_transactionally` | Preview loan account schedule using transactional processing for PMT |
| `loans_schedule/preview_tranches_on_schedule` | Preview loan account schedule for non-existent loan account |
| `loans_tranches/get_tranches` | Get loan account tranches list |
| `loans_tranches/edit_tranches` | Update loan account tranches list |
| `loans_transactions_octetstream/search` | Search loan transactions |
| `loans_transactions/get_by_id` | Get loan transaction |
| `loans_transactions/adjust` | Adjust loan transaction |
| `loans_transactions/search` | Search loan transactions |
| `loans_transactions/make_disbursement` | Make a disbursement on a loan |
| `loans_transactions/apply_fee` | Apply a fee on a loan account |
| `loans_transactions/apply_lock` | Lock loan account income sources (interest, fees, penalties) |
| `loans_transactions/apply_payment_made` | Make payment in redraw balance for loan account |
| `loans_transactions/make_principal_overpayment` | Make non-scheduled principal overpayment transaction on loan account |
| `loans_transactions/make_redraw_repayment` | Make a redraw repayment transaction on a loan |
| `loans_transactions/make_refund` | Make refund transaction on loan account |
| `loans_transactions/make_repayment` | Make repayment transaction on loan account |
| `loans_transactions/list` | Get loan transactions |
| `loans_transactions/get_transactions_for_all_versions` | Get loan transactions for all loan account versions |
| `loans_transactions/apply_unlock` | Unlock loan account income sources (interest, fees, penalties) |
| `loans_transactions/make_withdrawal` | Make withdrawal from redraw balance |
| `loans_transactions/make_deposit_on_credit_balance` | Represents the information for creating a transaction of type CREDIT_BALANCE_DEPOSIT |
| `loans/list` | Get loan accounts |
| `loans/create` | Create loan account |
| `loans/migrate_external` | Create loan account via external migration |
| `loans/delete` | Delete loan account |
| `loans/get_by_id` | Get loan account |
| `loans/patch` | Partially update loan account |
| `loans/update` | Update loan account |
| `loans/list_authorization_holds` | Get authorization holds related to a loan account, ordered from newest to oldest by creation date |
| `loans/get_balances_by_loan_account_id` | Get loan account balances |
| `loans/apply_balance_interest` | Apply interest on a loan account balance |
| `loans/list_cards` | Get cards associated with an account |
| `loans/create_card` | Represents the information needed to create and associate a new card to an account |
| `loans/delete_card` | Represents the information needed to delete a card associated to an account using its reference token |
| `loans/delete_funding_sources` | Delete loan account funding sources |
| `loans/create_loan_account_funding_sources` | Create funding sources for a loan account |
| `loans/update_loan_account_funding_sources` | Update loan account funding sources |
| `loans/delete_single_funding_source` | Delete loan account funding source |
| `loans/patch_funding_source` | Update loan account funding source |
| `loans/list_planned_fees` | Get planned fees |
| `loans/create_planned_fees` | Create planned fees |
| `loans/update_planned_fees` | Update planned fees |
| `loans/delete_planned_fees` | Delete planned fee |
| `loans/apply_planned_fees` | ApplY planned fees from the past installments, as backdated or from future installments, on the first pending install... |
| `loans/get_loan_account_document` | Get loan account document |
| `loans/get_pdf_document` | Download loan account document PDF |
| `loans/apply_interest` | Apply accrued interest |
| `loans/change_arrears_settings` | Change arrears settings for loan account |
| `loans/change_due-dates_settings` | Change due dates settings for loan account |
| `loans/change_fee_rate` | Change loan account fee rate |
| `loans/change_interest_rate` | Change loan account interest rate |
| `loans/change_loan_term` | Change loan account term |
| `loans/change_periodic_payment` | Change the periodic payment amount for an active loan, so that it is still possible to have principal and interest in... |
| `loans/change_repayment_value` | Change repayment value for loan account |
| `loans/change_state` | Change loan account state |
| `loans/pay_off` | Pay off loan account |
| `loans/preview_pay_off_amounts` | Preview pay off due amounts in a future date |
| `loans/refinance` | Refinance loan account |
| `loans/get_loan_account_rsv` | Allows retrieval of repayment schedule versioning for a loan account |
| `loans/reschedule` | Reschedule loan account |
| `loans/terminate_loan_account` | Terminate loan account |
| `loans/undo_refinance` | Undo loan account refinance action |
| `loans/undo_reschedule` | Undo loan account reschedule action |
| `loans/undo_write_off` | Undo write off for loan account |
| `loans/get_versions_by_id` | Get all versions of loan account |
| `loans/write_off` | Write off loan account |
| `loans/get_preview_loan_account_schedule` | Preview loan account schedule for non-existent loan account |
| `loans/reevaluate_collateral_assets` | Update collateral asset amounts |
| `loans/search` | Search loan accounts |
| `notification_settings_webhook/get_webhook_notification_settings` | Get the webhook notification settings |
| `notification_settings_webhook/update_webhook_notification_settings` | Update the webhook notification settings |
| `organization_holidays_general/create` | Create holidays |
| `organization_holidays_general/delete` | Delete holiday |
| `organization_holidays_general/get_by_id` | Get holiday |
| `organization_holidays_nonworkingdays/get_non_working_days` | Get non-working days |
| `organization_holidays_nonworkingdays/update_non_working_days` | Update non-working days |
| `organization_holidays/get` | Get holidays |
| `organization_holidays/update` | Update holidays |
| `organization_identification_document_templates/list` | Get ID templates |
| `organization_transaction_channels/list` | Get transaction channels |
| `organization_transaction_channels/create` | Create transaction channel |
| `organization_transaction_channels/delete` | Delete transaction channel |
| `organization_transaction_channels/get_by_id` | Get transaction channel |
| `organization_transaction_channels/update` | Update transaction channel |
| `profit_sharing_cashflows/get_cash_flows` | Allows retrieval of a list of cash flows |
| `profit_sharing_cashflows/create_cash_flow` | Create a new cash flow |
| `profit_sharing_cashflows/get_cash_flow_by_id` | Allows retrieval of a single cash flow |
| `profit_sharing_cashflows/update_cash_flow` | Update an existing cash flow |
| `profit_sharing_cashflows/create_cash_flow_settings` | Create new settings for a cash flow |
| `profit_sharing_cashflows/get_cash_flow_settings_by_id` | Retrieves the settings for a cash flow |
| `profit_sharing_cashflows/update_cash_flow_settings` | Update settings for an existing cash flow |
| `profit_sharing_pools/get_pools` | Allows retrieval of a list of pools |
| `profit_sharing_pools/create_pool` | Create a new investment pool |
| `profit_sharing_pools/get_pool_by_id` | Allows retrieval of a single pool |
| `profit_sharing_pools/update_pool` | Update an existing investment pool |
| `profit_sharing_pools/create_pool_settings` | Create new settings for investment pool |
| `profit_sharing_pools/get_pool_settings_by_id` | Retrieves settings for an investment pool |
| `profit_sharing_pools/update_pool_settings` | Update settings for an existing investment pool |
| `profit_sharing_product-settings/create_product_settings` | Create new product settings |
| `profit_sharing_product-settings/get_product_settings_by_id` | Allows retrieval of product settings |
| `profit_sharing_product-settings/update_product_settings` | Update existing product settings |
| `profit_sharing_product-settings/search_product_settings` | Allows the retrieval of product settings based on criteria |
| `profit_sharing_products/list` | Allows retrieval of Islamic savings products |
| `profit_sharing_proposals/find_proposal_account_details` | Allows the retrieval of proposal accounts details and account payment/profit cycle calculation by proposal id and oth... |
| `profit_sharing_proposals/find_proposals` | Allows the retrieval of proposals calculation |
| `profit_sharing_proposals/approve_proposal` | Allows approval of a proposal |
| `process_definitions/upload` | Upload a BPMN process definition |
| `setup_general/get_general_setup` | Get general setup |
| `setup_organization/get_organization_setup` | Get organization details |
| `setup_organization/update_organization_setup` | Update organization details |
| `subscriptions/create_or_get` | Allows the creation of a streaming events subscription |
| `subscriptions/delete` | Allows the deletion of a streaming events subscription |
| `subscriptions/get_events` | Get subscription events |
| `tasks/list` | Gets tasks |
| `tasks/create` | Create task |
| `tasks/delete` | Delete task |
| `tasks/get_by_id` | Get task |
| `tasks/patch` | Partially update task |
| `tasks/update` | Update task |
| `templates/create_template` | Create a new template |
| `templates/delete` | Delete an existing template |
| `templates/get_by_template_id` | Get template by id |
| `templates/update_template` | Update an existing template |
| `user_roles/list` | Get user roles |
| `user_roles/create` | Create user role |
| `user_roles/delete` | Delete user role |
| `user_roles/get_by_id` | Get user role |
| `user_roles/patch` | Partially update user role |
| `user_roles/update` | Update user role |
| `users/list` | Get users |
| `users/create` | Create user |
| `users/delete` | Delete user |
| `users/get_by_id` | Get user |
| `users/patch` | Partially update user |
| `users/update` | Update user |


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


## HTTP Server Mode

By default, MMCP communicates over stdio. Run it as a standalone HTTP server when you need a shared server, remote access, multiple MCP clients connecting to one instance, or debugging with [MCP Inspector](https://modelcontextprotocol.io/docs/tools/inspector).

```bash
mmcp -Dquarkus.http.host-enabled=true
```

The server binds to `0.0.0.0:8081` by default. To use a different port:

```bash
mmcp -Dquarkus.http.host-enabled=true -Dquarkus.http.port=9090
```

MCP clients that support remote servers can connect via the SSE endpoint at `http://<host>:8081/mcp/sse`.

You can also enable HTTP mode via environment variables instead of `-D` flags:

```bash
export QUARKUS_HTTP_HOST_ENABLED=true
export QUARKUS_HTTP_PORT=9090
mmcp
```

The same catalog, index, model, and access control configuration apply in both stdio and HTTP server modes.


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
This software is proprietary and confidential. Unauthorized copying, distribution, or use is strictly prohibited. © Mambu Tech B.V. All rights reserved.
