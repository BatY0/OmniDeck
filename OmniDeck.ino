/*
  Project: OmniDeck - An Asymmetric IoT Puzzle Platform
  Description: ESP32 IoT Code for Sensors, Actuators, OLED UI, and Arduino Cloud Sync.
  Game Mode: Operation "The Blind Heist"
*/

#include "thingProperties.h"
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <DHT.h>
#include <ESP32Servo.h>

// --- Pin Definitions ---
#define DHTPIN 4
#define DHTTYPE DHT11
#define ENC_CLK 32
#define ENC_DT 33
#define ENC_SW 25
#define ULTRA_TRIG 5
#define ULTRA_ECHO 18
#define LDR_PIN 34
#define SERVO_PIN 26
#define VIB_PIN 27

// --- Objects ---
Adafruit_SSD1306 display(128, 64, &Wire, -1);
Adafruit_MPU6050 mpu;
DHT dht11(DHTPIN, DHTTYPE);
Servo kilitServo;

// --- Local Variables ---
String promptMsg = "AWAITING MISSION";
String deviceMode = "IDLE"; 
int currentStage = 0; 
unsigned long lastSensorRead = 0;

// Encoder Interrupt Variable
volatile int localDial = 0; 

// Stage 1 Variables
int targetPass[3] = {0, 0, 0};
int enteredPass[3] = {0, 0, 0};
int passIndex = 0;

// Stage 2 Variables (5x5 Maze)
int mazeX = 2; int mazeY = 4; // Start Point (S)
bool mazeReady = false; 
const int mazeMap[5][5] = {
  {1, 1, 1, 1, 2}, // Y:0 (2 = Exit)
  {0, 0, 0, 1, 0}, // Y:1 (0 = Path)
  {0, 1, 0, 0, 0}, // Y:2 (1 = Wall)
  {0, 0, 1, 1, 0}, // Y:3
  {1, 0, 0, 1, 0}  // Y:4 (Start X:2, Y:4)
};

// Stage 3 Variables
unsigned long countdownStart = 0;

// ==========================================
// HARDWARE INTERRUPT (ENCODER)
// ==========================================
void IRAM_ATTR encoderISR() {
  static unsigned long lastInterruptTime = 0;
  unsigned long interruptTime = millis();
  
  if (interruptTime - lastInterruptTime > 5) { // Debounce
    if (digitalRead(ENC_DT) == LOW) {
      localDial--; // Clockwise
    } else {
      localDial++; // Counter-Clockwise
    }
    
    // --- DIAL WRAPAROUND (0 - 9) ---
    if (localDial > 9) localDial = 0;
    else if (localDial < 0) localDial = 9;
    
    lastInterruptTime = interruptTime;
  }
}

void setup() {
  Serial.begin(115200);
  delay(1500); 

  // Init Pins
  pinMode(VIB_PIN, OUTPUT);
  pinMode(ENC_CLK, INPUT_PULLUP);
  pinMode(ENC_DT, INPUT_PULLUP);
  pinMode(ENC_SW, INPUT_PULLUP);
  pinMode(ULTRA_TRIG, OUTPUT);
  pinMode(ULTRA_ECHO, INPUT);

  // Attach Interrupt
  attachInterrupt(digitalPinToInterrupt(ENC_CLK), encoderISR, FALLING);

  // Init Servo (Safe Lock Position)
  kilitServo.write(40);
  delay(50);
  ESP32PWM::allocateTimer(0);
  kilitServo.setPeriodHertz(50);
  kilitServo.attach(SERVO_PIN, 500, 2400);

  // Init Display & Sensors
  if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) Serial.println("OLED ERROR");
  display.clearDisplay(); display.display();
  mpu.begin();
  dht11.begin();

  // Init Arduino Cloud
  initProperties();
  ArduinoCloud.begin(ArduinoIoTPreferredConnection);
  setDebugMessageLevel(2);
  ArduinoCloud.printDebugInfo();

  hacker_cmd = "IDLE";
  game_log = "SYSTEM ONLINE";
}

