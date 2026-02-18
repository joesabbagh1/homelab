# TLS for local apps (cert-manager + Cloudflare DNS-01)

This setup provides TLS for apps in your **local network only**. Nothing is exposed to the internet.

## How it works

- **cert-manager** requests certificates from Let's Encrypt using the **DNS-01** challenge.
- **Cloudflare** is used so cert-manager can create a temporary TXT record to prove you control the domain. No HTTP/HTTPS traffic hits your home.
- **Traefik** (already installed) terminates TLS and routes to your services.
- Your **domain** (`joesabbagh.com`) is used only for certificate issuance and for **local DNS**. You point those hostnames to your cluster only on your LAN (e.g. via Pi-hole or router DNS), so the public never reaches your network.

## One-time setup

### 1. Cloudflare API token

1. In Cloudflare: **My Profile → API Tokens → Create Token**.
2. Use “Edit zone DNS” template or custom:
   - **Zone → Zone → Read**
   - **Zone → DNS → Edit**
3. Zone resources: **Include → All zones** (or limit to the zones you use).
4. Create the token and copy it.

### 2. Create the secret in the cluster

```bash
kubectl create secret generic cloudflare-dns-api-token -n cert-manager \
  --from-literal=api-token=YOUR_CLOUDFLARE_API_TOKEN
```

To manage this with SOPS (recommended), add an encrypted Secret and point the ClusterIssuer at it, or use Flux Kustomization with `secretGenerator` and decryption.

### 3. Set your email in the ClusterIssuer

Edit `apps/base/cert-manager/cluster-issuer-cloudflare.yaml` and replace `replace-me@example.com` with your email (for Let's Encrypt expiry notifications).

### 4. Local-only DNS (keep home network private)

So that only your LAN can reach your apps:

- **Option A – Local DNS override**  
  In your router, Pi-hole, AdGuard Home, or `/etc/hosts`, make your app hostnames resolve to your cluster’s IP (e.g. the node where Traefik’s NodePort is available, or a MetalLB/LoadBalancer IP):
  - `linkding.joesabbagh.com` → cluster IP
  - `jellyfin.joesabbagh.com` → cluster IP
  - `commafeed.joesabbagh.com` → cluster IP
  - `n8n.joesabbagh.com` → cluster IP

- **Option B – Split-horizon**  
  In Cloudflare (or your public DNS), do **not** create A/AAAA records for these hostnames, or point them to a “sink” IP. Then only your local DNS (which you control) will resolve them to your cluster.

Result: from the internet, these hostnames either don’t resolve or don’t point to you; from your LAN, they resolve to the cluster and you get TLS via cert-manager.

## After setup

- Each app uses a **Certificate** (cert-manager) and a **Traefik IngressRoute** (not the standard Kubernetes Ingress). cert-manager issues and renews certificates; Traefik serves HTTPS on the `websecure` entryPoint using those secrets.
- Certificates are stored in each app’s namespace and renewed automatically.
- Access apps over HTTPS on the `websecure` port (e.g. NodePort 30443), using the hostnames above, only from inside your network.
