from src.env_config import get_logger

import time, serial

logger = get_logger(__name__)

class RollerMotor:
    def __init__(self, port = '', baudrate = 115200):
        logger.info(f"Connecting to motor on {port} ...")
        try:
            self.ser = serial.Serial(port, baudrate, timeout = 1)
            time.sleep(2)
            logger.info("Connection successful!")
        except Exception as e:
            logger.error(f"Failed to connect to serial port. Error details: {e}")
            exit(1)

    def set_speed(self, left_speed, right_speed):
        command = f"{int(left_speed)},{int(right_speed)}\n"
        self.ser.write(command.encode('utf-8'))
        logger.info(f"Roller Speed: L = {left_speed}, R = {right_speed}")

    def close(self):
        self.set_speed(0, 0)
        time.sleep(0.1)
        self.ser.close()
        logger.info("Connection closed.")