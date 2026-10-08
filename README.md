# CK-X Simulator — Achref's edition

A self-hosted practice environment for the Kubernetes certification exams (CKA, CKAD, CKS). Every attempt runs on a fresh multi-node Kubernetes cluster in Docker, with an exam-style browser interface, a countdown timer, automatic grading and worked solutions.

This is a personal fork of [CK-X](https://github.com/sailor-sh/CK-X) by Sailor.sh. It adds more CKA labs and a simpler, ad-free interface.

## What's different in this fork

- **3 extra CKA labs** (48 tasks, about 113 automatic checks). See [Labs](#labs).
- **Simple home page.** The site opens directly on the exam list: pick a certification, pick a lab, start. No landing page, and no paid "premium bundle" entries in the list.
- **No pop-ups.** The automatic rating/testimonial pop-up after an exam is gone.
- **No usage tracking.** `TRACK_METRICS` is set to `false`, so nothing is sent to the external CK-X metrics server.

## Labs

| Certification | Lab | Tasks | Difficulty | Time |
|---|---|---|---|---|
| CKA | Practice Lab - Core Concepts | 10 | Easy | 60 min |
| CKA | Practice Lab - Advanced Administration | 20 | Hard | 120 min |
| CKA | **Practice Lab - Troubleshooting & Cluster Operations** *(new)* | 18 | Hard | 120 min |
| CKA | **Mock Exam 01 (theplatformlab)** *(new)* | 15 | Medium | 120 min |
| CKA | **Mock Exam 02 (theplatformlab)** *(new)* | 15 | Medium | 120 min |
| CKAD | Comprehensive Lab - 1 | 21 | Medium | 120 min |
| CKAD | Comprehensive Lab - 2 | 20 | Hard | 120 min |
| CKS | Practice Lab - Kubernetes Security Essentials | 12 | Hard | 120 min |
| Other | Docker Speed Run - Core Concepts | 16 | Medium | 90 min |
| Other | Helm Fundamentals Lab | 12 | Medium | 90 min |

The two mock exams are adapted from [theplatformlab/CKA-Certified-Kubernetes-Administrator](https://github.com/theplatformlab/CKA-Certified-Kubernetes-Administrator) (MIT). Tasks that need SSH access to the nodes (container runtime setup, audit logs, `kubeadm certs renew`) were replaced with equivalents that can be graded through the API; each lab's solutions page explains the original kubeadm procedure.

## Requirements

- Docker with Docker Compose v2 (`docker compose`)
- 4 GB RAM minimum, 8 GB recommended
- About 10 GB of free disk space
- Linux, macOS, or Windows with WSL2

## Quick start

This fork has to be **built from source**. The upstream one-line installer downloads the original images, which don't include these changes.

```bash
git clone https://github.com/Achref-LOUSSAIEF/CK-X.git
cd CK-X
docker compose build webapp facilitator
docker compose up -d
```

Open **http://localhost:30080**, choose a lab and click **Start exam**. Preparing the cluster takes 3–6 minutes.

During the exam you work in the terminal of the host `ckad9999` (`kubectl`, `helm`, `jq` are installed and `k` is an alias for `kubectl`). When you end the exam, every task is graded and the solutions become available.

Stop everything with `docker compose down`.

## Updating

After pulling new commits, rebuild the two services that contain the interface and the labs:

```bash
git pull
docker compose build webapp facilitator
docker compose up -d
docker compose restart nginx
```

## Troubleshooting

| Problem | Fix |
|---|---|
| `localhost:30080` shows `{"message":"Facilitator Service API"}` | Containers got new internal addresses after a rebuild. Run `docker compose restart nginx`. |
| New labs or interface changes don't appear | The prebuilt images are still in use. Run `docker compose build webapp facilitator && docker compose up -d`, then reload with Ctrl+Shift+R. |
| Port 30080 already in use | Another copy of CK-X is running (for example the one installed by the upstream installer). Stop it with `docker compose down` in its folder. |
| Lab preparation never finishes | Check the cluster logs with `docker compose logs -f k8s-api-server` and make sure Docker has enough memory. |

## Adding your own labs

Each lab is a folder under `facilitator/assets/exams/<category>/<id>/` with an `assessment.json` (questions and checks), setup and validation scripts, and an `answers.md`. Register it in `facilitator/assets/exams/labs.json` and rebuild the facilitator. The full format is described in the [Lab Creation Guide](docs/how-to-add-new-labs.md).

## Credits

- [CK-X](https://github.com/sailor-sh/CK-X) by [Sailor.sh](https://sailor.sh), the simulator this fork is based on
- [theplatformlab/CKA-Certified-Kubernetes-Administrator](https://github.com/theplatformlab/CKA-Certified-Kubernetes-Administrator) (MIT, © 2026 TECH WITH MOHAMED), source of the two mock exams
- Built on [Docker-in-Docker](https://www.docker.com/), [k3d](https://k3d.io/stable/), [Node.js](https://nodejs.org/en), [Nginx](https://nginx.org/) and [ConSol VNC](https://github.com/ConSol/docker-headless-vnc-container/)

## Disclaimer

CK-X is an independent tool, not affiliated with the CNCF, the Linux Foundation or PSI, and does not guarantee exam success. See the [Privacy Policy](docs/PRIVACY_POLICY.md) and [Terms of Service](docs/TERMS_OF_SERVICE.md).

## License

CK-X is licensed under the **Business Source License 1.1** by Sailor.sh. Personal, educational, research and non-production use is allowed; commercial or production use, hosting it as a service, and selling or monetizing it require a commercial license from Sailor.sh. See [LICENSE](LICENSE) for the full terms.
