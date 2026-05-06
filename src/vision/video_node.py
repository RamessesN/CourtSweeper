from src.env_config import get_logger

import src.distance.distance_sub as ds
import src.vision.cv_config as cfg

from robomaster_ultra import camera
from ultralytics import YOLO
from typing import Optional

import cv2, time, queue
import numpy as np

logger = get_logger(__name__)

latest_frame: Optional[np.ndarray] = None
annotated_frame: Optional[np.ndarray] = None

target_x, target_y = None, None
prev_time = 0
running = True
fps_list = []

visual_error_x = 0
target_locked = False    # whether lock a ball
scan_needed = False      # whether 360-scan to search
no_ball_counter = 0      # counter of ball

# Mac Config
model = YOLO("src/vision/mlmodel/pt/tennis_v2.pt")

# Linux Config
# model = YOLO("src/vision/mlmodel/engine/tennis_v2.engine")
# model.names = {0: 'tennis ball'}

def yolo_predict(frame):
    global prev_time, target_x, target_y
    global visual_error_x, target_locked, scan_needed, no_ball_counter

    results = model(frame, conf = 0.25, device = cfg.DEVICE, verbose = False)
    annotated = results[0].plot()

    height, width = frame.shape[:2]
    center_x = width // 2

    if len(results[0].boxes) > 0:
        boxes = results[0].boxes    # recognize all targets

        no_ball_counter = 0
        scan_needed = False
        target_locked = True

        closest_box = None
        max_y2 = -1

        for box in boxes:
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            if y2 > max_y2:
                max_y2 = y2
                closest_box = box   # recognize the closest target

        x1, y1, x2, y2 = map(int, closest_box.xyxy[0])
        target_x = (x1 + x2) // 2
        target_y = (y1 + y2) // 2

        visual_error_x = target_x - center_x

        cv2.rectangle(annotated, (x1, y1), (x2, y2), (0, 255, 255), 3)

        if not (10 <= target_x <= width - 10) or not (10 <= target_y <= height - 10): # filter
            target_x = None
            target_y = None
            visual_error_x = 0
            target_locked = False
    else:
        target_x = None
        target_y = None
        visual_error_x = 0
        target_locked = False

        no_ball_counter += 1
        if no_ball_counter >= 15: # 连续 15 帧没看到球触发`找球`模式
            scan_needed = True

    cv2.line(annotated, (center_x, 0), (center_x, height), (160, 160, 160), 1)
    cv2.line(annotated, (0, height // 2), (width, height // 2), (160, 160, 160), 1)

    if target_x is not None and target_y is not None:
        cv2.circle(annotated, (target_x, target_y), 5, (255, 0, 0), -1)
        cv2.putText(annotated, f"Err: {visual_error_x}", (target_x + 10, target_y - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 255), 2)

    current_time = time.time()
    fps = 1.0 / (current_time - prev_time) if prev_time > 0 else 0
    prev_time = current_time

    fps_list.append(fps)
    if len(fps_list) > 10: # average of each 10 frames
        fps_list.pop(0)
    avg_fps = sum(fps_list) / len(fps_list)

    distance_text = "N/A"
    if ds.latest_distance is not None:
        distance_text = f"{ds.latest_distance / 10:.2f} cm"

    cv2.putText( # resolution
        annotated, f"RES: {width}x{height}", (10, 30), cv2.FONT_HERSHEY_SIMPLEX,
        1, (0, 0, 255), 2, lineType = cv2.LINE_AA
    )
    cv2.putText( # frame
        annotated, f"FPS: {int(avg_fps)}", (10, 60), cv2.FONT_HERSHEY_SIMPLEX,
        1, (0, 255, 0), 2, lineType = cv2.LINE_AA
    )
    cv2.putText( # distance
        annotated, f"Distance: {distance_text}", (10, 90), cv2.FONT_HERSHEY_SIMPLEX,
        1, (255, 0, 0), 2, lineType = cv2.LINE_AA
    )

    state_text = "Locked" if target_locked else ("Scanning" if scan_needed else "Searching")
    color = (0, 255, 0) if target_locked else (0, 165, 255)
    cv2.putText(annotated, f"Status: {state_text}", (10, 120), cv2.FONT_HERSHEY_SIMPLEX, 1, color, 2, lineType = cv2.LINE_AA)

    return annotated

def video_capture(ep_camera):
    global latest_frame, annotated_frame, running

    ep_camera.start_video_stream(display = False, resolution = camera.STREAM_360P)

    while running:
        try:
            img = ep_camera.read_cv2_image()
            if img is not None:
                img = cv2.resize(img, (640, 360))

                latest_frame = img
                annotated_frame = yolo_predict(img)

                cv2.imshow("on Live", annotated_frame)

                if cv2.waitKey(1) & 0xFF == ord('q'):
                    running = False
                    break

        except queue.Empty:
            logger.warning("等待画面超时 (跳过此帧)...")
            continue
        
        except Exception as e:
            logger.error(f"读取视频流发生严重异常: {e}")
            break