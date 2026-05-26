#set text(size: 14pt)

#set page(footer: context [
  *Court Sweeper*
  #h(1fr)
  #counter(page).display(
    "1/1",
    both: true,
  )
])

#set heading(numbering: "1.")
#show heading: set text(red)

#set table(
  stroke: (x, y) => {
    let h = if y > 0 {
      (top: 1pt)
    } else {
      (top: none)
    }
    let v = if x == 1 {
      (left: 1pt)
    } else {
      (left: none)
    }
    (top: h.top, left: v.left, bottom: none, right: none)
  },
  // gutter: 0.2em,
  fill: (x, y) => if y == 0 { orange },
  inset: (left: 0.5em, right: 0.5em),
)

#show table.cell: it => {
  set text(size: 12pt)
  if it.y == 0 {
    set text(white)
    strong(it)
  } else if it.body == [] {
    // Replace empty cells with 'N/A'
    pad(..it.inset)[_N/A_]
  } else {
    it
  }
}

#show figure.caption: set text(red)
#show figure.where(
  kind: table,
): set figure.caption(position: top)

#set math.equation(numbering: "(1)")

#set document(
  title: [Theoretical Manual],
)


#v(3fr)

#title()

#v(2fr)

#figure(
  image("figures/courtsweeper.png", width: 60%),
)

#v(3fr)

#pagebreak()

#outline()

#pagebreak()

This manual presents the mathematical and algorithmic foundations underpinning each subsystem of the CourtSweeper. It formalises the sensor models, kinematic equations, control laws, navigation algorithms, communication protocols, and actuation principles.

= Perception Models
<theory_perception>

== Camera Pinhole Model

The system adopts the standard pinhole camera model. Let the camera intrinsic matrix be:

$
  K = mat(
    f_x, 0, c_x;
    0, f_y, c_y;
    0, 0, 1;
  ), quad P = mat(
    f_x, 0, c_x, 0;
    0, f_y, c_y, 0;
    0, 0, 1, 0;
  )
$

For the CourtSweeper, the intrinsic parameters are approximated as $f_x = f_y = W$ and $(c_x, c_y) = (W/2, H/2)$, where $W times H$ is the resized frame dimension (typically $640 times 360$). The lens is assumed to be distortion-free (Brown-Conrady model with all $k_i = 0$).

#figure(
  table(
    columns: (auto, 1fr, 1fr, 1fr, 1fr, 1fr),
    // table.hline(stroke: 2pt),
    table.header([Parameter], [Value], [Min.], [Typical], [Max.], [Units]),
    // table.hline(stroke: 1pt),
    table.hline(stroke: 0.5pt),
    [$f_x, f_y$ (focal length)], [$W$], [320], table.cell(fill: aqua)[640], [1280], [px],
    table.hline(stroke: 0.5pt),
    [$c_x$ (principal point x)], [$W/2$], [160], table.cell(fill: aqua)[320], [640], [px],
    table.hline(stroke: 0.5pt),
    [$c_y$ (principal point y)], [$H/2$], [90], table.cell(fill: aqua)[180], [360], [px],
    table.hline(stroke: 0.5pt),
    [Distortion], [`plumb_bob`], [], table.cell(fill: aqua)[$k_i = 0$], [], [],
    table.hline(stroke: 0.5pt),
  ),
  caption: [Camera Intrinsic Parameters],
) <tab:cam_intrinsics>

*IBVS Visual Error.*
The system employs Image-Based Visual Servoing (IBVS): the control error is computed directly in the image plane rather than in 3D Cartesian space. Given the YOLO-detected target centre $(x_t, y_t)$ and the frame centre $(c_x, c_y)$:

$
  e_x(t) = x_t - c_x
$ <eq:visual_error>

A positive $e_x$ indicates the target lies to the right of the optical axis. This scalar is fed as the process variable to the lateral PID controller (see @theory_pid).

*Nearest-Target Depth Proxy.*
When multiple tennis balls appear in a single frame, the system selects the nearest candidate using the bottom Y-coordinate heuristic:

$
  "target" = arg max_("box"_i) (y_(2,i))
$ <eq:nearest>

Larger $y_2$ values correspond to objects lower in the frame, which under the ground-facing camera assumption implies closer proximity.

== YOLO Object Detection Theory

*Architecture.*
The system deploys YOLOv6-Nano (`yolo26n.pt`), a single-stage anchor-free detector comprising three components:

