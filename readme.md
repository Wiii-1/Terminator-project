# Terminator Hunt: Relentless Agentic AI Predator for Project Zomboid

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Development Tools](#development-tools)
- [Python Libraries & Tools](#python-libraries--tools-for-terminator-hunt-mod)
- [Installation](#installation)
- [Usage](#usage)
- [Development Roadmap](#development-roadmap)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

**Terminator Hunt** is a Project Zomboid mod that introduces a relentless, adaptive AI predator inspired by the Terminator. The AI hunts, adapts, and escalates its behavior to create a tense and unpredictable survival experience.

---

## Features

- **Advanced AI**: Patrols, tracks, and hunts the player using decision trees and state machines.
- **Dynamic Threats**: Scavenges for weapons, sets traps, and creates ambushes.
- **Adaptive Escalation**: Responds to player actions, noise, and comfort level.
- **Environmental Interaction**: Uses traps, desecrates corpses, and leaves storytelling cues.
- **Sandbox Testing**: Designed for iterative testing in Project Zomboid sandbox mode.

---

## Development Tools

- **IDE**: Visual Studio Code or any Lua editor
- **Game Modding**: Project Zomboid + Lua modding API
- **Version Control**: Git & GitHub (or locally)
- **Testing**: Project Zomboid sandbox mode
- **Optional Helpers**: Coding agents for scaffolding Lua functions or repetitive scripts

---

## Python Libraries & Tools for Terminator Hunt Mod

### 1. AI / Decision Logic Testing
- **`networkx`** – For graph-based pathfinding simulations. Model maps and AI movement before translating to Lua.
- **`numpy` / `scipy`** – For calculations, probability distributions, and simple decision weights.
- **`random`** – Procedural generation testing for traps, ambush points, or loot distribution.

### 2. Procedural Generation
- **`noise`** – Perlin/simplex noise for terrain or trap placement simulations.
- **`matplotlib` / `seaborn`** – Visualize procedural layouts or AI movement patterns before coding in Lua.

### 3. Workflow / Automation Helpers
- **`Jupyter Notebook`** – Prototype AI behavior, test algorithms, visualize results quickly.
- **`pandas`** – Manage and track simulated resource inventories, AI decisions, or escalation triggers.

### 4. Optional Utilities
- **`pyinstaller`** – If you want to package any Python helper scripts to run offline.
- **VSCode extensions:** Lua, Python, GitLens for version control.

---

## Other Tools

- **Lua IDE / Debugger** – VSCode with Lua plugin, or ZeroBrane Studio.
- **Git/GitHub** – Version control, especially with two developers.
- **Project Zomboid Sandbox** – Test AI in real scenarios.
- **Diagramming tool** – Draw AI state machines & decision trees (draw.io, Lucidchart).
- **Optional code agents** – Can scaffold repetitive Lua functions or procedural scripts to save time.

---

## Installation

1. Set up the Project Zomboid modding environment.
2. Clone or download this repository into your Project Zomboid `mods` folder.
3. Follow the mod setup instructions in the documentation (coming soon).

---

## Usage

1. Launch Project Zomboid in sandbox mode.
2. Enable the "Terminator Hunt" mod in the mods menu.
3. Play and experience the relentless AI predator.

---

## Development Roadmap

### Phase 1: Setup & Planning (Week 1)
- Install and set up Project Zomboid modding environment.
- Define Terminator behaviors: hunting logic, ambush patterns, escalation triggers.
- Sketch AI state machine and decision tree.
- Decide basic environmental interactions (traps, scavenged weapons, corpse desecration).

**Deliverable:** Basic project skeleton, AI behavior outline, and mod folder structure ready.

### Phase 2: Core AI Behavior (Week 2–3)
- Implement Terminator patrol, tracking, and movement logic.
- Code simple hunting decision-making: when to attack, hide, or chase.
- Test AI pathfinding and detection.

**Deliverable:** Terminator moves, tracks, and follows the player in-game.

### Phase 3: Procedural Threats & Resources (Week 4–5)
- Implement scavenging logic: AI finds weapons, ammo, or traps.
- Procedurally place traps, ambush points, and hazards.
- Code basic escalation: AI responds to player noise, greed, or complacency.

**Deliverable:** Terminator hunts intelligently using resources and creates dynamic threats.

### Phase 4: Adaptive Player Interaction (Week 6–7)
- Monitor player behavior: movement, skill leveling, greed, and noise.
- Implement escalation logic: AI hunts more aggressively if player gets too comfortable.
- Test and tweak player-AI interactions.

**Deliverable:** Dynamic, responsive AI that adapts to player actions.

### Phase 5: Polishing & Emergent Behavior (Week 8)
- Implement corpse desecration and environmental storytelling cues.
- Refine AI decision-making for smoother, more believable hunting.
- Balance difficulty and escalation rates.

**Deliverable:** Terminator behaves as a true predator; gameplay feels tense and unpredictable.

### Phase 6: Final Testing & Documentation (Week 9)
- Full playthrough tests for bugs, edge cases, and AI exploits.
- Create documentation: AI behavior logic, mod setup instructions, and milestone summary.
- Optional: Record a demo video or screenshots for presentation.

**Deliverable:** Fully functional mod with documentation and demo.

---

## Contributing

- Split tasks: one handles AI logic, the other handles traps/resources/environment.
- Use coding agents to scaffold repetitive Lua functions.
- Test every small increment—don’t wait until everything is finished to debug.
- Keep MVP first; polish later.

---

## License
