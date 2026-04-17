# YDLidar-Protocol: 
# 1) angle = (Raw >> 1) / 64.0
# 2) distance = Raw / 4.0 mm

import time, serial, struct
from src.env_config import get_logger

logger = get_logger(__name__)

PORT     = '/dev/cu.usbserial-0001'
BAUDRATE = 115200

def parse_ydlidar():
    logger.info(f"LiDAR Connecting: {PORT} @ {BAUDRATE}")
    try:
        serial_port = serial.Serial(PORT, BAUDRATE, timeout = 1) # Open the Serial Port
        
        buffer = bytearray()
        
        while True:
            chunk = serial_port.read(1024)
            if not chunk:
                continue
            buffer.extend(chunk)
            
            while len(buffer) >= 10:
                if buffer[0] == 0xAA and buffer[1] == 0x55: # buffer head: AA tt
                    packet_type = buffer[2]
                    sample_quantity = buffer[3]
                    
                    # normal point cloud packet when `packet_type == 0` 
                    if packet_type != 0x00:
                        buffer.pop(0)
                        continue
                        
                    # total length of the packet: the first 10 bytes + number of points sampled * 2 bytes
                    packet_len = 10 + sample_quantity * 2
                    
                    if len(buffer) < packet_len:
                        break

                    # FSA (Start angle) & LSA (End angle)，little-endian mode
                    fsa_raw = struct.unpack_from('<H', buffer, 4)[0]
                    lsa_raw = struct.unpack_from('<H', buffer, 6)[0]
                    
                    # angle
                    start_angle = (fsa_raw >> 1) / 64.0
                    end_angle   = (lsa_raw >> 1) / 64.0
                    
                    # distance
                    distances = []
                    for i in range(sample_quantity):
                        dist_raw = struct.unpack_from('<H', buffer, 10 + i * 2)[0]
                        
                        distance_mm = dist_raw / 4.0 
                        if distance_mm > 0:
                            distances.append(distance_mm)
                    
                    if distances:
                        avg_dist = (sum(distances) / len(distances)) / 10 
                        logger.info(
                            f"Total {sample_quantity} points | Angle: {start_angle:.1f}° to {end_angle:.1f}° | Distance: {avg_dist:.1f} cm"
                        )
                    
                    buffer = buffer[packet_len:]
                else:
                    buffer.pop(0)

    except serial.SerialException as e:
        logger.error(f"Serial Port Error: {e}")
    except KeyboardInterrupt:
        logger.info("\nParse Over.")        
    finally:
        if 'serial_port' in locals() and serial_port.is_open:
            serial_port.close()

if __name__ == '__main__':
    parse_ydlidar()
