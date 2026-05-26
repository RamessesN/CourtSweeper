#set text(size: 14pt)

#set document(
  title: [CourtSweeper User Guide],
)

#set page(footer: context [
  *Court Sweeper*
  #h(1fr)
  #counter(page).display(
    "1/1",
    both: true,
  )
])

#set heading(numbering: "1.")

#set table(
  stroke: (x, y) => {
    // if x == 0 { (right: 0.75pt) } else { (right: none) }
    (bottom: 0.5pt)
  },
  fill: (x, y) => if y == 0 { silver },
  inset: (left: 0.5em, right: 0.5em),
)

#show table.cell: it => {
  set text(size: 12pt)
  if it.y == 0 {
    strong(it)
  } else if it.body == [] {
    pad(..it.inset)[_N/A_]
  } else {
    it
  }
}

// #show figure.caption: set text(red)
#show figure.where(
  kind: table,
): set figure.caption(position: top)
#show figure.where(
  kind: table,
): set block(breakable: true)

// Display inline code in a small box
// that retains the correct baseline.
#show raw.where(block: false): box.with(
  fill: luma(240),
  inset: (x: 3pt, y: 0pt),
  outset: (y: 3pt),
  radius: 2pt,
)

// Display code blocks with smaller text and background.
#show raw.where(block: true): it => {
  set text(size: 10pt)
  block(
    width: 100%,
    fill: luma(240),
    inset: 12pt,
    radius: 4pt,
    it,
  )
}

#v(1fr)

#title()

#v(1fr)

#figure(
  image("figures/fig_chassis.pdf", width: 80%),
)

#v(1fr)

#pagebreak()

#outline()

#pagebreak()

= Introduction

CourtSweeper is a vision-guided autonomous ball retrieval robot designed for collecting scattered tennis balls on tennis courts. Equipped with an NVIDIA Jetson Orin NX edge computing unit running real-time YOLO object detection, a dual-roller intake mechanism for efficient ball collection, and an iOS companion app for remote monitoring and intervention, CourtSweeper delivers end-to-end autonomous court maintenance.

This document is the *CourtSweeper User Guide*, intended for two audiences:

- *Regular Users*: After receiving the product, follow this manual to assemble the hardware, download the iOS app, and begin operating --- no programming experience required.
- *Developers*: Users with experience in Python, ROS2, and deep learning may follow this manual to set up a complete development environment for secondary development and feature extension.

The document is organised as follows:

+ @package lists all parts and materials included in the shipping box
+ @assembly provides a step-by-step hardware assembly tutorial with photographs
+ @quickstart is for regular users: app download, connection, and operation guide
+ @dev is for developers: Jetson flashing, ROS2 environment, SDK configuration, training pipeline
+ @running covers system startup and operational workflows
+ @troubleshoot lists common issues and diagnostic procedures
+ The Appendix contains quick-reference tables (pin mapping, UDP commands, Wi-Fi modes)

= Package Contents
<package>

CourtSweeper ships as a kit of disassembled parts. Upon unboxing, please verify that all items listed below are present:

#figure(
  table(
    columns: (1fr, auto, 1fr),
    align: center + horizon,
    table.header([Part No.], [Component], [Qty]),
    table.hline(stroke: 0.5pt),
    [A01], [DJI RoboMaster EP chassis (incl. Mecanum wheels ×4)], [1],
    table.hline(stroke: 0.5pt),
    [A02], [DJI EP Intelligent Battery (3S LiPo, 10.8V, 2400mAh)], [1],
    table.hline(stroke: 0.5pt),
    [A03], [RoboMaster EP HD camera (integrated)], [1],
    table.hline(stroke: 0.5pt),
    [B01], [NVIDIA Jetson Orin NX (incl. power adapter)], [1],
    table.hline(stroke: 0.5pt),
    [B02], [YDLIDAR X3-YB-1 (incl. USB-serial cable)], [1],
    table.hline(stroke: 0.5pt),
    [B03], [Arduino UNO + USB-B data cable], [1],
    table.hline(stroke: 0.5pt),
    [C01], [775 D-shaft DC motor], [2],
    table.hline(stroke: 0.5pt),
    [C02], [BTS7960 high-current motor driver module], [2],
    table.hline(stroke: 0.5pt),
    [C03], [3S LiPo battery (11.1V, 5200mAh, 40C)], [1],
    table.hline(stroke: 0.5pt),
    [C04], [Low-voltage buzzer BX100], [1],
    table.hline(stroke: 0.5pt),
    [D01], [60mm rubber friction wheel (D-bore)], [2],
    table.hline(stroke: 0.5pt),
    [D02], [30mm extended brass coupling], [2],
    table.hline(stroke: 0.5pt),
    [D03], [Dual-roller mounting bracket (incl. screws)], [1],
    table.hline(stroke: 0.5pt),
    [E01], [Dupont wire set (male-to-female, various)], [1],
    table.hline(stroke: 0.5pt),
    [E02], [XT60 power cable / terminal block], [1],
  ),
  caption: [Bill of Materials],
) <tab:bom>

