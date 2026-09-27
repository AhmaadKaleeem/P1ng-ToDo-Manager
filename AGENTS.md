# Agent Harness Guidelines

This project follows the principles from [Awesome Harness Engineering](https://github.com/ai-boost/awesome-harness-engineering) and the **Ponytail**, **Impeccable**, and **Hedgehog** skills.

## Context Management
1. **Minimize Token Usage**: Only read the files you strictly need for the task. Do not `cat` or `view_file` massive files unless necessary.
2. **File Structure**: UI components are split into `lib/presentation/pages/` and `lib/presentation/widgets/`. Only load the specific page or widget you are modifying.
3. **Avoid Boilerplate**: Follow Ponytail rules—use the standard library, YAGNI, delete over addition.
4. **Impeccable Design**: For any UI work, use `Impeccable` guidelines—outstanding UI, animations, modern typography, excellent UX.
5. **No Excessive Comments (Ponytail)**: Do not add boilerplate or obvious comments (e.g., `// builds the widget`). Code should be self-documenting. Only write comments when necessary to explain *why* a specific technical decision was made, or to guide another developer through complex logic.
6. **No Backend Code**: Do not write server or backend code unless explicitly instructed. If a feature requires a backend, inform and guide the user first. (Note: Local SQLite/Drift persistence is considered part of the local-first frontend app and is permitted).
7. **Hedgehog Architecture**: Rely on the `hedgehog` skill for deep system integration, rapid problem-solving, and efficient scaffolding.
8. **Automatic Documentation**: Whenever a new feature is built or completed, you MUST automatically update the project documentation (such as PRODUCT.md or ROADMAP.md) by applying the `/copywriting` skill to write persuasive, human-sounding product copy for the new feature before ending your turn.
