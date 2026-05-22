from src.env_config import get_logger

import src.vision.video_node as vn
import src.distance.distance_sub as ds
import src.chassis.chassis_ctrl as cc
import src.roller.roller_drive as rd

from robomaster_ultra import robot
import threading

logger = get_logger(__name__)

def main():
    ep_robot = robot.Robot()
    ep_robot.initialize(conn_type = "sta")
    ep_robot.set_robot_mode(mode = "free")
    
    try:
        intake_motor = rd.RollerMotor(port = '/dev/cu.usbmodem2017_2_251')
    except Exception:
        intake_motor = None

    ds.get_distance(ep_robot.sensor)
    
    chassis_thread = threading.Thread(
        target = cc.chassis_ctrl, 
        args = (ep_robot.chassis, intake_motor), 
        daemon = True
    )
    chassis_thread.start()
    
    try:
        vn.video_capture(ep_robot.camera)
    except KeyboardInterrupt:
        logger.info("接收到退出信号。")
    finally:
        vn.running = False
        cc.chassis_stop(ep_robot.chassis)
        
        if intake_motor:
            intake_motor.close()
            
        intake_motor.close()
        ep_robot.sensor.unsub_distance()
        ep_robot.close()

if __name__ == "__main__":
    main()