# Jenkins Setup Guide

Complete step-by-step guide to configure Jenkins for AppDynamics Smart Agent management.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Jenkins Configuration](#jenkins-configuration)
- [Credentials Setup](#credentials-setup)
- [Pipeline Creation](#pipeline-creation)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### System Requirements
- **Jenkins Server**: Version 2.300 or later
- **Jenkins Agent**: Linux-based agent in AWS VPC (same network as target EC2 instances)
- **Target Hosts**: Ubuntu EC2 instances with SSH access
- **Network**: All hosts in same VPC with appropriate security groups

### Required Jenkins Plugins

Install these plugins via **Manage Jenkins → Plugins**:

1. **Pipeline** (core plugin, usually pre-installed)
2. **SSH Agent Plugin**
   - Install: `Manage Jenkins → Plugins → Available → Search "SSH Agent"`
3. **Credentials Plugin** (usually pre-installed)
4. **Git Plugin** (if using SCM)

## Jenkins Configuration

### 1. Configure Jenkins Agent

Your Jenkins agent must be able to reach target EC2 instances via private IPs.

**Option A: EC2 Instance as Agent**
1. Launch EC2 instance in same VPC
2. Install Java (required by Jenkins)
   ```bash
   sudo apt-get update
   sudo apt-get install -y openjdk-11-jdk
   ```
3. Add agent in Jenkins:
   - Go to **Manage Jenkins → Nodes → New Node**
   - Name: `aws-vpc-agent` (or your preferred name)
   - Type: Permanent Agent
   - Remote root directory: `/home/ubuntu/jenkins`
   - Labels: `linux` (must match pipeline agent label)
   - Launch method: Launch agent via SSH
   - Host: EC2 private IP
   - Credentials: Add SSH credentials for agent

**Option B: Use Existing Linux Agent**
- Ensure agent has label `linux`
- Verify network connectivity to target hosts

### 2. Configure Agent Labels

All pipelines use the `linux` label. To modify:
1. Go to **Manage Jenkins → Nodes**
2. Click on your agent
3. Configure → Labels: `linux`
4. Save

## Credentials Setup

### Required Credentials

Navigate to: **Manage Jenkins → Credentials → System → Global credentials (unrestricted)**

#### 1. SSH Private Key for Target Hosts

**Type**: SSH Username with private key

- **ID**: `ssh-private-key` (must match exactly)
- **Description**: `SSH key for EC2 target hosts`
- **Username**: `ubuntu` (or your SSH user)
- **Private Key**: Choose one:
  - **Enter directly**: Paste your PEM file content
  - **From file**: Upload PEM file
  - **From Jenkins master**: Specify path

**Example**:
```
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA...
...
-----END RSA PRIVATE KEY-----
```

#### 2. Deployment Hosts List

**Type**: Secret text

- **ID**: `deployment-hosts` (must match exactly)
- **Description**: `List of target EC2 host IPs`
- **Secret**: Enter newline-separated IPs

**Example**:
```
172.31.1.243
172.31.1.48
172.31.1.5
172.31.10.20
172.31.10.21
```

**Important**: One IP per line, no commas, no spaces, no extra characters.

#### 3. AppDynamics Account Access Key (Optional)

**Type**: Secret text

- **ID**: `account-access-key` (must match exactly)
- **Description**: `AppDynamics account access key`
- **Secret**: Your AppDynamics access key

**Example**: `abcd1234-ef56-7890-gh12-ijklmnopqrst`

### Credential Security Best Practices

- Use Jenkins credential encryption (built-in)
- Restrict access via Jenkins role-based authorization
- Rotate SSH keys periodically
- Use least-privilege IAM roles for EC2 instances

## Smart Agent Package Setup

Before building the Jenkins container, you need the AppDynamics Smart Agent ZIP in the repository root.

### Download Smart Agent

1. **Navigate to repository root**:
   ```bash
   cd /home/ubuntu/jenkins-sm-lab
   ```

2. **Download the Smart Agent ZIP**:
   ```bash
   # Download from AppDynamics
   curl -o appdsmartagent_64_linux_25.10.0.497.zip "https://download.appdynamics.com/download/prox/download-file/smart-agent/latest/appdsmartagent_64_linux.zip"
   
   # Or transfer from another machine
   scp appdsmartagent_64_linux_*.zip ubuntu@<server-ip>:~/jenkins-sm-lab/
   ```

3. **Verify the download**:
   ```bash
   ls -lh appdsmartagent_64_linux_25.10.0.497.zip
   ```

### How It Works

The Dockerfile copies the ZIP file into the Jenkins container during the Docker build:
```dockerfile
COPY appdsmartagent_64_linux_25.10.0.497.zip /var/jenkins_home/smartagent/appdsmartagent.zip
```

The deploy pipeline reads it from `/var/jenkins_home/smartagent/appdsmartagent.zip` (inside the Jenkins container) and deploys it to target hosts.


## Pipeline Creation


## Pipeline Creation

### Method 1: Pipeline from SCM (Recommended)

For each of the 11 pipelines:

1. **Create New Item**
   - Go to Jenkins Dashboard
   - Click **New Item**
   - Enter name: `01-Deploy-Smart-Agent`
   - Select: **Pipeline**
   - Click **OK**

2. **Configure Pipeline**
   - **Description**: `Deploys AppDynamics Smart Agent to multiple hosts`
   - **Build Triggers**: Leave unchecked (manual only)
   - **Pipeline**:
     - Definition: `Pipeline script from SCM`
     - SCM: `Git`
     - Repository URL: `https://github.com/your-org/jenkins-sm-lab.git`
     - Credentials: Add if private repo
     - Branch: `*/main` or `*/master`
     - Script Path: `pipelines/01-deploy-smart-agent.jenkinsfile`

3. **Save**

4. **Repeat** for all 11 pipelines with appropriate names and script paths

### Method 2: Direct Pipeline Script

1. **Create New Item** (same as above)
2. **Configure Pipeline**
   - **Pipeline**:
     - Definition: `Pipeline script`
     - Script: Copy/paste content from Jenkinsfile
3. **Save**

### Pipeline Naming Convention

Recommended naming for clarity:
```
01-Deploy-Smart-Agent
02-Install-Machine-Agent
03-Install-Java-Agent
04-Install-Node-Agent
05-Install-DB-Agent
06-Stop-Clean-SmartAgent
07-Uninstall-Machine-Agent
08-Uninstall-Java-Agent
09-Uninstall-Node-Agent
10-Uninstall-DB-Agent
11-Cleanup-All-Agents
```

## Testing

### 1. Test Credentials

Before running pipelines, verify credentials work:

```groovy
// Test pipeline
pipeline {
    agent { label 'linux' }
    stages {
        stage('Test SSH') {
            steps {
                withCredentials([
                    sshUserPrivateKey(credentialsId: 'ssh-private-key', keyFileVariable: 'SSH_KEY'),
                    string(credentialsId: 'deployment-hosts', variable: 'HOSTS')
                ]) {
                    sh '''
                        echo "Testing SSH credentials..."
                        echo "$HOSTS" | head -1 | while read HOST; do
                            ssh -i $SSH_KEY -o StrictHostKeyChecking=no -o ConnectTimeout=10 ubuntu@$HOST "echo 'Connection successful'"
                        done
                    '''
                }
            }
        }
    }
}
```

### 2. Test with Single Host

Modify `deployment-hosts` credential to contain only one test host initially.

### 3. Run Deployment Pipeline

1. Go to **01-Deploy-Smart-Agent** pipeline
2. Click **Build with Parameters**
3. Parameters:
   - `BATCH_SIZE`: `1` (for testing)
   - `SSH_USER`: `ubuntu`
   - Leave others default
4. Click **Build**
5. Monitor console output

### 4. Verify Deployment

SSH into target host:
```bash
ssh ubuntu@172.31.1.243
cd /opt/appdynamics/appdsmartagent
sudo ./smartagentctl status
```

## Troubleshooting

### Common Issues

#### 1. "No agent available" Error

**Cause**: Jenkins agent not configured or offline

**Solution**:
- Check: **Manage Jenkins → Nodes**
- Ensure agent is online
- Verify agent has `linux` label
- Test agent connectivity

#### 2. SSH Connection Failures

**Cause**: Wrong credentials, network issues, or security group restrictions

**Solution**:
```bash
# Test from Jenkins agent
ssh -i /path/to/key ubuntu@172.31.1.243 -o ConnectTimeout=10

# Check security group allows SSH from agent
# Verify private key matches public key on target
```

#### 3. "Credential not found" Error

**Cause**: Credential ID mismatch

**Solution**:
- Verify credential IDs exactly match:
  - `ssh-private-key`
  - `deployment-hosts`
  - `account-access-key`
- Check credential scope is `Global`

#### 4. Permission Denied on Target Hosts

**Cause**: SSH user lacks sudo permissions

**Solution**:
```bash
# On target host, verify user is in sudoers
sudo visudo
# Add line:
ubuntu ALL=(ALL) NOPASSWD: ALL
```

#### 5. Pipeline Fails at "Prepare" Stage

**Cause**: Host list format incorrect

**Solution**:
- Check `deployment-hosts` credential
- Ensure one IP per line
- No trailing spaces or empty lines
- Use Unix line endings (LF, not CRLF)

### Debug Tips

#### Enable Verbose SSH Output

Modify pipeline temporarily:
```groovy
ssh -vvv -i ${env.KEY_FILE} ...
```

#### Check Jenkins System Log

**Manage Jenkins → System Log** for credential binding issues

#### View Workspace Files

During pipeline run, SSH to Jenkins agent:
```bash
cd /path/to/jenkins/workspace/01-Deploy-Smart-Agent
cat all_hosts.txt
cat batch_info.txt
```

### Getting Help

- **Jenkins Logs**: `Manage Jenkins → System Log`
- **Build Console Output**: Click build number → Console Output
- **Agent Logs**: Check agent machine `/var/log/jenkins/`

## Advanced Configuration

### Custom Agent Labels

If using different agent label:
1. Update all Jenkinsfiles: `agent { label 'your-label' }`
2. Or use environment variable in Jenkins configuration

### Parallel Execution Limits

To limit concurrent SSH connections per batch, modify pipeline:
```groovy
// Add semaphore or throttle
```

### Multi-Region Deployment

Create separate credential sets for different regions/VPCs:
- `deployment-hosts-us-east-1`
- `deployment-hosts-us-west-2`

Duplicate pipelines for each region.

### Integration with Jenkins Folders

Organize pipelines in folders:
```
AppDynamics/
  ├── Deployment/
  │   └── 01-Deploy-Smart-Agent
  ├── Installation/
  │   ├── 02-Install-Machine-Agent
  │   ├── 03-Install-Java-Agent
  │   └── ...
  └── Cleanup/
      └── 11-Cleanup-All-Agents
```

## Next Steps

- Review [Architecture Documentation](ARCHITECTURE.md)
- See [Pipeline Reference](PIPELINE_REFERENCE.md)
- Customize pipelines for your environment
- Set up monitoring/alerting on pipeline failures

---

**Questions?** Check the main [README.md](README.md) for additional resources.
