//
//  DrawingListView.swift
//  feelsound
//
//  Created by 안준경 on 5/22/25.
//

import SwiftUI

struct DrawingListView: View {
    @Environment(\.dismiss) private var dismiss
    
    // 이미지 배열
    let drawingList: [String] = ["panda", "paint"]
    
    // 3열 그리드 설정
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            VStack{
                HStack {
                    Button(action: {
                        dismiss()
                    }, label: {
                        Image(systemName: "arrow.left")
                            .resizable()
                            .frame(width:28, height:22)
                            .foregroundColor(.white)
                    })
                    
                    Spacer()
                }
                .padding(.leading, 20)
                
                HStack {
                    Text("Drawing List")
                        .font(.system(size: 28))
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                
                HStack{
                    Button(action: {
                        
                    }, label: {
                        Text("ALL >")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    })
                    .frame(width:80, height:34)
                    .background(.purple)
                    .cornerRadius(20)
                    
                    Button(action: {
                        
                    }, label: {
                        Text("Recent")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    })
                    .frame(width:80, height:34)
                    .background(.gray)
                    .cornerRadius(20)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 20)
                
                // LazyVGrid를 사용한 그리드 레이아웃
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(drawingList.indices, id: \.self) { index in
                            NavigationLink(destination: ColoringView(imageName: drawingList[index])) {
                                VStack {
                                    // 이미지를 동그라미 모양으로 표시
                                    Image(drawingList[index])
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: 2)
                                        )
                                    
                                    // 선택적: 이미지 아래에 텍스트 추가
                                    Text("Drawing \(index + 1)")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.top, 4)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            
            Spacer()
        }
        .background(.black)
        .padding(.bottom, 0)
    }
}

struct DrawingListView_Previews: PreviewProvider {
    static var previews: some View {
        DrawingListView()
    }
}
