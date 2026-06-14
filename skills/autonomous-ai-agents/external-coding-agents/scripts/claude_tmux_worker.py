#!/usr/bin/env python3
"""Manage an interactive Claude Code worker inside tmux.

This is for Hermes-driven delegation to a durable interactive Claude CLI session,
not for OpenAI-compatible API wrapping.

Examples:
  python3 claude_tmux_worker.py start --session claude-review --workdir /path/to/repo --yolo
  python3 claude_tmux_worker.py send --session claude-review --prompt "Review auth.py; run tests; summarize findings."
  python3 claude_tmux_worker.py capture --session claude-review --lines 120
  python3 claude_tmux_worker.py stop --session claude-review
"""
from __future__ import annotations

import argparse
import os
import shlex
import shutil
import subprocess
import sys
from pathlib import Path


def run(cmd: list[str], *, check: bool = True, cwd: str | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=cwd, check=check)


def require(cmd: str) -> str:
    path = shutil.which(cmd)
    if not path:
        raise SystemExit(f"Required command not found: {cmd}")
    return path


def tmux_has(session: str) -> bool:
    return run(["tmux", "has-session", "-t", session], check=False).returncode == 0


def start(args: argparse.Namespace) -> int:
    require("tmux")
    require("claude")
    workdir = str(Path(args.workdir).expanduser().resolve())
    if not Path(workdir).is_dir():
        print(f"workdir not found: {workdir}", file=sys.stderr)
        return 2
    if tmux_has(args.session):
        print(f"tmux session already exists: {args.session}")
        return 0

    claude_args = ["claude"]
    if args.name:
        claude_args += ["--name", args.name]
    if args.model:
        claude_args += ["--model", args.model]
    if args.effort:
        claude_args += ["--effort", args.effort]
    if args.resume:
        claude_args += ["--resume", args.resume]
    if args.continue_last:
        claude_args += ["--continue"]
    if args.yolo:
        claude_args += ["--dangerously-skip-permissions", "--permission-mode", "bypassPermissions"]
    elif args.permission_mode:
        claude_args += ["--permission-mode", args.permission_mode]
    for d in args.add_dir or []:
        claude_args += ["--add-dir", str(Path(d).expanduser().resolve())]
    if args.append_system_prompt:
        claude_args += ["--append-system-prompt", args.append_system_prompt]

    cmd = " ".join(shlex.quote(x) for x in claude_args)
    run(["tmux", "new-session", "-d", "-s", args.session, "-c", workdir, "-x", str(args.width), "-y", str(args.height), cmd])
    print(f"started {args.session} in {workdir}: {cmd}")
    return 0


def send(args: argparse.Namespace) -> int:
    require("tmux")
    if not tmux_has(args.session):
        print(f"tmux session not found: {args.session}", file=sys.stderr)
        return 2
    prompt = args.prompt
    if args.prompt_file:
        prompt = Path(args.prompt_file).expanduser().read_text(encoding="utf-8")
    if not prompt:
        print("no prompt supplied", file=sys.stderr)
        return 2
    run(["tmux", "send-keys", "-t", args.session, "-l", prompt])
    run(["tmux", "send-keys", "-t", args.session, "Enter"])
    print(f"sent prompt to {args.session} ({len(prompt)} chars)")
    return 0


def capture(args: argparse.Namespace) -> int:
    require("tmux")
    if not tmux_has(args.session):
        print(f"tmux session not found: {args.session}", file=sys.stderr)
        return 2
    cp = run(["tmux", "capture-pane", "-t", args.session, "-p", "-S", f"-{args.lines}"])
    print(cp.stdout.rstrip())
    return 0


def stop(args: argparse.Namespace) -> int:
    require("tmux")
    if tmux_has(args.session):
        if args.graceful:
            run(["tmux", "send-keys", "-t", args.session, "/exit", "Enter"], check=False)
        else:
            run(["tmux", "kill-session", "-t", args.session], check=False)
        print(f"stopped {args.session}")
    else:
        print(f"tmux session not found: {args.session}")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("start")
    p.add_argument("--session", required=True)
    p.add_argument("--workdir", default=os.getcwd())
    p.add_argument("--name")
    p.add_argument("--model")
    p.add_argument("--effort", choices=["low", "medium", "high", "xhigh", "max"])
    p.add_argument("--resume")
    p.add_argument("--continue-last", action="store_true")
    p.add_argument("--permission-mode", choices=["acceptEdits", "auto", "bypassPermissions", "default", "dontAsk", "plan"])
    p.add_argument("--yolo", action="store_true")
    p.add_argument("--add-dir", action="append")
    p.add_argument("--append-system-prompt")
    p.add_argument("--width", type=int, default=140)
    p.add_argument("--height", type=int, default=45)
    p.set_defaults(func=start)

    p = sub.add_parser("send")
    p.add_argument("--session", required=True)
    p.add_argument("--prompt")
    p.add_argument("--prompt-file")
    p.set_defaults(func=send)

    p = sub.add_parser("capture")
    p.add_argument("--session", required=True)
    p.add_argument("--lines", type=int, default=120)
    p.set_defaults(func=capture)

    p = sub.add_parser("stop")
    p.add_argument("--session", required=True)
    p.add_argument("--graceful", action="store_true")
    p.set_defaults(func=stop)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
