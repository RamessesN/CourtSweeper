latest_distance: float | None = None

def get_distance(ep_sensor):
    ep_sensor.sub_distance(freq = 10, callback = sub_data_handler_distance)

def sub_data_handler_distance(sub_info):
    global latest_distance
    latest_distance = sub_info[0]
