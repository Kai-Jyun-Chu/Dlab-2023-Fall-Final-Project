# 🐍 Vivado Snake Game – DLab 2023 Fall

A hardware-implemented Snake Game built using Verilog on Xilinx Vivado. This game features basic movement, food consumption, obstacles, and a scoring system, designed as part of the DLab 2023 Fall course.

---

## 🎮 Controls

- **Start** the game with **Button 0 (btn0)**.
- Snake movement is controlled via direction buttons or switches:
  - **Right → Left → Up → Down**
- If the snake **collides** with the wall or itself, it **loses one life** and returns to the previous position.
- Press **btn0 again** to restart after dying.
- If all lives are lost, the game is over.
- Press **reset** to fully restart the game.
- *(Occasionally, you may need to reprogram the FPGA device.)*

---

## Core Features

1. The snake is initially **5 units** in length.
2. Supports **movement** and **turning**.
3. Displays **food** as a **circle** that can be consumed.
4. In **Level 2**, random **obstacles** are introduced.
5. **Eating food does not affect the snake's length** in our version (configurable).
    - For demonstration purposes, the snake may grow significantly.
    - To maintain smooth gameplay, the **score requirement is lowered** to avoid excessive length.
6. Game area has a **boundary** – collisions result in loss of life.
7. Uses **buttons** or **switches** for directional control.

---

## Advanced Features

1. **Scoring system** tracks fruits eaten.
2. **Variable snake length** (optionally enabled).
3. If the snake **hits an obstacle**, score is reduced. 
   - If score reaches zero, the game ends.
4. **Multi-level gameplay**:
   - Reach a target score (default: 3) to proceed to **Level 2**.
   - Obstacles appear in Level 2.
5. **Life and score are connected**:
   - Losing a life resets the score.
6. **Basic interface**:
   - Displays game states (start, win, fail) – considered a bonus feature.