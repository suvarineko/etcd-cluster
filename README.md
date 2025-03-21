# etcd-cluster Helm Chart

A Helm chart for deploying a secure etcd cluster on Kubernetes with TLS encryption.

## Overview

This Helm chart deploys a highly available etcd cluster with the following features:
- TLS encryption for client and peer communication
- Automatic certificate generation and management
- Graceful node addition and removal
- Metrics collection
- Configurable deployment parameters

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- A Kubernetes cluster with sufficient resources

## Installation

```bash
# Add the repository (replace with your actual repo)
helm repo add my-repo https://example.com/charts

# Install the chart with the release name "my-etcd"
helm install my-etcd my-repo/etcd-cluster \
  --namespace etcd-system \
  --create-namespace
```

## Configuration

### Basic Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of etcd replicas (should be 3 or 5 for HA) | `3` |
| `clusterDomain` | Domain used for TLS certificate generation | `""` |
| `baseDomain` | Base domain for service discovery | `"*.io"` |
| `image.registry` | Container registry | `""` |
| `image.repo` | Container repository | `""` |
| `image.image` | Container image name | `etcd` |
| `image.tag` | Container image tag | `3.5.10-0` (Chart appVersion) |
| `image.imagePullPolicy` | Image pull policy | `IfNotPresent` |

### TLS Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `tls.ca.cert` | Custom CA certificate (PEM format) | `""` |
| `tls.ca.key` | Custom CA key (PEM format) | `""` |
| `tls.server.extraIpAddresses` | Additional IP addresses for server certificate | `[]` |
| `tls.server.extraDnsNames` | Additional DNS names for server certificate | `[]` |
| `tls.client.extraIpAddresses` | Additional IP addresses for client certificate | `[]` |
| `tls.client.extraDnsNames` | Additional DNS names for client certificate | `[]` |
| `tls.certValidityDuration` | Certificate validity in days | `3650` |

### Service Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.name` | Service name | `etcd-cluster` |
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.clientPort` | etcd client port | `32379` |
| `service.serverPort` | etcd server port | `32380` |

### Advanced Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `nodeSelector` | Node labels for pod assignment | `{}` |
| `tolerations` | Tolerations for pod assignment | `[]` |
| `nameOverride` | Override chart name | `""` |
| `fullnameOverride` | Override full app name | `""` |

## Architecture

The etcd cluster consists of a StatefulSet with a configurable number of replicas (default 3). Each pod contains:

1. An etcd server container
2. Scripts for managing cluster membership during pod startup and termination
3. TLS certificates for secure communication

The cluster uses pod hostnames and a headless service for peer discovery and communication. TLS certificates are automatically generated and stored in Kubernetes secrets.

## TLS Certificates

The chart generates three types of TLS certificates:

1. **CA Certificate**: Used to sign all other certificates
2. **Server Certificate**: Used for server-to-server (peer) communication
3. **Admin Certificate**: Used for administrator access to the cluster

If you provide your own CA certificate and key, they will be used instead of generating new ones.

## Cluster Membership Management

The chart includes scripts to manage etcd cluster membership:

- **etcd-prestart.sh**: Removes the pod from the cluster if it already exists and adds it with a fresh identity
- **etcd-prestop.sh**: Gracefully removes the pod from the cluster during shutdown

These scripts ensure that the cluster maintains quorum during rolling updates and pod restarts.

## Metrics

The etcd cluster exposes basic metrics on port 9963, which can be scraped by Prometheus.

## Example Usage

### Connecting to the etcd cluster

```bash
# Set up environment variables for etcdctl
export ETCDCTL_API=3
export ETCDCTL_ENDPOINTS=https://etcd-cluster-0.etcd-cluster.etcd-system.svc:32379
export ETCDCTL_CACERT=/path/to/ca.crt
export ETCDCTL_CERT=/path/to/tls.crt
export ETCDCTL_KEY=/path/to/tls.key

# List all keys
etcdctl get --prefix /

# Put a key
etcdctl put /mykey myvalue

# Get a key
etcdctl get /mykey
```

## Limitations

- The chart currently assumes a fixed number of replicas (3) in some of its configuration
- Volume persistence is not configured by default - data is lost when pods are deleted

## Troubleshooting

### Common Issues

1. **Certificate issues**: Ensure that the certificates are correctly mounted and accessible to the etcd container
2. **Quorum loss**: If more than (n-1)/2 nodes fail, the cluster will lose quorum and require manual recovery
3. **Network connectivity**: Ensure that pods can communicate with each other on the specified ports

### Debugging

```bash
# Get pods
kubectl get pods -n <namespace>

# Check pod logs
kubectl logs -n <namespace> <pod-name>

# Check etcd cluster health
kubectl exec -it <pod-name> -n <namespace> -- etcdctl --endpoints=https://localhost:32379 \
  --cacert=/var/lib/etcd-secrets/ca.crt \
  --cert=/var/lib/etcd-secrets/tls.crt \
  --key=/var/lib/etcd-secrets/tls.key \
  endpoint health
```

## License

This chart is licensed under the Apache License 2.0.