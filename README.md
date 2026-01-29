# Mambu MCP Server

A [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) server implementation for the [Mambu Banking Platform](https://mambu.com/). This server enables AI agents and agentic applications to securely interact with the Mambu V2 API, allowing them to discover and execute banking operations programmatically.

## Overview

The Mambu MCP Server acts as a bridge between AI systems and Mambu's banking APIs. It provides:

*   **Dynamic API Catalog**: Automatically loads Mambu V2 API operations from OpenAPI specifications
*   **AI-Native Tools**: Exposes banking operations as MCP tools that AI agents can discover and use
*   **Secure Authentication**: Built-in support for Mambu API authentication
*   **Configurable Access**: Fine-grained control over which operations are available to AI agents


## Installation

Connect to the Repository and Install MMCP

```bash
brew tap mambu-gmbh/mmcp-brew https://github.com/mambu-gmbh/mmcp-brew
brew install mmcp
```

You can make sure you are on the latest version by running:

```bash
brew update
brew upgrade mmcp
```


## Quick Start

### 1. Configure Your Mambu Credentials

The MCP server requires environment variables to connect to your Mambu instance:

*   `MAMBU_BASE_URL`: Your Mambu API endpoint (e.g., `https://your-tenant.mambu.com/api`)
*   `MAMBU_AUTH_API_KEY`: Your Mambu API key (for API Consumer authentication)

The MCP server supports two types of authentication:

1. **API Consumer authentication with an API Key** (recommended): Set the `MAMBU_AUTH_API_KEY` environment variable with your API key.
2. **Basic authentication**: If `MAMBU_AUTH_API_KEY` is not set, the server will fallback to basic authentication using `MAMBU_AUTH_USERNAME` and `MAMBU_AUTH_PASSWORD` environment variables.

These are configured in your MCP client (see next section).

### 2. Configure Your MCP Client

Most agentic applications and AI tools support MCP through a configuration file. Below are examples for common platforms.

#### Claude Desktop

Edit your Claude Desktop configuration file:

*   **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
*   **Linux**: `~/.config/Claude/claude_desktop_config.json`

Add the Mambu MCP server configuration:

```json
{
  "mcpServers": {
    "mambu": {
      "command": "mmcp",
      "args": [],
      "env": {
        "MAMBU_BASE_URL": "https://your-tenant.mambu.com/api",
        "MAMBU_AUTH_API_KEY": "your-api-key"
      }
    }
  }
}
```

#### Junie CLI

Edit your Junie MCP configuration file:

Add the Mambu MCP server configuration:

```json
{
  "mcpServers": {
    "mambu": {
      "type": "com.intellij.ml.llm.matterhorn.core.mcp.McpServerConfiguration.McpServerCommand",
      "name": "mambu",
      "command": "/opt/homebrew/bin/mmcp",
      "env": {
        "MAMBU_BASE_URL": "https://<DOMAIN>/api",
        "MAMBU_AUTH_API_KEY": "<API_KEY>"
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
      "MAMBU_AUTH_API_KEY": "your-api-key"
    }
  }
}
```

#### Other MCP Clients

For other MCP-compatible tools, use this general pattern:

```json
{
  "servers": {
    "mambu": {
      "command": "mmcp",
      "args": [],
      "env": {
        "MAMBU_BASE_URL": "https://your-tenant.mambu.com/api",
        "MAMBU_AUTH_API_KEY": "your-api-key"
      }
    }
  }
}
```

### 3. Restart Your MCP Client

After configuring, restart your MCP client application. The Mambu MCP server will start automatically when needed.

### 4. Verify Connection

Ask your AI agent to list available Mambu tools or try a simple operation:

```
"What Mambu operations are available?"
"Get client information for client ID 12345"
```

## Available Tools

The server exposes MCP tools that your AI agent can use to interact with Mambu:

### `describeOperation`

Returns detailed schema and parameter information for a specific Mambu API operation.

*   **Input**: `label` (string) - The operation identifier (e.g., `clients_v2.get_client`)
*   **Output**: JSON object with operation details including parameters, method, path, and description

### `invoke`

Executes a Mambu API operation.

*   **Input**:
   *   `label` (string) - The operation to execute
   *   `params` (object) - Parameters required by the operation
*   **Output**: JSON response containing:
   *   `statusCode` - HTTP status code (e.g., 200)
   *   `body` - The response data from Mambu

## Security Considerations

### Credential Storage

Your Mambu credentials are stored in your MCP client's configuration file. Protect this file:

**macOS/Linux**:
```bash
chmod 600 ~/Library/Application\ Support/Claude/claude_desktop_config.json
```


### Alternative: Environment Variables

For better security, you can use a wrapper script that loads credentials from a secure location:

**macOS/Linux** (`launch-mmcp.sh`):
```bash
#!/bin/bash
source ~/.mambu_credentials  # Contains your env vars
mmcp
```


## API Operation Control

By default, the server enables read-only operations (GET requests) and disables mutating operations (POST, PUT, DELETE) for safety. 
Users can selectively enable/disable each operation by setting overides in their MCP configuration or environment variables. 

As an example, you can enable the `clients/create` operation by adding the following to your MCP configuration:
```json
{
  "servers": {
    "mambu": {
      "command": "mmcp",
      "args": [],
      "env": {
        "MAMBU_BASE_URL": "https://your-tenant.mambu.com/api",
        "MAMBU_AUTH_API_KEY": "your-api-key",
        "CLIENTS_CREATE": "true"
      }
    }
  }
}
```

The operations and default values follow:

| Environment Variable                                               | Default value |
|--------------------------------------------------------------------|---|
| ACCOUNTING_INTEREST_ACCRUAL_SEARCH                                 | false |
| ACCOUNTING_REPORTS_CREATE                                          | false |
| ACCOUNTING_REPORTS_GET                                             | true |
| API_KEY_ROTATION_ROTATE_KEY                                        | false |
| APPLICATION_STATUS_GET                                             | true |
| ARCHIVE_DEPOSITS_TRANSACTIONS_CUSTOM_FIELDS_GET_BY_ID              | true |
| ARCHIVE_DEPOSITS_TRANSACTIONS_CUSTOM_FIELDS_SEARCH                 | false |
| BACKGROUND_PROCESS_GET_LATEST_BY_TYPE                              | true |
| BACKGROUND_PROCESS_UPDATE                                          | false |
| BRANCHES_CREATE                                                    | false |
| BRANCHES_GET_BY_ID                                                 | true |
| BRANCHES_LIST                                                      | true |
| BULKS_GET_BULK_STATUS                                              | true |
| CARDS_CREATE_AUTHORIZATION_HOLD                                    | false |
| CARDS_CREATE_BULK_AUTHORIZATION_HOLDS                              | false |
| CARDS_CREATE_CARD_TRANSACTION                                      | false |
| CARDS_DECREASE_AUTHORIZATION_HOLD                                  | false |
| CARDS_GET_ACCOUNT_BALANCES                                         | true |
| CARDS_GET_AUTHORIZATION_HOLD_BY_ID                                 | true |
| CARDS_GET_CARD_TRANSACTION                                         | true |
| CARDS_INCREASE_AUTHORIZATION_HOLD                                  | false |
| CARDS_PATCH_AUTHORIZATION_HOLD                                     | false |
| CARDS_REVERSE_AUTHORIZATION_HOLD                                   | false |
| CARDS_REVERSE_CARD_TRANSACTION                                     | false |
| CENTRES_GET_BY_ID                                                  | true |
| CENTRES_LIST                                                       | true |
| CLIENTS_CREATE                                                     | false |
| CLIENTS_DELETE                                                     | false |
| CLIENTS_DOCUMENTS_CREATE_DOCUMENT                                  | false |
| CLIENTS_DOCUMENTS_GET_CLIENT_DOCUMENT_BY_ID                        | true |
| CLIENTS_DOCUMENTS_GET_CLIENT_DOCUMENT_FILE_BY_ID                   | true |
| CLIENTS_DOCUMENTS_GET_DOCUMENTS_BY_CLIENT_ID                       | true |
| CLIENTS_GET_BY_ID                                                  | true |
| CLIENTS_GET_CREDIT_ARRANGEMENTS_BY_CLIENT_ID_OR_KEY                | true |
| CLIENTS_GET_ROLE_BY_CLIENT_ID                                      | true |
| CLIENTS_LIST                                                       | true |
| CLIENTS_PATCH                                                      | false |
| CLIENTS_SEARCH                                                     | false |
| CLIENTS_UPDATE                                                     | false |
| COMMENTS_CREATE_COMMENT                                            | false |
| COMMENTS_GET_COMMENTS                                              | true |
| COMMUNICATIONS_MESSAGES_ENQUEUE_BY_DATE                            | false |
| COMMUNICATIONS_MESSAGES_ENQUEUE_BY_KEYS                            | false |
| COMMUNICATIONS_MESSAGES_GET_BY_ENCODED_KEY                         | true |
| COMMUNICATIONS_MESSAGES_RESEND                                     | false |
| COMMUNICATIONS_MESSAGES_SEARCH                                     | false |
| COMMUNICATIONS_MESSAGES_SEARCH_SORTED                              | false |
| COMMUNICATIONS_MESSAGES_SEND                                       | false |
| CONFIGURATION_ACCOUNTING_RULES_YAML_GET                            | true |
| CONFIGURATION_ACCOUNTING_RULES_YAML_UPDATE                         | false |
| CONFIGURATION_AUTHORIZATION_HOLDS_YAML_GET                         | true |
| CONFIGURATION_AUTHORIZATION_HOLDS_YAML_UPDATE                      | false |
| CONFIGURATION_BRANCHES_YAML_GET                                    | true |
| CONFIGURATION_BRANCHES_YAML_UPDATE                                 | false |
| CONFIGURATION_CENTRES_YAML_GET                                     | true |
| CONFIGURATION_CENTRES_YAML_UPDATE                                  | false |
| CONFIGURATION_CLIENT_ROLES_YAML_GET                                | true |
| CONFIGURATION_CLIENT_ROLES_YAML_UPDATE                             | false |
| CONFIGURATION_CURRENCIES_YAML_GET                                  | true |
| CONFIGURATION_CURRENCIES_YAML_UPDATE                               | false |
| CONFIGURATION_CUSTOM_FIELDS_GET                                    | true |
| CONFIGURATION_CUSTOM_FIELDS_GET_TEMPLATE                           | true |
| CONFIGURATION_CUSTOM_FIELDS_UPDATE                                 | false |
| CONFIGURATION_DEPOSIT_PRODUCTS_YAML_GET                            | true |
| CONFIGURATION_DEPOSIT_PRODUCTS_YAML_UPDATE                         | false |
| CONFIGURATION_END_OF_DAY_PROCESSING_YAML_GET                       | true |
| CONFIGURATION_END_OF_DAY_PROCESSING_YAML_UPDATE                    | false |
| CONFIGURATION_GROUP_ROLE_NAMES_YAML_GET                            | true |
| CONFIGURATION_GROUP_ROLE_NAMES_YAML_UPDATE                         | false |
| CONFIGURATION_HOLIDAYS_YAML_GET                                    | true |
| CONFIGURATION_HOLIDAYS_YAML_UPDATE                                 | false |
| CONFIGURATION_ID_DOCUMENT_TEMPLATES_YAML_GET                       | true |
| CONFIGURATION_ID_DOCUMENT_TEMPLATES_YAML_UPDATE                    | false |
| CONFIGURATION_INDEX_RATES_YAML_GET                                 | true |
| CONFIGURATION_INDEX_RATES_YAML_UPDATE                              | false |
| CONFIGURATION_INTERNAL_CONTROLS_YAML_GET                           | true |
| CONFIGURATION_INTERNAL_CONTROLS_YAML_UPDATE                        | false |
| CONFIGURATION_LABELS_YAML_GET                                      | true |
| CONFIGURATION_LABELS_YAML_UPDATE                                   | false |
| CONFIGURATION_LOAN_PRODUCTS_YAML_GET                               | true |
| CONFIGURATION_LOAN_PRODUCTS_YAML_UPDATE                            | false |
| CONFIGURATION_LOAN_RISK_LEVELS_YAML_GET                            | true |
| CONFIGURATION_LOAN_RISK_LEVELS_YAML_UPDATE                         | false |
| CONFIGURATION_ORGANIZATION_GET                                     | true |
| CONFIGURATION_ORGANIZATION_GETTEMPLATE                             | true |
| CONFIGURATION_ORGANIZATION_UPDATE                                  | false |
| CONFIGURATION_TRANSACTION_CHANNELS_YAML_GET                        | true |
| CONFIGURATION_TRANSACTION_CHANNELS_YAML_UPDATE                     | false |
| CONFIGURATION_USER_ROLES_GET                                       | true |
| CONFIGURATION_USER_ROLES_GETTEMPLATE                               | true |
| CONFIGURATION_USER_ROLES_UPDATE                                    | false |
| CONSUMERS_CREATE                                                   | false |
| CONSUMERS_CREATE_API_KEY_FOR_CONSUMER                              | false |
| CONSUMERS_CREATE_SECRET_KEY_FOR_CONSUMER                           | false |
| CONSUMERS_DELETE                                                   | false |
| CONSUMERS_DELETE_API_KEY_FOR_CONSUMER                              | false |
| CONSUMERS_GET_BY_ID                                                | true |
| CONSUMERS_GET_KEYS_BY_CONSUMER_ID                                  | true |
| CONSUMERS_LIST                                                     | true |
| CONSUMERS_PATCH                                                    | false |
| CONSUMERS_UPDATE                                                   | false |
| CREDIT_ARRANGEMENTS_ADD_ACCOUNT                                    | false |
| CREDIT_ARRANGEMENTS_CHANGE_STATE                                   | false |
| CREDIT_ARRANGEMENTS_CREATE                                         | false |
| CREDIT_ARRANGEMENTS_DELETE                                         | false |
| CREDIT_ARRANGEMENTS_GET_BY_ID                                      | true |
| CREDIT_ARRANGEMENTS_GET_SCHEDULE                                   | true |
| CREDIT_ARRANGEMENTS_LIST                                           | true |
| CREDIT_ARRANGEMENTS_LIST_ACCOUNTS                                  | true |
| CREDIT_ARRANGEMENTS_PATCH                                          | false |
| CREDIT_ARRANGEMENTS_REMOVE_ACCOUNT                                 | false |
| CREDIT_ARRANGEMENTS_SEARCH                                         | false |
| CREDIT_ARRANGEMENTS_UPDATE                                         | false |
| CRONS_EARLY_EOD_RUN_EARLIER_HOURLY_AND_END_OF_DAY_CRONS            | false |
| CRONS_EOD_RUN_HOURLY_AND_END_OF_DAY_CRONS                          | false |
| CURRENCIES_ACCOUNTING_RATES_CREATE                                 | false |
| CURRENCIES_ACCOUNTING_RATES_LIST                                   | true |
| CURRENCIES_CREATE                                                  | false |
| CURRENCIES_DELETE                                                  | false |
| CURRENCIES_GET                                                     | true |
| CURRENCIES_LIST                                                    | true |
| CURRENCIES_RATES_CREATE                                            | false |
| CURRENCIES_RATES_LIST                                              | true |
| CURRENCIES_UPDATE                                                  | false |
| CUSTOM_FIELD_SETS_LIST                                             | true |
| CUSTOM_FIELD_SETS_LIST_BY_SET_ID                                   | true |
| CUSTOM_FIELDS_GET_BY_ID                                            | true |
| DATA_IMPORT_ACTION                                                 | false |
| DATA_IMPORT_DATA_IMPORT                                            | false |
| DATA_IMPORT_GET_IMPORT                                             | true |
| DATABASE_BACKUP_DOWNLOAD_BACKUP                                    | true |
| DATABASE_BACKUP_TRIGGER_BACKUP                                     | false |
| DEPOSIT_PRODUCTS_BATCH_UPDATE                                      | false |
| DEPOSIT_PRODUCTS_CREATE                                            | false |
| DEPOSIT_PRODUCTS_DELETE                                            | false |
| DEPOSIT_PRODUCTS_GET_BY_ID                                         | true |
| DEPOSIT_PRODUCTS_LIST                                              | true |
| DEPOSIT_PRODUCTS_PATCH                                             | false |
| DEPOSIT_PRODUCTS_UPDATE                                            | false |
| DEPOSITS_APPLY_INTEREST                                            | false |
| DEPOSITS_BALANCE_SUMMARY_LIST                                      | true |
| DEPOSITS_BALANCE_SUMMARY_SEARCH                                    | false |
| DEPOSITS_CHANGE_INTEREST_RATE                                      | false |
| DEPOSITS_CHANGE_STATE                                              | false |
| DEPOSITS_CHANGE_WITHHOLDING_TAX                                    | false |
| DEPOSITS_CREATE                                                    | false |
| DEPOSITS_CREATE_AUTHORIZATION_HOLD                                 | false |
| DEPOSITS_CREATE_BLOCK_FUND                                         | false |
| DEPOSITS_CREATE_CARD                                               | false |
| DEPOSITS_CREATE_INTEREST_AVAILABILITY                              | false |
| DEPOSITS_DELETE                                                    | false |
| DEPOSITS_DELETE_CARD                                               | false |
| DEPOSITS_DELETE_INTEREST_AVAILABILITY                              | false |
| DEPOSITS_DOWNLOAD_SEARCH_FILE_DOWNLOAD                             | true |
| DEPOSITS_GET_AUTHORIZATION_HOLD_BY_ID                              | true |
| DEPOSITS_GET_BY_ID                                                 | true |
| DEPOSITS_GET_DEPOSIT_ACCOUNT_DOCUMENT                              | true |
| DEPOSITS_GET_FUNDED_LOANS                                          | true |
| DEPOSITS_GET_INTEREST_AVAILABILITIES_LIST                          | true |
| DEPOSITS_GET_INTEREST_AVAILABILITY_BY_ID                           | true |
| DEPOSITS_GET_PDF_DOCUMENT                                          | true |
| DEPOSITS_GET_SCHEDULE_FOR_FUNDED_ACCOUNT                           | true |
| DEPOSITS_GET_WITHHOLDING_TAX_HISTORY                               | true |
| DEPOSITS_LIST                                                      | true |
| DEPOSITS_LIST_AUTHORIZATION_HOLDS                                  | true |
| DEPOSITS_LIST_BLOCKS                                               | true |
| DEPOSITS_LIST_CARDS                                                | true |
| DEPOSITS_MAKE_BULK_INTEREST_ACCOUNT_SETTINGS_AVAILABILITIES        | false |
| DEPOSITS_MAKE_MULTIPLE_TRANSACTIONS_ASYNC                          | false |
| DEPOSITS_PATCH                                                     | false |
| DEPOSITS_PATCH_BLOCK_FUND                                          | false |
| DEPOSITS_REOPEN                                                    | false |
| DEPOSITS_REVERSE_AUTHORIZATION_HOLD                                | false |
| DEPOSITS_SEARCH                                                    | false |
| DEPOSITS_START_MATURITY                                            | false |
| DEPOSITS_TRANSACTIONS_ADJUST                                       | false |
| DEPOSITS_TRANSACTIONS_APPLY_FEE                                    | false |
| DEPOSITS_TRANSACTIONS_EDIT_TRANSACTION_DETAILS                     | false |
| DEPOSITS_TRANSACTIONS_GET_BY_ID                                    | true |
| DEPOSITS_TRANSACTIONS_GET_DEPOSIT_TRANSACTION_DOCUMENT             | true |
| DEPOSITS_TRANSACTIONS_LIST                                         | true |
| DEPOSITS_TRANSACTIONS_MAKE_BULK_DEPOSITS                           | false |
| DEPOSITS_TRANSACTIONS_MAKE_DEPOSIT                                 | false |
| DEPOSITS_TRANSACTIONS_MAKE_DEPOSIT_ASYNC                           | false |
| DEPOSITS_TRANSACTIONS_MAKE_SEIZURE                                 | false |
| DEPOSITS_TRANSACTIONS_MAKE_TRANSFER                                | false |
| DEPOSITS_TRANSACTIONS_MAKE_WITHDRAWAL                              | false |
| DEPOSITS_TRANSACTIONS_MAKE_WITHDRAWAL_ASYNC                        | false |
| DEPOSITS_TRANSACTIONS_SEARCH                                       | false |
| DEPOSITS_TRANSFER_OWNERSHIP                                        | false |
| DEPOSITS_UNBLOCK_FUND                                              | false |
| DEPOSITS_UNDO_MATURITY                                             | false |
| DEPOSITS_UPDATE                                                    | false |
| DEPOSITS_UPDATE_INTEREST_AVAILABILITY                              | false |
| DOCUMENTS_CREATE_DOCUMENT                                          | false |
| DOCUMENTS_DELETE_DOCUMENT_BY_ID                                    | false |
| DOCUMENTS_DOWNLOAD_DOCUMENT_BY_ID                                  | true |
| DOCUMENTS_GET_DOCUMENTS_BY_ENTITY_ID                               | true |
| FUNDING_SOURCES_SELL                                               | false |
| GL_ACCOUNTS_CREATE                                                 | false |
| GL_ACCOUNTS_GET_BY_ID                                              | true |
| GL_ACCOUNTS_LIST                                                   | true |
| GL_ACCOUNTS_PATCH                                                  | false |
| GL_JOURNAL_ENTRIES_CREATE                                          | false |
| GL_JOURNAL_ENTRIES_LIST                                            | true |
| GL_JOURNAL_ENTRIES_SEARCH                                          | false |
| GROUPS_CREATE                                                      | false |
| GROUPS_DELETE                                                      | false |
| GROUPS_GET_BY_ID                                                   | true |
| GROUPS_GET_CREDIT_ARRANGEMENTS_BY_GROUP_ID_OR_KEY                  | true |
| GROUPS_LIST                                                        | true |
| GROUPS_PATCH                                                       | false |
| GROUPS_SEARCH                                                      | false |
| GROUPS_UPDATE                                                      | false |
| INDEX_RATE_SOURCES_CREATE_INDEX_RATE                               | false |
| INDEX_RATE_SOURCES_CREATE_INDEX_RATE_SOURCE                        | false |
| INDEX_RATE_SOURCES_DELETE_INDEX_RATE                               | false |
| INDEX_RATE_SOURCES_DELETE_INDEX_RATE_SOURCE                        | false |
| INDEX_RATE_SOURCES_GET_INDEX_RATE_SOURCE_BY_ID                     | true |
| INDEX_RATE_SOURCES_LIST_INDEX_RATE_SOURCES                         | true |
| INDEX_RATE_SOURCES_LIST_INDEX_RATES                                | true |
| INSTALLMENTS_LIST                                                  | true |
| LOAN_PRODUCTS_CREATE                                               | false |
| LOAN_PRODUCTS_DELETE                                               | false |
| LOAN_PRODUCTS_GET_BY_ID                                            | true |
| LOAN_PRODUCTS_LIST                                                 | true |
| LOAN_PRODUCTS_PATCH                                                | false |
| LOAN_PRODUCTS_UPDATE                                               | false |
| LOANS_APPLY_BALANCE_INTEREST                                       | false |
| LOANS_APPLY_INTEREST                                               | false |
| LOANS_APPLY_PLANNED_FEES                                           | false |
| LOANS_CHANGE_ARREARS_SETTINGS                                      | false |
| LOANS_CHANGE_DUE_DATES_SETTINGS                                    | false |
| LOANS_CHANGE_FEE_RATE                                              | false |
| LOANS_CHANGE_INTEREST_RATE                                         | false |
| LOANS_CHANGE_LOAN_TERM                                             | false |
| LOANS_CHANGE_PERIODIC_PAYMENT                                      | false |
| LOANS_CHANGE_REPAYMENT_VALUE                                       | false |
| LOANS_CHANGE_STATE                                                 | false |
| LOANS_CREATE                                                       | false |
| LOANS_CREATE_CARD                                                  | false |
| LOANS_CREATE_LOAN_ACCOUNT_FUNDING_SOURCES                          | false |
| LOANS_CREATE_PLANNED_FEES                                          | false |
| LOANS_DELETE                                                       | false |
| LOANS_DELETE_CARD                                                  | false |
| LOANS_DELETE_FUNDING_SOURCES                                       | false |
| LOANS_DELETE_PLANNED_FEES                                          | false |
| LOANS_DELETE_SINGLE_FUNDING_SOURCE                                 | false |
| LOANS_GET_BALANCES_BY_LOAN_ACCOUNT_ID                              | true |
| LOANS_GET_BY_ID                                                    | true |
| LOANS_GET_LOAN_ACCOUNT_DOCUMENT                                    | true |
| LOANS_GET_LOAN_ACCOUNT_RSV                                         | true |
| LOANS_GET_PDF_DOCUMENT                                             | true |
| LOANS_GET_PREVIEW_LOAN_ACCOUNT_SCHEDULE                            | false |
| LOANS_GET_VERSIONS_BY_ID                                           | true |
| LOANS_LIST                                                         | true |
| LOANS_LIST_AUTHORIZATION_HOLDS                                     | true |
| LOANS_LIST_CARDS                                                   | true |
| LOANS_LIST_PLANNED_FEES                                            | true |
| LOANS_MIGRATE_EXTERNAL                                             | false |
| LOANS_PATCH                                                        | false |
| LOANS_PATCH_FUNDING_SOURCE                                         | false |
| LOANS_PAY_OFF                                                      | false |
| LOANS_PREVIEW_PAY_OFF_AMOUNTS                                      | false |
| LOANS_REEVALUATE_COLLATERAL_ASSETS                                 | false |
| LOANS_REFINANCE                                                    | false |
| LOANS_RESCHEDULE                                                   | false |
| LOANS_SCHEDULE_EDIT_SCHEDULE                                       | false |
| LOANS_SCHEDULE_GET_SCHEDULE_FOR_LOAN_ACCOUNT                       | true |
| LOANS_SCHEDULE_PREVIEW_PROCESS_PMT_TRANSACTIONALLY                 | false |
| LOANS_SCHEDULE_PREVIEW_SCHEDULE                                    | false |
| LOANS_SCHEDULE_PREVIEW_TRANCHES_ON_SCHEDULE                        | false |
| LOANS_SEARCH                                                       | false |
| LOANS_TERMINATE_LOAN_ACCOUNT                                       | false |
| LOANS_TRANCHES_EDIT_TRANCHES                                       | false |
| LOANS_TRANCHES_GET_TRANCHES                                        | true |
| LOANS_TRANSACTIONS_ADJUST                                          | false |
| LOANS_TRANSACTIONS_APPLY_FEE                                       | false |
| LOANS_TRANSACTIONS_APPLY_LOCK                                      | false |
| LOANS_TRANSACTIONS_APPLY_PAYMENT_MADE                              | false |
| LOANS_TRANSACTIONS_APPLY_UNLOCK                                    | false |
| LOANS_TRANSACTIONS_GET_BY_ID                                       | true |
| LOANS_TRANSACTIONS_GET_TRANSACTIONS_FOR_ALL_VERSIONS               | true |
| LOANS_TRANSACTIONS_LIST                                            | true |
| LOANS_TRANSACTIONS_MAKE_DISBURSEMENT                               | false |
| LOANS_TRANSACTIONS_MAKE_PRINCIPAL_OVERPAYMENT                      | false |
| LOANS_TRANSACTIONS_MAKE_REDRAW_REPAYMENT                           | false |
| LOANS_TRANSACTIONS_MAKE_REFUND                                     | false |
| LOANS_TRANSACTIONS_MAKE_REPAYMENT                                  | false |
| LOANS_TRANSACTIONS_MAKE_WITHDRAWAL                                 | false |
| LOANS_TRANSACTIONS_OCTETSTREAM_SEARCH                              | false |
| LOANS_TRANSACTIONS_SEARCH                                          | false |
| LOANS_UNDO_REFINANCE                                               | false |
| LOANS_UNDO_RESCHEDULE                                              | false |
| LOANS_UNDO_WRITE_OFF                                               | false |
| LOANS_UPDATE                                                       | false |
| LOANS_UPDATE_LOAN_ACCOUNT_FUNDING_SOURCES                          | false |
| LOANS_UPDATE_PLANNED_FEES                                          | false |
| LOANS_WRITE_OFF                                                    | false |
| NOTIFICATION_SETTINGS_WEBHOOK_GET_WEBHOOK_NOTIFICATION_SETTINGS    | true |
| NOTIFICATION_SETTINGS_WEBHOOK_UPDATE_WEBHOOK_NOTIFICATION_SETTINGS | false |
| ORGANIZATION_HOLIDAYS_GENERAL_CREATE                               | false |
| ORGANIZATION_HOLIDAYS_GENERAL_DELETE                               | false |
| ORGANIZATION_HOLIDAYS_GENERAL_GET_BY_ID                            | true |
| ORGANIZATION_HOLIDAYS_GET                                          | true |
| ORGANIZATION_HOLIDAYS_NONWORKINGDAYS_GET_NON_WORKING_DAYS          | true |
| ORGANIZATION_HOLIDAYS_NONWORKINGDAYS_UPDATE_NON_WORKING_DAYS       | false |
| ORGANIZATION_HOLIDAYS_UPDATE                                       | false |
| ORGANIZATION_IDENTIFICATION_DOCUMENT_TEMPLATES_LIST                | true |
| ORGANIZATION_TRANSACTION_CHANNELS_CREATE                           | false |
| ORGANIZATION_TRANSACTION_CHANNELS_DELETE                           | false |
| ORGANIZATION_TRANSACTION_CHANNELS_GET_BY_ID                        | true |
| ORGANIZATION_TRANSACTION_CHANNELS_LIST                             | true |
| ORGANIZATION_TRANSACTION_CHANNELS_UPDATE                           | false |
| PROFIT_SHARING_CASHFLOWS_CREATE_CASH_FLOW                          | false |
| PROFIT_SHARING_CASHFLOWS_CREATE_CASH_FLOW_SETTINGS                 | false |
| PROFIT_SHARING_CASHFLOWS_GET_CASH_FLOW_BY_ID                       | true |
| PROFIT_SHARING_CASHFLOWS_GET_CASH_FLOW_SETTINGS_BY_ID              | true |
| PROFIT_SHARING_CASHFLOWS_GET_CASH_FLOWS                            | true |
| PROFIT_SHARING_CASHFLOWS_UPDATE_CASH_FLOW                          | false |
| PROFIT_SHARING_CASHFLOWS_UPDATE_CASH_FLOW_SETTINGS                 | false |
| PROFIT_SHARING_POOLS_CREATE_POOL                                   | false |
| PROFIT_SHARING_POOLS_CREATE_POOL_SETTINGS                          | false |
| PROFIT_SHARING_POOLS_GET_POOL_BY_ID                                | true |
| PROFIT_SHARING_POOLS_GET_POOL_SETTINGS_BY_ID                       | true |
| PROFIT_SHARING_POOLS_GET_POOLS                                     | true |
| PROFIT_SHARING_POOLS_UPDATE_POOL                                   | false |
| PROFIT_SHARING_POOLS_UPDATE_POOL_SETTINGS                          | false |
| PROFIT_SHARING_PRODUCT_SETTINGS_CREATE_PRODUCT_SETTINGS            | false |
| PROFIT_SHARING_PRODUCT_SETTINGS_GET_PRODUCT_SETTINGS_BY_ID         | true |
| PROFIT_SHARING_PRODUCT_SETTINGS_SEARCH_PRODUCT_SETTINGS            | true |
| PROFIT_SHARING_PRODUCT_SETTINGS_UPDATE_PRODUCT_SETTINGS            | false |
| PROFIT_SHARING_PROPOSALS_FIND_PROPOSAL_ACCOUNT_DETAILS             | true |
| PROFIT_SHARING_PROPOSALS_FIND_PROPOSALS                            | true |
| SETUP_GENERAL_GET_GENERAL_SETUP                                    | true |
| SETUP_ORGANIZATION_GET_ORGANIZATION_SETUP                          | true |
| SETUP_ORGANIZATION_UPDATE_ORGANIZATION_SETUP                       | false |
| TASKS_CREATE                                                       | false |
| TASKS_DELETE                                                       | false |
| TASKS_GET_BY_ID                                                    | true |
| TASKS_LIST                                                         | true |
| TASKS_PATCH                                                        | false |
| TASKS_UPDATE                                                       | false |
| TEMPLATES_CREATE_TEMPLATE                                          | false |
| TEMPLATES_DELETE                                                   | false |
| TEMPLATES_GET_BY_TEMPLATE_ID                                       | true |
| TEMPLATES_UPDATE_TEMPLATE                                          | false |
| USER_ROLES_CREATE                                                  | false |
| USER_ROLES_DELETE                                                  | false |
| USER_ROLES_GET_BY_ID                                               | true |
| USER_ROLES_LIST                                                    | true |
| USER_ROLES_PATCH                                                   | false |
| USER_ROLES_UPDATE                                                  | false |
| USERS_CREATE                                                       | false |
| USERS_DELETE                                                       | false |
| USERS_GET_BY_ID                                                    | true |
| USERS_LIST                                                         | true |
| USERS_PATCH                                                        | false |
| USERS_UPDATE                                                       | false |


## Running as a Server
By default, the mmcp application does not start a server. If you want to start an SSE and streamable http server, you can pass in the parmater:

    mmcp -Dquarkus.http.host-enabled=true

The server will then listen on port 8080.
## Troubleshooting

### Server Won't Start

*   Verify `mmcp` is in your PATH or use the full path to the executable
*   Check that all three environment variables are set in your MCP client configuration
*   Ensure your Mambu credentials are correct

### Authentication Errors

*   Verify your `MAMBU_BASE_URL` includes `/api` at the end
*   Check that your username and password are correct
*   Ensure your Mambu user has API access permissions

### Connection Issues

*   Verify network connectivity to your Mambu instance
*   Check if your Mambu instance requires VPN or IP whitelisting
*   Review your MCP client logs for detailed error messages

### Getting Help

*   Check the [GitHub Issues](https://github.com/mambu/mmcp-server/issues) for known problems
*   Review MCP client documentation for client-specific configuration
*   Enable debug logging (see Developer Guide)



## Uninstallation MMCP

To remove MMCP:

```bash
brew uninstall mmcp
brew untap mambu-gmbh/mmcp-brew
```

## License

This Homebrew tap is maintained by Mambu Tech B.V..