- *Backbone:* EfficientRep --- a re-parameterisation-friendly CNN for multi-scale feature extraction.
- *Neck:* Rep-PAN --- a Path Aggregation Network with re-parameterisation blocks.
- *Head:* Decoupled head with independent classification and localisation branches.

*Loss Functions.*
Training minimises the composite loss:

$
  cal(L)_"total" = lambda_("box") cal(L)_"CIoU" + lambda_("cls") cal(L)_"BCE" + lambda_("dfl") cal(L)_"DFL"
$

where:
- $cal(L)_"CIoU"$ (Complete IoU loss) regresses bounding boxes by jointly optimising overlap area, centre-point distance, and aspect ratio consistency.
- $cal(L)_"BCE"$ (Binary Cross-Entropy) penalises class misclassification.
- $cal(L)_"DFL"$ (Distribution Focal Loss) models box edge positions as discrete probability distributions for anchor-free regression.
- $lambda_("box") = 7.5$, $lambda_("cls") = 0.5$, $lambda_("dfl") = 1.5$ are empirically weighted.

*Training Hyperparameters.*

#figure(
  table(
    // columns: (5fr, 3fr, 3fr, 4fr),
    columns: (auto, 1fr, 1fr, auto),
    align: center + horizon,
    table.header([Hyperparameter], [Value], [Min.], [Typical]),
    [Epochs], [200], [50], table.cell(fill: aqua)[200--300],
    [Input size (imgsz)], [640], [320], table.cell(fill: aqua)[640],
    [Batch size], [16], [4], table.cell(fill: aqua)[16--64],
    [Initial LR ($l r 0$)], [0.01], [0.001], table.cell(fill: aqua)[0.01],
    [Final LR factor ($l r f$)], [0.01], [0.001], table.cell(fill: aqua)[0.01],
    [Optimiser], [SGD], [], table.cell(fill: aqua)[SGD \ (momentum = 0.937)],
    [Weight decay], [0.0005], [0], table.cell(fill: aqua)[0.0005],
    [Warmup epochs], [3.0], [0], table.cell(fill: aqua)[3.0],
    [Mosaic augmentation], [1.0], [0], table.cell(fill: aqua)[1.0],
    [Horizontal flip probability], [0.5], [0], table.cell(fill: aqua)[0.5],
    [HSV perturbation], [(0.015, 0.7, 0.4)], [], table.cell(fill: aqua)[],
    [Random erasing probability], [0.4], [0], table.cell(fill: aqua)[0.4],
    [Early-stopping patience], [100], [10], table.cell(fill: aqua)[50--100],
    [Automatic Mixed Precision (AMP)], [ON], [], table.cell(fill: aqua)[ON],
  ),
  caption: [YOLO Training Hyperparameters],
) <tab:yolo_training>

*Inference Parameters.*

#figure(
  table(
    columns: (auto, 1fr, 1fr, 1fr),
    align: center + horizon,
    table.header([Parameter], [Value], [Min.], [Typical]),
    [Confidence threshold], [0.25], [0.05], table.cell(fill: aqua)[0.25--0.50],
    [NMS IoU threshold], [0.7], [0.3], table.cell(fill: aqua)[0.5--0.7],
    [Inference resolution], [$640 times 360$], [], table.cell(fill: aqua)[],
    [Input channels], [3 (RGB)], [], table.cell(fill: aqua)[],
  ),
  caption: [YOLO Inference Parameters],
) <tab:yolo_inference>

*Model Conversion Pipeline.*
For edge deployment on the NVIDIA Jetson Orin NX, the model undergoes a three-stage optimisation:

$
  // TODO: put it above
  "PyTorch (.pt)" arrow.r("export") "ONNX (.onnx)" arrow.r("trtexec") "TensorRT (.engine, FP16)"
$

The FP16 half-precision engine reduces inference latency by approximately $2 times$ with negligible detection accuracy degradation on the Jetson's Ampere GPU.

== LiDAR Triangulation Principle

The YDLIDAR X3-YB-1 operates on the laser triangulation principle. An infrared laser emitter projects a spot onto the target surface; the reflected spot is imaged by a CMOS sensor at a known baseline offset from the emitter. The distance $d$ to the target is recovered by solving the triangle formed by the laser axis, the lens optical axis, and the reflected ray path:

$ d = (b dot f) / (Delta x) $

