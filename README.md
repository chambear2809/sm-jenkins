# AppDynamics Smart Agent Management with Jenkins

[![Jenkins](https://img.shields.io/badge/Jenkins-D24939?style=flat&logo=jenkins&logoColor=white)](https://www.jenkins.io/)
[![AWS](https://img.shields.io/badge/AWS-232F3E?style=flat&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![AppDynamics](https://img.shields.io/badge/AppDynamics-0078D4?style=flat)](https://www.appdynamics.com/)

Automated deployment and lifecycle management of AppDynamics Smart Agent across multiple EC2 hosts using Jenkins pipelines.

## 🎯 Overview

This lab demonstrates how to use Jenkins to manage AppDynamics Smart Agent and various AppDynamics agents (Node, Machine, DB, Java) across multiple Ubuntu EC2 instances within a single AWS VPC. The project includes 11 parameterized pipelines covering the complete agent lifecycle.

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

### 3️⃣ Configure Jenkins Parameters

Each pipeline accepts these parameters:
- `BATCH_SIZE` - Number of hosts per batch (default: 256)
- `SSH_USER` - SSH username (default: ubuntu)
- `SMARTAGENT_USER` - User for Smart Agent service (optional)
- `SMARTAGENT_GROUP` - Group for Smart Agent service (optional)


### 4️⃣ Download Smart Agent Package

Download the AppDynamics Smart Agent to your Jenkins agent:

```bash
# SSH into Jenkins agent
ssh ubuntu@<jenkins-agent-ip>

# Create directory
sudo mkdir -p /var/jenkins_home/smartagent
sudo chown jenkins:jenkins /var/jenkins_home/smartagent

# Download Smart Agent
cd /var/jenkins_home/smartagent
curl -o appdsmartagent.zip "https://download.appdynamics.com/download/prox/download-file/smart-agent/latest/appdsmartagent_64_linux.zip"

# Or transfer from local machine
# scp appdsmartagent_64_linux_*.zip ubuntu@<jenkins-agent-ip>:/var/jenkins_home/smartagent/appdsmartagent.zip

# Verify
ls -lh appdsmartagent.zip
```

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
   - Script Path: `pipelines/01-deploy-smart-agent.jenkinsfile`
6. Save

Repeat for all 11 pipelines.

### 6️⃣ Deploy!

**Via Jenkins UI:**
1. Go to your pipeline (e.g., "Deploy-Smart-Agent")
2. Click **Build with Parameters**
3. Adjust parameters if needed
4. Click **Build**

**Via Jenkins CLI:**
```bash
java -jar jenkins-cli.jar -s http://your-jenkins:8080/ build "Deploy-Smart-Agent" \
  -p BATCH_SIZE=128
```

## 📋 Available Pipelines

### Deployment (1 pipeline)
| Pipeline | Description | File |
|----------|-------------|------|
| **01. Deploy Smart Agent** | Installs Smart Agent and starts service | `01-deploy-smart-agent.jenkinsfile` |

### Agent Installation (4 pipelines)
| Pipeline | Command | File |
|----------|---------|------|
| **02. Install Machine Agent** | `smartagentctl install machine` | `02-install-machine-agent.jenkinsfile` |
| **03. Install Java Agent** | `smartagentctl install java` | `03-install-java-agent.jenkinsfile` |
| **04. Install Node Agent** | `smartagentctl install node` | `04-install-node-agent.jenkinsfile` |
| **05. Install Database Agent** | `smartagentctl install db` | `05-install-db-agent.jenkinsfile` |

### Smart Agent Management (2 pipelines)
| Pipeline | Description | File |
|----------|-------------|------|
| **06. Stop and Clean Smart Agent** | Stops service and purges data | `06-stop-clean-smartagent.jenkinsfile` |
| **11. Cleanup All Agents** | Deletes /opt/appdynamics directory | `11-cleanup-all-agents.jenkinsfile` |

### Agent Uninstallation (4 pipelines)
| Pipeline | Command | File |
|----------|---------|------|
| **07. Uninstall Machine Agent** | `smartagentctl uninstall machine` | `07-uninstall-machine-agent.jenkinsfile` |
| **08. Uninstall Java Agent** | `smartagentctl uninstall java` | `08-uninstall-java-agent.jenkinsfile` |
| **09. Uninstall Node Agent** | `smartagentctl uninstall node` | `09-uninstall-node-agent.jenkinsfile` |
| **10. Uninstall Database Agent** | `smartagentctl uninstall db` | `10-uninstall-db-agent.jenkinsfile` |

**Total: 11 pipelines** - All support configurable batch sizes (default: 256)

## 🛠️ How It Works

1. **Developer** triggers a Jenkins pipeline manually or via webhook
2. **Jenkins** assigns job to agent in AWS VPC
3. **Pipeline** loads target hosts from Jenkins credentials
4. **Batching Logic** splits hosts into manageable batches
5. **Parallel Execution** - Pipeline SSHs into each target host simultaneously within batch
6. **Commands Execute** - Install/uninstall/stop/clean operations run on each host
7. **Results Reported** - Success/failure status displayed in Jenkins console

## 🔐 Security

- **Private Network** - All communication via VPC private IPs
- **SSH Keys** - Stored securely as Jenkins credentials
- **No Public Access** - Target hosts don't need public IPs
- **Security Group** - Restricts SSH access to Jenkins agent only
- **Credentials Binding** - Secrets never exposed in logs

## 📈 Scaling

All pipelines use automatic batching to support any number of hosts:

### How It Works
- **Automatic batching** - Splits hosts into groups (configurable, default: 256)
- **Sequential batch processing** - Avoids overwhelming runner resources
- **Parallel within batch** - Each batch processes all hosts simultaneously
- **Works at any scale** - 1 host to thousands

### Batching Strategy
1. Splits your host list into manageable batches
2. Processes each batch sequentially
3. Deploys to all hosts within each batch in parallel using background processes

**Examples:**
- **10 hosts** = 1 batch, all deploy in parallel
- **500 hosts** = 2 batches × 256 hosts
- **1,000 hosts** = 4 batches × 256 hosts
- **5,000 hosts** = 20 batches × 256 hosts

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
- **[Conversion Notes](CONVERSION_NOTES.md)** - GitHub Actions → Jenkins migration guide
- **[Project Index](INDEX.md)** - Complete project navigation and reference

## 🔄 Migration from GitHub Actions

This project is a Jenkins conversion of a GitHub Actions lab. Key differences:

| Feature | GitHub Actions | Jenkins |
|---------|----------------|---------|
| Workflow Definition | YAML | Groovy (Jenkinsfile) |
| Secret Management | GitHub Secrets | Jenkins Credentials |
| Matrix Strategy | Built-in matrix | Custom batching logic |
| Runner/Agent | self-hosted runner | Jenkins agent |
| Trigger | workflow_dispatch | Build with Parameters |

## 🤝 Contributing

This is a lab/demo project. Feel free to fork and adapt for your own use cases!

## 🔗 Links

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [AppDynamics Documentation](https://docs.appdynamics.com/)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [SSH Agent Plugin](https://plugins.jenkins.io/ssh-agent/)

---

**Built with ❤️ for AppDynamics automation**
