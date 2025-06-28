# Pi Cluster - GitOps Homelab

A GitOps-managed Kubernetes homelab running self-hosted applications with automated deployments, monitoring, and secure external access.

## 🏗️ Architecture

This repository uses **Flux CD v2** to manage a Kubernetes cluster following GitOps principles. All infrastructure and applications are declaratively defined in Git, with automatic reconciliation and encrypted secrets management.

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Git Repository │───▶│   Flux CD v2     │───▶│  Kubernetes     │
│   (This Repo)   │    │   Controller     │    │   Cluster       │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │  SOPS + Age      │
                       │  Encryption      │
                       └──────────────────┘
```

## 🚀 Applications

### Self-Hosted Services
- **[Audiobookshelf](https://www.audiobookshelf.org/)** (v2.25.1) - Audiobook and podcast server
- **[Immich](https://immich.app/)** (v1.134.0) - Photo management and backup solution
- **[Homepage](https://gethomepage.dev/)** (v1.3.2) - Customizable dashboard for your services
- **[Linkding](https://github.com/sissbruecker/linkding)** - Bookmark manager

### Infrastructure Components
- **[Renovate](https://renovatebot.com/)** - Automated dependency updates
- **[Kube-Prometheus-Stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)** (v66.2.2) - Complete monitoring solution

## 🌐 Access & Networking

### External Access
Services are securely exposed via **Cloudflare Tunnels** without opening firewall ports:
- `audiobookshelf.philipnguyen.uk` - Audiobook server
- `grafana.philipnguyen.uk` - Monitoring dashboard
- Additional services configured per environment

### Internal Networking
- **Traefik** - Ingress controller for internal routing
- **Service mesh** - Kubernetes native service discovery

## 📁 Repository Structure

```
├── apps/                           # Application deployments
│   ├── base/                      # Base Kubernetes manifests
│   │   ├── audiobookshelf/        # Audiobook server
│   │   ├── homepage/              # Dashboard
│   │   ├── immich/                # Photo management
│   │   └── linkding/              # Bookmark manager
│   └── staging/                   # Environment-specific overlays
│       └── */cloudflare.yaml      # Cloudflare tunnel configs
├── clusters/                      # Cluster configuration
│   └── staging/                   # Staging environment
│       ├── apps.yaml              # App deployments
│       ├── infrastructure.yaml    # Infrastructure components
│       ├── monitoring.yaml        # Monitoring stack
│       └── .sops.yaml            # Encryption configuration
├── infrastructure/                # Infrastructure controllers
│   └── controllers/
│       └── base/renovate/         # Dependency management
└── monitoring/                    # Monitoring and observability
    ├── controllers/               # Monitoring controllers
    └── configs/                   # Monitoring configurations
```

## 🔒 Security

### Secrets Management
- **SOPS** encryption for sensitive data at rest
- **Age** encryption keys for secret management
- Encrypted regex pattern: `^(data|stringData)$`

### Access Control
- Kubernetes RBAC with dedicated service accounts
- Cluster roles with minimal required permissions
- Secure external access via Cloudflare tunnels

## 🛠️ Technology Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **GitOps** | Flux CD v2 | Continuous deployment |
| **Configuration** | Kustomize | Configuration management |
| **Secrets** | SOPS + Age | Encryption at rest |
| **Monitoring** | Prometheus + Grafana | Observability |
| **Ingress** | Traefik | Internal routing |
| **External Access** | Cloudflare Tunnels | Secure external connectivity |
| **Updates** | Renovate | Automated dependency management |

## 🚦 Getting Started

### Prerequisites
- Kubernetes cluster (tested on Raspberry Pi cluster)
- Flux CD v2 installed
- Age key for SOPS encryption
- Cloudflare account with tunnel setup

### Initial Setup

1. **Install Flux CD**
   ```bash
   flux bootstrap github \
     --owner=MinhNguyen911 \
     --repository=pi-cluster \
     --branch=main \
     --path=clusters/staging
   ```

2. **Configure SOPS encryption**
   ```bash
   # Generate Age key
   age-keygen -o age.agekey
   
   # Create Kubernetes secret
   kubectl create secret generic sops-age \
     --from-file=age.agekey=age.agekey \
     --namespace=flux-system
   ```

3. **Apply cluster configuration**
   ```bash
   kubectl apply -f clusters/staging/
   ```

### Adding New Applications

1. Create base manifests in `apps/base/your-app/`
2. Add environment-specific overlays in `apps/staging/your-app/`
3. Update `apps/staging/kustomization.yaml`
4. Commit and push - Flux will automatically deploy

## 📊 Monitoring

Access monitoring dashboards:
- **Grafana**: `https://grafana.philipnguyen.uk`
- **Default credentials**: Check encrypted secrets in repository

### Key Metrics
- Application health and performance
- Kubernetes cluster metrics
- Resource utilization
- Custom application dashboards

## 🔄 Automated Updates

**Renovate** runs hourly to:
- Check for new container image versions
- Update Helm chart versions
- Create pull requests for dependency updates
- Maintain security patches automatically

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes following the existing structure
4. Test in a development environment
5. Submit a pull request

## 📝 License

This project is for personal use. Feel free to use as inspiration for your own homelab setup.

---

**Note**: This is a personal homelab setup. Passwords and sensitive configurations are encrypted using SOPS. You'll need to provide your own secrets and configuration for your environment.