= Hardware Assembly
<assembly>

#block(
  fill: orange.lighten(80%),
  inset: 1em,
  radius: 4pt,
)[*+ WARNING:* Ensure all devices are powered off before assembly. Work on a clean, flat surface to avoid losing small parts.]

== Chassis Setup

The RoboMaster EP chassis arrives with Mecanum wheels pre-installed. Only the following steps are required:

+ Insert the EP Intelligent Battery into the rear battery bay; a click indicates proper seating.
+ Press and hold the chassis power button for 2 seconds to turn it on. Verify the battery indicator LEDs illuminate.

#figure(
  image("figures/fig_chassis.pdf", width: 65%),
  caption: [DJI RoboMaster EP chassis],
)

== Dual-Roller Intake Assembly

The intake mechanism is the core mechanical subsystem of CourtSweeper, consisting of two 775 motors, two 60mm rubber wheels, two couplings, and a mounting bracket.

*Step 2.1 --- Coupling installation.* Slide the 30mm brass coupling onto the D-shaft of each 775 motor and tighten the set screw with a hex key. Ensure the coupling is fully seated against the shaft shoulder with no axial play.

#figure(
  image("figures/fig_motor.pdf", width: 50%),
  caption: [Coupling-to-motor installation detail],
)

*Step 2.2 --- Wheel installation.* Press the 60mm rubber friction wheel onto the opposite D-bore of each coupling and tighten the set screw to secure.

#figure(
  image("figures/fig_dual_roller.pdf", width: 60%),
  caption: [Front view of the dual-roller intake mechanism],
)

*Step 2.3 --- Bracket attachment.* Mount both motor-wheel assemblies onto the dual-roller bracket so the two rubber wheels face each other, with a gap approximately equal to a tennis ball diameter. Fasten the motors using M3 screws through the bracket holes.

*Step 2.4 --- Mounting to chassis.* Attach the entire intake bracket to the front underside of the EP chassis using M4 screws through the pre-drilled mounting holes.

== Motor Driver Wiring

The BTS7960 driver modules require connections to both the Arduino UNO logic pins and the 3S LiPo battery power. Pin assignments are listed in @tab:arduino_pins.

#figure(
  table(
    columns: (1fr, 1fr, 1fr, 1fr),
    align: center + horizon,
    table.header([Motor], [EN (Enable)], [RPWM (Forward)], [LPWM (Reverse)]),
    [Left Motor], [D4], [D5], [D6],
    [Right Motor], [D7], [D9], [D10],
  ),
  caption: [Arduino pin assignments for dual BTS7960 drivers],
) <tab:arduino_pins>

*Wiring steps:*

+ *Logic side:* Use Dupont wires to connect each BTS7960's EN, RPWM, and LPWM to the corresponding Arduino pins (see @tab:arduino_pins). Both modules share the Arduino 5V and GND.
+ *Power side:* Connect the 3S LiPo battery positive and negative terminals to the power input of both BTS7960 modules in parallel via XT60 connectors. Connect each BTS7960 output to the corresponding 775 motor.
+ *Ground bonding:* Connect Arduino GND to BTS7960 GND to establish a common reference for logic signals.

#figure(
  image("figures/fig_drive.pdf", width: 80%),
  caption: [BTS7960 motor driver wiring diagram],
)

