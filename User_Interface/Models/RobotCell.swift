//
//  RobotCell.swift
//  CourtSweeper
//
//  Created by 赵禹惟 on 2026/5/21.
//

import Foundation

struct RobotCell: Identifiable, Equatable {
    let id: Int
    let row: Int
    let column: Int
    var isCleaned: Bool = false // 默认未清理（红色），清理完为绿色
}
