#!/usr/bin/env python3
"""Build the question pool of the "CKA Random" exam.

Run it again after adding or changing a CKA lab:

    python3 tools/build-random-pool.py

It reads every CKA lab listed in SOURCES (assessment.json, setup and
validation scripts, answers.md) and writes
facilitator/assets/exams/cka/random/pool.json. For each question it records:

  claims  resources the task owns (namespaces, host files, cluster-scoped
          objects, nodes it changes). Two tasks with a common claim are
          never picked for the same attempt.
  uses    shared things the task relies on (a node it pins Pods to, the
          default StorageClass). A task that uses X is never picked together
          with a task that claims X.

The facilitator picks a conflict-free mix from this pool on every attempt
(facilitator/src/services/randomExamService.js).
"""
import json
import os
import re

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
EXAMS = os.path.join(ROOT, "facilitator", "assets", "exams")
OUT = os.path.join(EXAMS, "cka", "random", "pool.json")

SOURCES = ["cka/002", "cka/003", "cka/004", "cka/005", "cka/006", "cka/007", "cka/008", "cka/009", "cka/010", "cka/011"]

# Tasks that drain or cordon a node: they evict the Pods of every other task
# on that node, so they only make sense in their own exam.
EXCLUDE = {"cka/003/7", "cka/004/3", "cka/007/12", "cka/010/14"}

NODE_RE = re.compile(r"k3d-cluster-(?:agent-[01]|server-0)")
COREDNS_CHANGES = re.compile(r"(?:configmap|cm) coredns|coredns-custom|rollout restart (?:deployment|deploy) coredns")
NODE_CHANGES = re.compile(r"kubectl (?:taint|label) (?:node|nodes|no)\b|kubectl (?:cordon|drain|uncordon)\b")
CLUSTER_KINDS = {
    "StorageClass": "storageclass", "PriorityClass": "priorityclass", "ClusterRole": "clusterrole",
    "ClusterRoleBinding": "clusterrolebinding", "CustomResourceDefinition": "crd",
    "PersistentVolume": "pv", "ValidatingAdmissionPolicy": "vap",
    "ValidatingAdmissionPolicyBinding": "vapbinding", "IngressClass": "ingressclass",
    "RuntimeClass": "runtimeclass",
}
CLI_KINDS = {
    "storageclass": "storageclass", "sc": "storageclass", "priorityclass": "priorityclass",
    "pc": "priorityclass", "clusterrole": "clusterrole", "clusterrolebinding": "clusterrolebinding",
    "pv": "pv", "persistentvolume": "pv", "crd": "crd", "ingressclass": "ingressclass",
}


def answer_sections(path):
    """Split answers.md into {question id: section text}."""
    sections, cur, buf = {}, None, []
    for line in open(path, encoding="utf-8"):
        m = re.match(r"^## Question (\d+)\b", line)
        if m:
            if cur:
                sections[cur] = "".join(buf)
            cur, buf = m.group(1), [line]
        elif cur:
            buf.append(line)
    if cur:
        sections[cur] = "".join(buf)
    return sections


def analyse(lab, q, answers):
    qid = q["id"]
    files = [os.path.join(EXAMS, lab, "scripts", "setup", f"q{qid}_setup.sh")]
    files += [os.path.join(EXAMS, lab, "scripts", "validation", v["verificationScriptFile"]) for v in q["verification"]]
    scripts = "\n".join(open(f, encoding="utf-8").read() for f in files if os.path.exists(f))
    setup = open(files[0], encoding="utf-8").read() if os.path.exists(files[0]) else ""
    text = "\n".join([q["question"], scripts, answers.get(qid, "")])

    claims, uses = set(), set()
    # namespaces
    nss = set(re.findall(r"(?:\s-n|--namespace)[ =]([a-z0-9][a-z0-9-]*)", text))
    nss |= set(re.findall(r"\bnamespace:\s*([a-z0-9][a-z0-9-]*)", text))
    nss |= set(re.findall(r"create (?:namespace|ns) ([a-z0-9][a-z0-9-]*)", text))
    nss |= set(re.findall(r"namespaces? `([a-z0-9][a-z0-9-]*)`", text))
    nss.add(q["namespace"])
    claims |= {f"ns:{n}" for n in nss if n not in ("kube-system", "kube-node-lease")}
    # files on the exam host outside /tmp/exam/qN (those are renumbered)
    for p in re.findall(r"(?<![\w.-])(/(?:tmp|opt|root|home/candidate)/[A-Za-z0-9_.-]+(?:/[A-Za-z0-9_.-]+)*)", text):
        if re.match(r"^/tmp/exam/q\d+(/|$)", p) or p.startswith("/tmp/exam-assets") or p in ("/tmp/exam", "/tmp"):
            continue
        claims.add("path:" + p)
    # cluster-scoped objects
    for kind, name in re.findall(r"kind: (\w+)\s*\n(?:[^\n]*\n){0,3}?\s*name: ([a-z0-9][a-z0-9.-]*)", text):
        if kind in CLUSTER_KINDS:
            claims.add(f"{CLUSTER_KINDS[kind]}:{name}")
    for verb_kind, name in re.findall(r"kubectl (?:create|get|delete|patch|edit|describe|annotate|label) (\w+) ([a-z0-9][a-z0-9.-]*)", text):
        if verb_kind in CLI_KINDS:
            claims.add(f"{CLI_KINDS[verb_kind]}:{name}")
    # nodes
    nodes = set(NODE_RE.findall(text))
    if NODE_CHANGES.search(scripts + answers.get(qid, "")):
        claims |= {f"node:{n}" for n in nodes}
    else:
        uses |= {f"node:{n}" for n in nodes}
    # default StorageClass
    # changing the default StorageClass happens in a setup script or in the solution;
    # a grader that only checks the annotation does not change it
    if "is-default-class" in setup + answers.get(qid, ""):
        claims.add("default-storageclass")
    elif re.search(r"PersistentVolumeClaim|volumeClaimTemplates|default StorageClass", text):
        uses.add("default-storageclass")
    # CoreDNS: a task that edits or restarts it would disturb a task that relies on it
    if COREDNS_CHANGES.search(setup + answers.get(qid, "")):
        claims.add("coredns")
    elif re.search(r"coredns", text, re.I):
        uses.add("coredns")
    uses -= claims
    return sorted(claims), sorted(uses)


def main():
    pool = []
    for lab in SOURCES:
        labdir = os.path.join(EXAMS, lab)
        cfg = json.load(open(os.path.join(labdir, "config.json")))
        questions = json.load(open(os.path.join(labdir, cfg.get("questions", "assessment.json"))))["questions"]
        answers = answer_sections(os.path.join(labdir, "answers.md"))
        for q in questions:
            key = f"{lab}/{q['id']}"
            if key in EXCLUDE or not q.get("domain") or q["id"] not in answers:
                continue
            claims, uses = analyse(lab, q, answers)
            pool.append({"source": lab, "id": q["id"], "domain": q["domain"], "claims": claims, "uses": uses})
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w") as f:
        json.dump({"generatedBy": "tools/build-random-pool.py", "questions": pool}, f, indent=1)
        f.write("\n")
    by = {}
    for p in pool:
        by[p["domain"]] = by.get(p["domain"], 0) + 1
    print(f"{len(pool)} questions in the pool:", by)


if __name__ == "__main__":
    main()
