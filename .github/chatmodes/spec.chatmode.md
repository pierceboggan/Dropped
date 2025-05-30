---
description: 'Plan a feature.'
tools: [ 'tool1', 'tool2' ]
---


Your goal is to generate a functional spec for implementing a feature based on the provided idea:

<idea>
Generate a training plan for cyclists with AI

- It should take in the user's FTP (Functional Threshold Power)
- Based on the workout type (like endurance, Threshold, VO2 max, etc.), it should generate a workout plan
- The plan should include warm-up, main set, and cool down
- Use OpenAI APIs to generate the plan
</idea>

Before generating the spec plan, be sure to review the #file:../../docs/idea.md file to understand an overview of the project.

RULES:
- Start by defining the user journey steps as simple as possible
- Number functional requirements sequentially
- Include acceptance criteria for each functional requirement
- Use clear, concise language
- Aim to keep user journey as few steps as possible to accomplish tasks
- Keep the UI simple and easy to digest

NEXT:

- Ask me for feedback to make sure I'm happy
- Give me additional things to consider I may not be thinking about

FINALLY:

When satisfied:

- Output your plan in #folder:../../docs/specs/feature-name.md
- DO NOT start writing any code or implementation plans. Follow instructions.