void loop() {
  ArduinoCloud.update(); 

  // Read sensors and update logic every 100ms
  if (millis() - lastSensorRead > 100) {
    readSensors();
    runGameLogic();
    updateUI();
    lastSensorRead = millis();
  }
}

// ==========================================
// 1. SENSOR READING & CLOUD SYNC
// ==========================================
void readSensors() {
  // MPU6050
  sensors_event_t a, g, tempEvent;
  mpu.getEvent(&a, &g, &tempEvent);
  float ax = -a.acceleration.y; 
  float ay = a.acceleration.x;

  if (ax > 4) tilt = "RIGHT";
  else if (ax < -4) tilt = "LEFT";
  else if (ay > 4) tilt = "BACK";
  else if (ay < -4) tilt = "FRONT";
  else tilt = "LEVEL";

  // Ultrasonic
  digitalWrite(ULTRA_TRIG, LOW); delayMicroseconds(2);
  digitalWrite(ULTRA_TRIG, HIGH); delayMicroseconds(10);
  digitalWrite(ULTRA_TRIG, LOW);
  dist = pulseIn(ULTRA_ECHO, HIGH) * 0.034 / 2;

  // LDR and DHT
  light = 4095 - analogRead(LDR_PIN);
  temp = dht11.readTemperature();

  // Sync Encoder
  dial = localDial; 
}

// ==========================================
// 2. LOCAL GAME LOGIC
// ==========================================
void runGameLogic() {
  // STAGE 1: PASSCODE ENTRY
  if (currentStage == 1) {
    if (digitalRead(ENC_SW) == LOW) { 
      enteredPass[passIndex] = dial;
      passIndex++;
      triggerVib(100); 
      delay(300); 
      
      if (passIndex == 3) {
        if (enteredPass[0] == targetPass[0] && enteredPass[1] == targetPass[1] && enteredPass[2] == targetPass[2]) {
          promptMsg = "CODE ACCEPTED!";
          game_log = "STAGE 1 PASSED";
          deviceMode = "STANDBY";
          currentStage = 0; 
        } else {
          promptMsg = "WRONG CODE!";
          game_log = "STAGE 1 FAILED";
          passIndex = 0;
          for(int i=0; i<3; i++){ triggerVib(200); delay(150); }
        }
      } else {
        promptMsg = "ENTER DIGIT " + String(passIndex + 1);
      }
    }
  }

  // STAGE 2: INVISIBLE MAZE
  else if (currentStage == 2) {
    if (tilt == "LEVEL") {
      mazeReady = true; 
    } 
    else if (mazeReady) { 
      int nextX = mazeX;
      int nextY = mazeY;

      if (tilt == "RIGHT") nextX++;
      else if (tilt == "LEFT") nextX--;
      else if (tilt == "FRONT") nextY--;
      else if (tilt == "BACK") nextY++;

      mazeReady = false; 

      if (nextX < 0 || nextX > 4 || nextY < 0 || nextY > 4) {
        triggerVib(500); 
        promptMsg = "OUT OF BOUNDS! RESET"; 
        mazeX = 2; mazeY = 4; 
      } 
      else {
        int cell = mazeMap[nextY][nextX];
        
        if (cell == 1) { // Wall
          triggerVib(500); 
          promptMsg = "IMPACT! RESETTING"; 
          mazeX = 2; mazeY = 4; 
        } 
        else if (cell == 2) { // Exit
          promptMsg = "MAZE CLEARED!"; 
          game_log = "STAGE 2 PASSED"; 
          deviceMode = "STANDBY";
          currentStage = 0;
        } 
        else { // Path
          mazeX = nextX;
          mazeY = nextY;
          triggerVib(50); 
          promptMsg = "POS: X" + String(mazeX) + " Y" + String(mazeY);
          game_log = "OPERATOR AT X" + String(mazeX) + " Y" + String(mazeY);
        }
      }
    }
  }

  // STAGE 3: BIOMETRIC SYNC
  else if (currentStage == 3) {
    if (light < 1500 && dist >= 8 && dist <= 14) {
      if (countdownStart == 0) countdownStart = millis();
      int remain = 5 - ((millis() - countdownStart) / 1000);
      
      if (remain <= 0) {
        promptMsg = "ACCESS GRANTED!"; 
        game_log = "ALL STAGES CLEARED";
        kilitServo.write(0); // UNLOCK!
        deviceMode = "UNLOCKED";
        currentStage = 4;
      } else {
        promptMsg = "HOLD... " + String(remain);
      }
    } else {
      if (countdownStart != 0) { 
        countdownStart = 0; triggerVib(400); promptMsg = "SYNC LOST! RETRY";
      } else {
        promptMsg = "TASK: SYNC SENSORS";
      }
    }
  }
}