where $b$ is the baseline distance, $f$ the receiver lens focal length, and $Delta x$ the spot displacement on the CMOS array. The sensor head rotates at 7 Hz to achieve 360#sym.degree scanning coverage.

#figure(
  table(
    columns: (auto, 1fr, 1fr, 1fr, 1fr, auto),
    align: center + horizon,
    table.header([Parameter], [Min.], [Typical], [Max.], [Units], [Remarks]),
    [Sampling rate], [], table.cell(fill: aqua)[4000], [], [Hz], [Points per second],
    [Scan frequency], [], table.cell(fill: aqua)[7], [], [Hz], [Motor rotation],
    [Angular resolution], [0.6], table.cell(fill: aqua)[], [], [#sym.degree], [At 7 Hz],
    [Range], [0.05], table.cell(fill: aqua)[], [10], [m], [Indoor, 80% reflectivity],
    [Minimum filtering threshold], [], table.cell(fill: aqua)[20], [], [mm], [`MIN_DIST_MM`],
  ),
  caption: [LiDAR Operating Parameters],
) <tab:lidar_params>

== IR Proximity Sensing

The RoboMaster EP chassis provides a built-in infrared proximity sensor. Range data $d_"IR"(t)$ is polled at 10 Hz via the SDK subscription callback and used as a continuous scalar input (unit: millimetres) for longitudinal PID control and ingestion stage triggering.

#figure(
  table(
    columns: (auto, 1fr, 1fr, 1fr, 1fr),
    align: center + horizon,
    table.header([Parameter], [Min.], [Typical], [Max.], [Units]),
    [Polling frequency], [], table.cell(fill: aqua)[10], [], [Hz],
    [Valid range (operational)], [10], table.cell(fill: aqua)[], [8848], [mm],
    [Pre-ingestion threshold], [], table.cell(fill: aqua)[200], [], [mm],
    [Blind-zone range], [], table.cell(fill: aqua)[$< 450$], [], [mm],
    [Ingestion-confirmation threshold], [], table.cell(fill: aqua)[$> 250$], [], [mm],
    [Sentinel (uninitialised)], [], table.cell(fill: aqua)[8848], [], [mm],
  ),
  caption: [IR Distance Sensor Parameters],
) <tab:ir_params>

The sentinel value 8848 mm (height of Mount Everest in metres) is used to represent an infinitely far reading when the sensor has not yet been initialised, causing the controller to default to a pure vision-guided mode.

= Mecanum Wheel Kinematics
<theory_kinematics>

== 3-DOF Full Holonomic Inverse Kinematics (Nav2 Mode)

For autonomous navigation with Nav2, the Twist velocity command $bold(v) = (v_x, v_y, omega_z)$ is decomposed into per-wheel speeds using the standard Mecanum inverse kinematics:

$
  mat(omega_1; omega_2; omega_3; omega_4)
  = gamma dot
  mat(
    1, 1, 1;
    1, -1, -1;
    1, -1, -1;
    1, 1, 1;
  )
  mat(v_x; v_y; omega_z)
$

where $gamma = 100$ is an empirical RPM scaling factor. Explicitly:

$
  omega_"right" & = v_x + v_y + omega_z \
   omega_"left" & = v_x - v_y - omega_z
$

with the final wheel assignments:

$
  "w1 (right-front)" & = omega_"right" times 100 \
   "w2 (left-front)" & = omega_"left" times 100 \
    "w3 (left-rear)" & = omega_"left" times 100 \
   "w4 (right-rear)" & = omega_"right" times 100
$

== 2-DOF Simplified Inverse Kinematics (Reactive Mode)

For visual servoing, the control is reduced to two scalar commands --- forward speed $v_f$ and turn speed $v_t$:

$
   omega_"left" & = v_f + v_t \
  omega_"right" & = v_f - v_t
$ <eq:mec_2dof>

This formulation sacrifices lateral strafing capability but allows the dual-PID controller to directly govern approach-while-aligning behaviour with two degrees of freedom.

== Primitive Motion Analysis

#figure(
  table(
    columns: (1fr, 1fr, 1fr),
    align: center + horizon,
    table.header([Motion], [$omega_"left"$], [$omega_"right"$]),
    [Pure forward ($v_t = 0$)], [$v_f$], [$v_f$],
    [Pure rotation ($v_f = 0$)], [$+v_t$], [$-v_t$],
  ),
  caption: [Wheel-Speed Decomposition for Fundamental Motions (2-DOF Model)],
) <tab:mec_primitives>

