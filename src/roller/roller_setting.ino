unsigned long lastRecvTime = 0;
bool isMoving = false;

// Left Motor
const int L_EN   = 4;
const int L_RPWM = 5; // forward
const int L_LPWM = 6; // reverse

// Right Motor
const int R_EN   = 7;
const int R_RPWM = 9;  // forward
const int R_LPWM = 10; // reverse

// Initialization
void setup() {
  pinMode(L_EN, OUTPUT);
  pinMode(L_RPWM, OUTPUT);
  pinMode(L_LPWM, OUTPUT);
  
  pinMode(R_EN, OUTPUT);
  pinMode(R_RPWM, OUTPUT);
  pinMode(R_LPWM, OUTPUT);

  digitalWrite(L_EN, LOW);
  digitalWrite(R_EN, LOW);

  Serial.begin(115200);
  Serial.setTimeout(10);
}

// Main Logic
void loop() {
  if (Serial.available() > 0) {
    int speedL = Serial.parseInt();
    int speedR = Serial.parseInt();

    if (Serial.read() == '\n') {
      driveMotor(L_EN, L_RPWM, L_LPWM, -speedL);
      driveMotor(R_EN, R_RPWM, R_LPWM, speedR);
      
      lastRecvTime = millis();

      if (speedL != 0 || speedR != 0) {
          isMoving = true;
      }
    }
  }

  if (isMoving && (millis() - lastRecvTime > 500)) {
    stopMotor(); 
    isMoving = false;
  }
}

void driveMotor(int enPin, int fwdPin, int revPin, int speed) {
  speed = constrain(speed, -255, 255);

  if (speed == 0) {
    digitalWrite(enPin, LOW);
    analogWrite(fwdPin, 0);
    analogWrite(revPin, 0);
  } else if (speed > 0) {
    digitalWrite(enPin, HIGH);
    analogWrite(fwdPin, speed);
    analogWrite(revPin, 0);
  } else {
    digitalWrite(enPin, HIGH);
    analogWrite(fwdPin, 0);
    analogWrite(revPin, abs(speed));
  }
}

void stopMotor() {
  driveMotor(L_EN, L_RPWM, L_LPWM, 0);
  driveMotor(R_EN, R_RPWM, R_LPWM, 0);
}