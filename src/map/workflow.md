### slam 建图启动流程：
1. **启动雷达:** 
```bash
ros2 launch rplidar_ros rplidar_a1_launch.py serial_port:=/dev/ttyCH341USB0
```

2. **雷达过滤**:
```bash
ros2 run laser_filters scan_to_scan_filter_chain --ros-args --params-file ~/ros2_ws/config/laser_filter_params.yaml
```

3. **雷达静态TF:** 
```bash
ros2 run tf2_ros static_transform_publisher 0 0 0 0 0 0 base_footprint base_link
```

```bash
ros2 run tf2_ros static_transform_publisher 0 0 0 0 0 0 base_link laser
```

4. **小车底盘数据桥接:** 
```bash
python -m src.map.map_generation
```

5. **启动SLAM算法:** 
```bash
ros2 launch slam_toolbox online_async_launch.py slam_params_file:=~/ros2_ws/config/mapper_params_online_async.yaml
```

6. **RViz:**
```bash
rviz2 -d ~/ros2_ws/config/custom_config_v2.rviz
```

7. **运行键盘控制工具:** 
```bash
ros2 run teleop_twist_keyboard teleop_twist_keyboard --ros-args -p speed:=0.5 -p turn:=0.2
```

> EXTRA - **保存地图:**
```bash
ros2 run nav2_map_server map_saver_cli -f custom_court
```

---

### slam 导航启动流程:

1. **启动雷达:** 
```bash
ros2 launch rplidar_ros rplidar_a1_launch.py serial_port:=/dev/ttyCH341USB0
```

3. **雷达过滤:**
```bash
ros2 run laser_filters scan_to_scan_filter_chain --ros-args --params-file ~/ros2_ws/config/laser_filter_params.yaml
```

4. **雷达静态TF:**
```bash
ros2 run tf2_ros static_transform_publisher 0 0 0 0 0 0 base_footprint base_link
```

```bash
ros2 run tf2_ros static_transform_publisher 0 0 0 0 0 0 base_link laser
```

5. **小车底盘数据桥接**
```bash
python -m src.map.map_generation
```

6. **Nav2**
```bash
ros2 launch nav2_bringup localization_launch.py \
map:=/home/nvidia/ros2_ws/maps/custom_court.yaml \
use_sim_time:=False \
params_file:=/home/nvidia/ros2_ws/config/nav2_params.yaml
```

```bash
ros2 launch nav2_bringup navigation_launch.py \
map:=/home/nvidia/ros2_ws/maps/custom_court.yaml \
use_sim_time:=False \
params_file:=/home/nvidia/ros2_ws/config/nav2_params.yaml
```

7. **RViz**
```bash
rviz2 -d ~/Desktop/navigation.rviz
```
