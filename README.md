# OmniDeck: Modular Asymmetric IoT Puzzle Console

**OmniDeck** is an open-source, modular IoT hardware platform designed for interactive, asymmetric cooperative puzzles. It functions as a **"Dumb Terminal"** that bridges physical sensory data with cloud-based game logic, allowing a local **Operative** and a remote **Hacker** to collaborate in real-time.

---

## Core Concept: The Asymmetric Heist
The project is built on a high-stakes **Hacker vs. Operative** dynamic:

* **The Operative:** Holds the physical console. They must navigate menus and manipulate hardware (tilting, dialing, covering sensors) to bypass physical security layers.
* **The Hacker:** Monitors a live **Adafruit IO** dashboard from anywhere in the world. They interpret telemetry to guide the Operative and send remote commands to trigger physical actuators.

---

## Hardware Architecture
OmniDeck utilizes an **ESP32** to aggregate data from 5 sensors and drive 2 actuators.

### Sensors (Inputs)
| Component | Function |
| :--- | :--- |
| **MPU6050** | 6-Axis Motion & Tilt sensing for spatial/balance puzzles. |
| **KY-040 Encoder** | High-precision rotary dial for digital safe-cracking. |
| **HC-SR04** | Ultrasonic distance mapping for proximity/stealth triggers. |
| **DHT11** | Environmental monitoring (e.g., "overheating" the system). |
| **LDR Module** | Ambient light detection for "blackout" or flashlight modes. |

### Actuators & UI (Outputs)
| Component | Function |
| :--- | :--- |
| **SSD1306 OLED** | 128x64 HUD for real-time status and dynamic graphics. |
| **SG90 Servo** | Mechanical latch for unlocking a physical "prize" compartment. |
| **Vibration Motor** | Haptic feedback engine for Morse code clues and warnings. |



---

## System Design
OmniDeck follows a **Hub-and-Spoke architecture** using the **MQTT protocol**.

1.  **Hardware Proxy:** The ESP32 collects raw sensor data and publishes it as **JSON payloads**.
2.  **Cloud Hub:** **Adafruit IO** acts as the central broker, decoupling the physical hardware from the game logic.
3.  **Logic Engine:** The Web Dashboard processes incoming telemetry and publishes command signals (e.g., `servo_unlock: 1`) back to the hardware.



---

## Example Puzzle Mechanics
* **The Vault:** The Hacker sees a 4-digit code on their screen. The Operative must use the **KY-040 Encoder** to input the numbers, receiving a haptic "click" via the **Vibration Motor** when correct.
* **The Laser Grid:** The Operative must keep the device perfectly level using the **MPU6050**. If the tilt exceeds 15°, the Hacker’s dashboard alerts "Detected!" and the Operative must restart.
* **The Blackout:** The Hacker triggers a "Blackout" mode. The Operative must find a real-world light source (using the **LDR**) to restore the OLED display.

---


## 🧑‍💻 Author
**BatY0** *Department of Computer Engineering* [GitHub Profile](https://github.com/BatY0)
