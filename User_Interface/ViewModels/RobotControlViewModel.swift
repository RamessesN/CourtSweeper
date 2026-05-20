//
//  RobotControlViewModel.swift
//  CourtSweeper
//
//  Created by 赵禹惟 on 2026/5/21.
//

import SwiftUI
import Combine

@Observable
class RobotControlViewModel {
    // MARK: - 1. 核心可调配置参数（在此修改可直接改变App行为）
    let rows: Int = 5       // 网格行数 m
    let columns: Int = 6    // 网格列数 n
    
    // 针对不同屏幕尺寸的物理高度比例系数
    let iphoneVideoRatio: CGFloat = 0.35 // iPhone上视频占屏幕总高 35%
    let ipadVideoRatio: CGFloat = 0.40   // iPad上视频占屏幕总高 40%
    
    // MARK: - 2. 状态发布源（驱动UI自动刷新）
    var currentVideoIndex: Int = 0
    var gridCells: [RobotCell] = []
    
    // MARK: - 3. 初始化机制
    init() {
        initializeGrid()
    }
    
    private func initializeGrid() {
        var cells: [RobotCell] = []
        var count = 0
        for r in 0..<rows {
            for c in 0..<columns {
                cells.append(RobotCell(id: count, row: r, column: c, isCleaned: false))
                count += 1
            }
        }
        self.gridCells = cells
    }
    
    // MARK: - 4. 用户操作接口（点击事件对应的逻辑响应）
    func triggerOneClickRecall() {
        // 一键召回逻辑：后续在这里编写给小车发送召回指令的代码
        // 临时联调：随机改变一个网格状态
        if let randomIndex = gridCells.indices.randomElement() {
            gridCells[randomIndex].isCleaned.toggle()
        }
    }
    
    func triggerEmergencyStop() {
        // 紧急停止逻辑：后续在这里编写发送最高优先级停止包的代码
        // 临时联调：重置所有网格为未清理状态
        for index in gridCells.indices {
            gridCells[index].isCleaned = false
        }
    }
    
    func triggerContinueExecution() {
        // 继续执行逻辑：后续在这里编写恢复任务队列的代码
    }
}
