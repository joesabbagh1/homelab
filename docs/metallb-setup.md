# MetalLB setup

MetalLB gives **LoadBalancer** Services a stable IP on your LAN (L2 mode). Used for Pi-hole (DNS IP) and optionally for Traefik (single IP for all apps on port 443).

## What’s in the repo

- **Helm repo:** `infrastructure/helm/metallb-repo.yaml` (Flux HelmRepository).
- **MetalLB app:** `apps/base/metallb/` — namespace, HelmRelease (chart 0.15.x), **IPAddressPool**, **L2Advertisement**.
- **Production:** `apps/production/metallb` is included in the main apps kustomization (before Pi-hole).

## One-time: set your IP pool

Edit **`apps/base/metallb/ipaddresspool.yaml`** and set `addresses` to a range that:

- Is in your LAN (same subnet as your nodes).
- Is **not** in your router’s DHCP range (e.g. use `.240`–`.250` if DHCP ends at `.200`).

Examples:

```yaml
spec:
  addresses:
    - 192.168.1.240-192.168.1.250
# or
    - 192.168.10.100/28
```

Push; Flux applies MetalLB and the pool. After that, any `Service` with `type: LoadBalancer` will get an IP from this pool.

## Check it

```bash
kubectl get pods -n metallb-system
kubectl get ipaddresspool -n metallb-system
kubectl get l2advertisement -n metallb-system
```

When you deploy Pi-hole (or Traefik as LoadBalancer), `kubectl get svc -n <namespace>` will show an **EXTERNAL-IP** from the pool.

## Talos / kube-proxy

If you use **strict ARP** (required for some setups with kube-proxy), ensure it’s enabled. On Talos this is often already set; if LoadBalancer IPs don’t work, check the [MetalLB installation notes](https://metallb.io/installation/) for your environment.
