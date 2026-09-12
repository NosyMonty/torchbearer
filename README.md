# The Torchbearer

A 2D dark fantasy dungeon platformer built in Godot 4.6.2, where a lone villager sets out to relight an extinguished eternal flame carrying their own torch as both a light source and a double-edged weapon against the dark.

## Story

When shadow monsters extinguish the village's eternal flame, a young villager takes up a torch and sets out to relight it — journeying from their now-damaged home, through a monster-infested cave, to face what remains.

## Controls

| Action | Key |
|---|---|
| Move Left | A / Left Arrow |
| Move Right | D / Right Arrow |
| Jump (+ Double Jump) | Space |
| Attack (3-hit ground combo, air combo) | J |
| Throw Fireball (costs torch fuel) | K |
| Slide | Shift |
| Reset to Last Checkpoint | R |
| Pause | Escape |

## Core Mechanics

- **Torch Fuel System**: your torch depletes over time and refuels at checkpoints. Run out, and enemies hit harder while your own attacks weaken; the torch isn't just light, it's your edge in a fight.
- **Combo Combat**: a 3-hit ground combo, a distinct air combo with its own freeze-and-thrust finisher, a double jump, and a hitbox-shrinking slide for tight gaps.
- **Checkpoints**: lanterns that light permanently once reached, refuel your torch, and remember exactly where you left off.
- **Persistent World**: defeated enemies, broken vases, and lit checkpoints all stay that way even after death or reloading.
- **Risk/Reward Fire Hazards**: step into open flame to trade health for a torch refuel.
- **Three Levels, Three Bosses**: Tutorial Village (Stone Golem), Slightly Destroyed Village (Undead Puppet), and the Cave (Bringer of Death, final boss) — each level's exit stays locked until its boss falls.

## Enemies

- **Bat**: a basic flying chaser
- **Bringer of Death**: melee attacks plus a dodgeable portal-summoned ranged attack
- **Stone Golem**: a stationary turret with melee, projectile, and laser attacks, plus a periodic armour-shield phase
- **Blind Huntress**: detects the player by noise (running, jumping, attacking) rather than sight, with a search-and-patrol AI when she loses track

## Requirements

Windows 10/11. No installation needed beyond extracting the provided .zip and running the .exe.