// ==========================================
// 3. CLOUD COMMANDS CALLBACK (HACKER)
// ==========================================
void onHackerCmdChange() {
  if (hacker_cmd == "STAGE1") {
    currentStage = 1; passIndex = 0; deviceMode = "STAGE 1";
    targetPass[0] = (int)temp / 10;
    targetPass[1] = (int)temp % 10;
    targetPass[2] = (targetPass[0] + targetPass[1]) % 10;
    promptMsg = "TASK: ENTER CODE";
    game_log = "CODE GENERATED: " + String(targetPass[0]) + String(targetPass[1]) + String(targetPass[2]);
  }
  else if (hacker_cmd == "STAGE2") {
    currentStage = 2; mazeX = 2; mazeY = 4; mazeReady = false; 
    deviceMode = "STAGE 2";
    promptMsg = "TASK: NAVIGATE";
    game_log = "MAZE INITIATED";
  }
  else if (hacker_cmd == "STAGE3") {
    currentStage = 3; countdownStart = 0; deviceMode = "STAGE 3";
    promptMsg = "TASK: SYNC SENSORS";
  }
  else if (hacker_cmd == "OPEN") {
    kilitServo.write(0); promptMsg = "FORCE OPENED"; deviceMode = "UNLOCKED";
  }
  else if (hacker_cmd == "CLOSE") {
    kilitServo.write(40); promptMsg = "LOCKED"; deviceMode = "LOCKED"; currentStage = 0;
  }
  else if (hacker_cmd.startsWith("VIB")) {
    if (hacker_cmd == "VIBLONG") {
      triggerVib(1200); 
    } 
    else if (hacker_cmd.length() > 3) {
      int count = hacker_cmd.substring(3).toInt(); 
      if (count > 0 && count <= 9) {
        for(int i = 0; i < count; i++) {
          triggerVib(400); 
          delay(400);      
        }
      }
    } 
    else {
      triggerVib(400);
    }
  }
}

void triggerVib(int duration) {
  digitalWrite(VIB_PIN, HIGH);
  delay(duration);
  digitalWrite(VIB_PIN, LOW);
}

// ==========================================
// 4. OLED UI RENDER
// ==========================================
void updateUI() {
  display.clearDisplay(); display.setTextColor(WHITE);

  // ZONE 1: Status Bar
  display.drawRect(0, 0, 128, 14, WHITE);
  display.setCursor(2, 4); display.setTextSize(1);
  display.print("RSSI:"); display.print(WiFi.RSSI());
  display.setCursor(82, 4); 
  display.print(ArduinoCloud.connected() ? "CLOUD:OK" : "NO CLOUD");

  // ZONE 2: Sensors & Mode 
  display.setCursor(2, 18); display.print("MODE: "); display.print(deviceMode);
  display.setCursor(2, 28); display.print("DIST: "); display.print(dist); display.print("cm");
  display.setCursor(2, 38); display.print("TEMP: "); display.print(temp, 1); display.print("C");
  display.setCursor(68, 28); display.print("DIAL:"); display.print(dial);
  display.setCursor(68, 38); display.print("LDR :"); display.print(light);

  // ZONE 3: Prompt Zone
  display.drawFastHLine(0, 50, 128, WHITE);
  display.setCursor(2, 54); display.print("> "); display.print(promptMsg);

  display.display();
}