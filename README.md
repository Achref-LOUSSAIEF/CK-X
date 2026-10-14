# CK-X Simulator — Achref's edition

A self-hosted practice environment for the **CKA (Certified Kubernetes Administrator)** exam. Every attempt runs on a fresh multi-node Kubernetes cluster in Docker, with an exam-style browser interface, a countdown timer, automatic grading and worked solutions.

This is a personal fork of [CK-X](https://github.com/sailor-sh/CK-X) by Sailor.sh, focused only on the CKA (plus Helm practice), with more labs and a simpler, ad-free interface.

## What's different in this fork

- **CKA only.** The CKAD, CKS and Docker labs were removed; six CKA exams and a Helm lab remain, listed in a recommended order from Easy to Hard.
- **4 extra CKA exams** (62 tasks). See [Labs](#labs).
- **Simple home page.** The site opens directly on the exam list: pick a certification, pick a lab, start. No landing page, and no paid "premium bundle" entries in the list.
- **Closer to the real exam interface.** Each question has its own host to SSH to, Firefox in the exam desktop only opens the allowed documentation (kubernetes.io and helm.sh), the question panel doesn't reveal the topic (no "Concepts" line), and there is no plain-terminal view and no Terminate button during the exam, only End Exam.
- **No pop-ups.** The automatic rating/testimonial pop-up after an exam is gone.
- **Kubernetes v1.35**, like the current CKA exam. The exam cluster and the `kubectl` in the exam terminal are pinned to the same version (v1.35.9).
- **No usage tracking.** `TRACK_METRICS` is set to `false`, so nothing is sent to the external CK-X metrics server.

## Labs

Work through them in this order:

| # | Exam | Difficulty | Tasks | Time |
|---|---|---|---|---|
| 1 | CKA 1 · Warm-up: Core Concepts | Easy | 10 | 60 min |
| 2 | **CKA 2 · Mock Exam A** *(new)* | Medium | 15 | 120 min |
| 3 | **CKA 3 · Mock Exam B** *(new)* | Medium | 15 | 120 min |
| 4 | CKA 4 · Advanced Administration *(questions clarified, graders fixed)* | Hard | 20 | 120 min |
| 5 | **CKA 5 · Troubleshooting & Cluster Operations** *(new)* | Hard | 18 | 120 min |
| 6 | **CKA 6 · Final Exam Simulation** *(new)* | Hard | 14 | 120 min |
| 7 | **CKA 7 · Exam Simulation II** *(new)* | Hard | 16 | 120 min |
| 8 | **CKA 8 · Exam Simulation III** *(new)* | Hard | 16 | 120 min |
| 9 | **CKA Random · New Mix Every Attempt** *(new)* | Hard | 16 | 120 min |
| – | Helm Fundamentals | Medium | 12 | 90 min |

- **Mock Exams A and B** are adapted from [theplatformlab/CKA-Certified-Kubernetes-Administrator](https://github.com/theplatformlab/CKA-Certified-Kubernetes-Administrator) (MIT).
- **Final Exam Simulation** is an original exam; its list of topics was inspired by [markdjones82/CKA-PREP-2025-v2](https://github.com/markdjones82/CKA-PREP-2025-v2).
- **Exam Simulations II and III** are original exams on topics the other labs don't cover (Downward API, local PVs, aggregated ClusterRoles, ValidatingAdmissionPolicy, PDB-blocked drains, HTTPRoute weights and header matches, and more).
- **CKA Random** builds a different exam on every attempt: 16 tasks drawn from CKA 2 to CKA 8, weighted like the real exam's domains, never two tasks that touch the same namespace, node or cluster-wide object. The solutions page of each attempt says which exam every task comes from. After changing a lab, run `python3 tools/build-random-pool.py` to refresh its pool.
- **Not covered:** CK-X gives no SSH access to cluster nodes, so node-level tasks (kubeadm upgrades, etcd backup/restore, kubelet and control-plane repair, CNI and container runtime installation) can't be practised here. The solutions pages explain the kubeadm procedures where a lab replaced such a task.

## Requirements

- Docker with Docker Compose v2 (`docker compose`)
- 4 GB RAM minimum, 8 GB recommended
- About 10 GB of free disk space
- Linux, macOS, or Windows with WSL2
- cgroup v2, which Kubernetes 1.35 requires. This is the default on Docker Desktop and on current Linux distributions; on Linux, `stat -fc %T /sys/fs/cgroup/` should print `cgroup2fs`.

## Quick start

This fork has to be **built from source**. The upstream one-line installer downloads the original images, which don't include these changes.

```bash
git clone https://github.com/Achref-LOUSSAIEF/CK-X.git
cd CK-X
docker compose build webapp facilitator
docker compose up -d
```

Open **http://localhost:30080**, choose a lab and click **Start exam**. Preparing the cluster takes 3–6 minutes.

During the exam, each question names its own host, like the real exam (`ssh cka-q1`, `ssh cka-q2`, …). Open the terminal in the exam desktop and SSH to that host first; its prompt shows the host you're on. `kubectl`, `helm` and `jq` are installed, and `k` is an alias for `kubectl`. All these host names reach the same machine, so the habit is what you practise; working on the "wrong" host doesn't cost points here. When you end the exam, every task is graded and the solutions become available.

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
| Changing the Kubernetes version | Edit `K3S_IMAGE` in `kind-cluster/scripts/env-setup` and `KUBECTL_VERSION` in `jumphost/Dockerfile` (keep them on the same minor version), then run `docker compose build k8s-api-server jumphost && docker compose up -d`. |
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
