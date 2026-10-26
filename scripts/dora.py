#!/usr/bin/env python3
"""Approximate the four DORA metrics from GitHub Actions history (stdlib only).

A "deployment" is a successful `deploy-dev` job in the `ci` workflow on main.
  - Deployment frequency: successful deployments per day
  - Lead time for changes: commit timestamp -> deploy-dev job completed (median)
  - Change failure rate: failed ci runs on main / all completed ci runs on main
  - Time to restore: failed run -> next successful run (median)

Usage:
  GITHUB_TOKEN=... python3 scripts/dora.py --repo owner/devops-prototype --days 30
  (token optional for public repos; without it the API allows 60 requests/hour)
"""

from __future__ import annotations

import argparse
import json
import os
import statistics
import subprocess
import sys
import urllib.request
from datetime import datetime, timedelta, timezone

API = "https://api.github.com"


def gh_get(path: str) -> dict:
    req = urllib.request.Request(API + path, headers={"Accept": "application/vnd.github+json"})  # noqa: S310
    token = os.getenv("GITHUB_TOKEN")
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    with urllib.request.urlopen(req, timeout=30) as resp:  # noqa: S310 (fixed https host)
        return json.load(resp)


def parse(ts: str) -> datetime:
    return datetime.fromisoformat(ts.replace("Z", "+00:00"))


def default_repo() -> str | None:
    try:
        url = subprocess.check_output(
            ["git", "config", "--get", "remote.origin.url"], text=True  # noqa: S607
        ).strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None
    tail = url.split("github.com")[-1].lstrip(":/")
    return (tail[:-4] if tail.endswith(".git") else tail) or None


def human(td: timedelta | None) -> str:
    if td is None:
        return "n/a"
    minutes = td.total_seconds() / 60
    return f"{minutes:.0f} min" if minutes < 120 else f"{minutes / 60:.1f} h"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--repo", default=default_repo(), help="owner/name")
    parser.add_argument("--days", type=int, default=30)
    args = parser.parse_args()
    if not args.repo:
        print("Pass --repo owner/name (no git remote found)", file=sys.stderr)
        return 2

    # timezone.utc (not datetime.UTC) keeps this runnable on macOS's system Python 3.9
    since = datetime.now(timezone.utc) - timedelta(days=args.days)  # noqa: UP017
    runs = gh_get(
        f"/repos/{args.repo}/actions/workflows/ci.yml/runs"
        f"?branch=main&event=push&per_page=100&created=>={since:%Y-%m-%d}"
    )["workflow_runs"]
    completed = sorted(
        (r for r in runs if r["status"] == "completed"), key=lambda r: r["created_at"]
    )

    deploys, lead_times = 0, []
    for run in completed:
        if run["conclusion"] != "success":
            continue
        jobs = gh_get(f"/repos/{args.repo}/actions/runs/{run['id']}/jobs")["jobs"]
        job = next((j for j in jobs if j["name"] == "deploy-dev"), None)
        if job and job["conclusion"] == "success" and job["completed_at"]:
            deploys += 1
            committed = parse(run["head_commit"]["timestamp"])
            lead_times.append(parse(job["completed_at"]) - committed)

    failures = [r for r in completed if r["conclusion"] == "failure"]
    successes = [r for r in completed if r["conclusion"] == "success"]
    restore_times = []
    for f in failures:
        nxt = next((s for s in successes if s["created_at"] > f["created_at"]), None)
        if nxt:
            restore_times.append(parse(nxt["updated_at"]) - parse(f["updated_at"]))

    judged = len(failures) + len(successes)
    print(f"DORA report for {args.repo}, last {args.days} days")
    print(f"  Deployment frequency : {deploys / args.days:.2f} per day ({deploys} deploys)")
    lead = statistics.median(lead_times) if lead_times else None
    print(f"  Lead time (median)   : {human(lead)}")
    cfr = f"{100 * len(failures) / judged:.0f}%" if judged else "n/a"
    print(f"  Change failure rate  : {cfr} ({len(failures)}/{judged} runs)")
    mttr = statistics.median(restore_times) if restore_times else None
    print(f"  Time to restore      : {human(mttr)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
