# Quick Start Guide

Get Jenkins managing AppDynamics Smart Agent from the five pipelines in this repo.

## TL;DR

1. Add Jenkins credentials: `ssh-private-key`, `deployment-hosts`, `account-access-key`
2. Add `sf-api-token` for Client Inventory API checks
3. For Database Agent installs, also add `db-monitor-password`
4. Place `appdsmartagent_64_linux_25.10.0.497.zip` where the Jenkins agent can read it; the default is the repo workspace
5. Create Jenkins Pipeline jobs from the five files in `pipelines/`
6. Run `Deploy-Smart-Agent`, then install optional agents or run cleanup as needed

## Minimum Setup

### 1. Add Credentials

**Jenkins -> Manage Jenkins -> Credentials -> Global**

| Type | ID | Content |
|------|----|---------|
| SSH Username with private key | `ssh-private-key` | SSH user and private key for target hosts |
| Secret text | `deployment-hosts` | Target hosts, one per line |
| Secret text | `account-access-key` | AppDynamics access key |
| Secret text | `sf-api-token` | Token for `X-SF-Token` Client Inventory API checks |
| Secret text | `db-monitor-password` | Database monitoring password, only needed for DB Agent |

The SSH username comes from the `ssh-private-key` credential. There is no separate `SSH_USER` parameter.

### 2. Place Smart Agent ZIP

```bash
cd /home/ubuntu/jenkins-sm-lab
curl -o appdsmartagent_64_linux_25.10.0.497.zip "https://download.appdynamics.com/download/prox/download-file/smart-agent/latest/appdsmartagent_64_linux.zip"
```

The deploy pipeline defaults to `SMARTAGENT_ZIP_PATH=appdsmartagent_64_linux_25.10.0.497.zip`, resolved relative to the Jenkins agent workspace. The Dockerfile also copies the ZIP into the Jenkins controller container at `/var/jenkins_home/smartagent/appdsmartagent.zip`; use that path only if the job runs on the controller or an agent with the same mounted path.

### 3. Build Jenkins Image

```bash
docker build -t sm-jenkins .
```

The image installs plugins from `plugins.txt`. Jenkins first-run setup is left enabled; use the initial admin password shown by Jenkins when the container starts.

### 4. Create Pipeline Jobs

Create one Pipeline job per file:

| Job name | Script path |
|----------|-------------|
| `Deploy-Smart-Agent` | `pipelines/Jenkinsfile.deploy` |
| `Install-AppDynamics-Agent` | `pipelines/Jenkinsfile.install-appd-agent` |
| `Install-Machine-Agent` | `pipelines/Jenkinsfile.install-machine-agent` |
| `Install-DB-Agent` | `pipelines/Jenkinsfile.install-db-agent` |
| `Cleanup-All-Agents` | `pipelines/Jenkinsfile.cleanup` |

Use **Pipeline script from SCM**, point Jenkins at this repository, and set the script path from the table.

## Common Runs

### Deploy Smart Agent

```text
Pipeline: Deploy-Smart-Agent
Parameters: defaults, or set BATCH_SIZE=1 for the first smoke test
```

### Install Machine Agent

```text
Pipeline: Install-Machine-Agent
Parameters: set TIER_NAME/NODE_NAME only if needed
```

### Install Database Agent

```text
Pipeline: Install-DB-Agent
Parameters: DB_HOST, DB_PORT, DB_TYPE, DB_USERNAME, DB_PASSWORD_CREDENTIAL_ID
Default password credential: db-monitor-password
```

### Complete Cleanup

```text
Pipeline: Cleanup-All-Agents
Parameters: CONFIRM_CLEANUP=true
Warning: this deletes REMOTE_INSTALL_DIR on every target host.
```

## Shared Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `BATCH_SIZE` | `25` | Hosts processed in parallel per batch, 1-256 |
| `REMOTE_INSTALL_DIR` | `/opt/appdynamics/appdsmartagent` | Remote Smart Agent directory |
| `SSH_PORT` | `22` | SSH port |
| `APPD_USER` | `ubuntu` | Service user for deploy/install pipelines |
| `APPD_GROUP` | `ubuntu` | Service group for deploy/install pipelines |
| `API_CHECK_ENABLED` | `true` | Run the Client Inventory API check after the host summary |
| `API_BASE_URL` | `https://fso-tme.saas.appdynamics.com/fm-service/v1` | Client Inventory API base URL |
| `API_TOKEN_CREDENTIAL_ID` | `sf-api-token` | Secret Text credential used as `X-SF-Token` |

`REMOTE_INSTALL_DIR` must stay under `/opt/appdynamics/`; cleanup and redeploy refuse broader paths.

The API check uses `openapi.json` and calls `GET /clients?limit=1&offset=0&include_health=false`. Cleanup checks API reachability/authentication only; it does not assert inventory deletion timing.

## Quick Checks

```bash
ssh ubuntu@<host> "cd /opt/appdynamics/appdsmartagent && sudo ./smartagentctl status"
ssh ubuntu@<host> "cd /opt/appdynamics/appdsmartagent && sudo ./smartagentctl list"
ssh ubuntu@<host> "sudo tail -f /opt/appdynamics/appdsmartagent/logs/*"
```

## Jenkins CLI Example

```bash
java -jar jenkins-cli.jar -s http://your-jenkins:8080/ \
  -auth admin:token \
  build "Deploy-Smart-Agent" \
  -p BATCH_SIZE=25
```

## Common Errors

| Error | Fix |
|-------|-----|
| "No agent available" | Check the Jenkins agent is online and labeled `linux` |
| "Credential not found" | Verify credential IDs match exactly |
| "SSH connection failed" | Check security groups and private network routing |
| "Permission denied" | Verify SSH user and passwordless sudo on target hosts |
| "No hosts provided" | Check `deployment-hosts` credential format |