#block(
  fill: orange.lighten(80%),
  inset: 1em,
  radius: 4pt,
)[*+ WARNING:* Always insert the low-voltage buzzer (BX100) into the 3S LiPo balance lead during wiring to monitor cell voltage and prevent over-discharge damage.]

#figure(
  image("figures/fig_ep_battery.pdf", width: 45%),
  caption: [EP chassis battery and 3S LiPo motor battery],
)

== LiDAR Installation

Secure the YDLIDAR X3-YB-1 to the rear upper mounting bracket of the chassis using screws. Connect the USB-serial adapter cable to an available USB port on the Jetson Orin NX.

#figure(
  image("figures/fig_lidar.pdf", width: 40%),
  caption: [YDLIDAR X3-YB-1 sensor],
)

== Jetson Orin NX Installation

Mount the Jetson Orin NX module on the mid-deck of the chassis using screws or cable ties. Connect the 19V power adapter to the Jetson DC power jack.

#figure(
  image("figures/fig_jetson.pdf", width: 55%),
  caption: [NVIDIA Jetson Orin NX edge computing unit],
)

== Power Distribution Topology

CourtSweeper employs an isolated dual-battery power scheme:

+ *EP chassis battery:* Supplies the chassis drive motors and camera independently.
+ *3S LiPo battery:* Dedicated to the 775 intake motors and BTS7960 drivers.
+ *Jetson 19V adapter:* Provides independent power for the computing unit.

*Common ground requirement:* The GND planes of the Arduino, BTS7960 drivers, and Jetson must be connected to ensure reliable PWM logic signal transmission.

== Pre-Flight Checklist

Before first power-up, verify each item:
+ Mecanum wheels are securely fastened, no looseness
+ Coupling set screws are tightened
+ Rubber wheels rotate freely without rubbing the bracket
+ All terminal connections are secure, no exposed conductors
+ 3S LiPo voltage ≥ 11.1V (BX100 not alarming)
+ EP battery fully charged (≥ 3 indicator bars)
+ LiDAR window is clean and unit rotates freely
+ Jetson cooling fan is operational
+ Arduino USB cable is connected to Jetson

// #figure(
//   table(
//     columns: (auto, 1fr, 1fr),
//     table.header([No.], [Check Item], [Status]),
//     [1], [Mecanum wheels are securely fastened, no looseness], [],
//     [2], [Coupling set screws are tightened], [],
//     [3], [Rubber wheels rotate freely without rubbing the bracket], [],
//     [4], [All terminal connections are secure, no exposed conductors], [],
//     [5], [3S LiPo voltage ≥ 11.1V (BX100 not alarming)], [],
//     [6], [EP battery fully charged (≥ 3 indicator bars)], [],
//     [7], [LiDAR window is clean and unit rotates freely], [],
//     [8], [Jetson cooling fan is operational], [],
//     [9], [Arduino USB cable is connected to Jetson], [],
//   ),
//   caption: [Pre-flight checklist],
// ) <tab:checklist>

= Quick Start (Regular Users)
<quickstart>

This chapter is for users who want to operate the robot out of the box. Following the steps below, you can complete your first drive within 10 minutes.

== Download the iOS App

Open the App Store on your iPhone or iPad, search for *"CourtSweeper"*, and install the official app.

#figure(
  image("figures/iOS_app.png", width: 75%),
  caption: [CourtSweeper iOS app main interface],
)

== Connect to the Robot

+ Confirm the robot is powered on (Jetson green LED solid, EP chassis battery indicator lit).
+ Open the Wi-Fi settings on your iOS device, select the Jetson's broadcasted hotspot (SSID format: `CourtSweeper-XXXX`), enter the factory default password `courtsweeper`.
+ Launch the CourtSweeper app. It should auto-detect and connect to the robot. Once connected, the main interface displays the live video stream.

== App Interface Overview

*Main HUD:* The central area renders the real-time MJPEG video stream from the robot's camera. The feed is overlaid with YOLO-detected tennis ball bounding boxes and a crosshair reticle, giving the operator real-time perception feedback.

#figure(
  image("figures/app_vision.png", width: 40%),
  caption: [Live camera feed with YOLO-detected tennis ball bounding boxes and crosshair reticle],
)

