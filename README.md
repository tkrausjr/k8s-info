# k8s-info

> A collection of kubernetes tools and scripts to accomplish various tasks

## Table of Contents
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)

---

## Prerequisites
Before you begin, ensure you have met the following requirements:
* [Install kubectl & jq] 
* [Credentials for accessing Supervisor as an Administrator] 
* Provide links to installation guides for these prerequisites if necessary.

## Installation
```bash
# Clone the repository
git clone https://github.com/tkrausjr/k8s-info.git
# Navigate to the project directory
cd k8s-info
# Install dependencies in OSX
brew install kubectl
brew install jq
# Make script executable
chmod ./sup-vks-info.sh
```
### To run the sup-vks-info.sh Script.
```bash
# Get access to the Supervisor Context as an Administrator
# VCF 9.x with VCF CLI
vcf context create my-supervisor --endpoint <supervisor-IP> --insecure-skip-tls-verify --type k8s --auth-type basic
./sup-vks-info.sh
```

