# Kubernetes Lab Documentation

A multi-cloud Kubernetes cluster bootstrapped with kubeadm, managed via GitOps using Flux CD.

## Overview

This lab environment hosts a variety of workloads including blockchain nodes, game servers, communication services, and monitoring infrastructure. The cluster uses Cilium for advanced networking with BGP and L2 announcements for LoadBalancer services.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           MULTI-CLOUD KUBERNETES CLUSTER                     │
│                              (kubeadm bootstrapped)                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐                   │
│  │   Node 1     │    │   Node 2     │    │   Node 3     │                   │
│  │ (Control)    │◄──►│  (Worker)    │◄──►│  (Worker)    │                   │
│  │              │    │              │    │              │                   │
│  │ • API Server │    │ • Workloads  │    │ • Workloads  │                   │
│  │ • etcd       │    │ • Ingress    │    │ • Database   │                   │
│  │ • Scheduler  │    │              │    │              │                   │
│  └──────────────┘    └──────────────┘    └──────────────┘                   │
│         │                   │                   │                            │
│         └───────────────────┴───────────────────┘                            │
│                             │                                                │
│                    ┌────────┴────────┐                                       │
│                    │  Cilium CNI     │                                       │
│                    │  • L2 Announce  │                                       │
│                    │  • BGP Control  │                                       │
│                    │  • Hubble       │                                       │
│                    └────────┬────────┘                                       │
│                             │                                                │
│                    ┌────────┴────────┐                                       │
│                    │  LoadBalancer   │                                       │
│                    │  5.161.82.129   │                                       │
│                    └─────────────────┘                                       │
└─────────────────────────────────────────────────────────────────────────────┘
```

## GitOps Structure

```
lab/
├── apps/                        # Application deployments
│   ├── base/                    # Base configurations
│   │   ├── linkding/           # Bookmark manager
│   │   ├── multipaper/         # Minecraft server cluster
│   │   ├── prosody/            # XMPP server
│   │   └── zcash/              # Blockchain nodes
│   ├── staging/                # Staging environment
│   └── production/             # Production environment
│
├── clusters/                    # Flux bootstrap
│   └── lab/
│       ├── flux-system/        # Flux controllers
│       ├── apps.yaml           # App Kustomization
│       ├── infrastructure.yaml # Infra Kustomization
│       └── monitoring.yaml     # Monitoring Kustomization
│
├── infrastructure/              # System components
│   ├── controllers/            # Renovate, etc.
│   ├── databases/              # CloudNative PG
│   ├── networking/             # Cilium, Ingress
│   └── storage/                # Local-path provisioner
│
└── monitoring/                  # Observability
    └── controllers/            # Prometheus stack
```

## Networking Architecture

```
                              INTERNET
                                  │
                                  ▼
                    ┌─────────────────────────┐
                    │    External IP Pool     │
                    │     5.161.82.129/32     │
                    └───────────┬─────────────┘
                                │
            ┌───────────────────┼───────────────────┐
            │                   │                   │
            ▼                   ▼                   ▼
     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
     │   :443      │     │   :8443     │     │   :5222     │
     │   Ingress   │     │ Lightwallet │     │   Prosody   │
     └──────┬──────┘     └─────────────┘     └─────────────┘
            │
            ├──────────────────┬──────────────────┐
            │                  │                  │
            ▼                  ▼                  ▼
    ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
    │   Grafana    │   │   Linkding   │   │    Other     │
    │  grafana.    │   │  linkding.   │   │   Services   │
    │sirius-sec.com│   │sirius-sec.com│   │              │
    └──────────────┘   └──────────────┘   └──────────────┘

    ┌─────────────────────────────────────────────────────┐
    │                    CILIUM CNI                        │
    ├─────────────────────────────────────────────────────┤
    │  • L2 Announcements (eth0)                          │
    │  • BGP Control Plane                                │
    │  • LoadBalancer IP Pool (sirius-ippool)             │
    │  • Shared LB Policy                                 │
    │  • Hubble Observability                             │
    │  • Envoy Proxy (NET_BIND_SERVICE, BPF caps)         │
    └─────────────────────────────────────────────────────┘
