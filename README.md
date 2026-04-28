# Splunk AppDynamics Smart Agent Management with Jenkins

[![Jenkins](https://img.shields.io/badge/Jenkins-D24939?style=flat&logo=jenkins&logoColor=white)](https://www.jenkins.io/)
[![AWS](https://img.shields.io/badge/AWS-232F3E?style=flat&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![AppDynamics](https://img.shields.io/badge/AppDynamics-0078D4?style=flat)](https://www.appdynamics.com/)

Automated deployment and lifecycle management of AppDynamics Smart Agent across multiple EC2 hosts using Jenkins pipelines.

## 🎯 Overview

This lab demonstrates how to use Jenkins to manage AppDynamics Smart Agent across multiple Ubuntu EC2 instances within a single AWS VPC. The project includes 4 parameterized pipelines covering the complete Smart Agent lifecycle, including installation of Machine and Database agents.

**Key Features:**
- 🚀 **Parallel Deployment** - Deploy to multiple hosts simultaneously
- 🔄 **Complete Lifecycle Management** - Install, uninstall, stop, and clean agents
- 🏗️ **Infrastructure as Code** - All pipelines version-controlled
- 🔐 **Secure** - SSH key-based authentication via Jenkins credentials
- 📈 **Massively Scalable** - Deploy to thousands of hosts with automatic batching
- 🎛️ **Jenkins Agent** - Executes within your AWS VPC

## 📊 Architecture

All infrastructure runs in a single AWS VPC with a shared security group. The Jenkins agent communicates with target hosts via private IPs.

## 🚀 Quick Start

### Prerequisites
- Jenkins server (2.300+)
- Jenkins agent in the same VPC as target EC2 instances
- SSH key pair for authentication
- AppDynamics Smart Agent package and config
- Required Jenkins plugins:
  - Pipeline
  - SSH Agent Plugin
  - Credentials Plugin
  - Git Plugin

### 1️⃣ Clone and Configure

```bash
git clone <your-repo-url>
cd jenkins-sm-lab
```

### 2️⃣ Set Up Jenkins Credentials

Navigate to: **Manage Jenkins → Credentials → System → Global credentials**

**Required Credentials:**
- **SSH_PRIVATE_KEY** (SSH Username with private key)
  - Kind: SSH Username with private key
  - ID: `ssh-private-key`
  - Username: `ubuntu` (or your SSH user)
  - Private Key: Enter directly or from file
  
- **DEPLOYMENT_HOSTS** (Secret text)
  - Kind: Secret text
  - ID: `deployment-hosts`
  - Secret: Newline-separated list of IPs:
    ```
    172.31.1.243
    172.31.1.48
    172.31.1.5
    ```

**Optional Credentials:**
- **ACCOUNT_ACCESS_KEY** (Secret text)
  - Kind: Secret text
  - ID: `account-access-key`
  - Secret: Your AppDynamics account access key

- **DB_MONITOR_PASSWORD** (Secret text)
  - Kind: Secret text
  - ID: `db-monitor-password`
  - Secret: Database monitoring password for the Database Agent pipeline

- **SF_API_TOKEN** (Secret text)
  - Kind: Secret text
  - ID: `sf-api-token`
  - Secret: Token sent as `X-SF-Token` for Client Inventory API checks

### 3️⃣ Configure Jenkins Parameters

All pipelines accept these shared parameters:
- `BATCH_SIZE` - Number of hosts processed in parallel per batch (default: 25, max: 256)
- `REMOTE_INSTALL_DIR` - Smart Agent directory on target hosts (must stay under `/opt/appdynamics/`)
- `SSH_PORT` - SSH port (default: 22)
- `API_CHECK_ENABLED` - Run the Client Inventory API check after the host summary (default: true)
- `API_BASE_URL` - Client Inventory API base URL (default: `https://fso-tme.saas.appdynamics.com/fm-service/v1`)
- `API_TOKEN_CREDENTIAL_ID` - Secret Text credential for `X-SF-Token` (default: `sf-api-token`)

Deploy and install pipelines also accept:
- `APPD_USER` - User for Smart Agent or installed agent service (default: ubuntu)
- `APPD_GROUP` - Group for Smart Agent or installed agent service (default: ubuntu)

The SSH username comes from the `ssh-private-key` credential. There is no separate `SSH_USER` build parameter.


### 4️⃣ Place Smart Agent ZIP in Repository

The deploy pipeline defaults to `SMARTAGENT_ZIP_PATH=appdsmartagent_64_linux_25.10.0.497.zip`, resolved relative to the Jenkins agent workspace. Keep the ZIP in the repository checkout, or override `SMARTAGENT_ZIP_PATH` with an absolute path available on the Jenkins agent.

```bash
# Download Smart Agent to repository root
cd /home/ubuntu/jenkins-sm-lab
curl -o appdsmartagent_64_linux_25.10.0.497.zip "https://download.appdynamics.com/download/prox/download-file/smart-agent/latest/appdsmartagent_64_linux.zip"

# Verify
ls -lh appdsmartagent_64_linux_25.10.0.497.zip
```

**Note**: The Dockerfile also copies this ZIP into the Jenkins controller container at `/var/jenkins_home/smartagent/appdsmartagent.zip`. Use that absolute path only when the pipeline runs on the controller or on an agent with the same mounted path. Jenkins plugins are installed from the tracked `plugins.txt` file. The Docker image does not bake in an admin password; complete the Jenkins first-run setup when the container starts.

### 5️⃣ Create Jenkins Pipelines

For each Jenkinsfile in the `pipelines/` directory:

1. Go to Jenkins Dashboard
2. Click **New Item**
3. Enter item name (e.g., "Deploy-Smart-Agent")
4. Select **Pipeline**
5. Under **Pipeline** section:
   - Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: Your repository URL
   - Script Path: matching Jenkinsfile path, such as `pipelines/Jenkinsfile.deploy`
6. Save

Repeat for all pipelines (Jenkinsfile.install-machine-agent, Jenkinsfile.install-db-agent, Jenkinsfile.cleanup).

### 6️⃣ Deploy!

**Via Jenkins UI:**
1. Go to your pipeline (e.g., "Deploy-Smart-Agent")
2. Click **Build with Parameters**
3. Adjust parameters if needed
4. Click **Build**

**Via Jenkins CLI:**
```bash
java -jar jenkins-cli.jar -s http://your-jenkins:8080/ build "Deploy-Smart-Agent" \
  -p BATCH_SIZE=25
```

## 📋 Available Pipelines

### Deployment (1 pipeline)
| Pipeline | Description | File |
|----------|-------------|------|
| **01. Deploy Smart Agent** | Installs Smart Agent and starts service | `Jenkinsfile.deploy` |

### Agent Installation (2 pipelines)
| Pipeline | Description | File |
|----------|-------------|------|
| **02. Install Machine Agent** | Installs Machine Agent via smartagentctl | `Jenkinsfile.install-machine-agent` |
| **03. Install Database Agent** | Installs Database Agent via smartagentctl | `Jenkinsfile.install-db-agent` |

### Smart Agent Management (1 pipeline)
| Pipeline | Description | File |
|----------|-------------|------|
| **04. Cleanup All Agents** | Deletes the validated `REMOTE_INSTALL_DIR` | `Jenkinsfile.cleanup` |

**Total: 4 pipelines** - All support configurable batch sizes (default: 25, max: 256)

## 🛠️ How It Works

1. **Developer** triggers a Jenkins pipeline manually or via webhook
2. **Jenkins** assigns job to agent in AWS VPC
3. **Pipeline** loads target hosts from Jenkins credentials
4. **Batching Logic** splits hosts into manageable batches
5. **Parallel Execution** - Pipeline SSHs into each target host simultaneously within batch
6. **Commands Execute** - Install/uninstall/stop/clean operations run on each host
7. **Results Reported** - Success/failure status displayed in Jenkins console
8. **API Checked** - Pipelines validate `openapi.json` and call `GET /clients` with `X-SF-Token`

## 🔐 Security

- **Private Network** - All communication via VPC private IPs
- **SSH Keys** - Stored securely as Jenkins credentials
- **No Public Access** - Target hosts don't need public IPs
- **Security Group** - Restricts SSH access to Jenkins agent only
- **Credentials Binding** - Secrets never exposed in logs
- **Path Guardrails** - Destructive operations are limited to validated `/opt/appdynamics/...` paths
- **SSH Host Keys** - Pipelines use `StrictHostKeyChecking=accept-new` with workspace known-host files
- **API Token Isolation** - Client Inventory API checks use the dedicated `sf-api-token` credential

## 🔎 Client Inventory API Check

The repo tracks `openapi.json` for the Client Inventory API. All four pipelines run `scripts/check-client-inventory-api.sh` after their host summary when `API_CHECK_ENABLED=true`.

The check verifies:
- `openapi.json` is present and defines `/clients`
- `GET ${API_BASE_URL}/clients?limit=1&offset=0&include_health=false` returns HTTP 2xx
- the response body looks like JSON

Cleanup only checks API reachability and authentication. It does not assert that removed hosts disappear from inventory, because inventory retention timing is API-side behavior.

## 📈 Scaling

All pipelines use automatic batching to support any number of hosts:

### How It Works
- **Automatic batching** - Splits hosts into groups (configurable, default: 25, max: 256)
- **Sequential batch processing** - Avoids overwhelming runner resources
- **Parallel within batch** - Each batch processes all hosts simultaneously through Jenkins `parallel`
- **Works at any scale** - 1 host to thousands

### Batching Strategy
1. Splits your host list into manageable batches
2. Processes each batch sequentially
3. Deploys to all hosts within each batch in parallel using Jenkins `parallel`

**Examples:**
- **10 hosts** = 1 batch, all deploy in parallel
- **100 hosts** = 4 batches × 25 hosts
- **500 hosts** = 20 batches × 25 hosts
- **1,000 hosts** = 40 batches × 25 hosts

## 🎨 Jenkins Pipeline Features

### Declarative Syntax
All pipelines use Jenkins Declarative Pipeline syntax for:
- Better readability
- Built-in error handling
- Easier maintenance
- Post-build actions

### Shared Logic
Common batching and SSH logic is embedded in each pipeline to:
- Simplify deployment
- No external dependencies
- Self-contained pipelines

### Error Handling
Each pipeline includes:
- Per-host error tracking
- Failed host reporting
- Batch-level failure handling
- Always-executed summary stage

## 📚 Documentation

- **[Quick Start](QUICK_START.md)** - Get running in 5 minutes
- **[Setup Guide](SETUP_GUIDE.md)** - Detailed Jenkins configuration instructions
- **[Architecture](ARCHITECTURE.md)** - System diagrams and technical architecture
- **[Project Index](INDEX.md)** - Complete project navigation and reference


## 🤝 Contributing

This is a lab/demo project. Feel free to fork and adapt for your own use cases!

## 🔗 Links

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [AppDynamics Documentation](https://docs.appdynamics.com/)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [SSH Agent Plugin](https://plugins.jenkins.io/ssh-agent/)

---

**Built with ❤️ for AppDynamics automation**
