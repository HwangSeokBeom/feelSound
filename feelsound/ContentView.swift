//
//  ContentView.swift
//  feelsound
//
//  Created by 심소영 on 5/8/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var router: Router
    @State var selection: Tab = .home
    @State private var characterViewID = UUID() // 캐릭터 뷰 식별 ID

    var body: some View {
        NavigationStack(path: $router.navPath) {
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {

                    // TabView에는 .challenge 제외
                    if selection != .challenge {
                        TabView(selection: $selection) {
                            LiquidFlowView().tag(Tab.home)
                            NatureSoundEffectView().tag(Tab.recipe)
                            VStack { Text("sample3") }.tag(Tab.search)
                            VStack { Text("sample4") }.tag(Tab.shop)
                            Color.clear.tag(Tab.challenge)
                        }
                        .accentColor(.primary)
                        .navigationBarHidden(true)
                    }

                    // challenge 선택 시 CharacterView 렌더링
                    if selection == .challenge {
                        CharacterView()
                            .id(characterViewID) // 강제 리렌더링
                            .transition(.opacity)
                    }

                    // 하단 탭바
                    CustomTabBar(selectedTab: $selection)
                        .frame(height: 100)
                        .ignoresSafeArea(edges: .bottom)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut, value: selection)
                .onChange(of: selection) { newTab in
                    if newTab != .challenge {
                        characterViewID = UUID() // 캐릭터 뷰 완전 제거 유도
                    }
                }
            }
            .edgesIgnoringSafeArea(.bottom)
            .navigationDestination(for: Router.Destination.self) { destination in
                switch destination {
                case .sampleView1:
                    TiltDropletView().toolbar(.hidden)
                case .sampleView2:
                    RainFallView().toolbar(.hidden)
                case .sampleView3:
                    FortuneCookieView().toolbar(.hidden)
                case .sampleView5:
                    CharacterView()
                }
            }
        }
    }
}


struct CustomTabBar: View {
    @AppStorage("isPremium") var isPremium : Bool = false

    @Binding var selectedTab: Tab
    
    var body: some View {
        VStack(spacing: 0){
            Rectangle()
                .fill(Color(hex : "38374A"))
                .frame(height: 1.2)
            HStack {
                ForEach(Tab.allCases, id: \.rawValue) { tab in
                    Spacer()
                    Image(systemName: tab.imageName)
                        .scaleEffect(tab == selectedTab ? 1.25 : 1.0)
                        .foregroundStyle(tab == selectedTab ? Color.white : Color(hex : "7A7A7A"))
                        .font(.system(size: 20))
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                selectedTab = tab
                            }
                        }
                        .padding()
                    Spacer()
                }
            }
        }
        .background(Color(hex : "0B0A12"))
    }
}


enum Tab: Int, Identifiable, CaseIterable {
    case home
    case recipe
    case search
    case shop
    case challenge

    var id: Int {
        return rawValue
    }

    var name: String {
        switch self {
        case .home:
            return "home"
        case .recipe:
            return "recipe"
        case .search:
            return "search"
        case .shop:
            return "shop"
        case .challenge:
            return "challenge"
        }
    }

    var imageName: String {
        switch self {
        case .home:
            return "house"
        case .recipe:
            return "book.pages"
        case .search :
            return "magnifyingglass"
        case .shop:
            return "cart"
        case .challenge:
            return "heart.text.square"
        }
    }

    var tabItem: some View {
        Group {
            Text(name)
            Image(systemName: imageName)
        }
    }
}
