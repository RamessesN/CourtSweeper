<div align="center">
    <h2> 开发日志 </h2>
</div>

### 雷达使用日志
1. 追溯到 [YLidar-SDK 官方库](https://github.com/YDLIDAR/YDLidar-SDK)，尝试用 C语言 编译但报错；
2. 修改底层库，实现对 darwin 生态的 apple silicon mac 的编译兼容 (已提交 [PR](https://github.com/YDLIDAR/YDLidar-SDK/pull/73))。实际测试 `make` 编译后发现 `tof_test` 和 `tri_test` 不兼容该 X2pro 激光雷达 (固件检测是 X3)，故转向 python；
3. 经查询 [技术手册](https://www.ydlidar.com/doc-tool-download) 得知该激光雷达串口传输的协议（包括编码规则等），通过直接处理编码从源头解决问题。

---

### 电机使用日志
1. 尝试通过两台 BTS7960 驱动两架 755 电机。强电部分通过一个单独的 LiPo 3S 电池 (12V电压) 单独供电。弱电部分尝试通过 jetson orin nx 外置的 40pin 直接控制，经测试发现该 jetson 板为加载官方 nvidia 原厂镜像 (Reference Developer Kit) 的第三方载板，故设备树 device-tree 导致的硬件引脚映射不同，间接导致 `Jetson.GPIO` 库寻址失败 (`Err: Bad file descriptor`)；
3. 经查询第三方载板 [技术手册](http://www.plink-ai.com/Uploads/download/Y-C18_Carrier_Board_Datasheet_CN_v3.pdf) 得知对应引脚映射关系，再次尝试通过 jetson 基于底层 GPIO 框架 `libgpiod` 驱动电机无效；
4. 经 LED 测试和万用表电压检查发现因为该载板的 "开漏输出" 保护机制导致不能直接外接电机驱动（需要下拉电阻）；
5. 考虑到简化机器人规模，尝试通过 DJI Robomaster 底盘上的 PWM 引脚驱动电机，测试发现底盘上默认输出的是 1.5ms 的伺服中心脉冲（用于驱动舵机 PWM），不是驱动 BTS7960 的逻辑 PWM；
6. 尝试采用 “上位机(jetson) + 下位机(arduino uno)” 策略打组合拳，解决问题。