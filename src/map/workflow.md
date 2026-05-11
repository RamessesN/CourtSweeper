### slam 建图启动流程：
1. **启动通信桥梁:**
```bash
ros2 launch rosbridge_server rosbridge_websocket_launch.xml
```

2. **启动雷达:** 
```bash
ros2 launch rplidar_ros rplidar_a1_launch.py serial_port:=/dev/cu.usbserial-3120
```

3. **雷达静态TF:** 
```bash
ros2 run tf2_ros static_transform_publisher 0 0 0 0 0 0 base_link laser
```

4. **小车底盘数据桥接:** 
```bash
python -m src.map.map_generation
```

5. **启动SLAM算法:** 
```bash
ros2 launch slam_toolbox online_async_launch.py
```

6. **修复SLAM算法下的静态TF:** 
```bash
ros2 run tf2_ros static_transform_publisher --frame-id base_link --child-frame-id base_footprint
```

7. **启动专属可视化界面:**
```bash
rviz2 -d ~/ros2_ws/config/custom_config.rviz
```

8. **运行键盘控制工具:** 
```bash
ros2 run teleop_twist_keyboard teleop_twist_keyboard --ros-args -p speed:=0.5 -p turn:=0.2
```

---

> EXTRA - **保存地图:**
```bash
ros2 run nav2_map_server map_saver_cli -f custom_court
```