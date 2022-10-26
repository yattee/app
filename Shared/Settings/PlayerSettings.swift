import Defaults
import SwiftUI

struct PlayerSettings: View {
    @Default(.instances) private var instances
    @Default(.playerInstanceID) private var playerInstanceID

    @Default(.playerSidebar) private var playerSidebar
    @Default(.showHistoryInPlayer) private var showHistory
    @Default(.playerControlsLayout) private var playerControlsLayout
    @Default(.fullScreenPlayerControlsLayout) private var fullScreenPlayerControlsLayout
    @Default(.horizontalPlayerGestureEnabled) private var horizontalPlayerGestureEnabled
    @Default(.seekGestureSpeed) private var seekGestureSpeed
    @Default(.seekGestureSensitivity) private var seekGestureSensitivity
    @Default(.showKeywords) private var showKeywords
    @Default(.pauseOnHidingPlayer) private var pauseOnHidingPlayer
    @Default(.closeLastItemOnPlaybackEnd) private var closeLastItemOnPlaybackEnd
    #if os(iOS)
        @Default(.enterFullscreenInLandscape) private var enterFullscreenInLandscape
        @Default(.rotateToPortraitOnExitFullScreen) private var rotateToPortraitOnExitFullScreen
    #endif
    @Default(.closePiPOnNavigation) private var closePiPOnNavigation
    @Default(.closePiPOnOpeningPlayer) private var closePiPOnOpeningPlayer
    @Default(.closePlayerOnOpeningPiP) private var closePlayerOnOpeningPiP
    #if !os(macOS)
        @Default(.closePlayerOnItemClose) private var closePlayerOnItemClose
        @Default(.pauseOnEnteringBackground) private var pauseOnEnteringBackground
        @Default(.closePiPAndOpenPlayerOnEnteringForeground) private var closePiPAndOpenPlayerOnEnteringForeground
    #endif

    @Default(.enableReturnYouTubeDislike) private var enableReturnYouTubeDislike
    @Default(.systemControlsCommands) private var systemControlsCommands

    @EnvironmentObject<AccountsModel> private var accounts
    @EnvironmentObject<PlayerModel> private var player

    #if os(iOS)
        private var idiom: UIUserInterfaceIdiom {
            UIDevice.current.userInterfaceIdiom
        }
    #endif

    var body: some View {
        Group {
            #if os(macOS)
                sections

                Spacer()
            #else
                List {
                    sections
                }
            #endif
        }
        #if os(tvOS)
        .frame(maxWidth: 1000)
        #elseif os(iOS)
        .listStyle(.insetGrouped)
        #endif
        .navigationTitle("Player")
    }

    private var sections: some View {
        Group {
            Section(header: SettingsHeader(text: "Playback".localized())) {
                sourcePicker
                pauseOnHidingPlayerToggle
                #if !os(macOS)
                    pauseOnEnteringBackgroundToogle
                    closePlayerOnItemCloseToggle
                #endif
                closeLastItemOnPlaybackEndToggle
                systemControlsCommandsPicker
            }

            #if !os(tvOS)
                Section(header: SettingsHeader(text: "Controls".localized()), footer: controlsLayoutFooter) {
                    horizontalPlayerGestureEnabledToggle
                    SettingsHeader(text: "Seek gesture sensitivity".localized(), secondary: true)
                    seekGestureSensitivityPicker
                    SettingsHeader(text: "Seek gesture speed".localized(), secondary: true)
                    seekGestureSpeedPicker
                    SettingsHeader(text: "Regular size".localized(), secondary: true)
                    playerControlsLayoutPicker
                    SettingsHeader(text: "Fullscreen size".localized(), secondary: true)
                    fullScreenPlayerControlsLayoutPicker
                }
            #endif

            Section(header: SettingsHeader(text: "Interface".localized())) {
                #if os(iOS)
                    if idiom == .pad {
                        sidebarPicker
                    }
                #endif

                #if os(macOS)
                    sidebarPicker
                #endif

                keywordsToggle
                showHistoryToggle

                if !accounts.isDemo {
                    returnYouTubeDislikeToggle
                }
            }

            #if os(iOS)
                Section(header: SettingsHeader(text: "Orientation".localized())) {
                    if idiom == .pad {
                        enterFullscreenInLandscapeToggle
                    }
                    rotateToPortraitOnExitFullScreenToggle
                }
            #endif

            Section(header: SettingsHeader(text: "Picture in Picture".localized())) {
                closePiPOnNavigationToggle
                closePiPOnOpeningPlayerToggle
                closePlayerOnOpeningPiPToggle
                #if !os(macOS)
                    closePiPAndOpenPlayerOnEnteringForegroundToggle
                #endif
            }
        }
    }

    private var sourcePicker: some View {
        Picker("Source", selection: $playerInstanceID) {
            Text("Instance of current account").tag(String?.none)

            ForEach(instances) { instance in
                Text(instance.description).tag(Optional(instance.id))
            }
        }
        .modifier(SettingsPickerModifier())
    }

