#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <DHT.h>
#include <ESP32Servo.h>

// --- PİN TANIMLAMALARI (Seninle konuştuğumuz şemaya göre) ---
#define OLED_RESET     -1
#define SCREEN_WIDTH   128
#define SCREEN_HEIGHT  64
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

Adafruit_MPU6050 mpu;

#define DHTPIN         4
#define DHTTYPE        DHT11
DHT dht(DHTPIN, DHTTYPE);

#define ENC_CLK        32
#define ENC_DT         33
#define ENC_SW         25

#define ULTRA_TRIG     5
#define ULTRA_ECHO     18

#define LDR_PIN        34

#define SERVO_PIN      26
Servo myservo;

#define VIB_PIN        27

// --- DEĞİŞKENLER ---
int lastClk = HIGH;
int encoderCount = 0;

void setup() {
  Serial.begin(115200);
  while (!Serial);
  Serial.println("OmniDeck Sistem Testi Basliyor...");

  // 1. OLED Başlatma
  if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println("OLED Hatasi!");
  }
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(WHITE);
  display.setCursor(0,0);
  display.println("OMNIDECK TEST");
  display.display();
  delay(1000);

  // 2. MPU6050 Başlatma
  if (!mpu.begin()) {
    Serial.println("MPU6050 bulunamadi!");
  }
  mpu.setAccelerometerRange(MPU6050_RANGE_8_G);

  // 3. DHT11 Başlatma
  dht.begin();

  // 4. Pin Modları
  pinMode(ENC_CLK, INPUT_PULLUP);
  pinMode(ENC_DT, INPUT_PULLUP);
  pinMode(ENC_SW, INPUT_PULLUP);
  pinMode(ULTRA_TRIG, OUTPUT);
  pinMode(ULTRA_ECHO, INPUT);
  pinMode(VIB_PIN, OUTPUT);

  // 5. Servo Başlatma
  ESP32PWM::allocateTimer(0);
  myservo.setPeriodHertz(50);
  myservo.attach(SERVO_PIN, 500, 2400);
  
  Serial.println("Sistem Hazir!");
}

void loop() {
  display.clearDisplay();
  display.setCursor(0,0);

  // --- 1. MPU6050 TEST (Eğme) ---
  sensors_event_t a, g, temp;
  mpu.getEvent(&a, &g, &temp);
  display.print("MPU X:"); display.print(a.acceleration.x, 1);
  display.print(" Y:"); display.println(a.acceleration.y, 1);

  // --- 2. DHT11 TEST (Isı/Nem) ---
  float h = dht.readHumidity();
  float t = dht.readTemperature();
  display.print("Temp:"); display.print(t, 1);
  display.print("C Hum:%"); display.println(h, 0);

  // --- 3. LDR TEST (Işık) ---
  int ldrVal = analogRead(LDR_PIN);
  display.print("Iisik:"); display.println(ldrVal);

  // --- 4. ULTRASONIK TEST (Mesafe) ---
  digitalWrite(ULTRA_TRIG, LOW);
  delayMicroseconds(2);
  digitalWrite(ULTRA_TRIG, HIGH);
  delayMicroseconds(10);
  digitalWrite(ULTRA_TRIG, LOW);
  long duration = pulseIn(ULTRA_ECHO, HIGH);
  float distance = duration * 0.034 / 2;
  display.print("Mesafe:"); display.print(distance, 1); display.println(" cm");

  // --- 5. ENCODER TEST (Düğme) ---
  int newClk = digitalRead(ENC_CLK);
  if (newClk != lastClk && newClk == LOW) {
    if (digitalRead(ENC_DT) != newClk) encoderCount++;
    else encoderCount--;
  }
  lastClk = newClk;
  display.print("Enc:"); display.print(encoderCount);
  if(digitalRead(ENC_SW) == LOW) display.print(" [BASILDI]");
  display.println();

  // --- 6. ACTUATOR TEST (Servo ve Motor) ---
  
  // Işık testi (LDR) - Karanlıksa titret
  if(ldrVal < 500) {
    digitalWrite(VIB_PIN, HIGH);
    display.println("!!! TITRESIM AKTIF !!!");
  } else {
    digitalWrite(VIB_PIN, LOW);
  }

  if(distance < 10) {
    // TETIKLEME ANI: Kilit açılıyor
    // 40'tan 0'a gitmek saat yönünde harekettir.
    myservo.write(0); 
    display.println(">>> KILIT ACIK (0 deg) <<<");
  } else {
    // BEKLEME ANI: Kilit pozisyonu (Kilitli tutmak için 40 dereceye geri döner)
    myservo.write(40); 
    display.println("--- KILITLI (40 deg) ---");
  }
  display.display();
  delay(100); // Ekran tazeleme hızı
}