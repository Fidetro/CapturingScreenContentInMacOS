/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that provides the UI to configure screen capture.
*/

import SwiftUI
import ScreenCaptureKit

/// The app's configuration user interface.
struct ConfigurationView: View {
    
    private let sectionSpacing: CGFloat = 20
    private let verticalLabelSpacing: CGFloat = 8
    
    private let alignmentOffset: CGFloat = 10
    
    @StateObject private var audioPlayer = AudioPlayer()
    @ObservedObject var screenRecorder: ScreenRecorder
    @Binding var userStopped: Bool
    @State var showPickerSettingsView = false
    
    var body: some View {
        VStack {
            Form {
                HeaderView("Video")
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 1, trailing: 0))
                
                // A group that hides view labels.
                Group {
                    VStack(alignment: .leading, spacing: verticalLabelSpacing) {
                        Text("Capture Type")
                        Picker("Capture", selection: $screenRecorder.captureType) {
                            Text("Display")
                                .tag(ScreenRecorder.CaptureType.display)
                            Text("Window")
                                .tag(ScreenRecorder.CaptureType.window)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: verticalLabelSpacing) {
                        Text("Screen Content")
                        switch screenRecorder.captureType {
                        case .display:
                            Picker("Display", selection: $screenRecorder.selectedDisplay) {
                                ForEach(screenRecorder.availableDisplays, id: \.self) { display in
                                    Text(display.displayName)
                                        .tag(SCDisplay?.some(display))
                                }
                            }
                            
                        case .window:
                            Picker("Window", selection: $screenRecorder.selectedWindow) {
                                ForEach(screenRecorder.availableWindows, id: \.self) { window in
                                    Text(window.displayName)
                                        .tag(SCWindow?.some(window))
                                }
                            }
                        }
                    }
                }
                .labelsHidden()
                
                Toggle("Exclude sample app from stream", isOn: $screenRecorder.isAppExcluded)
                    .disabled(screenRecorder.captureType == .window)
                    .onChange(of: screenRecorder.isAppExcluded) {
                        // Capturing app audio is only possible when the sample is included in the stream.
                        // Ensure the audio stops playing if the user enables the "Exclude app from stream" checkbox.
                        if screenRecorder.isAppExcluded {
                            audioPlayer.stop()
                        }
                    }
                
                // Add some space between the Video and Audio sections.
                Spacer()
                    .frame(height: 20)
                
                HeaderView("Audio")
                
                Toggle("Capture audio", isOn: $screenRecorder.isAudioCaptureEnabled)
                Toggle("Exclude app audio", isOn: $screenRecorder.isAppAudioExcluded)
                    .disabled(screenRecorder.isAppExcluded)
                AudioLevelsView(audioLevelsProvider: screenRecorder.audioLevelsProvider)
                Button {
                    if !audioPlayer.isPlaying {
                        audioPlayer.play()
                    } else {
                        audioPlayer.stop()
                    }
                } label: {
                    Text("\(!audioPlayer.isPlaying ? "Play" : "Stop") App Audio")
                }
                .disabled(screenRecorder.isAppExcluded)
                
                // Picker section.
                Spacer()
                    .frame(height: 20)
                
                HeaderView("Content Picker")
                Toggle("Activate Picker", isOn: $screenRecorder.isPickerActive)
                Group {
                    Button {
                        showPickerSettingsView = true
                    } label: {
                        Image(systemName: "text.badge.plus")
                        Text("Picker Configuration")
                    }
                    Button {
                        screenRecorder.presentPicker()
                    } label: {
                        Image(systemName: "sparkles.tv")
                        Text("Present Picker")
                    }
                }
                .disabled(!screenRecorder.isPickerActive)
            }
            .padding()
            
            Spacer()
            HStack {
                Button {
                    Task { await screenRecorder.start() }
                    // Fades the paused screen out.
                    withAnimation(Animation.easeOut(duration: 0.25)) {
                        userStopped = false
                    }
                } label: {
                    Text("Start Capture")
                }
                .disabled(screenRecorder.isRunning)
                Button {
                    Task { await screenRecorder.stop() }
                    // Fades the paused screen in.
                    withAnimation(Animation.easeOut(duration: 0.25)) {
                        userStopped = true
                    }

                } label: {
                    Text("Stop Capture")
                }
                .disabled(!screenRecorder.isRunning)
            }
            .frame(maxWidth: .infinity, minHeight: 60)
            .onChange(of: screenRecorder.pickerUpdate) {
                if !screenRecorder.isRunning {
                    // start
                    Task { await screenRecorder.start() }
                    // Fades the paused screen out.
                    withAnimation(Animation.easeOut(duration: 0.25)) {
                        userStopped = false
                    }
                } else {

                }
            }
        }
        .background(MaterialView())
        .sheet(isPresented: $showPickerSettingsView) {
            PickerSettingsView(screenRecorder: screenRecorder)
                .frame(minWidth: 500.0, maxWidth: .infinity, minHeight: 600.0, maxHeight: .infinity)
                .padding(.top, 7)
                .padding(.leading, 25)
        }
    }
}

/// A view that displays a styled header for the Video and Audio sections.
struct HeaderView: View {
    
    private let title: String
    private let alignmentOffset: CGFloat = 10.0
    
    init(_ title: String) {
        self.title = title
    }
    
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.secondary)
            .alignmentGuide(.leading) { _ in alignmentOffset }
    }
}
