import math

latest_x: float | None = None
latest_y: float | None = None
latest_yaw: float | None = None

def get_xy(ep_chassis):
    ep_chassis.sub_position(freq = 20, callback = sub_position_handler)

def get_yaw(ep_chassis):
    ep_chassis.sub_attitude(freq = 20, callback = sub_attitude_info_handler)

def sub_position_handler(position_info):
    global latest_x, latest_y
    # position_info format: (x, y, z)
    latest_x, latest_y = position_info[0], position_info[1]

def sub_attitude_info_handler(attitude_info):
    global latest_yaw
    # attitude_info format: (yaw, pitch, roll)
    latest_yaw = attitude_info[0]

def euler2quaternion(yaw_rad):
    return {
        'x': 0.0,
        'y': 0.0,
        'z': math.sin(yaw_rad / 2.0),
        'w': math.cos(yaw_rad / 2.0)
    }
