//
//  RobotControlView.swift
//  CourtSweeper
//
//  Created by 赵禹惟 on 2026/5/21.
//

import SwiftUI

struct RobotControlView: View {
    // 引入解耦后的 ViewModel 状态管家
    @State private var viewModel = RobotControlViewModel()
    
    var body: some View {
        GeometryReader { outerGeometry in
            let totalHeight = outerGeometry.size.height
            let isPad = UIDevice.current.userInterfaceIdiom == .pad
            let videoRatio = isPad ? viewModel.ipadVideoRatio : viewModel.iphoneVideoRatio
            
            VStack(spacing: 0) {
                
                // MARK: - 上方：视频流轮播区
                VStack {
                    TabView(selection: $viewModel.currentVideoIndex) {
                        ZStack {
                            Color.black
                            Text("主相机视频流")
                                .foregroundStyle(.white)
                                .font(.headline)
                        }
                        .tag(0)
                        
                        ZStack {
                            Color.black
                            Text("全景/雷达画面")
                                .foregroundStyle(.white)
                                .font(.headline)
                        }
                        .tag(1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .frame(height: totalHeight * videoRatio)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 6)
                
                // MARK: - 中间：网格阵列框
                VStack {
                    GeometryReader { gridGeometry in
                        let availableWidth = gridGeometry.size.width - CGFloat(viewModel.columns - 1) * 6
                        let itemWidth = availableWidth / CGFloat(viewModel.columns)
                        let gridItems = Array(repeating: GridItem(.fixed(itemWidth), spacing: 6), count: viewModel.columns)
                        
                        VStack {
                            Spacer(minLength: 0)
                            
                            ScrollView(.vertical, showsIndicators: false) {
                                LazyVGrid(columns: gridItems, spacing: 6) {
                                    ForEach(viewModel.gridCells) { cell in
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(cell.isCleaned ? Color.green : Color.red.opacity(0.8))
                                                .animation(.easeInOut(duration: 0.3), value: cell.isCleaned)
                                            
                                            Text("\(cell.row),\(cell.column)")
                                                .font(.system(size: isPad ? 14 : 9, weight: .medium))
                                                .foregroundColor(.white)
                                        }
                                        .frame(width: itemWidth, height: itemWidth)
                                    }
                                }
                            }
                            
                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGroupedBackground)))
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .frame(maxHeight: .infinity)
                
                Spacer(minLength: isPad ? 20 : 8)
                
                // MARK: - 下方：操作按钮区
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack(spacing: 12) {
                        Button(action: { viewModel.triggerOneClickRecall() }) {
                            Text("一键召回")
                                .font(.system(size: isPad ? 18 : 15, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .frame(height: isPad ? 65 : 50)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        Button(action: { viewModel.triggerEmergencyStop() }) {
                            Text("紧急停止")
                                .font(.system(size: isPad ? 18 : 15, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .frame(height: isPad ? 65 : 50)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        Button(action: { viewModel.triggerContinueExecution() }) {
                            Text("继续执行")
                                .font(.system(size: isPad ? 18 : 15, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .frame(height: isPad ? 65 : 50)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, isPad ? 32 : 20)
                    .padding(.bottom, isPad ? 24 : 12)
                }
                .background(Color(.systemBackground))
            }
        }
        .safeAreaPadding(.bottom)
    }
}

#Preview {
    RobotControlView()
}
