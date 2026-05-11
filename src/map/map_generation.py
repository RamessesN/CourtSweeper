import time, math
import roslibpy

import src.chassis.chassis_sub as c_sub

ep_chassis = None

last_cmd_time = 0.0
is_moving = False

def cmd_vel_callback(message):
    global ep_chassis, last_cmd_time, is_moving
    if ep_chassis is None:
        return
    
    try:
        last_cmd_time = time.time()
        is_moving = True
        
        vx = message['linear']['x']
        vy = message['linear']['y']
        vw = message['angular']['z']

        left_speed = vx - vy - vw
        right_speed = vx + vy + vw

        factor = 100 
        w1_speed = right_speed * factor
        w2_speed = left_speed * factor
        w3_speed = left_speed * factor
        w4_speed = right_speed * factor
        
        ep_chassis.drive_wheels(
            w1=int(w1_speed), 
            w2=int(w2_speed), 
            w3=int(w3_speed), 
            w4=int(w4_speed)
        )
    except Exception as e:
        print(f"速度指令执行出错: {e}")

if __name__ == "__main__":
    from robomaster_ultra import robot, conn

    # ROS 跨进程通信
    client = roslibpy.Ros(host = '127.0.0.1', port = 9090)
    client.run()

    odom_pub = roslibpy.Topic(client, '/odom', 'nav_msgs/Odometry')
    tf_pub = roslibpy.Topic(client, '/tf', 'tf2_msgs/TFMessage')

    cmd_sub = roslibpy.Topic(client, '/cmd_vel', 'geometry_msgs/Twist')
    cmd_sub.subscribe(cmd_vel_callback)

    ep_robot = robot.Robot()
    ep_robot.initialize(conn_type = "sta")
    ep_robot.set_robot_mode(mode = "free")

    ep_chassis = ep_robot.chassis

    c_sub.get_xy(ep_chassis)
    c_sub.get_yaw(ep_chassis)

    try:
        while True:
            if c_sub.latest_x is None or c_sub.latest_yaw is None:
                time.sleep(0.05)
                continue

            yaw_rad = math.radians(c_sub.latest_yaw)
            quat = c_sub.euler2quaternion(yaw_rad)

            t_now = time.time()
            sec = int(t_now)
            nanosec = int((t_now - sec) * 1e9)
            ros_time = {'sec': sec, 'nanosec': nanosec}

            tf_msg = {
                'transforms': [{
                    'header': {'stamp': ros_time, 'frame_id': 'odom'},
                    'child_frame_id': 'base_link',
                    'transform': {
                        'translation': {'x': c_sub.latest_x, 'y': c_sub.latest_y, 'z': 0.0},
                        'rotation': quat
                    }
                }]
            }
            tf_pub.publish(roslibpy.Message(tf_msg))

            odom_msg = {
                'header': {'stamp': ros_time, 'frame_id': 'odom'},
                'child_frame_id': 'base_link',
                'pose': {
                    'pose': {
                        'position': {'x': c_sub.latest_x, 'y': c_sub.latest_y, 'z': 0.0},
                        'orientation': quat
                    }
                }
            }
            odom_pub.publish(roslibpy.Message(odom_msg))

            if is_moving and (time.time() - last_cmd_time > 0.3):
                ep_chassis.drive_wheels(w1=0, w2=0, w3=0, w4=0)
                is_moving = False

            time.sleep(0.02)

    except KeyboardInterrupt:
        print("\n结束")

    finally:
        cmd_sub.unsubscribe()
        ep_chassis.unsub_attitude()
        ep_chassis.unsub_position()
        if ep_chassis:
            ep_chassis.drive_wheels(w1=0, w2=0, w3=0, w4=0)
        ep_robot.close()
        client.terminate()