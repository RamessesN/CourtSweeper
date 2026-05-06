from rplidar import RPLidar

import math
import threading
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation

PORT = '/dev/cu.usbserial-120'
BAUDRATE = 115200
VIEW_RADIUS_CM = 50
MIN_DIST_MM = 20

lidar_data = {}

def parse_rplidar_thread():
    global lidar_data
    try:
        lidar = RPLidar(PORT, baudrate=BAUDRATE)
        print(f"Connecting to RPLiDAR on {PORT}...")
        
        for scan in lidar.iter_scans():
            for (_, angle, distance_mm) in scan:
                if distance_mm > MIN_DIST_MM:
                    lidar_data[math.radians(angle)] = distance_mm / 10.0
                    
    except Exception as e:
        print(f"\nLIDAR Thread Error: {e}")
    finally:
        try:
            lidar.stop()
            lidar.stop_motor()
            lidar.disconnect()
        except:
            pass

def update_plot(frame, scatter, line_0deg):
    global lidar_data
    
    if not lidar_data:
        return scatter, line_0deg
    
    angles = list(lidar_data.keys())
    distances = list(lidar_data.values())
    scatter.set_offsets(list(zip(angles, distances)))

    lidar_data = {} 

    return scatter, line_0deg

def run_visualization():
    thread = threading.Thread(target=parse_rplidar_thread, daemon=True)
    thread.start()

    fig = plt.figure(figsize=(8, 8))
    ax = fig.add_subplot(111, projection='polar')
    ax.set_title(f"RPLiDAR A1M8: Range 0-{VIEW_RADIUS_CM}cm", va='bottom')
    
    ax.set_theta_zero_location('N')
    ax.set_theta_direction(-1)
    ax.set_ylim(0, VIEW_RADIUS_CM)
    
    line_0deg, = ax.plot([0, 0], [0, VIEW_RADIUS_CM], 
                         color='blue', linewidth=2, 
                         label='0° Front', linestyle='--')
    ax.legend(loc='upper right')

    scatter = ax.scatter([], [], s=5, c='red', alpha=0.8)

    ani = FuncAnimation(fig, update_plot, fargs=(scatter, line_0deg), 
                        interval=50, blit=True, cache_frame_data=False)

    plt.show()

if __name__ == '__main__':
    run_visualization()