*Wheel Numbering Convention.*
The DJI SDK `drive_wheels(w1, w2, w3, w4)` interface adopts the following mapping:

#figure(
  table(
    stroke: none,
    columns: (1fr, 1fr, 1fr, 1fr),
    align: center + horizon,
    table.header([w1], [w2], [w3], [w4]),
    [Right-Front], [Left-Front], [Left-Rear], [Right-Rear],
  ),
  caption: [DJI SDK Wheel Convention],
) <tab:wheel_convention>

= PID Control Theory
<theory_pid>

The reactive chassis controller employs two independent PID regulators in the standard parallel form:

$
  u(t) = K_p e(t) + K_i integral_0^t e(tau) dif tau + K_d (dif e(t)) / (dif t)
$ <eq:pid_parallel>

where $e(t)$ is the control error at time $t$, and $(K_p, K_i, K_d)$ are the proportional, integral, and derivative gains respectively.

== Lateral Alignment PID (`pid_turn`)

This controller drives the target's image-plane centroid offset $e_x$ (@eq:visual_error) to zero, aligning the robot with the ball.

#figure(
  table(
    columns: (auto, 1fr, 1fr, 1fr, auto, auto),
    align: center + horizon,
    table.header([Parameter], [Min.], [Typical], [Max.], [Units], [Remarks]),
    [$K_p$], [], table.cell(fill: aqua)[0.15], [], [RPM/px], [Proportional gain],
    [$K_i$], [], table.cell(fill: aqua)[0.03], [], [RPM/(px dot s)], [Integral gain],
    [$K_d$], [], table.cell(fill: aqua)[0.03], [], [RPM dot s/px], [Derivative gain],
    [Setpoint], [], table.cell(fill: aqua)[0], [], [px], [Centred on optical axis],
    [Output lower], [-50], table.cell(fill: aqua)[], [], [RPM], [Max left-turn speed],
    [Output upper], [], table.cell(fill: aqua)[], [+50], [RPM], [Max right-turn speed],
  ),
  caption: [Lateral PID Parameters],
) <tab:pid_turn>

The output is negated before application: a target on the right ($e_x > 0$) produces a negative turn command, i.e., clockwise rotation.

== Longitudinal Approach PID (`pid_forward`)

This controller regulates the IR-measured distance $d(t)$ toward a 10 mm setpoint (physical contact with the ball).

#figure(
  table(
    columns: (auto, 1fr, 1fr, 1fr, auto, auto),
    align: center + horizon,
    table.header([Parameter], [Min.], [Typical], [Max.], [Units], [Remarks]),
    [$K_p$], [], table.cell(fill: aqua)[0.5], [], [RPM/mm], [Proportional gain],
    [$K_i$], [], table.cell(fill: aqua)[0.1], [], [RPM/(mm dot s)], [Integral gain],
    [$K_d$], [], table.cell(fill: aqua)[0.05], [], [RPM dot s/mm], [Derivative gain],
    [Setpoint], [], table.cell(fill: aqua)[10], [], [mm], [Ball contact distance],
    [Output lower], [-40], table.cell(fill: aqua)[], [], [RPM], [Max reverse speed],
    [Output upper], [], table.cell(fill: aqua)[], [+40], [RPM], [Max forward speed],
  ),
  caption: [Longitudinal PID Parameters],
) <tab:pid_forward>

== Dual-PID Visual Servoing Architecture

The two controllers operate in a priority-ordered cascade:

+ *Cruise tracking* ($d > 800$ mm): Both PID loops active. If $|e_x| > 40$ px, forward speed is clamped to 5 RPM to prioritise lateral alignment over advance.
+ *PID approach* ($d <= 800$ mm): The `pid_forward` output overrides the open-loop cruise speed.
+ *Blind-zone relay*: When visual tracking is lost ($e_x$ unavailable) but both $d < 450$ mm and last-valid distance $d_"last" < 300$ mm, the chassis maintains a straight 30 RPM advance with zero turn command. This bridges the camera forward-mount dead zone.
+ *Ingestion trigger* ($d <= 200$ mm): Motors pre-spin, chassis advances at fixed 30 RPM. The system transitions to the ingestion confirmation window.