    private var systemControlsCommandsPicker: some View {
        func labelText(_ label: String) -> String {
            #if os(macOS)
                String(format: "System controls show buttons for %@".localized(), label)
            #else
                label
            #endif
        }

        return Picker("System controls buttons", selection: $systemControlsCommands) {
            Text(labelText("10 seconds forwards/backwards".localized())).tag(SystemControlsCommands.seek)
            Text(labelText("Restart/Play next".localized())).tag(SystemControlsCommands.restartAndAdvanceToNext)
        }
        .onChange(of: systemControlsCommands) { _ in
            player.updateRemoteCommandCenter()
        }
        .modifier(SettingsPickerModifier())
    }

    private var sidebarPicker: some View {
        Picker("Sidebar", selection: $playerSidebar) {
            #if os(macOS)
                Text("Show sidebar").tag(PlayerSidebarSetting.always)
            #endif

            #if os(iOS)
                Text("Show sidebar when space permits").tag(PlayerSidebarSetting.whenFits)
            #endif

            Text("Hide sidebar").tag(PlayerSidebarSetting.never)
        }
        .modifier(SettingsPickerModifier())
    }

    private var horizontalPlayerGestureEnabledToggle: some View {
        Toggle("Seek with horizontal swipe on video", isOn: $horizontalPlayerGestureEnabled)
    }

    private var seekGestureSpeedPicker: some View {
        Picker("Seek gesture speed", selection: $seekGestureSpeed) {
            ForEach([1, 0.75, 0.66, 0.5, 0.33, 0.25, 0.1], id: \.self) { value in
                Text(String(format: "%.0f%%", value * 100)).tag(value)
            }
        }
        .disabled(!horizontalPlayerGestureEnabled)
        .modifier(SettingsPickerModifier())
    }

    private var seekGestureSensitivityPicker: some View {
        Picker("Seek gesture sensitivity", selection: $seekGestureSensitivity) {
            Text("Highest").tag(1.0)
            Text("High").tag(10.0)
            Text("Normal").tag(30.0)
            Text("Low").tag(50.0)
            Text("Lowest").tag(100.0)
        }
        .disabled(!horizontalPlayerGestureEnabled)
        .modifier(SettingsPickerModifier())
    }

    @ViewBuilder private var controlsLayoutFooter: some View {
        #if os(iOS)
            Text("Large layout is not suitable for all devices and using it may cause controls not to fit on the screen.")
        #endif
    }

    private var playerControlsLayoutPicker: some View {
        Picker("Regular Size", selection: $playerControlsLayout) {
            ForEach(PlayerControlsLayout.allCases.filter(\.available), id: \.self) { layout in
                Text(layout.description).tag(layout.rawValue)
            }
        }
        .modifier(SettingsPickerModifier())
    }

    private var fullScreenPlayerControlsLayoutPicker: some View {
        Picker("Fullscreen size", selection: $fullScreenPlayerControlsLayout) {
            ForEach(PlayerControlsLayout.allCases.filter(\.available), id: \.self) { layout in
                Text(layout.description).tag(layout.rawValue)
            }
        }
        .modifier(SettingsPickerModifier())
    }

    private var keywordsToggle: some View {
        Toggle("Show keywords", isOn: $showKeywords)
    }

    private var showHistoryToggle: some View {
        Toggle("Show history", isOn: $showHistory)
    }

    private var returnYouTubeDislikeToggle: some View {
        Toggle("Enable Return YouTube Dislike", isOn: $enableReturnYouTubeDislike)
    }

    private var pauseOnHidingPlayerToggle: some View {
        Toggle("Pause when player is closed", isOn: $pauseOnHidingPlayer)
    }

    #if !os(macOS)
        private var pauseOnEnteringBackgroundToogle: some View {
            Toggle("Pause when entering background", isOn: $pauseOnEnteringBackground)
        }

        private var closePlayerOnItemCloseToggle: some View {
            Toggle("Close player when closing video", isOn: $closePlayerOnItemClose)
        }
    #endif

    private var closeLastItemOnPlaybackEndToggle: some View {
        Toggle("Close video after playing last in the queue", isOn: $closeLastItemOnPlaybackEnd)
    }

    #if os(iOS)
        private var enterFullscreenInLandscapeToggle: some View {
            Toggle("Enter fullscreen in landscape", isOn: $enterFullscreenInLandscape)
        }

        private var rotateToPortraitOnExitFullScreenToggle: some View {
            Toggle("Rotate to portrait when exiting fullscreen", isOn: $rotateToPortraitOnExitFullScreen)
        }
    #endif

    private var closePiPOnNavigationToggle: some View {
        Toggle("Close PiP when starting playing other video", isOn: $closePiPOnNavigation)
    }

    private var closePiPOnOpeningPlayerToggle: some View {
        Toggle("Close PiP when player is opened", isOn: $closePiPOnOpeningPlayer)
    }

    private var closePlayerOnOpeningPiPToggle: some View {
        Toggle("Close player when starting PiP", isOn: $closePlayerOnOpeningPiP)
    }

    #if !os(macOS)
        private var closePiPAndOpenPlayerOnEnteringForegroundToggle: some View {
            Toggle("Close PiP and open player when application enters foreground", isOn: $closePiPAndOpenPlayerOnEnteringForeground)
        }
    #endif
}

struct PlayerSettings_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading) {
            PlayerSettings()
        }
        .injectFixtureEnvironmentObjects()
    }
}
