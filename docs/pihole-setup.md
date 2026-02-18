# Pi-hole setup (Kubernetes + MetalLB)

Pi-hole is exposed with a **LoadBalancer** Service. MetalLB assigns it a **stable IP** from the pool. Point your router’s DNS to that IP.

## Prerequisites: MetalLB

MetalLB must be deployed first (it’s in `apps/production` before Pi-hole). It needs an **IP pool** that matches your LAN and isn’t used by DHCP.

1. Edit **`apps/base/metallb/ipaddresspool.yaml`** and set `addresses` to a range in your LAN, e.g.:
   - `192.168.1.240-192.168.1.250`, or
   - `192.168.10.100/28`
2. Push; Flux will apply MetalLB, then Pi-hole.

## Deploy

After MetalLB is running, Pi-hole will get an external IP. Check it:

```bash
kubectl get svc -n pihole
# NAME     TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)        AGE
# pihole   LoadBalancer   10.106.x.x      192.168.1.240  53:30xxx/TCP,53:30xxx/UDP,80:30xxx/TCP
```

The **EXTERNAL-IP** (e.g. `192.168.1.240`) is your **DNS server IP** for the router.

## Admin password

Create a secret so the web UI uses a fixed password (optional). If you skip this, Pi-hole sets a random password and prints it to the log.

```bash
kubectl create secret generic pihole-password -n pihole \
  --from-literal=password=YOUR_ADMIN_PASSWORD
```

To see a randomly generated password later:

```bash
kubectl logs -n pihole -l app=pihole | grep -i password
```

## Router DNS

On your router (or each device), set **Primary DNS** to the Pi-hole Service **EXTERNAL-IP** (the MetalLB-assigned IP). That makes all LAN traffic use Pi-hole for DNS. The IP is stable even if the Pi-hole pod moves.

## Local DNS records for your apps

So that `linkding.joesabbagh.com` (and the rest) resolve to your cluster and go through Traefik:

1. Open the Pi-hole admin UI: **https://pihole.joesabbagh.com:30443** (or `http://<PIHOLE_EXTERNAL_IP>/admin`).
2. Go to **Local DNS → DNS Records** (or **Local DNS** → **CNAME/A records** depending on Pi-hole version).
3. Add the following. Use either:
   - The **node IP** where Traefik’s NodePort is reachable, or  
   - **Traefik’s LoadBalancer EXTERNAL-IP** if you switch Traefik to `type: LoadBalancer` (see below).

   | Domain                      | IP                    |
   |----------------------------|------------------------|
   | linkding.joesabbagh.com    | Traefik IP (see below) |
   | jellyfin.joesabbagh.com    | Traefik IP             |
   | commafeed.joesabbagh.com   | Traefik IP             |
   | n8n.joesabbagh.com         | Traefik IP             |
   | pihole.joesabbagh.com      | Traefik IP             |

- **Traefik still NodePort:** use the InternalIP of the node where the Traefik pod runs (`kubectl get pod -n traefik -o wide`).
- **Traefik as LoadBalancer:** use the EXTERNAL-IP of the Traefik Service (`kubectl get svc -n traefik`). Then you can use **https://linkding.joesabbagh.com** (port 443) without `:30443`.

After this, any device using Pi-hole as DNS will resolve these hostnames to the cluster.

## Optional: Traefik as LoadBalancer

For one stable IP and standard port 443 (no `:30443`):

1. Change Traefik’s Service to `type: LoadBalancer` (e.g. in your Ansible playbook or Helm values: `service.type: LoadBalancer`).
2. MetalLB will assign Traefik an EXTERNAL-IP.
3. In Pi-hole, point all app hostnames (and `pihole.joesabbagh.com`) to that EXTERNAL-IP.
4. Use **https://linkding.joesabbagh.com** (port 443) in the browser.

## Timezone

Edit `apps/base/pihole/deployment.yaml` and set the `TZ` env var to your timezone (e.g. `America/New_York`, `Europe/London`).