```

## Application Stack

### Deployed Services

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          APPLICATION LAYER                               │
├──────────────┬──────────────┬──────────────┬───────────────────────────┤
│              │              │              │                            │
│   ZCASH      │   PROSODY    │   LINKDING   │        MULTIPAPER          │
│   ─────      │   ───────    │   ────────   │        ──────────          │
│              │              │              │                            │
│  ┌────────┐  │  ┌────────┐  │  ┌────────┐  │  ┌────────┐  ┌────────┐   │
│  │ Zebrad │  │  │  XMPP  │  │  │  Web   │  │  │ Master │  │  Proxy │   │
│  │  Node  │  │  │ Server │  │  │   UI   │  │  │ Server │  │Velocity│   │
│  └────────┘  │  └────────┘  │  └────────┘  │  └────────┘  └────────┘   │
│      │       │      │       │      │       │      │            │        │
│      ▼       │      │       │      │       │      ▼            │        │
│  ┌────────┐  │      │       │      │       │  ┌────────┐       │        │
│  │  Light │  │      │       │      │       │  │MariaDB │◄──────┘        │
│  │ Wallet │  │      │       │      │       │  └────────┘                │
│  └────────┘  │      │       │      │       │                            │
│              │      │       │      │       │  Plugins:                  │
│  Ports:      │  Ports:      │  Port:       │  • LuckPerms               │
│  • 8232 RPC  │  • 5222 C2S  │  • 9090      │  • Essentials              │
│  • 8233 P2P  │  • 5269 S2S  │              │  • mcMMO                   │
│  • 9067 gRPC │  • 5281 HTTPS│              │                            │
│              │              │              │                            │
└──────────────┴──────────────┴──────────────┴───────────────────────────┘
```

### Namespaces

| Namespace | Purpose |
|-----------|---------|
| `zcash` | Blockchain node and lightwallet services |
| `prosody` | XMPP/Jabber messaging server |
| `linkding` | Bookmark management application |
| `minecraft` | Multipaper game server cluster |
| `monitoring` | Prometheus, Grafana, AlertManager |
| `database` | CloudNative PostgreSQL cluster |
| `flux-system` | GitOps controllers |
| `local-path-storage` | Storage provisioner |
| `renovate` | Dependency update automation |

## Data Layer

```
┌─────────────────────────────────────────────────────────────────────────┐
│                            DATA LAYER                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                    CloudNative PostgreSQL                        │   │
│   │                      (3-node HA cluster)                         │   │
│   │  ┌──────────┐    ┌──────────┐    ┌──────────┐                   │   │
│   │  │ Primary  │◄──►│ Replica  │◄──►│ Replica  │                   │   │
│   │  │  (1Gi)   │    │  (1Gi)   │    │  (1Gi)   │                   │   │
│   │  └──────────┘    └──────────┘    └──────────┘                   │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│   ┌─────────────────────────┐    ┌─────────────────────────┐            │
│   │       MariaDB           │    │    Local Path Storage    │            │
│   │   (Minecraft - 50Gi)    │    │                          │            │
│   │  ┌──────────┐           │    │  • linkding: 1Gi         │            │
│   │  │  Single  │           │    │  • zebrad: dynamic       │            │
│   │  │ Instance │           │    │  • lightwallet: dynamic  │            │
│   │  └──────────┘           │    │  • prosody: dynamic      │            │
│   └─────────────────────────┘    └─────────────────────────┘            │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## GitOps Flow

```
┌──────────────┐     ┌──────────────┐     ┌──────────────────────────────┐
│   Developer  │────►│    GitHub    │────►│        Flux CD               │
│   (push)     │     │  sirius0xdev │     │                              │
└──────────────┘     │    /lab      │     │  ┌────────────────────────┐  │
                     └──────────────┘     │  │   source-controller    │  │
                            │             │  │   (1 min sync)         │  │
                            │             │  └───────────┬────────────┘  │
                            │             │              │               │
                            │             │  ┌───────────▼────────────┐  │
                            │             │  │ kustomize-controller   │  │
                            │             │  │ helm-controller        │  │
                            │             │  └───────────┬────────────┘  │
                            │             │              │               │
                            │             │  ┌───────────▼────────────┐  │
                            │             │  │   Apply to Cluster     │  │
                            │             │  └────────────────────────┘  │
                            │             └──────────────────────────────┘
                            │
                            │             ┌──────────────────────────────┐
                            │             │        Renovate              │
                            └────────────►│   (hourly dependency scan)   │
                                          │                              │
                                          │  Creates PRs for updates:    │
                                          │  • Container images          │
                                          │  • Helm charts               │
                                          │  • Kubernetes manifests      │
                                          └──────────────────────────────┘
