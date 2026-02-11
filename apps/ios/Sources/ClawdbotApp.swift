import SwiftUI

@main
struct ClawdbotApp: App {
    @State private var appModel: NodeAppModel
    @State private var gatewayController: GatewayConnectionController
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: Int = 3  // Default to Trading tab

    init() {
        // Initialize crash reporting FIRST
        CrashReporter.initialize()

        GatewaySettingsStore.bootstrapPersistence()
        let appModel = NodeAppModel()
        _appModel = State(initialValue: appModel)
        _gatewayController = State(initialValue: GatewayConnectionController(appModel: appModel))
    }

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                TodayTab()
                    .tabItem {
                        Label("Today", systemImage: "star.fill")
                    }
                    .tag(0)

                PersonalTab()
                    .tabItem {
                        Label("Personal", systemImage: "person.fill")
                    }
                    .tag(1)

                WorkTab()
                    .tabItem {
                        Label("Work", systemImage: "briefcase.fill")
                    }
                    .tag(2)

                TradingTab()
                    .tabItem {
                        Label("Trading", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .tag(3)

                HOATab()
                    .tabItem {
                        Label("HOA", systemImage: "building.2.fill")
                    }
                    .tag(4)
            }
            .toolbarBackground(.white, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .tint(CB.blue)
            .environment(self.appModel)
            .environment(self.appModel.voiceWake)
            .environment(self.gatewayController)
            .onOpenURL { url in
                Task { await self.appModel.handleDeepLink(url: url) }
            }
            .onChange(of: self.scenePhase) { _, newValue in
                self.appModel.setScenePhase(newValue)
                self.gatewayController.setScenePhase(newValue)
            }
        }
    }
}
