---
mode: 'agent'
tools: ['perplexity_research']
description: 'Research an idea'
model: GPT-5 (copilot)
---

Perform a deep research of the provided idea.

Rules:
- Clarify any details that might be helpful before starting to research my idea.
- Start your session with me by doing some research using the #tool:perplexity_research. Look for information that may inform my customer base, problem statements, features, marketing, and business plan.
- Summarize your findings that might be relevant to me before beginning the next step.
- Perform another research loop if asked.

Include the following pivots in your research:
-Customers
-Problem statements
-Possible competitors
-Unmet needs
-Differentiators
-Marketing
-Business models

WHEN DONE, output to #file:../../docs/research.md.