The blind-zone relay condition is formalised as:

$ not "target_valid" and (d < 450) and (d_"last" < 300) $ <eq:blind_zone>

*Ingestion Confirmation.*
Ingestion is confirmed via a sliding-window majority vote on the distance sensor:

$
  "is_swallowed" = (sum_(k=1)^10 bold(1)[d(t + k dot 20 "ms") > 250]) >= 10
$ <eq:swallow_check>

i.e., 10 consecutive readings exceeding 250 mm within a 200 ms window, protected by a 3-second hard timeout.

= Navigation & Planning Theory
<theory_nav>

== SLAM (`slam_toolbox`)

The system employs `slam_toolbox` in Online Asynchronous mode for Simultaneous Localisation and Mapping. The algorithm is built on a sparse pose-graph:

- *Nodes* represent robot poses $(x_i, y_i, theta_i)$ at key scan timestamps.
- *Edges* encode spatial constraints: odometry edges (from wheel odometry) and scan-matching edges (from LiDAR scan alignment).
- *Scan matching* uses Karto-style correlative scan matchers (multi-resolution search over $(x, y, theta)$) to align incoming LiDAR scans against the accumulated occupancy grid.
- *Global optimisation*: The pose-graph is periodically optimised via non-linear least squares, minimising:
  $
    bold(X)^* = arg min_bold(X) sum_(i,j) bold(e)_(i j)^T bold(Omega)_(i j) bold(e)_(i j)
  $
  where $bold(e)_(i j)$ is the constraint error between nodes $i$ and $j$ and $bold(Omega)_(i j)$ is the information matrix.
- *Loop closure*: Upon revisiting a previously mapped region, additional scan-matching constraints are added and the full graph is re-optimised.

The resulting map is a 2D occupancy grid, where each cell stores the log-odds $l_(x,y)$ of being occupied:

$ p("occupied" | z_(1:t)) = 1 - 1 / (1 + exp(l_(x,y))) $

== AMCL Localisation

Adaptive Monte Carlo Localisation (AMCL) estimates the robot pose $bold(x)_t = (x, y, theta)_t$ through a particle filter:

+ *Prediction*: Each particle is propagated by sampling from the motion model $p(bold(x)_t | bold(x)_(t-1), bold(u)_(t-1))$ using wheel odometry.
+ *Update*: Each particle's weight is updated by the measurement model $p(bold(z)_t | bold(x)_t, m)$ using LiDAR scan likelihood against the pre-built map $m$.
+ *Resampling*: Particles are resampled proportionally to weights (KLD-sampling for adaptive particle count).

== Smac Hybrid-A\* Global Planner

Nav2 employs the Smac Hybrid-A\* planner, which extends classical A\* search to a continuous state space. The hybrid state $bold(s) = (x, y, theta)$ is evaluated with:

$ f(bold(s)) = g(bold(s)) + h(bold(s)) $

where $g(bold(s))$ is the accumulated cost-to-come (including penalties for proximity to obstacles and non-smooth transitions) and $h(bold(s))$ is an admissible heuristic (typically a 2D Euclidean distance with obstacle-awareness). The continuous-state feasibility check ensures that generated states satisfy the robot's kinematic constraints (minimum turning radius).

== Regulated Pure Pursuit Local Controller

The Regulated Pure Pursuit (RPP) controller computes angular velocity $omega$ from a look-ahead point $(x_l, y_l)$ on the global path:

$ omega = (2 v sin(alpha)) / L_d $

where $v$ is the current linear velocity, $alpha$ is the angle between the robot's heading and the look-ahead point, and $L_d$ is the adaptive look-ahead distance. The regulation heuristics include velocity scaling near the goal, collision checking on the look-ahead arc, and curvature-based deceleration.

== Boustrophedon Coverage Path

The workspace coverage strategy generates an S-shaped (boustrophedon) path through all traversable grid cells. Given a calibrated workspace $cal(W)$ discretised into cells of dimension $Delta x times Delta y$ (matching the intake mechanism width), the path comprises alternating horizontal sweeps:

$ cal(P)_"coverage" = {bold(w)_k in cal(W)_"traversable" | k = 1,dots,n} $

Grid cells are classified into one of four states:

