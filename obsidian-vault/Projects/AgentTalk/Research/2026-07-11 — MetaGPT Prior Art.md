# MetaGPT — Prior Art Survey

**Date:** 2026-07-11  
**Source:** [arXiv:2308.00352](https://arxiv.org/abs/2308.00352) — "MetaGPT: Meta Programming for A Multi-Agent Collaborative Framework" (ICLR 2024)  
**Authors:** Sirui Hong, Mingchen Zhuge, et al. (DeepWisdom)  
**Code:** [github.com/geekan/MetaGPT](https://github.com/geekan/MetaGPT)

---

## The Problem

Naively chaining LLMs leads to **cascading hallucinations** and logic inconsistencies. Prior chat-based multi-agent systems (e.g., ChatDev) suffer from unproductive dialogue loops ("Hi, hello – have you had lunch?") and lack structured output formats.

## Key Innovation

MetaGPT encodes **Standard Operating Procedures (SOPs)** from human software engineering into prompt sequences, then assigns specialized roles to agents in an **assembly-line paradigm**.

> `Code = SOP(Team)` — the core philosophy: materialize SOP and apply it to LLM-based teams.

## Architecture

### Role Specialization

| Role | Responsibilities |
|------|-----------------|
| **Product Manager** | Business analysis, PRD with user stories, competitive analysis, requirement pool |
| **Architect** | System design, file lists, data structures, interface definitions, sequence diagrams |
| **Project Manager** | Task allocation and distribution |
| **Engineer** | Code generation, write + execute unit tests |
| **QA Engineer** | Code review, bug fixing, test generation |

All agents follow the **ReAct** reasoning paradigm (Yao et al., 2022).

### Communication Protocol

- **Structured outputs**, not free-form dialogue: agents produce documents (PRDs, design artifacts, flowcharts, interface specs).
- **Publish-Subscribe mechanism** via a **global message pool**: agents publish structured messages; other agents subscribe only to role-relevant messages (e.g., Architect subscribes to PRD). Solves information overload and complex topology.

### Iterative Programming with Executable Feedback

- Engineer writes code → runs unit tests → debugs.
- Feedback loop: max **3 retries** until tests pass.
- Reduces hallucination during review.

## Performance

| Benchmark | MetaGPT (GPT-4) | GPT-4 baseline |
|-----------|-----------------|----------------|
| HumanEval (Pass@1) | **85.9%** | 67.0% |
| MBPP (Pass@1) | **87.7%** | 78.0% |

On the **SoftwareDev** benchmark (70 tasks), MetaGPT achieved **3.75/4 executability** vs 2.25 for ChatDev. Executive feedback mechanism provided **+5.4% absolute improvement** on MBPP.

## Key Design Decisions for AgentTalk

1. **SOP-driven orchestration** — encoding human workflows as prompts is a proven pattern for reducing hallucination.
2. **Pub-sub message pool** — agents communicate through a shared message bus rather than pairwise channels; role-based subscription keeps information flow relevant.
3. **Structured outputs (documents/diagrams)** — more robust than free-form dialogue for inter-agent handoffs.
4. **Assembly-line decomposition** — complex tasks → chained subtasks → deterministic workflow.
5. **Executable feedback** — running tests on generated code catches errors before they propagate.

## Verdict

MetaGPT is the most directly relevant prior art for AgentTalk's orchestration layer. Its SOP + pub-sub + assembly-line architecture is the strongest reference point for designing structured multi-agent coordination.

**Adopt concepts:** SOP encoding, pub-sub message pool, structured output contracts between agents, iterative feedback with execution.

**Diverge where:** AgentTalk may need more general-purpose orchestration (not just software engineering), and may want a formal consensus protocol for multi-agent decision-making rather than a fixed workflow.

---

**Tags:** #prior-art #metagpt #multi-agent #orchestration #sop #agenttalk
