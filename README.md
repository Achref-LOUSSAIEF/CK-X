# CKA Simulator

A self-hosted practice environment for the **CKA (Certified Kubernetes Administrator)** exam. Every attempt runs on a fresh multi-node Kubernetes cluster in Docker, with an exam-style browser interface, a countdown timer, automatic grading and worked solutions.

> **CKA Simulator is based on [CK-X](https://github.com/sailor-sh/CK-X) by [Sailor.sh](https://sailor.sh).** It is a personal, non-commercial fork focused only on the CKA (plus Helm practice), with more labs and a simpler, ad-free interface. CK-X's copyright, branding and license notices are kept, as its license requires.

## What's different from CK-X

- **CKA only.** The CKAD, CKS and Docker labs were removed; eleven CKA exams, a random CKA exam and a Helm lab remain, listed in a recommended order from Easy to Hard.
- **9 extra CKA exams** (145 tasks) and **CKA Random**, a new mix on every attempt. See [Labs](#labs).
- **Score by domain.** The results page shows your score for each of the five CKA domains and compares the total with the real pass mark (66%).
- **Simple home page.** The site opens directly on the exam list: pick a certification, pick a lab, start. No landing page, and no paid "premium bundle" entries in the list.
- **Closer to the real exam environment.** You start on a machine called `base` with no `kubectl`, and each question names its own host to SSH to; SSH from one exam host to another is refused, as in the real exam, so you go back with `exit`. The exam hosts have `kubectl` (with `k` and completion), `helm`, `yq`, `curl`, `wget`, `man` and passwordless `sudo` / `sudo -i`. Firefox in the exam desktop only opens the documentation the CKA allows (kubernetes.io, helm.sh and the Gateway API docs) plus the task-specific links shown in a question's **Quick Reference**. The question panel doesn't reveal the topic (no "Concepts" line), and there is no plain-terminal view and no Terminate button during the exam, only End Exam.
- **No pop-ups.** The automatic rating/testimonial pop-up after an exam is gone.
- **Kubernetes v1.35**, like the current CKA exam. The exam cluster and the `kubectl` in the exam terminal are pinned to the same version (v1.35.9).
- **Faster start-up.** A local pull-through cache keeps a copy of every Docker Hub image the labs use, and the cluster container keeps its Docker data, so after the first exam the cluster and the lab Pods start without downloading everything again.
- **No usage tracking.** `TRACK_METRICS` is set to `false`, so nothing is sent to the external CK-X metrics server.
- **Its own name.** The interface, the exam desktop and terminal, and the Docker project and images are called CKA Simulator, so it can't be mixed up with an upstream CK-X install.

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
| 9 | **CKA 9 · mockctl Practice 1** *(new)* | Medium | 18 | 120 min |
| 10 | **CKA 10 · mockctl Practice 2** *(new)* | Medium | 18 | 120 min |
| 11 | **CKA 11 · Classic Exam Tasks** *(new)* | Medium | 15 | 120 min |
| 12 | **CKA Random · New Mix Every Attempt** *(new)* | Hard | 16 | 120 min |
| – | Helm Fundamentals | Medium | 12 | 90 min |

- **CKA 9, CKA 10 and CKA 11** are Medium: do them any time after CKA 3, for example between the Hard exams as a confidence check. CKA 11 covers classic exam tasks the other labs don't (filtering logs, counting schedulable nodes, repairing CoreDNS and adding a custom DNS entry, Service and Pod DNS names, sharing a node's resources between replicas, cross-namespace Gateway routes, custom columns).
- **Exam Simulations II and III** cover topics the other labs don't (Downward API, local PVs, aggregated ClusterRoles, ValidatingAdmissionPolicy, PDB-blocked drains, HTTPRoute weights and header matches, and more).
- **CKA Random** builds a different exam on every attempt: 16 tasks drawn from CKA 2 to CKA 11, weighted like the real exam's domains, never two tasks that touch the same namespace, node or cluster-wide object. The solutions page of each attempt says which exam every task comes from. After changing a lab, run `python3 tools/build-random-pool.py` to refresh its pool.
- Where each exam comes from is listed under [Credits](#credits).
- **Not covered:** the simulator gives no SSH access to cluster nodes, so node-level tasks (kubeadm upgrades, etcd backup/restore, kubelet and control-plane repair, CNI and container runtime installation) can't be practised here. The solutions pages explain the kubeadm procedures where a lab replaced such a task.

## Requirements

- Docker with Docker Compose v2 (`docker compose`)
- 4 GB RAM minimum, 8 GB recommended
- About 10 GB of free disk space
- Linux, macOS, or Windows with WSL2
- cgroup v2, which Kubernetes 1.35 requires. This is the default on Docker Desktop and on current Linux distributions; on Linux, `stat -fc %T /sys/fs/cgroup/` should print `cgroup2fs`.

## Quick start

CKA Simulator is **built from source**; the upstream CK-X installer downloads the original CK-X images, which don't include these changes.

```bash
git clone https://github.com/Achref-LOUSSAIEF/CK-X.git cka-simulator
cd cka-simulator
docker compose up -d --build
```

Open **http://localhost:30080**, choose a lab and click **Start exam**. The first build takes a while; preparing the cluster for an exam then takes 3–6 minutes (less once the image cache is filled).

During the exam, open the terminal in the exam desktop: you are on `base`, like in the real exam. Each question names its own host (`ssh cka-q1`, `ssh cka-q2`, …); SSH to it, solve the task, then `exit` back to `base` before the next one (SSH from one exam host to another is refused). The hosts have `kubectl` with the `k` alias and completion, `helm`, `yq`, `curl`, `wget` and `man`; use `sudo` or `sudo -i` for root, as in the exam. Some questions show a **Quick Reference** with documentation for that task: open those links in the desktop's Firefox. All the host names reach the same cluster, so the habit is what you practise; working on the "wrong" host doesn't cost points here. When you end the exam, every task is graded and the solutions become available.

Stop everything with `docker compose down`.

## Updating

After pulling new commits, rebuild and restart:

```bash
git pull
docker compose up -d --build
docker compose restart nginx
```

**Coming from a version named CK-X?** The Docker project is now called `cka-simulator`, so stop the old containers **before** updating, otherwise they keep running under the old name and hold port 30080: run `docker compose down` in the folder first, then update and start as above. The old volumes can be removed afterwards with `docker volume ls` and `docker volume rm`.

## Troubleshooting

| Problem | Fix |
|---|---|
| `localhost:30080` shows `{"message":"Facilitator Service API"}` | Containers got new internal addresses after a rebuild. Run `docker compose restart nginx`. |
| New labs or interface changes don't appear | The images weren't rebuilt. Run `docker compose up -d --build`, then reload with Ctrl+Shift+R. |
| Port 30080 already in use | Another copy is running: an upstream CK-X install, or this one under its old name. Stop it with `docker compose down` in its folder (or `docker compose -p <old-folder-name> down`). |
| Changing the Kubernetes version | Edit `K3S_IMAGE` in `kind-cluster/scripts/env-setup` and `KUBECTL_VERSION` in `jumphost/Dockerfile` (keep them on the same minor version), then run `docker compose build k8s-api-server jumphost && docker compose up -d`. |
| Check or disable the image cache | `docker compose exec k8s-api-server image-cache status` lists the cached images. To turn the cache off, set `CKX_IMAGE_CACHE=false` under `k8s-api-server` in `docker-compose.yaml` and run `docker compose up -d`. To empty it: `docker compose down` then `docker volume rm cka-simulator_ckx-image-cache`. |
| Lab preparation never finishes | Check the cluster logs with `docker compose logs -f k8s-api-server` and make sure Docker has enough memory. |

## Adding your own labs

Each lab is a folder under `facilitator/assets/exams/<category>/<id>/` with an `assessment.json` (questions and checks), setup and validation scripts, and an `answers.md`. Register it in `facilitator/assets/exams/labs.json` and rebuild the facilitator. The full format is described in the [Lab Creation Guide](docs/how-to-add-new-labs.md).

## Credits

**The simulator.** CKA Simulator is based on [CK-X](https://github.com/sailor-sh/CK-X) by [Sailor.sh](https://sailor.sh), originally created by [Nishan B](https://github.com/nishanb). The exam engine, the interface it grew from, the remote desktop and the cluster setup are theirs.

**The exams.** Where every exam comes from:

| Exam | Source | Owner and license | What was changed |
|---|---|---|---|
| CKA 1 · Warm-up: Core Concepts | Original CK-X lab `cka-001` | [CK-X](https://github.com/sailor-sh/CK-X) by Sailor.sh, BSL 1.1 | Reworded like the real exam, graders made less strict about image tags and container names |
| CKA 2 · Mock Exam A | Mock Exam 01 of [theplatformlab/CKA-Certified-Kubernetes-Administrator](https://github.com/theplatformlab/CKA-Certified-Kubernetes-Administrator) | © 2026 TECH WITH MOHAMED, MIT License | Made concrete and auto-graded; the 3 tasks that need SSH to a node were replaced. The MIT license text is reproduced in its solutions page |
| CKA 3 · Mock Exam B | Mock Exam 02 of the same repository | © 2026 TECH WITH MOHAMED, MIT License | Same as above |
| CKA 4 · Advanced Administration | Original CK-X lab `cka-002` | [CK-X](https://github.com/sailor-sh/CK-X) by Sailor.sh, BSL 1.1 | Questions clarified, graders and setup fixed, reworded like the real exam |
| CKA 5 · Troubleshooting & Cluster Operations | Written for CKA Simulator | – | – |
| CKA 6 · Final Exam Simulation | Written for CKA Simulator; the list of topics was inspired by [markdjones82/CKA-PREP-2025-v2](https://github.com/markdjones82/CKA-PREP-2025-v2) | Topic idea credited to [markdjones82](https://github.com/markdjones82); no text, scenario or script was copied (that repository has no license) | – |
| CKA 7 · Exam Simulation II | Written for CKA Simulator | – | – |
| CKA 8 · Exam Simulation III | Written for CKA Simulator | – | – |
| CKA 9 · mockctl Practice 1 | Tasks 1–15 from Unofficial CKA Practice Exam 1 of [ericsson-james/mockctl-exam-lab](https://github.com/ericsson-james/mockctl-exam-lab); tasks 16–18 written for CKA Simulator | © 2026 James Ericsson, MIT License | Moved from mockctl's simulated cluster to a real one; its 3 node-level tasks were left out. The MIT license text is reproduced in its solutions page |
| CKA 10 · mockctl Practice 2 | Tasks 1–14 from Unofficial CKA Practice Exam 2 of the same repository; tasks 15–18 written for CKA Simulator | © 2026 James Ericsson, MIT License | Same as above |
| CKA 11 · Classic Exam Tasks | Written for CKA Simulator; the topics were inspired by the practice questions and runbooks of [cloudhein/CKA](https://github.com/cloudhein/CKA) | Topic ideas credited to [cloudhein](https://github.com/cloudhein); no text, scenario or script was copied (that repository has no license) | – |
| CKA Random | A mix of the tasks of CKA 2 to CKA 11, so the credits above apply to each task; every solutions page names the exam each task comes from | – | – |
| Helm Fundamentals | Original CK-X lab `helm-001` | [CK-X](https://github.com/sailor-sh/CK-X) by Sailor.sh, BSL 1.1 | – |

Each exam's solutions page repeats its credit at the top. If you own one of these sources and want the credit worded differently, or the content removed, please open an issue.

**Software.** Built on [Docker-in-Docker](https://www.docker.com/), [k3d](https://k3d.io/stable/), [Node.js](https://nodejs.org/en), [Nginx](https://nginx.org/) and [ConSol VNC](https://github.com/ConSol/docker-headless-vnc-container/)

## Disclaimer

CKA Simulator and CK-X are independent tools, not affiliated with the CNCF, the Linux Foundation or PSI, and do not guarantee exam success. See the [Privacy Policy](docs/PRIVACY_POLICY.md) and [Terms of Service](docs/TERMS_OF_SERVICE.md).

## License

CKA Simulator is a modified version of CK-X and is distributed under the same license as CK-X: the **Business Source License 1.1** by Sailor.sh. Personal, educational, research and non-production use is allowed; commercial or production use, hosting it as a service, and selling or monetizing it require a commercial license from Sailor.sh. See [LICENSE](LICENSE) for the full terms.
