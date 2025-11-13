# Jenkins Smart Agent Lab - Project Index

Complete reference guide for the Jenkins-based AppDynamics Smart Agent management system.

## 📂 Project Structure

```
jenkins-sm-lab/
├── README.md                    # Main project overview and documentation
├── QUICK_START.md               # 5-minute getting started guide
├── SETUP_GUIDE.md              # Detailed Jenkins configuration guide
├── CONVERSION_NOTES.md         # GitHub Actions → Jenkins migration notes
├── INDEX.md                    # This file - project navigation
├── .gitignore                  # Git ignore rules
└── pipelines/                  # All Jenkins pipeline definitions
    ├── 01-deploy-smart-agent.jenkinsfile
    ├── 02-install-machine-agent.jenkinsfile
    ├── 03-install-java-agent.jenkinsfile
    ├── 04-install-node-agent.jenkinsfile
    ├── 05-install-db-agent.jenkinsfile
    ├── 06-stop-clean-smartagent.jenkinsfile
    ├── 07-uninstall-machine-agent.jenkinsfile
    ├── 08-uninstall-java-agent.jenkinsfile
    ├── 09-uninstall-node-agent.jenkinsfile
    ├── 10-uninstall-db-agent.jenkinsfile
    └── 11-cleanup-all-agents.jenkinsfile
```

## 📋 Documentation Guide

### For First-Time Users
1. **Start here**: [QUICK_START.md](QUICK_START.md) - Get running in 5 minutes
2. **Then read**: [README.md](README.md) - Understand the system architecture
3. **Deep dive**: [SETUP_GUIDE.md](SETUP_GUIDE.md) - Complete configuration details

### For GitHub Actions Users
1. **Migration guide**: [CONVERSION_NOTES.md](CONVERSION_NOTES.md)
2. **Comparison table**: See "Key Conversions" section
3. **Side-by-side**: Run both systems in parallel during transition

