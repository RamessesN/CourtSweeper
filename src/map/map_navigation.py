from src.env_config import get_logger
import src.chassis.chassis_sub as c_sub

import time
import math
import cv2
import rclpy

from rclpy.node import Node

from nav_msgs.msg import Odometry
from geometry_msgs.msg import Twist
from geometry_msgs.msg import TransformStamped

from sensor_msgs.msg import CompressedImage
from sensor_msgs.msg import CameraInfo

from tf2_ros import TransformBroadcaster

from robomaster_ultra import robot

logger = get_logger(__name__)

ep_chassis = None

last_cmd_time = 0.0
is_moving = False


def build_camera_info_message(width, height):
    fx = fy = float(width)

    cx = width / 2.0
    cy = height / 2.0

    msg = CameraInfo()

    msg.width = width
    msg.height = height

    msg.distortion_model = "plumb_bob"

    msg.k = [
        fx, 0.0, cx,
        0.0, fy, cy,
        0.0, 0.0, 1.0
    ]

    msg.d = [0.0] * 5

    msg.r = [
        1.0, 0.0, 0.0,
        0.0, 1.0, 0.0,
        0.0, 0.0, 1.0
    ]

    msg.p = [
        fx, 0.0, cx, 0.0,
        0.0, fy, cy, 0.0,
        0.0, 0.0, 1.0, 0.0
    ]

    return msg


def euler_to_quaternion(yaw):
    qz = math.sin(yaw / 2.0)
    qw = math.cos(yaw / 2.0)

    return (0.0, 0.0, qz, qw)


class RoboMasterNavigation(Node):

    def __init__(self):
        super().__init__('robomaster_navigation')

        global ep_chassis

        # -------------------------------------------------
        # Publisher
        # -------------------------------------------------
        self.odom_pub = self.create_publisher(
            Odometry,
            '/odom',
            10
        )

        self.camera_pub = self.create_publisher(
            CompressedImage,
            '/camera/image/compressed',
            10
        )

        self.camera_info_pub = self.create_publisher(
            CameraInfo,
            '/camera/camera_info',
            10
        )

        # -------------------------------------------------
        # TF Broadcaster
        # -------------------------------------------------
        self.tf_broadcaster = TransformBroadcaster(self)

        # -------------------------------------------------
        # cmd_vel Subscriber
        # -------------------------------------------------
        self.cmd_sub = self.create_subscription(
            Twist,
            '/cmd_vel',
            self.cmd_vel_callback,
            10
        )

        # -------------------------------------------------
        # RoboMaster Init
        # -------------------------------------------------
        self.ep_robot = robot.Robot()

        self.ep_robot.initialize(conn_type="sta")

        self.ep_robot.set_robot_mode(mode="free")

        ep_chassis = self.ep_robot.chassis

        self.ep_camera = self.ep_robot.camera

        c_sub.get_xy(ep_chassis)
        c_sub.get_yaw(ep_chassis)

        self.ep_camera.start_video_stream(display=False)

        # -------------------------------------------------
        # Timer
        # -------------------------------------------------
        self.last_img_pub_time = 0.0

        self.timer = self.create_timer(
            0.02,
            self.timer_callback
        )

        logger.info("RoboMaster Navigation Node Started.")

    def cmd_vel_callback(self, message):
        global ep_chassis
        global last_cmd_time
        global is_moving

        if ep_chassis is None:
            return

        try:
            last_cmd_time = time.time()

            is_moving = True

            vx = message.linear.x
            vy = message.linear.y
            vw = message.angular.z

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
            logger.error(f"cmd_vel error: {e}")

    def timer_callback(self):

        global is_moving
        global last_cmd_time

        if c_sub.latest_x is None:
            return

        if c_sub.latest_yaw is None:
            return

        # -------------------------------------------------
        # Pose
        # -------------------------------------------------
        yaw_rad = math.radians(c_sub.latest_yaw)

        yaw_rad = math.atan2( 
            math.sin(yaw_rad),
            math.cos(yaw_rad)
        )

        qx, qy, qz, qw = euler_to_quaternion(yaw_rad)

        corrected_x = c_sub.latest_x
        corrected_y = c_sub.latest_y

        now = self.get_clock().now().to_msg()

        # -------------------------------------------------
        # TF
        # -------------------------------------------------
        t = TransformStamped()

        t.header.stamp = now

        t.header.frame_id = 'odom'
        t.child_frame_id = 'base_footprint'

        t.transform.translation.x = corrected_x
        t.transform.translation.y = corrected_y
        t.transform.translation.z = 0.0

        t.transform.rotation.x = qx
        t.transform.rotation.y = qy
        t.transform.rotation.z = qz
        t.transform.rotation.w = qw

        self.tf_broadcaster.sendTransform(t)

        # -------------------------------------------------
        # Odometry
        # -------------------------------------------------
        odom = Odometry()

        odom.header.stamp = now
        odom.header.frame_id = 'odom'

        odom.child_frame_id = 'base_footprint'

        odom.pose.pose.position.x = corrected_x
        odom.pose.pose.position.y = corrected_y
        odom.pose.pose.position.z = 0.0

        odom.pose.pose.orientation.x = qx
        odom.pose.pose.orientation.y = qy
        odom.pose.pose.orientation.z = qz
        odom.pose.pose.orientation.w = qw

        self.odom_pub.publish(odom)

        # -------------------------------------------------
        # Camera
        # -------------------------------------------------
        current_time = time.time()

        if current_time - self.last_img_pub_time > 0.1:

            self.last_img_pub_time = current_time

            img = self.ep_camera.read_cv2_image(
                strategy="newest"
            )

            if img is not None:

                img_resized = cv2.resize(
                    img,
                    (640, 360)
                )

                height, width = img_resized.shape[:2]

                _, encoded_img = cv2.imencode(
                    '.jpg',
                    img_resized,
                    [int(cv2.IMWRITE_JPEG_QUALITY), 60]
                )

                img_msg = CompressedImage()

                img_msg.header.stamp = now
                img_msg.header.frame_id = 'base_link'

                img_msg.format = 'jpeg'
                img_msg.data = encoded_img.tobytes()

                self.camera_pub.publish(img_msg)

                cam_info = build_camera_info_message(
                    width,
                    height
                )

                cam_info.header.stamp = now
                cam_info.header.frame_id = 'base_link'

                self.camera_info_pub.publish(cam_info)

        # -------------------------------------------------
        # Watchdog
        # -------------------------------------------------
        if is_moving:

            if time.time() - last_cmd_time > 0.3:

                ep_chassis.drive_wheels(
                    w1=0,
                    w2=0,
                    w3=0,
                    w4=0
                )

                is_moving = False

    def destroy_node(self):

        logger.info("Shutting down...")

        self.ep_camera.stop_video_stream()

        ep_chassis.unsub_attitude()
        ep_chassis.unsub_position()

        ep_chassis.drive_wheels(
            w1=0,
            w2=0,
            w3=0,
            w4=0
        )

        self.ep_robot.close()

        super().destroy_node()


def main():

    rclpy.init()

    node = RoboMasterNavigation()

    try:
        rclpy.spin(node)

    except KeyboardInterrupt:
        pass

    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
