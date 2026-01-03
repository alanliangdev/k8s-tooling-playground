# Kubernetes Tooling Playground

This repository is designed as a growing, extensible sandbox for exploring the Kubernetes ecosystem. It provides an automated way to spin up a multi-node cluster using Kind and manages a library of industry-standard tools via Argo CD using the App-of-Apps pattern.

The goal of this project is to provide an "easy button" for developers and platform engineers to experiment with tools like Prometheus, Grafana, and Ingress controllers without the manual labour of individual installations.



## Prerequisites

Before starting, please ensure the following are installed:
* Docker (or Docker Desktop)
* Kind
* kubectl
* git

## Getting Started

To use this playground, you should have your own copy of the repository. This allows you to enable or disable specific tools and watch Argo CD synchronise those changes to your local cluster.

### 1. Fork and Clone
First, Fork this repository to your own GitHub account. Then, clone your fork to your local machine:

```bash
git clone https://github.com/[YOUR_GITHUB_USERNAME]/k8s-tooling-playground.git
cd k8s-tooling-playground
```

### 2. Initialise the Cluster
The bootstrap script handles the heavy lifting. It creates the Kind cluster, installs Argo CD, and automatically configures the Root Application to point to your personal fork.

```bash
chmod +x setup.sh
./setup.sh
```

### 3. Access the Tools
Once the initialise script completes, you can access the currently available tools:

* Argo CD: https://localhost:8080 (Management UI)
* Grafana: http://localhost:3000 (Visualisation)
* Prometheus: http://localhost:9090 (Metrics)

---

## Exploring the Ecosystem

This playground uses a "Parent-Child" application model. The Root Application in the bootstrap directory monitors the apps directory. Any tool defined in the apps folder is automatically deployed and managed by Argo CD.



### How to Experiment
As this repository grows, new tools will be added to the apps directory. To test the GitOps workflow:
1. Navigate to a tool's configuration in the apps/ directory.
2. Modify the manifest (e.g. changing a resource limit or a version).
3. Commit and push your changes:

   ```bash
   git add .
   git commit -m "Adjusting tool configuration"
   git push origin main
   ```

4. Observe the Argo CD interface as it detects the change and synchronises your cluster to match your Git repository.

## Resetting the Environment
To completely remove the cluster and start fresh, run the cleanup script:

./cleanup.sh