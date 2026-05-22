import time
import serial
import struct
import math
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
import threading

PORT = '/dev/cu.usbserial-0001'
BAUDRATE = 115200
VIEW_RADIUS_CM = 80
MIN_DIST_MM = 20

lidar_data = {}

def parse_ydlidar_thread():
    global lidar_data
    try:
        ser = serial.Serial(PORT, BAUDRATE, timeout=1)
        ser.setDTR(False)
        ser.setRTS(True)
        time.sleep(0.5)
        ser.write(b'\xA5\x60')

        buffer = bytearray()
        while True:
            chunk = ser.read(1024)
            if not chunk: continue
            buffer.extend(chunk)
            
            while len(buffer) >= 10:
                if buffer[0] == 0xAA and buffer[1] == 0x55:
                    packet_type = buffer[2]
                    sample_quantity = buffer[3]
                    
                    if packet_type != 0x00:
                        buffer.pop(0)
                        continue
                        
                    packet_len = 10 + sample_quantity * 2
                    if len(buffer) < packet_len: break

                    fsa_raw = struct.unpack_from('<H', buffer, 4)[0]
                    lsa_raw = struct.unpack_from('<H', buffer, 6)[0]
                    
                    start_angle = (fsa_raw >> 1) / 64.0
                    end_angle = (lsa_raw >> 1) / 64.0
                    angle_diff = (end_angle - start_angle) % 360
                    
                    for i in range(sample_quantity):
                        dist_raw = struct.unpack_from('<H', buffer, 10 + i * 2)[0]
                        distance_mm = dist_raw / 4.0
                        
                        if distance_mm > MIN_DIST_MM: 
                            if sample_quantity > 1:
                                angle = (start_angle + (angle_diff / (sample_quantity - 1)) * i) % 360
                            else:
                                angle = start_angle
                                
                            lidar_data[math.radians(angle)] = distance_mm / 10.0
                    
                    buffer = buffer[packet_len:]
                else:
                    buffer.pop(0)
    except Exception as e:
        print(f"\nSerial Thread Error: {e}")

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
    thread = threading.Thread(target=parse_ydlidar_thread, daemon=True)
    thread.start()

    fig = plt.figure(figsize=(8, 8))
    ax = fig.add_subplot(111, projection='polar')
    ax.set_title(f"YDLiDAR X2: Range 0-{VIEW_RADIUS_CM}cm", va='bottom')
    
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