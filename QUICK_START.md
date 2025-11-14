# Quick Start Guide

Get up and running with Jenkins AppDynamics Smart Agent management in minutes.

## TL;DR

1. **Setup Jenkins credentials** with IDs: `ssh-private-key`, `deployment-hosts`, `account-access-key`
2. **Place Smart Agent ZIP** in repository root (copied into Jenkins container during build)
3. **Create pipelines** from `pipelines/Jenkinsfile.deploy and pipelines/Jenkinsfile.cleanup`
4. **Run** → Build with Parameters

## Minimum Setup (5 minutes)

### 1. Add Credentials

**Jenkins → Manage Jenkins → Credentials → Global**

| Type | ID | Content |
|------|-----|---------|
| SSH Username with private key | `ssh-private-key` | Your PEM file |
| Secret text | `deployment-hosts` | IPs (one per line) |
| Secret text | `account-access-key` | AppD access key |


### 2. Place Smart Agent ZIP in Repository

Download the Smart Agent ZIP to the repository root:

```bash
cd /home/ubuntu/jenkins-sm-lab
curl -o appdsmartagent_64_linux_25.10.0.497.zip "https://download.appdynamics.com/download/prox/download-file/smart-agent/latest/appdsmartagent_64_linux.zip"
```

**What happens**: The Dockerfile copies this ZIP into the Jenkins container at `/var/jenkins_home/smartagent/appdsmartagent.zip` during the Docker build.

### 3. Create First Pipeline

1. **New Item** → Name: `Deploy-Smart-Agent` → **Pipeline**
2. **Pipeline** section:
   - Definition: `Pipeline script from SCM`
   - Repository URL: Your repo
   - Script Path: `pipelines/Jenkinsfile.deploy`
3. **Save**

### 4. Run It

1. Click **Build with Parameters**
2. Accept defaults (or adjust batch size)
3. **Build**

## Common Tasks

### Deploy Smart Agent to All Hosts
```
Pipeline: Deploy-Smart-Agent
Parameters: Default (batch_size=256)
```

### Complete Cleanup
```
Pipeline: Cleanup-All-Agents
Parameters: CONFIRM_CLEANUP=true
⚠️ Warning: This deletes /opt/appdynamics directory!
```
## Pipeline Parameters

All pipelines accept:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `BATCH_SIZE` | `256` | Hosts per batch |
| `SSH_USER` | `ubuntu` | SSH username |
| `SMARTAGENT_USER` | _(empty)_ | Service user (deploy only) |
| `SMARTAGENT_GROUP` | _(empty)_ | Service group (deploy only) |

## Credential IDs (Must Match Exactly)

```
ssh-private-key       # SSH key for targets
deployment-hosts      # Newline-separated IPs
account-access-key    # AppDynamics access key
```

## Troubleshooting One-Liners

### Test SSH from Jenkins agent
```bash
ssh -i /path/to/key ubuntu@172.31.1.243 "echo SUCCESS"
```

### Check agent label
```
Manage Jenkins → Nodes → [Your Agent] → Check label is "linux"
```

### Verify credentials exist
```
Manage Jenkins → Credentials → Check IDs match exactly
```

### View pipeline workspace
```bash
# On Jenkins agent machine
ls /path/to/jenkins/workspace/Deploy-Smart-Agent/
```

## Pipeline Execution Order (Typical Workflow)

```
1. Deploy-Smart-Agent          # Initial deployment
2. 02-Install-Machine-Agent       # Install agents as needed
3. 03-Install-Java-Agent
4. Deploy-Smart-Agent
5. 05-Install-DB-Agent
   
   ... (use as needed) ...

6. Cleanup-All-Agents       # Maintenance/troubleshooting
7. 07-09-10 Uninstall-*-Agent     # Remove specific agents
8. Cleanup-All-Agents          # Complete removal
```

## File Locations (On Target Hosts)

```
/opt/appdynamics/appdsmartagent/           # Smart Agent directory
/opt/appdynamics/appdsmartagent/config.ini # Configuration
/tmp/appdsmartagent_64_linux_*.zip         # Uploaded package
```

## Quick Checks

### Is Smart Agent running?
```bash
ssh ubuntu@<host> "cd /opt/appdynamics/appdsmartagent && sudo ./smartagentctl status"
```

### List installed agents?
```bash
ssh ubuntu@<host> "cd /opt/appdynamics/appdsmartagent && sudo ./smartagentctl list"
```

### Check logs?
```bash
ssh ubuntu@<host> "sudo tail -f /opt/appdynamics/appdsmartagent/logs/*"
```

## Jenkins CLI Usage

Install Jenkins CLI:
```bash
wget http://your-jenkins:8080/jnlpJars/jenkins-cli.jar
```

Trigger build:
```bash
java -jar jenkins-cli.jar -s http://your-jenkins:8080/ \
  -auth admin:token \
  build "Deploy-Smart-Agent" \
  -p BATCH_SIZE=128 \
  -p SSH_USER=ubuntu
```

## Security Checklist

- [ ] SSH keys stored as Jenkins credentials (not in code)
- [ ] Deployment hosts not hardcoded
- [ ] Jenkins agent in same VPC as targets
- [ ] Security groups allow SSH from agent only
- [ ] Target hosts have sudoers configured
- [ ] Credentials scope set to Global

## Getting More Help

- **Detailed Setup**: [SETUP_GUIDE.md](SETUP_GUIDE.md)
- **Full README**: [README.md](README.md)
- **Pipeline Details**: Each `.jenkinsfile` has comments
- **Jenkins Console**: Build → Console Output

## Common Errors & Fixes

| Error | Fix |
|-------|-----|
| "No agent available" | Check agent is online and labeled `linux` |
| "Credential not found" | Verify credential IDs match exactly |
| "SSH connection failed" | Check security groups and network connectivity |
| "Permission denied" | Verify sudo access on target hosts |
| "No hosts provided" | Check `deployment-hosts` credential format |

## Example: Full Deployment Workflow

```bash
# 1. Deploy Smart Agent
Build: Deploy-Smart-Agent (default params)
Wait: ✅ Success

# 2. Install Node.js agent on all hosts
Build: Deploy-Smart-Agent (default params)
Wait: ✅ Success

# 3. Verify on one host
ssh ubuntu@172.31.1.243
cd /opt/appdynamics/appdsmartagent
sudo ./smartagentctl status
# Should show: Smart Agent is running
# Should show: node agent installed

# 4. Later, to remove:
Build: 09-Uninstall-Node-Agent
Build: Cleanup-All-Agents
```

---

**Ready?** Start with pipeline `Deploy-Smart-Agent`!
