# Ergo Helm Chart

A Helm chart for deploying [Ergo](https://ergo.chat/) IRC server on Kubernetes.

## Prerequisites

- Kubernetes cluster
- Helm 3.x
- cert-manager installed in the cluster (for TLS certificates)

## Installation

### Install from OCI registry

```bash
helm install my-ergo oci://ghcr.io/geertjohan/ergo --version 0.1.0
```

### Install from local chart

```bash
git clone https://github.com/GeertJohan/ergo-helm-chart.git
cd ergo-helm-chart
helm install
helm --kube-context tboh-mycroft \
  upgrade --install \
  irc-geertjohan-nl ./ergo \
  --namespace irc-geertjohan-nl --create-namespace
  --values ./values.yaml
```

## Configuration

### Minimal Configuration

Create a `values.yaml` file with your configuration:

```yaml
hostname: "irc.example.com"

ergo:
  motd: |
    Welcome to MyNetwork IRC

    Please register: /msg nickserv register <password> <email>

  config:
    network:
      name: MyNetwork
    server:
      name: irc.example.com
    # ... rest of your Ergo configuration
```

Install with your values:

```bash
helm install my-ergo oci://ghcr.io/geertjohan/ergo --version 0.1.0 -f values.yaml
```

### Key Configuration Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `hostname` | IRC server hostname (used for certificate and external-dns) | `irc.example.com` |
| `image.repository` | Ergo image repository | `ghcr.io/ergochat/ergo` |
| `image.tag` | Ergo image tag | `v2.15.0` |
| `service.type` | Service type | `LoadBalancer` |
| `service.annotations` | Service annotations | See `values.yaml` |
| `certificate.enabled` | Enable cert-manager certificate | `true` |
| `certificate.secretName` | Secret name for TLS cert | `ergo-tls` |
| `certificate.issuerRef.name` | cert-manager issuer name | `letsencrypt-prod` |
| `certificate.issuerRef.kind` | cert-manager issuer kind | `ClusterIssuer` |
| `persistence.enabled` | Enable persistent storage | `true` |
| `persistence.size` | PVC size | `1Gi` |
| `ergo.config` | Ergo configuration object | See `values.yaml` |
| `ergo.motd` | Message of the day | See `values.yaml` |

## Ergo Configuration

The chart accepts the complete Ergo IRC server configuration via the `ergo.config` value as a YAML object. This allows you to override specific values without copying the entire default configuration.

### Override Specific Values

```yaml
ergo:
  config:
    network:
      name: MyNetwork
    server:
      name: irc.example.com
    opers:
      admin:
        class: server-admin
        password: "$2a$04$..."
        fingerprint: "AA:BB:CC:..."
```

Helm will merge your values with the defaults from `values.yaml`. Refer to the [Ergo documentation](https://ergo.chat/manual.html) for all available options.

**Important**: At minimum, update these values:
- `ergo.config.network.name` - Your IRC network name
- `ergo.config.server.name` - Your IRC server hostname (should match `hostname`)
- `ergo.config.opers` - Add your IRC operators

## Architecture

The deployment includes:

- **Main container**: Ergo IRC server
- **Sidecar container**: Config reloader that watches for configuration and certificate changes, sends SIGHUP to Ergo for live reloads
- **Service**: LoadBalancer service for external access (IRC+TLS on port 6697, WebSocket on port 443)
- **PersistentVolumeClaim**: ReadWriteOnce volume for Ergo's database
- **ConfigMap**: Ergo configuration files (`ircd.yaml` and `ergo.motd`)
- **Certificate**: cert-manager Certificate resource for TLS

**Note**: The deployment is hardcoded to 1 replica because Ergo uses database locking with a ReadWriteOnce PVC.

## Upgrading Configuration

Configuration changes can be applied without restarting the pod. The config-reloader sidecar will automatically send a SIGHUP signal to Ergo when configuration files or certificates change:

```bash
helm upgrade my-ergo oci://ghcr.io/geertjohan/ergo --version 0.1.0 -f values.yaml
```

## Uninstalling

```bash
helm uninstall my-ergo
```

**Warning**: This will not delete the PersistentVolumeClaim. To delete it:

```bash
kubectl delete pvc <release-name>-ergo-db
```

## License

This Helm chart is provided as-is. Ergo IRC server is licensed under the MIT License.

## TODO

- pod and service ports based on ergo configuration?
