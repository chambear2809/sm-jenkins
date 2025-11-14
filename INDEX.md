# Jenkins Smart Agent Lab - Project Index

Complete reference guide for the Jenkins-based AppDynamics Smart Agent management system.

## 📂 Project Structure

```
jenkins-sm-lab/
├── README.md                    # Main project overview and documentation
├── QUICK_START.md               # 5-minute getting started guide
├── SETUP_GUIDE.md              # Detailed Jenkins configuration guide
├── INDEX.md                    # This file - project navigation
├── INDEX.md                    # This file - project navigation
├── .gitignore                  # Git ignore rules
└── pipelines/                  # All Jenkins pipeline definitions
    ├── Jenkinsfile.deploy            # Deploy Smart Agent
    └── Jenkinsfile.cleanup           # Cleanup All Agents
```

## 📋 Documentation Guide

### For First-Time Users
1. **Start here**: [QUICK_START.md](QUICK_START.md) - Get running in 5 minutes
2. **Then read**: [README.md](README.md) - Understand the system architecture
3. **Deep dive**: [SETUP_GUIDE.md](SETUP_GUIDE.md) - Complete configuration details


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

### Available Pipelines

| # | Pipeline | File | Description | Parameters |
|---|----------|------|-------------|------------|
| 01 | Deploy Smart Agent | `Jenkinsfile.deploy` | Full Smart Agent deployment with config | BATCH_SIZE, SSH_USER, SMARTAGENT_USER, SMARTAGENT_GROUP |
| 02 | Cleanup All Agents | `Jenkinsfile.cleanup` | Delete /opt/appdynamics directory | CONFIRM_CLEANUP, SSH_USER |
## 🔑 Required Credentials

All pipelines require these Jenkins credentials to be configured:

| Credential ID | Type | Required? | Used By |
|---------------|------|-----------|---------|
| `ssh-private-key` | SSH Username with private key | ✅ Yes | All pipelines |
| `deployment-hosts` | Secret text | ✅ Yes | All pipelines |
| `account-access-key` | Secret text | ⚠️ Deploy only | Pipeline 01 only |

## 📈 Statistics

- **Total Pipelines**: 2
- **Lines of Code**: ~330 (all Jenkinsfiles)
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

## 📝 Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2024-11 | Initial Jenkins Smart Agent deployment system |
| | | - 2 pipelines created |
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
4. Verify both pipelines work correctly

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
