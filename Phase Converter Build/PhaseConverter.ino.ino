#include <Wire.h>
#include <Adafruit_ADS1X15.h>
#include <LiquidCrystal_I2C.h> // Include the library for I2C LCD

// Adafruit ADS1115 instance
Adafruit_ADS1115 ads;

// I2C LCD Display instance
LiquidCrystal_I2C lcd(0x27, 16, 2); // Address 0x27, 16 columns, 2 rows

// Current measurement constants
const float FACTOR = 20;  // 20A/1V from the CT
const float multiplier = 0.00005;

// Digital pin assignments
const int startPin = 6;
const int l1Pin = 5;
const int l2Pin = 4;
const int contactor1Pin = 3;
const int contactor2Pin = 2;
const int emergencyStart = 7;
const int digital_ground = 8;

void setup() {
  // I2C Voltmeter setup
  Serial.begin(9600);
  ads.setGain(GAIN_FOUR);  // +/- 1.024V, 1 bit = 0.5mV
  ads.begin();

  // Set up the digital pins as outputs
  pinMode(startPin, OUTPUT);
  pinMode(l1Pin, OUTPUT);
  pinMode(l2Pin, OUTPUT);
  pinMode(contactor1Pin, OUTPUT);
  pinMode(contactor2Pin, OUTPUT);
  pinMode(digital_ground, OUTPUT);

  // Initialize the outputs
  digitalWrite(startPin, LOW);
  digitalWrite(l1Pin, LOW);
  digitalWrite(l2Pin, LOW);
  digitalWrite(contactor1Pin, LOW);
  digitalWrite(contactor2Pin, LOW);
  digitalWrite(digital_ground, LOW);

  pinMode(emergencyStart, INPUT_PULLUP);

  // Initialize the LCD display
  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("Current (A): ");
}

void loop() {
  while ((ads.readADC_Differential_0_1() * multiplier * FACTOR) < .5) {
    if (digitalRead(emergencyStart) == LOW) {
      startMotor();
      while (true) {
      lcd.setCursor(0, 1);
      lcd.print(getcurrent_RUN());
      delay(500);
      }
    }
    lcd.setCursor(0, 1);
    lcd.print(0.00);
  }
  startMotor();
  float Current = getcurrent_RUN();
  while (Current > 1) 
  {
    Current = getcurrent_RUN();
    lcd.setCursor(0, 1);
    lcd.print(Current);
  }
  stopMotor();
  delay(3000);
}

void startMotor() {
  digitalWrite(startPin, HIGH);
  delay(50);
  digitalWrite(l1Pin, HIGH);
  digitalWrite(l2Pin, HIGH);
  digitalWrite(contactor1Pin, HIGH);
  delay(250);
  digitalWrite(startPin, LOW);
  delay(500);
  digitalWrite(contactor2Pin, HIGH);
}

void stopMotor() {
  digitalWrite(l1Pin, LOW);
  digitalWrite(l2Pin, LOW);
  digitalWrite(contactor1Pin, LOW);
  digitalWrite(contactor2Pin, LOW);
}

// Function to measure and calculate the run current
float getcurrent_RUN() {
  float voltage;
  float current;
  float sum = 0;
  long time_check = millis();
  int counter = 0;

  // Measure current for 1 second
  while (millis() - time_check < 1000) {
    voltage = ads.readADC_Differential_2_3() * multiplier;
    current = voltage * FACTOR;
    sum += sq(current);
    counter++;
  }

  // Calculate RMS current
  current = sqrt(sum / counter);
  return current;
}