### For Jenkins Administrators
1. **Setup**: [SETUP_GUIDE.md](SETUP_GUIDE.md) - Credentials, agents, plugins
2. **Troubleshooting**: [SETUP_GUIDE.md#troubleshooting](SETUP_GUIDE.md#troubleshooting)
3. **Advanced**: [SETUP_GUIDE.md#advanced-configuration](SETUP_GUIDE.md#advanced-configuration)

### For Developers
1. **Pipeline code**: [pipelines/](pipelines/)
2. **Conversion notes**: [CONVERSION_NOTES.md](CONVERSION_NOTES.md)
3. **Customization**: Modify Jenkinsfiles as needed

## 🚀 Quick Links by Task

### Initial Setup
- [ ] [Install Jenkins plugins](SETUP_GUIDE.md#required-jenkins-plugins)
- [ ] [Configure Jenkins agent](SETUP_GUIDE.md#1-configure-jenkins-agent)
- [ ] [Add credentials](SETUP_GUIDE.md#credentials-setup)
- [ ] [Create pipelines](SETUP_GUIDE.md#pipeline-creation)

### Deployment
- [ ] Deploy Smart Agent: `pipelines/01-deploy-smart-agent.jenkinsfile`
- [ ] Install agents: `pipelines/02-05-install-*.jenkinsfile`
- [ ] Verify deployment: [QUICK_START.md#quick-checks](QUICK_START.md#quick-checks)

### Management
- [ ] Stop/Clean: `pipelines/06-stop-clean-smartagent.jenkinsfile`
- [ ] Uninstall agents: `pipelines/07-10-uninstall-*.jenkinsfile`
- [ ] Complete cleanup: `pipelines/11-cleanup-all-agents.jenkinsfile`

### Troubleshooting
- [ ] [Common issues](SETUP_GUIDE.md#common-issues)
- [ ] [Debug tips](SETUP_GUIDE.md#debug-tips)
- [ ] [Error reference](QUICK_START.md#common-errors--fixes)

## 📊 Pipeline Reference

### Deployment & Installation

| # | Pipeline | File | Description | Parameters |
|---|----------|------|-------------|------------|
| 01 | Deploy Smart Agent | `01-deploy-smart-agent.jenkinsfile` | Full Smart Agent deployment with config | BATCH_SIZE, SSH_USER, SMARTAGENT_USER, SMARTAGENT_GROUP |
| 02 | Install Machine Agent | `02-install-machine-agent.jenkinsfile` | Install Machine monitoring agent | BATCH_SIZE, SSH_USER |
| 03 | Install Java Agent | `03-install-java-agent.jenkinsfile` | Install Java APM agent | BATCH_SIZE, SSH_USER |
| 04 | Install Node Agent | `04-install-node-agent.jenkinsfile` | Install Node.js APM agent | BATCH_SIZE, SSH_USER |
| 05 | Install DB Agent | `05-install-db-agent.jenkinsfile` | Install Database monitoring agent | BATCH_SIZE, SSH_USER |

### Management & Cleanup

| # | Pipeline | File | Description | Parameters |
|---|----------|------|-------------|------------|
| 06 | Stop & Clean Smart Agent | `06-stop-clean-smartagent.jenkinsfile` | Stop service and clean data | BATCH_SIZE, SSH_USER |
| 11 | Cleanup All Agents | `11-cleanup-all-agents.jenkinsfile` | Delete /opt/appdynamics directory | BATCH_SIZE, SSH_USER |

### Uninstallation

| # | Pipeline | File | Description | Parameters |
|---|----------|------|-------------|------------|
| 07 | Uninstall Machine Agent | `07-uninstall-machine-agent.jenkinsfile` | Remove Machine agent | BATCH_SIZE, SSH_USER |
| 08 | Uninstall Java Agent | `08-uninstall-java-agent.jenkinsfile` | Remove Java agent | BATCH_SIZE, SSH_USER |
| 09 | Uninstall Node Agent | `09-uninstall-node-agent.jenkinsfile` | Remove Node agent | BATCH_SIZE, SSH_USER |
| 10 | Uninstall DB Agent | `10-uninstall-db-agent.jenkinsfile` | Remove Database agent | BATCH_SIZE, SSH_USER |

## 🔑 Required Credentials

All pipelines require these Jenkins credentials to be configured:

| Credential ID | Type | Required? | Used By |
|---------------|------|-----------|---------|
| `ssh-private-key` | SSH Username with private key | ✅ Yes | All pipelines |
| `deployment-hosts` | Secret text | ✅ Yes | All pipelines |
| `account-access-key` | Secret text | ⚠️ Deploy only | Pipeline 01 only |

## 📈 Statistics

- **Total Pipelines**: 11
- **Lines of Code**: ~1,096 (all Jenkinsfiles)
- **Documentation**: ~950 lines
- **Supported Scale**: 1 to 10,000+ hosts
- **Default Batch Size**: 256 hosts
- **Languages**: Groovy (Jenkins DSL) + Bash

## 🎯 Use Cases

### Small Deployment (1-10 hosts)
```
1. Set BATCH_SIZE=1 for testing
2. Run 01-Deploy-Smart-Agent
3. Install specific agents (02-05)
```

### Medium Deployment (10-500 hosts)
```
1. Use default BATCH_SIZE=256
2. Run 01-Deploy-Smart-Agent
3. Install required agents
4. Monitor via Jenkins console
```

### Large Deployment (500-5000+ hosts)
```
1. Adjust BATCH_SIZE based on network capacity
2. Consider splitting by region/VPC
3. Use separate credential sets per region
4. Monitor resource usage on Jenkins agent
```

### Maintenance Scenarios
```
Update Agent:
  1. Run 06-Stop-Clean-SmartAgent
  2. Update package on Jenkins agent
  3. Run 01-Deploy-Smart-Agent

Remove Specific Agent:
  1. Run 07-10-Uninstall-*-Agent
  
Complete Removal:
  1. Run 06-Stop-Clean-SmartAgent
  2. Run 11-Cleanup-All-Agents
```

## 🔗 External Resources

### Jenkins
- [Official Documentation](https://www.jenkins.io/doc/)
- [Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [SSH Agent Plugin](https://plugins.jenkins.io/ssh-agent/)

### AppDynamics
- [Smart Agent Documentation](https://docs.appdynamics.com/)
- [Agent Installation Guides](https://docs.appdynamics.com/appd/23.x/latest/)

### Related Projects
- **GitHub Actions Version**: `../github-action-lab/`
- **Original Workflows**: `.github/workflows/`

## 📝 Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2024-11 | Initial Jenkins conversion from GitHub Actions |
| | | - 11 pipelines converted |
| | | - Full documentation suite |
| | | - Production-ready |

## 🤝 Contributing

### Adding New Pipelines
1. Copy existing pipeline as template
2. Modify agent type and commands
3. Update this INDEX.md
4. Test with single host
5. Document in README.md

### Modifying Existing Pipelines
1. Test changes on non-production hosts
2. Update inline comments
3. Update documentation if behavior changes
4. Verify all 11 pipelines still work

### Reporting Issues
1. Check [SETUP_GUIDE.md#troubleshooting](SETUP_GUIDE.md#troubleshooting)
2. Review Jenkins console output
3. Check agent connectivity
4. Verify credential configuration

## 📞 Support

**Documentation Issues**: Update relevant .md file  
**Pipeline Bugs**: Check Jenkinsfile comments and logs  
**Setup Help**: See [SETUP_GUIDE.md](SETUP_GUIDE.md)  
**Quick Questions**: See [QUICK_START.md](QUICK_START.md)

## ✅ Checklist for Production Use

- [ ] Jenkins server and agent configured
- [ ] All required plugins installed
- [ ] Credentials added with correct IDs
- [ ] Agent has `linux` label
- [ ] Network connectivity verified
- [ ] SSH keys work from agent
- [ ] Test deployment on 1 host successful
- [ ] Test deployment on batch successful
- [ ] Error handling tested
- [ ] Rollback procedure documented
- [ ] Team trained on pipeline usage

---

**Last Updated**: November 2024  
**Maintained By**: DevOps Team  
**License**: Same as parent project