#figure(
  table(
    columns: (1fr, 1fr, auto),
    align: center + horizon,
    table.header([State], [Symbol], [Semantics]),
    [Occupied], [$square.filled$], [Static obstacle (unreachable)],
    [Traversable], [$square.stroked$], [Free space, not yet visited],
    [Cleared], [$checkmark$], [Cell has been swept, no ball remaining],
    [Target], [$bullet$], [Ball detected via YOLO in this cell],
  ),
  caption: [Grid Cell State Classification],
) <tab:grid_states>

= Finite State Machine
<theory_fsm>

The behavioural logic of the CourtSweeper is formally defined as a Mealy-type Finite State Machine (FSM).

*Formal Definition.*
$ cal(M) = (Q, Sigma, delta, q_0, F) $

where:
- $Q = {q_0, q_1, q_2, q_3}$ is the finite set of states.
- $Sigma$ is the input alphabet of events (perception events, sensor thresholds, timer expirations, and UI commands).
- $delta: Q times Sigma -> Q$ is the transition function.
- $q_0 = "IDLE"$ is the initial state.
- $F = emptyset$ (no terminal states; the FSM runs indefinitely).

== State Definitions

#figure(
  table(
    columns: (2fr, 3fr, 3fr, 10fr),
    align: center + horizon,
    table.header([ID], [State], [Symbol], [Semantics]),
    [0],
    [IDLE],
    [$q_0$],
    [Awaiting command. Manual teleoperation overrides autonomy. Court calibration performed here.],

    [1],
    [SEARCHING],
    [$q_1$],
    [No ball detected. Chassis follows the pre-computed boustrophedon coverage path, marking traversed cells as cleared.],

    [2],
    [TRACKING],
    [$q_2$],
    [Ball detected. Coverage path paused. Dual-PID controller aligns chassis with target and navigates toward projected map coordinates.],

    [3],
    [INGESTING],
    [$q_3$],
    [Ball within 200 mm. Roller motors pre-spin; chassis advances; sliding-window detector confirms ingestion.],
  ),
  caption: [FSM State Set],
) <tab:fsm_states>

== Event Alphabet

The FSM responds to the following events:

#figure(
  table(
    columns: (auto, 1fr, auto),
    align: center + horizon,
    table.header([Event], [Symbol], [Trigger Condition]),
    [Ball detected], [$e_"detect"$], [`target_locked = True` (YOLO confidence $>= 0.25$)],
    [Ball lost], [$e_"lost"$], [`no_ball_counter >= 15` (consecutive frames)],
    [Approach threshold], [$e_"approach"$], [$d_"IR" <= 200$ mm],
    [Ball ingested], [$e_"ingested"$], [`is_swallowed = True` (@eq:swallow_check)],
    [Ingestion timeout], [$e_"timeout"$], [Elapsed 3 s without ingestion confirmation],
    [Coverage complete], [$e_"done"$], [All traversable cells marked cleared],
    [Auto mode], [$e_"auto"$], [UI AUTO switch toggled],
    [Manual override], [$e_"manual"$], [UI MANUAL switch toggled or teleop input received],
    [E-STOP], [$e_"estop"$], [UI E-STOP button pressed],
  ),
  caption: [FSM Input Events ($Sigma$)],
) <tab:fsm_events>

== Transition Function

#figure(
  table(
    stroke: none,
    columns: (1fr, 1fr, 1fr),
    align: center + horizon,
    table.header([From], [Event], [To]),
    table.hline(stroke: 1pt),
    [IDLE], [$e_"auto"$], [SEARCHING],
    table.hline(stroke: 1pt),
    [IDLE], [$e_"detect"$], [TRACKING],
    table.hline(stroke: 1pt),
    [SEARCHING], [$e_"detect"$], [TRACKING],
    table.hline(stroke: 1pt),
    [SEARCHING], [$e_"done"$], [IDLE],
    table.hline(stroke: 1pt),
    [TRACKING], [$e_"lost"$], [SEARCHING],
    table.hline(stroke: 1pt),
    [TRACKING], [$e_"approach"$], [INGESTING],
    table.hline(stroke: 1pt),
    [INGESTING], [$e_"ingested"$], [SEARCHING],
    table.hline(stroke: 1pt),
    [INGESTING], [$e_"timeout"$], [SEARCHING],
    table.hline(stroke: 1pt),
    [Any], [$e_"manual"$], [IDLE],
    table.hline(stroke: 1pt),
    [Any], [$e_"estop"$], [IDLE],
    table.hline(stroke: 1pt),
  ),
  caption: [FSM Transition Table $delta: Q times Sigma -> Q$],
) <tab:fsm_transitions>

