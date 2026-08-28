---
name: infra-ops
description: Use when provisioning, monitoring, or maintaining fleet infrastructure — VPS/hosts, Tailscale/Cloudflare networking, Docker/NixOS/systemd services, CI/CD (Woodpecker), backups, OS installs/updates, secrets, or fleet-wide ops. Covers runbooks, VPS_Test flake deploys, vpn-rotate, cloudflared, ufw, and lessons-learned. Load before touching Infra/, VPS_Test/, or any host via ssh/systemd/docker/nix.
---

# Infra / Ops standards

You operate the home-lab fleet that backs every project under `~/Development`. The fleet is the product — a broken deploy is a user-facing outage.

## Sources of truth — read before you touch a host

1. **`~/Development/Infra/README.md`** — fleet inventory, tailnet names, public edge (Cloudflare tunnels), conventions.
2. **`~/Development/Infra/linux-note/`** — alpha (`rafael-linux`) inventory, firewall (`firewall.md`), per-service `services/` compose, `setup.sh`.
3. **`~/Development/Infra/runbooks/`** — repeatable procedures (seat provisioning, protonvpn rotation, backups…). **Runbooks over memory**: if you do it twice, it gets a runbook.
4. **`~/Development/Infra/lessons-learned/`** — dated post-mortems, one file per incident. Read before you retry a risky path; write after every incident/fix.
5. **`~/Development/VPS_Test/`** (repo `github.com/pentateu/vps-test`, NixOS flake) — `vps-test` and `jon-vps` host config. **Flake-only deploys**: `nixos-rebuild test --flake .#<host>` then `switch`; a bare rebuild wipes declared services.
6. **`~/Development/Infra/scripts/`** — parameterized scripts the runbooks reference (e.g. `vpn-rotate.sh`).

## Fleet (2026-08, tailnet `tail8a19c.ts.net`)

| Host | Role | SSH | Notes |
|---|---|---|---|
| `rafael-linux` (alpha) | Manjaro, services: hometutor, Plane, Outline, woodpecker, ollama, postgres, nats, grafana | `ssh rafael@rafael-linux.local` `100.81.253.19` | `cloudflared-alpha` → `*.iswe.co.nz`; `vpn-rotate` for egress IP |
| `vps-test` | NixOS test: hometutor-test, eggs, iot, woodpecker | `ssh root@192.168.0.10` `100.108.226.99` | flake `#vps-test` |
| `plexypi` | Pi: Plex/media | `ssh rafael@plexypi.local` `100.117.70.66` | |
| `jon-vps` | Prod VPS `167.86.84.230` | `ssh root@167.86.84.230` `100.66.166.76` | prod |
| `macos-vm` | Dev workstation, fleet host | `100.67.238.71` | teamctl fleet host |

Public edge is Cloudflare tunnels; tailnet-only services stay on Tailscale-SSH.

## How to use this

- **Before any host mutation**: read the relevant runbook + `INVENTORY.md` + `firewall.md` + last `lessons-learned` for that host/topic. Check `teamctl status` for who else may be on the host.
- **For NixOS hosts**: `cd ~/Development/VPS_Test && nixos-rebuild test --flake .#<host> --target-host root@<host> --build-host root@<host>` then `switch` only after test is green. Never `nixos-rebuild switch` without `--flake`.
- **For alpha/Docker**: prefer `docker compose` under `linux-note/services/<svc>`; `systemctl` for `wg-quick@proton`, `cloudflared`, `tailscaled`.
- **For networking**: `tailscale status`, `tailscale ping`, `ip rule`, `ip route get 100.100.100.100`, `sudo vpn-rotate status/ip/rotate`, `ufw status`.
- **For CI/CD**: Woodpecker pipelines under each repo's `.woodpecker.yml`; Plane `ops` tickets for infra work.
- **Verification before you report done**: `systemctl is-active <svc>`, `docker ps`, `curl` the public hostname via Cloudflare, `getent hosts <tailnet-name>`, and a tailnet `ping`. Paste the outputs — "it works" is not evidence.
- **After**: update the runbook if you deviated, append a dated `lessons-learned/*.md` on any incident, and broadcast with a Plane comment / `teamctl tell`.

## House rules

- **Secrets never committed**: `.env` is gitignored; `.env.example` documents keys; age-encrypted `.age` in `VPS_Test` is OK. Use `envsitter` and `age` tooling; `git diff` must show no secret.
- **Idempotent and reversible**: every remote command must be re-runnable; capture the undo (`vpn-rotate off`, `systemctl stop`, previous flake rev).
- **Blast radius**: whole-host VPN (`vpn-rotate`) and `nixos-rebuild switch` affect every service on that host — announce in `#infra` / Plane ops ticket, and prefer `test` first.
- **Token economy for docs**: runbooks are terse imperative checklists, one procedure per file; lessons-learned are dated, one incident per file, with root cause + fix + prevention.