*Virtual Joysticks (bottom-left):*
+ Left joystick controls chassis translational motion (forward / backward / lateral strafe).
+ Right joystick controls chassis rotation (clockwise / counterclockwise).

*Control Buttons (bottom-right):*
+ *AUTO*: Switch to fully autonomous mode --- the robot plans and executes ball retrieval autonomously.
+ *MANUAL*: Switch to manual teleoperation mode.
+ *RECALL*: One-touch recall --- the robot navigates back to the origin pose via Nav2.
+ *E-STOP*: Emergency stop --- immediately brakes and suspends all autonomous logic.

*Telemetry Panel (top):* Displays battery voltage, Jetson CPU/GPU temperature, and the robot's current FSM state (IDLE / SEARCHING / TRACKING / INGESTING).

== First Operation

+ Ensure the surface is flat and free of obstacles.
+ Place the robot at the starting position of the court.
+ Tap *AUTO* in the app and observe the robot begin its autonomous coverage scan (Boustrophedon S-shaped sweep path).
+ To take manual control at any time, tap *MANUAL* and use the virtual joysticks.
+ When the robot is full or you wish to stop, tap *RECALL* to have the robot return to the origin.

During autonomous operation, the app provides a top-down court map showing the robot's current position, the Boustrophedon coverage path, and detected ball locations.

#figure(
  image("figures/app_map.png", width: 40%),
  caption: [Top-down court map view showing the robot's position, coverage path, and detected ball locations during autonomous mission execution],
)

= Developer Environment Setup
<dev>

This chapter is for developers who wish to extend CourtSweeper. You will configure a complete Jetson development environment including the RoboMaster-SDK-Ultra communication stack, ROS2 navigation framework, and YOLO training pipeline.

== Prerequisites

Before you begin, ensure you have:

+ A macOS or Ubuntu host machine for SSH access to the Jetson and YOLO model training
+ NVIDIA Jetson Orin NX (preloaded with Ubuntu 22.04 + JetPack 6.0)
+ Python 3.10+
+ Basic Linux command-line proficiency

== Jetson Flashing (JetPack 6.0)

If your Jetson does not have a preloaded OS or needs a factory reset, follow these steps:

+ Install NVIDIA SDK Manager on the host machine (Ubuntu 22.04 x86_64):
  ```bash
  sudo apt install nvidia-sdk-manager
  sdkmanager
  ```
+ Connect the Jetson to the host machine via USB-C cable and put it into Recovery Mode (hold the REC button while powering on).
+ In SDK Manager, select `Jetson Orin NX`, and check `JetPack 6.0` along with `Jetson Linux`, `CUDA Toolkit`, `cuDNN`, and `TensorRT`.
+ Wait for the flashing to complete (approximately 30 minutes). Complete the Ubuntu initial setup on first boot.

== ROS2 Humble Installation

Execute the following commands on the Jetson to install ROS2 Humble:

```bash
sudo apt update && sudo apt install -y locales
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
sudo apt install -y software-properties-common
sudo add-apt-repository -y universe
sudo apt update && sudo apt install -y curl
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
sudo apt update
sudo apt install -y ros-humble-desktop ros-dev-tools
```

Add the environment setup to `~/.bashrc`:

```bash
echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
source ~/.bashrc
```

Verify the installation:

```bash
ros2 run demo_nodes_cpp talker
```

== Clone the CourtSweeper Repository

```bash
git clone https://github.com/your-org/CourtSweeper.git ~/CourtSweeper
cd ~/CourtSweeper
```

== Python Dependency Installation

Install the project's Python dependencies on the Jetson:

```bash
# Core dependencies
pip install --break-system-packages numpy opencv-python pyserial simple-pid

# YOLO inference
pip install --break-system-packages ultralytics

# LiDAR driver
pip install --break-system-packages rplidar-roboticia

# RoboMaster-SDK-Ultra (core chassis communication library)
pip install --break-system-packages robomaster-sdk-ultra

# ROS2 utilities
pip install --break-system-packages transforms3d
```

== RoboMaster-SDK-Ultra Configuration

`robomaster-sdk-ultra` is CourtSweeper's high-performance Python SDK encapsulating all EP chassis communication. The Wi-Fi connection mode must be specified during initialisation:

+ *AP mode:* The Jetson connects to the robot as a hotspot (used for iOS app direct connection and dataset collection).
+ *STA mode:* Both robot and Jetson connect to the same Wi-Fi router (used for SLAM mapping and autonomous navigation).

Example code (`chassis_ctrl.py`):

```python
from robomaster import robot

ep_robot = robot.Robot()
# AP mode: Jetson acts as hotspot
ep_robot.initialize(conn_type="ap")
# STA mode: robot joins router network
# ep_robot.initialize(conn_type="sta", sn="robot_sn")

ep_robot.set_robot_mode(mode="free")
ep_chassis = ep_robot.chassis
```

Wi-Fi mode summary:

#figure(
  table(
    columns: (1fr, 1fr, 2fr),
    align: center + horizon,
    table.header([Mode], [SDK Parameter], [Use Case]),
    [AP], [`conn_type="ap"`], [iOS direct connection, dataset collection, manual teleop],
    [STA], [`conn_type="sta"`], [SLAM mapping, Nav2 autonomous navigation],
  ),
  caption: [Wi-Fi operation modes],
) <tab:wifi_modes>

== Arduino Firmware Flashing

The dual-roller intake motors are driven by the Arduino UNO via PWM. The firmware source is located at `src/roller/roller_setting.ino`.

+ Connect the Arduino UNO to the Jetson (or your laptop) via USB-B cable.
+ Install the Arduino IDE or CLI:
  ```bash
  sudo apt install -y arduino
  ```
+ Open `src/roller/roller_setting.ino`, select Tool → Port → `/dev/ttyUSB0` (or `/dev/ttyACM0`), and choose the `Arduino Uno` board.
+ Click "Upload" to flash the firmware.

Firmware capabilities:
+ Receives CSV-formatted commands `"L,R\n"` via serial (115200 bps, 8N1)
+ Parses left/right wheel speeds (range -255 to 255) and outputs corresponding PWM
+ Built-in 500ms watchdog: halts all motors on communication loss

== YOLO Model Training Pipeline

CourtSweeper uses YOLOv6-Nano for tennis ball detection. If you need to retrain the model with your own dataset, follow these steps:

*Step 1 --- Dataset collection.* Switch the robot to AP mode and run the collection tool:

```bash
python src/vision/training/dataset_collect.py
```

Use the camera preview to aim: press `s` to capture a photo. Collect at least 500 images under varying lighting and distances. Images are automatically saved to `./dataset/tennis_v2/`.

*Step 2 --- Dataset annotation.* Annotate the captured images with bounding boxes using LabelImg or Roboflow. Export in YOLO format (one `.txt` file per image).

*Step 3 --- Train the model.*

```bash
python src/vision/training/model_training.py
```

After training, the model file is saved at `src/vision/mlmodel/yolo26n.pt`.

*Step 4 --- Model conversion (PyTorch → ONNX → TensorRT).* For edge deployment on Jetson, convert the model to an FP16 TensorRT engine:

```bash
# PyTorch → ONNX
python src/vision/mlmodel/pt2onnx.py

# ONNX → TensorRT (FP16)
trtexec --onnx=yolo26n.onnx \
        --saveEngine=yolo26n.engine \
        --fp16
```

== Verification

Run the following commands in separate terminals to confirm each subsystem is operational:

```bash
# Terminal 1: Launch ROS2 bridge (chassis + video stream)
python src/chassis/chassis_ctrl.py

# Terminal 2: Launch LiDAR driver
python src/lidar/lidar_parse.py

# Terminal 3: Launch IR distance sensor subscriber
python src/distance/distance_sub.py

# Terminal 4: Launch video inference node
python src/vision/video_node.py
```

If all terminals run without errors and ROS2 topics `/odom`, `/scan`, and `/camera/image/compressed` produce output, the development environment is correctly configured.

= Running the System
<running>

The complete CourtSweeper operational workflow consists of three phases: power-on → mapping → autonomous navigation.

== Power-On Sequence