= Coordinate Transformations
<theory_transforms>

== Euler Angle to Quaternion

The robot operates on a planar surface; yaw $theta$ is the only non-zero Euler angle. The conversion to quaternion representation follows the axis-angle formula for a Z-axis rotation:

$ bold(q)(theta) = (q_x, q_y, q_z, q_w) = (0, 0, sin theta/2, cos theta/2) $ <eq:euler_to_quat>

== Yaw Normalisation

To prevent numerical drift due to $theta$ wrapping outside $[-pi, pi]$, the yaw is normalised using:

$ theta' = "atan2"(sin theta, cos theta) $ <eq:yaw_norm>

== TF Coordinate Tree

The ROS2 TF tree defines the rigid transformations in @tab:tf_tree.

#figure(
  table(
    stroke: none,
    columns: (auto, auto, 2fr, 2fr, 2fr, 2fr, 3fr),
    align: center + horizon,
    table.header([Parent Frame], [Child Frame], [$Delta x$], [$Delta y$], [$Delta z$], [$Delta theta$], [Remarks]),
    table.hline(stroke: 1pt),
    [`odom`], [`base_footprint`], [SLAM estimate], [SLAM estimate], [0], [SLAM estimate], [AMCL-provided],
    table.hline(stroke: 1pt),
    [`base_footprint`], [`base_link`], [0], [0], [0], [0], [Static (coincident origins)],
    table.hline(stroke: 1pt),
    [`base_link`], [`laser`], [0], [0], [0], [0], [Static (LiDAR mount)],
    table.hline(stroke: 1pt),
  ),
  caption: [TF Frame Hierarchy],
) <tab:tf_tree>

*Coordinate Sign Convention.*
- *Mapping mode* (`map_generation.py`): Yaw and $x$-coordinate are negated ($theta -> -theta$, $x -> -x$) to align the DJI odometry frame with the SLAM map convention.
- *Navigation mode* (`map_navigation.py`): Raw DJI coordinates are preserved; the saved map already conforms to the localisation frame.

= Communication Protocol Specifications
<theory_comms>

== ROS2 Inter-Process Communication

#figure(
  table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr),
    align: center + horizon,
    table.header([Topic], [Message Type], [Freq. (Hz)], [Direction], [Remarks]),
    [`/odom`], [`nav_msgs/Odometry`], [50], [Chassis $->$ ROS2], [DJI SDK telemetry],
    [`/scan`], [`sensor_msgs/LaserScan`], [$tilde.eq 10$], [LiDAR $->$ ROS2], [RPLidar driver],
    [`/cmd_vel`], [`geometry_msgs/Twist`], [On demand], [ROS2 $->$ Chassis], [Nav2 output],
    [`/camera/image/compressed`], [`sensor_msgs/CompressedImage`], [10], [Chassis $->$ ROS2], [JPEG, quality 60],
    [`/camera/camera_info`], [`sensor_msgs/CameraInfo`], [10], [Chassis $->$ ROS2], [Intrinsic calibration],
    [`/tf`], [`tf2_msgs/TFMessage`], [50], [Bridge $->$ ROS2], [Coordinate frames],
  ),
  caption: [ROS2 Topic Specification],
) <tab:ros_topics>

== UDP Control Protocol: iOS to Jetson

#figure(
  table(
    columns: (1fr, 2fr, 2fr),
    align: center + horizon,
    table.header([Command], [Payload Format], [Semantics]),
    [E-STOP], [`{"cmd": "estop"}`], [Immediate chassis brake, suspend all autonomous logic],
    [RECALL], [`{"cmd": "recall"}`], [Terminate mission, navigate to origin via Nav2],
    [AUTO], [`{"cmd": "auto"}`], [Switch FSM to autonomous mode],
    [MANUAL], [`{"cmd": "manual"}`], [Switch FSM to manual teleoperation],
    [JOYSTICK], [`{"vx": f, "vy": f, "vw": f}`], [Omnidirectional velocity command],
  ),
  caption: [UDP Command Packet Specification],
) <tab:udp_spec>

// *Transport Parameters.*

