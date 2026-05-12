#  Departmental Chess

## Chess with Search Algorithms as Game Mechanics

This repository contains a **Godot-based experimental chess game** where classical **search algorithms (BFS, DFS, A*) are used as gameplay mechanics instead of just AI logic**.

⚠️ This project is a **learning-focused prototype** and is **not actively maintained**.

Link: https://github.com/NeelayK/DepartmentalChess

Assets and Intial Setup: https://www.youtube.com/@Godot-with-me

---

##  Status

 **Prototype / Learning Project**

* Not actively maintained  
* Built for experimentation and academic exploration  
* Does not include a full game flow (no main menu, only core gameplay scene)

---

##  About This Project

Departmental Chess reimagines traditional chess by integrating **traversal algorithms directly into gameplay**.

Instead of only moving pieces using standard chess rules, players can:

* Use **Algorithm Cards**
* Trigger search algorithms
* Visually explore the board
* Execute moves based on algorithmic traversal

This transforms abstract computer science concepts into **interactive gameplay mechanics**.

---

## Core Concept

> “What if search algorithms were not behind the game… but *were the game*?”

Players use:

* **BFS (Breadth-First Search)** → Finds nearest targets  
* **DFS (Depth-First Search)** → Explores deep paths unpredictably  
* **A\*** (planned) → Optimal pathfinding using heuristics  

These algorithms:

* Traverse the chessboard
* Visually animate their search
* Determine how pieces move and capture

---

##  Features

* Chess-based grid system (8×8 board)  
* Algorithm-driven movement system  
* Card-based mechanic to trigger algorithms  
* Real-time visualization of search traversal  

---

## Tech Stack

* **Game Engine:** Godot  
* **Language:** GDScript  

---

## Gameplay Mechanics

### Algorithm Cards

Each card represents a search strategy:

* Has a cost (Action Points)
* Triggers a traversal from a selected piece
* Executes movement based on search results

---

### BFS (Breadth-First Search)

* Expands outward uniformly  
* Finds the **closest enemy**  
* Ideal for short-range tactical moves  

---

### DFS (Depth-First Search)

* Explores deep paths first  
* Can bypass nearby enemies  
* Produces **unpredictable and long-range moves**  

---

### A*

* Uses heuristics for optimal pathfinding  
* Pieces capture closest piece to the king 

---

## Limitations

Since this is a prototype:

*  No main menu or full game loop  
*  No AI opponent  
*  UI and UX are minimal  
*  Some bugs related to state synchronization and visualization  

---

## Technical Highlights

* **Asynchronous Visualization**
  * Algorithms run step-by-step using coroutines
  * Helps visualize how search progresses

* **Grid Representation**
  * Board stored as coordinate-based structure
  * Efficient lookup and traversal

* **King Protection Logic**
  * Algorithms avoid directly targeting the king
  * Prevents trivial game endings

---

##  Usage

You are free to:

* Explore the code for learning purposes  
* Study how search algorithms can be gamified  
* Use parts of the implementation in your own projects  

---

## Author

**Neelay Kamat**  
GitHub: https://github.com/NeelayK  

---

> ⚠️ *This project is an experimental implementation created for learning and demonstrating search algorithms through gameplay.*
