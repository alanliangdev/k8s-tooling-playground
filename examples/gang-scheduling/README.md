# Kubernetes 1.35 Native Gang Scheduling Playground

This repository demonstrates the **All-or-Nothing** [gang scheduling](https://kubernetes.io/docs/concepts/scheduling-eviction/gang-scheduling/) behavior introduced in Kubernetes 1.35.

## Prerequisites

Before starting, please ensure the following are installed:
* Docker, Kind, kubectl, Helm, and git.

👉 [View the CLI Installation Guide](../../docs/binary-install.md) for detailed instructions.

## Setup Kind Cluster

Run the following command to create a local kind cluster with gang-scheduling enabled:

```bash
kind create cluster --config kind-config.yaml --name gang-scheduling
```

The `kind-config.yaml` is configured to enable the required alpha feature gates and API groups:

- The following Feature Gates must be enabled: `GenericWorkload=true`, `GangScheduling=true`.
- The Runtime Config must enable the API group: `scheduling.k8s.io/v1alpha1=true`.

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  image: kindest/node:v1.35.0
featureGates:
  GenericWorkload: true
  GangScheduling: true
runtimeConfig:
  "scheduling.k8s.io/v1alpha1": "true"
```

## Scenario 1: The Valid Gang
Cluster resources can satisfy the `minCount`.

1. **Apply:**

    ```bash
    kubectl apply -f 01-valid-gang.yaml
    ```

2. **Observe:** All pods will transition to `Running` simultaneously once the quorum (3 pods) is met.

    ```bash
    kubectl get pod
    ```

3. **Cleanup:**

    ```bash
    kubectl delete -f 01-valid-gang.yaml
    ```

---

## Scenario 2: The Oversized Gang
Requesting 100 CPUs per pod to force a scheduling failure.

1. **Apply:**

    ```bash
    kubectl apply -f 02-oversized-gang.yaml
    ```

2. **Observe:** Pods remain `Pending`. Note that **zero** pods are bound; the scheduler holds the entire group because it cannot fulfill the `minCount`.

    ```bash
    kubectl get pod
    ```

3. **Event Timeout:** Current Alpha behavior utilizes a permit timeout (defaulting to five minutes) before FailedScheduling events are surfaced.

   ```bash
   kubectl get event | grep FailedScheduling
   ```
4. **Cleanup:**

    ```bash
    kubectl delete -f 02-oversized-gang.yaml
    ```

## Cleanup Kind Cluster

Run the following command to delete the kind cluster.

```bash
kind delete cluster --name gang-scheduling
```
