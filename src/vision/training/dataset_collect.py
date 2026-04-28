import cv2
import os, time, queue
import numpy as np
from robomaster_ultra import robot, camera

def img_collect():
    save_dir = "./dataset_v2"

    os.makedirs(save_dir, exist_ok = True)
        
    ep_robot = robot.Robot()
    
    ep_robot.initialize(conn_type = "ap")  
    ep_robot.set_robot_mode(mode = "free")  
    ep_camera = ep_robot.camera

    ep_camera.start_video_stream(display = False, resolution = camera.STREAM_720P)
    
    print("[ s ] -> snapshot and save")
    print("[ q ] -> quit")

    count = 0
    try:
        while True:
            try:
                img = ep_camera.read_cv2_image()
                
                if img is not None:
                    target_w, target_h = 1280, 960 
                    
                    img_resized = cv2.resize(img, (target_w, target_h))

                    display_img = img_resized.copy()
                    center_w, center_h = target_w // 2, target_h // 2
                    
                    cv2.line(display_img, (center_w - 20, center_h), (center_w + 20, center_h), (0, 255, 0), 2)
                    cv2.line(display_img, (center_w, center_h - 20), (center_w, center_h + 20), (0, 255, 0), 2)
                    
                    cv2.putText(display_img, f"Collected: {count}", (20, 40), 
                                cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2, cv2.LINE_AA)

                    cv2.imshow("Dataset Collector", display_img)
                    
                    key = cv2.waitKey(1) & 0xFF
                    
                    if key == ord('s'):
                        timestamp = time.strftime("%Y%m%d_%H%M%S")
                        filename = os.path.join(save_dir, f"tennis_{timestamp}_{count:04d}.jpg")
                        
                        success = cv2.imwrite(filename, img_resized)
                        if success:
                            count += 1
                            print(f"No. {count} -> {filename}")
                            
                            flash = np.ones((target_h, target_w, 3), dtype = np.uint8) * 255
                            cv2.imshow("Dataset Collector", flash)
                            cv2.waitKey(50)
                        else:
                            print(f"Save failed: {filename}")
                        
                    elif key == ord('q'):
                        print("\nQuiting")
                        break
                        
            except queue.Empty:
                continue
                
    except KeyboardInterrupt:
        print("\nQuiting")
    finally:
        cv2.destroyAllWindows()
        ep_camera.stop_video_stream()
        ep_robot.close()
        print(f"\n🎉 Finish! Totally {count} images.")

if __name__ == '__main__':
    img_collect()