#figure(
  table(
    columns: (auto, 1fr, 1fr, 1fr),
    align: center + horizon,
    table.header([Parameter], [Min.], [Typical], [Units]),
    [Serialisation], [], table.cell(fill: aqua)[JSON], [],
    [Packet size (commands)], [30], table.cell(fill: aqua)[80], [bytes],
    [Target latency], [5], table.cell(fill: aqua)[15], [ms],
  ),
  caption: [UDP Transport Parameters],
) <tab:udp_params>

== Serial Motor Protocol: Jetson to Arduino

#figure(
  table(
    columns: (auto, 1fr, 1fr, 1fr, 1fr, auto),
    align: center + horizon,
    table.header([Parameter], [Min.], [Typical], [Max.], [Units], [Remarks]),
    [Baud rate], [], table.cell(fill: aqua)[115200], [], [bps], [8N1 (8 data, 1 stop, no parity)],
    [Packet format], [], table.cell(fill: aqua)[`"L,R\n"`], [], [], [CSV-style, newline-terminated],
    [Speed range], [-255], table.cell(fill: aqua)[], [+255], [], [8-bit signed PWM],
    [Encoding], [], table.cell(fill: aqua)[UTF-8], [], [], [],
  ),
  caption: [Serial Communication Parameters],
) <tab:serial_spec>

== Wi-Fi Connection Modes

#figure(
  table(
    columns: (1fr, 1fr, 2fr),
    align: center + horizon,
    table.header([Mode], [SDK Parameter], [Use Case]),
    [Access Point (AP)],
    [`conn_type="ap"`],
    [Direct iOS connection; Jetson broadcasts SSID for dataset collection and field teleop],

    [Station (STA)],
    [`conn_type="sta"`],
    [Robot/Jetson joins existing Wi-Fi network for SLAM mapping and Nav2 navigation],
  ),
  caption: [Wi-Fi Operation Modes],
) <tab:wifi_modes>

= Motor Drive Theory
<theory_motor>

== PWM Duty Cycle Control

The Arduino firmware generates Pulse Width Modulation signals with 8-bit resolution. The duty cycle is:

$
  D = (|"speed"|) / 255 times 100\%
$ <eq:pwm_duty>

where $"speed" in [-255, 255]$ is the signed command. The effective motor voltage is:

$ V_"motor" = D dot V_"supply" = D dot 11.1 "V" $ <eq:motor_voltage>

Pre-spin duty ($"speed" = 90$) corresponds to $D tilde.eq 35\%$, yielding approximately 3.9 V across the 775 motor terminals.

== BTS7960 H-Bridge Topology

Each BTS7960 driver module forms a full H-bridge using two half-bridge outputs. The three-wire interface operates as follows:

#figure(
  table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr),
    align: center + horizon,
    table.header([EN], [RPWM], [LPWM], [Motor State], [Condition]),
    [LOW], [0], [0], [Coast (free-running)], [$"speed" = 0$],
    [HIGH], [$|s|$], [0], [Forward rotation], [$"speed" > 0$],
    [HIGH], [0], [$|s|$], [Reverse rotation], [$"speed" < 0$],
  ),
  caption: [BTS7960 Logic Truth Table],
) <tab:bts7960_truth>

The enable pin (EN) controls the H-bridge output stage: pulling it LOW disconnects both half-bridges, providing a passive coast-stop that prevents back-EMF-induced braking torque.

*Pin Mapping.*

#figure(
  table(
    columns: (1fr, 1fr, 1fr, 1fr),
    align: center + horizon,
    table.header([Motor], [EN], [RPWM], [LPWM]),
    [Left], [D4], [D5], [D6],
    [Right], [D7], [D9], [D10],
  ),
  caption: [Arduino Pin Assignment for Dual BTS7960 Drivers],
) <tab:arduino_pins>

== Communication Watchdog

A hardware-level safety mechanism is implemented in firmware:

$
  "if" ("isMoving" and (t_"now" - t_"lastRecv" > 500 "ms")) => "stopMotor()"
$ <eq:watchdog>

If no serial command is received within 500 ms while motors are in motion, all PWM channels are zeroed and the enable pins are pulled LOW. This prevents runaway behaviour in the event of communication loss (e.g., serial cable disconnection, Jetson crash, or software deadlock).

*Command Parsing.*
The Arduino firmware uses `Serial.parseInt()` to extract signed integers from the CSV stream, validating each packet with a newline terminator check (`Serial.read() == '\n'`). Incomplete or malformed packets are silently discarded, and the last valid speed values are retained.
