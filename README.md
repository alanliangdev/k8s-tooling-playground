# Kubernetes Tooling Playground

This repository is designed as a growing, extensible sandbox for exploring the Kubernetes ecosystem. It provides an automated way to spin up a multi-node cluster using Kind and manages a library of industry-standard tools via Argo CD using the App-of-Apps pattern.

The goal of this project is to provide an "easy button" for developers and platform engineers to experiment with tools like Prometheus, Grafana, Kro, and Ingress controllers without the manual labour of individual installations.

> ⚠️ **Disclaimer:** This playground is **not production ready**. It employs several shortcuts for ease of use, such as default admin credentials for Argo CD and Grafana, and lacks SSL/TLS certificates. It is designed strictly for local development and experimentation.

## Prerequisites

Before starting, please ensure the following are installed:
* Docker, Kind, kubectl, Helm, and git.

👉 [View the CLI Installation Guide](docs/binary-install.md) for detailed instructions.

> ⚠️ **Network Requirement:** This playground requires unrestricted internet access to pull container images (Docker Hub, Quay, etc.) and download Helm charts. If you are behind a corporate firewall or VPN that blocks public registries, the bootstrap process may fail.

## Getting Started

To use this playground, you should have your own copy of the repository. This allows you to enable or disable specific tools and watch Argo CD synchronise those changes to your local cluster.

### 1. Fork and Clone
First, Fork this repository to your own GitHub account. Then, clone your fork to your local machine:

```bash
git clone https://github.com/[YOUR_GITHUB_USERNAME]/k8s-tooling-playground.git
cd k8s-tooling-playground
```

### 2. Initialise the Cluster
The bootstrap script handles the heavy lifting. It creates the Kind cluster, installs Argo CD, and automatically configures the Root Application to point to your personal fork (and pushes these changes to your git repo).

```bash
chmod +x setup.sh
./setup.sh
```

### 3. Access the Tools
Once the initialise script completes, you can access the currently available tools:

* Argo CD: https://localhost:8080 (Management UI)
* Grafana: http://localhost:3000 (Visualisation)
* Prometheus: http://localhost:9090 (Metrics)

### Self-Managed Apps
In this playground, a **Self-Managed App** is any application that sources its manifests from *this* Git repository (your custom fork), rather than an upstream public repository (like `kube-prometheus-stack` or `kyverno` which usually point to public Helm charts). To ensure these apps work correctly in your fork, the `setup.sh` script automatically detects your git repository URL and updates the `repoURL` field in their manifests.

By default, this includes:
* The Root App (`bootstrap/root-app.yaml`)
* Kro Definitions (`apps/kro-definitions.yaml`)
* Kro Instances (`apps/kro-instances.yaml`)

If you add your own custom applications to this repository, you can register them in the `SELF_MANAGED_APPS` array within `setup.sh`. Since `setup.sh` is designed for initial bootstrapping, you should commit your changes to your fork, run `./cleanup.sh`, and then re-run `./setup.sh` to apply the new configuration.

---

## Exploring the Ecosystem

This playground uses a "Parent-Child" application model. The Root Application in the bootstrap directory monitors the `apps/` directory.

### Core Tools
* **Prometheus & Grafana:** Full-stack observability and dashboarding.
* **Kro (Kubernetes Resource Orchestrator):** Simplifies custom resource creation. It allows you to define complex multi-resource patterns (e.g., a "Web-App" abstraction) as a single API without writing Go code or custom operators.

### How to Experiment
As this repository grows, new tools will be added to the apps directory. To test the GitOps workflow:
1. **Modify:** Navigate to a tool in apps/ and adjust its manifest (e.g., update a version tag or a Helm value).
2. **Commit:** Push your changes to trigger the sync:

   ```bash
   git add .
   git commit -m "Update tool configuration"
   git push origin main
   ```

3. **Observe:** Watch the Argo CD UI as it detects the "Out of Sync" state and automatically reconciles your cluster to match your Git repository.

## Resetting the Environment
To completely remove the cluster and start fresh, run the cleanup script:

./cleanup.sh