#figure(
  table(
    columns: (1fr, auto, auto),
    align: center + horizon,
    table.header([Step], [Action], [Confirmation Signal]),
    [1], [Insert 3S LiPo (BX100 buzzer)], [BX100 displays voltage ≥ 11.1V],
    [2], [Insert EP battery], [Chassis battery indicator ≥ 3 bars],
    [3], [Connect Jetson 19V power], [Fan starts, green LED flashing],
    [4], [Connect Arduino USB to Jetson], [`ls /dev/ttyUSB0` visible],
    [5], [Wait for Jetson boot], [Wi-Fi hotspot appears / SSH login succeeds],
  ),
  caption: [Power-on sequence],
) <tab:power_on>

== SLAM Mapping

For first use (or after changing venues), an environment map must be built. The mapping workflow is driven by `map_generation.py`.

+ Configure the robot Wi-Fi to STA mode (both robot and Jetson connect to the same router).
+ Start mapping:

```bash
ros2 launch slam_toolbox online_async_launch.py
python src/../resource/map/map_generation.py
```

+ Use the iOS app in *MANUAL* mode to drive the robot across the entire court. `slam_toolbox` will build a 2D occupancy grid map in real time.
+ Once the area is fully covered, press Ctrl+C to stop mapping. The map is automatically saved as a ROS2 map file pair (`.pgm` + `.yaml`).

#figure(
  table(
    columns: (1fr, 2fr, 2fr),
    align: center + horizon,
    table.header([Step], [Command], [Description]),
    [1], [`ros2 launch slam_toolbox online_async_launch.py`], [Start SLAM node],
    [2], [`python map_generation.py`], [Start mapping control node],
    [3], [Manual teleop across full court], [Using App MANUAL mode],
    [4], [Ctrl+C stop mapping], [Map saved as `map.pgm` / `map.yaml`],
  ),
  caption: [SLAM mapping workflow],
) <tab:slam_workflow>

== Autonomous Navigation

After mapping is complete, start the Nav2 autonomous navigation stack:

```bash
ros2 launch nav2_bringup navigation_launch.py map:=./map.yaml
python src/../resource/map/map_navigation.py
```

+ The robot's high-level FSM (@fig:fsm) automatically transitions to the SEARCHING state and follows the Boustrophedon S-shaped coverage path across the court.
+ When YOLO detects a tennis ball, the FSM transitions to TRACKING. The dual-PID controller aligns the chassis with the target and approaches.
+ Within 200 mm range, the FSM enters INGESTING: roller motors pre-spin, and the chassis drives forward to collect the ball.
+ Upon full coverage or receipt of a RECALL command, Nav2 plans the shortest path back to the origin.

#figure(
  image("figures/fig_drive.pdf", width: 80%),
  caption: [CourtSweeper full operational workflow: SLAM mapping → Nav2 path planning → dual-PID tracking → roller ingestion],
) <fig:fsm>

== Common Launch Commands Quick Reference

#figure(
  table(
    columns: (3fr, 5fr, 3fr),
    align: center + horizon,
    table.header([Scenario], [Command], [Notes]),
    [SLAM Mapping],
    [`ros2 launch slam_toolbox online_async_launch.py && python map_generation.py`],
    [Requires STA mode],

    [Autonomous Navigation],
    [`ros2 launch nav2_bringup navigation_launch.py map:=./map.yaml && python map_navigation.py`],
    [Requires STA mode],

    [Manual Teleop], [`python src/chassis/chassis_ctrl.py`], [Requires AP mode + iOS app],
    [Test Video Only], [`python src/vision/video_node.py`], [ROS2 not required],
    [Test LiDAR Only], [`python src/lidar/lidar_parse.py`], [Requires ROS2],
    [Test Roller Motors], [`python src/roller/roller_drive.py`], [Requires Arduino connected],
  ),
  caption: [Common launch commands quick reference],
) <tab:commands>

= Troubleshooting
<troubleshoot>

The following table lists common issues encountered during CourtSweeper operation and their diagnostic procedures.

