# Jenkins Smart Agent Lab - Project Index

Complete reference for the Jenkins-based AppDynamics Smart Agent management lab.

## Project Structure

```text
jenkins-sm-lab/
├── README.md
├── QUICK_START.md
├── SETUP_GUIDE.md
├── ARCHITECTURE.md
├── INDEX.md
├── Dockerfile
├── plugins.txt
├── openapi.json
├── .gitignore
├── scripts/
│   └── check-client-inventory-api.sh
└── pipelines/
    ├── Jenkinsfile.deploy
    ├── Jenkinsfile.install-machine-agent
    ├── Jenkinsfile.install-db-agent
    └── Jenkinsfile.cleanup
```

## Documentation Guide

For first-time setup, start with [QUICK_START.md](QUICK_START.md), then use [SETUP_GUIDE.md](SETUP_GUIDE.md) for the Jenkins details. For system flow and scaling behavior, read [ARCHITECTURE.md](ARCHITECTURE.md).

## Pipeline Reference

| # | Pipeline | File | Description |
|---|----------|------|-------------|
| 01 | Deploy Smart Agent | `Jenkinsfile.deploy` | Extracts, configures, copies, starts, and verifies Smart Agent |
| 02 | Install Machine Agent | `Jenkinsfile.install-machine-agent` | Installs Machine Agent through `smartagentctl` |
| 03 | Install Database Agent | `Jenkinsfile.install-db-agent` | Installs Database Agent through `smartagentctl` |
| 04 | Cleanup All Agents | `Jenkinsfile.cleanup` | Stops Smart Agent and removes `REMOTE_INSTALL_DIR` |

All pipelines use `BATCH_SIZE` with a default of `25` and a maximum of `256`.

## Credentials

| Credential ID | Type | Required? | Used By |
|---------------|------|-----------|---------|
| `ssh-private-key` | SSH Username with private key | Yes | All pipelines |
| `deployment-hosts` | Secret text | Yes | All pipelines |
| `account-access-key` | Secret text | Deploy only | `Jenkinsfile.deploy` |
| `db-monitor-password` | Secret text | DB Agent only by default | `Jenkinsfile.install-db-agent` |
| `sf-api-token` | Secret text | API checks by default | All pipelines |

The DB pipeline accepts `DB_PASSWORD_CREDENTIAL_ID` if you want to use a different Secret Text credential.
All pipelines accept `API_TOKEN_CREDENTIAL_ID` if you want to use a different Client Inventory API token credential.

## Common Workflows

```text
Initial smoke test:
  1. Set deployment-hosts to one target host
  2. Run Deploy-Smart-Agent with BATCH_SIZE=1
  3. Verify smartagentctl status on the target

Batch deployment:
  1. Put all target hosts in deployment-hosts
  2. Run Deploy-Smart-Agent with BATCH_SIZE=25
  3. Increase or decrease BATCH_SIZE based on Jenkins agent/network capacity

Agent install:
  1. Run Deploy-Smart-Agent first
  2. Run Install-Machine-Agent or Install-DB-Agent
  3. Use the Summary stage to identify failed hosts

Cleanup:
  1. Run Cleanup-All-Agents
  2. Set CONFIRM_CLEANUP=true
  3. API check verifies reachability/authentication only
```

## Safety Notes

- `REMOTE_INSTALL_DIR` must be a specific path under `/opt/appdynamics/`.
- SSH host keys use `StrictHostKeyChecking=accept-new` with per-host known-host files in the Jenkins workspace.
- Jenkins admin credentials are not baked into the Docker image; complete the Jenkins first-run setup normally.
- Smart Agent ZIPs remain ignored by git, but `plugins.txt` is tracked because the Dockerfile requires it.
- `openapi.json` defines the Client Inventory API smoke check used by all pipelines.

## Checklist

- [ ] Jenkins server and Linux agent configured
- [ ] Agent has label `linux`
- [ ] Plugins installed from `plugins.txt`
- [ ] Required credentials created with exact IDs
- [ ] Smart Agent ZIP present before Docker build
- [ ] SSH connectivity verified from Jenkins agent
- [ ] `BATCH_SIZE=1` smoke test passed
- [ ] Batch deployment tested with more than one host
