from src.env_config import get_logger

import src.vision.video_node as vn
import src.distance.distance_sub as ds

from simple_pid import PID

import time

# Log config
logger = get_logger(__name__)

# PID config
pid_turn = PID(0.15, 0.03, 0.03, setpoint = 0)
pid_turn.output_limits = (-50, 50)

pid_forward = PID(0.5, 0.1, 0.05, setpoint = 10)
pid_forward.output_limits = (-40, 40)

def chassis_ctrl(ep_chassis, intake_motor = None):
    # 防止检测因检测到其他物体靠近而启动电机
    is_chasing_sequence = False
    last_valid_dist = 8848
    
    while True:
        target_valid = vn.target_locked
        error_x = vn.visual_error_x
        need_scan = vn.scan_needed
        dist = ds.latest_distance if ds.latest_distance is not None else 8848

        if target_valid:
            is_chasing_sequence = True
            last_valid_dist = dist
        elif need_scan:
            is_chasing_sequence = False
            last_valid_dist = 8848

        if is_chasing_sequence:
            if dist <= 200:
                logger.info(f"🎯 目标进入预备区 ({dist/10:.1f}cm)！预启动电机并缓慢推进...")
                
                if intake_motor:
                    intake_motor.set_speed(90, 90)
                    
                drive_chassis(ep_chassis, forward_speed = 30, turn_speed = 0)
                
                swallow_start_time = time.time()
                is_swallowed = False

                missing_count = 0
                
                while time.time() - swallow_start_time < 3.0:
                    current_dist = ds.latest_distance if ds.latest_distance is not None else 8848

                    if current_dist > 250:
                        missing_count += 1
                    else:
                        missing_count = 0

                    if missing_count >= 10:
                        is_swallowed = True
                        break

                    time.sleep(0.02)
                
                if is_swallowed:
                    logger.info("🎾 障碍物消失，球已成功吞入网箱！")
                else:
                    logger.info("⚠️ 推进超时，发生卡球或漏球。")
                    
                chassis_stop(ep_chassis)
                
                if intake_motor:
                    intake_motor.set_speed(0, 0)
                
                is_chasing_sequence = False 
                last_valid_dist = 8848
                time.sleep(0.5)
                continue
                
            elif not target_valid and dist < 450 and last_valid_dist < 300:
                logger.info(f"盲区接力 (当前:{dist/10:.1f}cm, 消失前:{last_valid_dist/10:.1f}cm) - 保持直行...")
                drive_chassis(ep_chassis, forward_speed = 30, turn_speed = 0)

            elif target_valid:
                turn_speed = -pid_turn(error_x)

                if abs(error_x) > 40:
                    forward_speed = 5
                else:
                    if dist < 800:
                        forward_speed = -pid_forward(dist)
                    else:
                        forward_speed = 30

                drive_chassis(ep_chassis, forward_speed, turn_speed)

            else:
                chassis_stop(ep_chassis)

        else:
            if need_scan:
                drive_chassis(ep_chassis, forward_speed = 0, turn_speed = 30)
            else:
                chassis_stop(ep_chassis)

        time.sleep(0.02)

def drive_chassis(ep_chassis, forward_speed, turn_speed):
    left_speed  = forward_speed + turn_speed
    right_speed = forward_speed - turn_speed

    ep_chassis.drive_wheels(
        w1 = right_speed, # 右前
        w2 = left_speed,  # 左前
        w3 = left_speed,  # 左后
        w4 = right_speed  # 右后
    )

def chassis_stop(ep_chassis):
    ep_chassis.drive_wheels(w1 = 0, w2 = 0, w3 = 0, w4 = 0)
    time.sleep(0.02)