```

## Monitoring Stack

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         OBSERVABILITY                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌────────────────┐    ┌────────────────┐    ┌────────────────┐        │
│   │   Prometheus   │───►│    Grafana     │◄───│   AlertManager │        │
│   │                │    │                │    │                │        │
│   │  • Metrics     │    │ grafana.       │    │  • Routing     │        │
│   │  • Rules       │    │ sirius-sec.com │    │  • Silencing   │        │
│   │  • Targets     │    │                │    │                │        │
│   └────────┬───────┘    └────────────────┘    └────────────────┘        │
│            │                    ▲                                        │
│            │                    │                                        │
│            ▼                    │                                        │
│   ┌────────────────┐    ┌───────┴────────┐                              │
│   │  Hubble        │───►│    Hubble UI   │                              │
│   │  (Cilium)      │    │                │                              │
│   │                │    │  • Flow Logs   │                              │
│   │  • Network     │    │  • Service Map │                              │
│   │    Flows       │    │  • Policies    │                              │
│   └────────────────┘    └────────────────┘                              │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Security

### Secret Management

Secrets are encrypted using SOPS with Age encryption:

```
┌─────────────────────────────────────────────┐
│              SOPS + Age Encryption           │
├─────────────────────────────────────────────┤
│                                              │
│  Encrypted in Git:                          │
│  • *values.yaml files                       │
│  • data/stringData fields in secrets        │
│                                              │
│  Age Public Key:                            │
│  age1fu3yw8700dznl0xgsrcgghjase...          │
│                                              │
│  Decryption: Flux SOPS integration          │
└─────────────────────────────────────────────┘
```

### Network Policies

- Default allow policies within Flux namespace
- Metrics scraping allowed from all namespaces
- Service-specific isolation (e.g., lightwallet)

## Cluster Bootstrap (kubeadm)

This cluster was bootstrapped using kubeadm with the following key steps:

1. **Initialize Control Plane**
   ```bash
   kubeadm init --pod-network-cidr=10.244.0.0/16
   ```

2. **Join Worker Nodes**
   ```bash
   kubeadm join <control-plane>:6443 --token <token> \
     --discovery-token-ca-cert-hash sha256:<hash>
   ```

3. **Install Cilium CNI**
   - Deployed via Helm through Flux
   - Configured with L2 announcements and BGP

4. **Bootstrap Flux**
   ```bash
   flux bootstrap github \
     --owner=sirius0xdev \
     --repository=lab \
     --branch=master \
     --path=clusters/lab
   ```

## Multi-Cloud Configuration

The cluster spans multiple cloud providers with:

- **Shared LoadBalancer IP Pool**: `5.161.82.129/32`
- **L2 Announcements**: For cross-node LoadBalancer failover
- **BGP Control Plane**: For dynamic route advertisement
- **Node Labels**: For workload placement control
  - `component: ingress` - Ingress controller nodes
  - `network-role: lb-node` - LoadBalancer nodes

## Component Versions

| Component | Version |
|-----------|---------|
| Flux CD | 2.7.2 |
| Cilium | 1.16.6 |
| CloudNative PG | 0.27.0 |
| Local Path Provisioner | 0.0.32 |
| Kube Prometheus Stack | 66.x |

## Domains

| Domain | Service |
|--------|---------|
| `sirius-sec.com` | Root domain |
| `grafana.sirius-sec.com` | Monitoring dashboards |
| `linkding.sirius-sec.com` | Bookmark manager |

## Quick Reference

### Access kubeconfig
```bash
export KUBECONFIG=/home/lancelot/lab/kubeconfig
```

### Check Flux status
```bash
flux get all -A
```

### View Cilium status
```bash
cilium status
hubble status
```

### Decrypt secrets locally
```bash
sops -d <encrypted-file.yaml>
```