#figure(
  table(
    columns: (1fr, 1fr, 1fr),
    align: center + horizon,
    table.header([Issue], [Possible Cause], [Solution]),
    [Motors won't spin],
    [Arduino not connected / firmware not flashed / BTS7960 wiring incorrect],
    [Check USB serial visibility: `ls /dev/ttyUSB*`; re-flash Arduino firmware; verify wiring against @tab:arduino_pins],

    [LiDAR produces no data],
    [USB cable loose / serial port permissions],
    [Execute `sudo chmod 666 /dev/ttyUSB0`; verify device detection: `lsusb | grep CP210x`],

    [Video lag / black screen],
    [Wi-Fi bandwidth insufficient / frame rate too high],
    [Move closer to Wi-Fi hotspot; lower resolution to 720P; close other bandwidth-consuming devices],

    [Serial communication dropouts],
    [Loose Dupont wires / serial port contention],
    [Inspect physical connections; check with `lsof /dev/ttyUSB0`; re-plug USB cable],

    [Ball ingestion fails],
    [Rubber wheel wear / motor speed insufficient / distance threshold mis-calibrated],
    [Inspect rubber wheels for visible wear and replace if needed; calibrate IR distance sensor thresholds; increase `pid_forward` output limits],

    [Robot does not move],
    [EP battery low / not in free motion mode],
    [Check chassis battery indicator; verify `set_robot_mode("free")` has been called in the code],

    [Cannot connect to Wi-Fi],
    [Hotspot not started / IP address conflict],
    [Verify Jetson `hostapd` service is running; restart Jetson and the iOS app],

    [YOLO does not detect balls],
    [Insufficient lighting / model not loaded / confidence threshold too high],
    [Improve lighting; verify the model path is correct; lower `conf_thres` to 0.15],
  ),
  caption: [Common troubleshooting table],
) <tab:troubleshoot>

= Appendix A: Quick Reference
<appendix>

== Arduino Pin Mapping

#figure(
  table(
    columns: (1fr, 1fr, 1fr, 1fr),
    align: center + horizon,
    table.header([Motor], [EN (Enable)], [RPWM (Forward)], [LPWM (Reverse)]),
    [Left Motor], [D4], [D5], [D6],
    [Right Motor], [D7], [D9], [D10],
  ),
  caption: [Arduino pin mapping (duplicated from @tab:arduino_pins)],
)

== UDP Control Commands (iOS → Jetson)

#figure(
  table(
    columns: (2fr, 3fr, 5fr),
    align: center + horizon,
    table.header([Command], [JSON Payload], [Semantics]),
    [E-STOP], [`{"cmd": "estop"}`], [Emergency stop: immediately brake, suspend all autonomous logic],
    [RECALL], [`{"cmd": "recall"}`], [One-touch recall: abort mission, navigate back to origin],
    [AUTO], [`{"cmd": "auto"}`], [Switch to autonomous mode],
    [MANUAL], [`{"cmd": "manual"}`], [Switch to manual teleoperation mode],
    [JOYSTICK], [`{"vx": f, "vy": f, "vw": f}`], [Omnidirectional velocity command (translation + rotation)],
  ),
  caption: [UDP control commands quick reference],
) <tab:udp_appendix>

== Wi-Fi Mode Selection

#figure(
  table(
    columns: (1fr, 1fr, 2fr),
    align: center + horizon,
    table.header([Mode], [SDK Parameter], [Use Case]),
    [AP], [`conn_type="ap"`], [iOS direct connection, dataset collection, manual teleop],
    [STA], [`conn_type="sta"`], [SLAM mapping, Nav2 autonomous navigation],
  ),
  caption: [Wi-Fi mode quick reference],
)

== CourtSweeper Source Code Structure

```text
src/
├── chassis/          # Dual-PID chassis controller + ingestion state machine
│   └── chassis_ctrl.py
├── roller/           # Arduino firmware + Jetson serial driver
│   ├── roller_setting.ino
│   └── roller_drive.py
├── vision/           # YOLO inference + training + dataset collection
│   ├── video_node.py
│   ├── cv_config.py
│   ├── training/
│   │   ├── dataset_collect.py
│   │   └── model_training.py
│   └── mlmodel/
│       └── pt2onnx.py
├── lidar/            # RPLidar driver
│   └── lidar_parse.py
├── distance/         # IR distance sensor subscriber
│   └── distance_sub.py
└── env_config.py     # Global logging + debug configuration
```

== Contact

// + *Technical Support Email:* `support@courtsweeper.example.com`
+ *Open-Source Repository:* #link("https://github.com/RamessesN/CourtSweeper")
+ *Issue Reporting:* Please submit bug reports or feature requests via GitHub Issues
