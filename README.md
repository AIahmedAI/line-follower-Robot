# Line-Following Robot 🤖

## Overview
A 4-wheel autonomous line-following robot built using **Arduino Uno**, IR sensors for path detection, and an ultrasonic sensor for obstacle avoidance.  
The robot is powered by dual 18650 Li-ion batteries and controlled via an **L298N motor driver**.

## Features
- 🚗 4WD DC motors for stable movement  
- 📡 IR sensors for line tracking  
- 🛑 Ultrasonic sensor + servo for obstacle detection  
- 🔋 7.4V Li-ion battery pack  
- 🧠 Arduino Uno R3 as main controller  

## Hardware Components
- Arduino Uno R3  
- L298N Motor Driver  
- 4 DC Gear Motors + Wheels  
- 2 IR Sensors  
- HC-SR04 Ultrasonic Sensor + SG90 Servo  
- 2x 18650 Batteries  

## How It Works
1. IR sensors detect black line on a light surface.  
2. Arduino processes sensor data and adjusts motor speed/direction.  
3. Ultrasonic sensor scans for obstacles and triggers avoidance maneuvers.  
4. Motors controlled via L298N driver for forward, backward, and turning.  

## Performance
- Max speed: ~0.40 m/s  
- Line tracking accuracy: ±1.5 cm  
- Battery life: ~2 hours continuous operation  

## Future Improvements
- Better sensor calibration  
- Advanced obstacle avoidance algorithms  
- Closed-loop control with encoders  

---

### Authors
Team Project – Faculty of Navigation Sciences & Space Technology, Beni-Suef University  
Course: Robotics SNS541  
Submission Date: 17/5/2026
