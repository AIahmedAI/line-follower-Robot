// ================== Pin Definitions ==================
#define enA 10 // Enable pin for Motor A (L298N)
#define in1 9  // Motor A input 1
#define in2 8  // Motor A input 2
#define in3 7  // Motor B input 1
#define in4 6  // Motor B input 2
#define enB 5  // Enable pin for Motor B (L298N)

#define L_S A0 // Left IR sensor
#define R_S A1 // Right IR sensor

#define echo A2    // Ultrasonic Echo pin
#define trigger A3 // Ultrasonic Trigger pin

#define servo A5   // Servo control pin

// ================== Variables ==================
int Set = 20; // Minimum safe distance in cm
int distance_L, distance_F, distance_R; 

// ================== Setup ==================
void setup() {
  Serial.begin(9600); // Start serial communication

  // Sensors
  pinMode(R_S, INPUT);
  pinMode(L_S, INPUT);
  pinMode(echo, INPUT);
  pinMode(trigger, OUTPUT);

  // Motors
  pinMode(enA, OUTPUT);
  pinMode(in1, OUTPUT);
  pinMode(in2, OUTPUT);
  pinMode(in3, OUTPUT);
  pinMode(in4, OUTPUT);
  pinMode(enB, OUTPUT);

  // Motor speed (PWM)
  analogWrite(enA, 150);
  analogWrite(enB, 150);

  // Servo
  pinMode(servo, OUTPUT);

  // Initial servo sweep
  for (int angle = 70; angle <= 140; angle += 5) servoPulse(servo, angle);
  for (int angle = 140; angle >= 0; angle
 -= 5) servoPulse(servo, angle);
  for (int angle = 0; angle <= 70; angle += 5) servoPulse(servo, angle);

  distance_F = Ultrasonic_read();
  delay(500);
}


char lastAction = 'F'; 

// ================== Main Loop ==================
void loop() {
  distance_F = Ultrasonic_read();
  Serial.print("D F="); Serial.println(distance_F);

  int right_val = digitalRead(R_S);
  int left_val = digitalRead(L_S);

  
  if ((right_val == 0) && (left_val == 0)) {
    if (distance_F <= Set) {
      Check_side(); 
    } else {
      
      if (lastAction == 'R') {
        turnRight();
      } else if (lastAction == 'L') {
        turnLeft();
      } else {
        forward();
      }
    }
  } 
  
  else if ((right_val == 0) && (left_val == 1)) {
    turnRight();
    lastAction = 'R'; 
  } 
  
  else if ((right_val == 1) && (left_val == 0)) {
    turnLeft();
    lastAction = 'L';   
  }
  
  else if ((right_val == 1) && (left_val == 1)) {
    forward();
    lastAction = 'F'; 
  }

  delay(10);
}

// ================== Servo Control ==================
void servoPulse(int pin, int angle) {
  int pwm = (angle * 11) + 500; // Convert angle to microseconds
  digitalWrite(pin, HIGH);
  delayMicroseconds(pwm);
  digitalWrite(pin, LOW);
  delay(50); // Refresh cycle
}

// ================== Ultrasonic Sensor ==================
long Ultrasonic_read() {
  digitalWrite(trigger, LOW);
  delayMicroseconds(2);
  digitalWrite(trigger, HIGH);
  delayMicroseconds(10);
  long time = pulseIn(echo, HIGH);
  return time / 29 / 2; // Convert to cm
}

// ================== Obstacle Avoidance ==================
void compareDistance() {
  if (distance_L > distance_R) {
    turnLeft(); delay(500);
    forward();  delay(600);
    turnRight();delay(600);

    forward();  delay(600);
    turnRight();
    while(digitalRead(R_S) == 0 && digitalRead(L_S) == 0) {
      delay(10); // انتظر حتى يجد الخط
    }
  } else {
    turnRight();delay(500);
    forward();  delay(600);
    turnLeft(); delay(600);
    forward();  delay(600);
    turnLeft(); 
    while(digitalRead(R_S) == 0 && digitalRead(L_S) == 0) {
      delay(10); // انتظر حتى يجد الخط
    }
  }
}

void Check_side() {
  Stop(); delay(100);

  for (int angle = 70; angle <= 140; angle += 5) servoPulse(servo, angle);
  delay(300);
  distance_R = Ultrasonic_read();
  Serial.print("D R="); Serial.println(distance_L);

  for (int angle = 140; angle >= 0; angle -= 5) servoPulse(servo, angle);
  delay(500);
  distance_L = Ultrasonic_read();
  Serial.print("D L="); Serial.println(distance_R);

  for (int angle = 0; angle <= 70; angle += 5) servoPulse(servo, angle);
  delay(300);

  compareDistance();
}

// ================== Motor Control ==================
void forward() {
  digitalWrite(in1, LOW);
  digitalWrite(in2, HIGH);
  digitalWrite(in3, HIGH);
  digitalWrite(in4, LOW);
}

void backward() {
  digitalWrite(in1, HIGH);
  digitalWrite(in2, LOW);
  digitalWrite(in3, LOW);
  digitalWrite(in4, HIGH);
}

void turnRight() {
  digitalWrite(in1, LOW);
  digitalWrite(in2, HIGH);
  digitalWrite(in3, LOW);
  digitalWrite(in4, LOW);
}

void turnLeft() {
  digitalWrite(in1, LOW);
  digitalWrite(in2, LOW);
  digitalWrite(in3, HIGH);
  digitalWrite(in4, LOW);
}

void Stop() {
  digitalWrite(in1, LOW);
  digitalWrite(in2, LOW);
  digitalWrite(in3, LOW);
  digitalWrite(in4, LOW);
}
