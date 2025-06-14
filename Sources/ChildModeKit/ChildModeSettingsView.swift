import SwiftUI

public struct ChildModeSettingsView: View {
    @ObservedObject public var configuration: ChildModeConfiguration
    @State private var newPasscode = ""
    @State private var confirmPasscode = ""
    @State private var showPasscodeError = false
    @State private var customTimeInput = ""
    @State private var showCustomTime = false
    
    public var customPermissions: [PermissionToggle]
    public var showSetupSection: Bool
    public var onSetupComplete: (() -> Void)?
    
    public init(
        configuration: ChildModeConfiguration,
        customPermissions: [PermissionToggle] = [],
        showSetupSection: Bool = false,
        onSetupComplete: (() -> Void)? = nil
    ) {
        self.configuration = configuration
        self.customPermissions = customPermissions
        self.showSetupSection = showSetupSection
        self.onSetupComplete = onSetupComplete
    }
    
    public var body: some View {
        Form {
            if showSetupSection {
                setupSection
            }
            
            parentalControlsSection
            customPermissionsSection
            passcodeSection
        }
    }
    
    private var setupSection: some View {
        Section("Child Mode Setup") {
            VStack(alignment: .leading, spacing: 10) {
                Text("Complete setup:")
                    .font(.headline)
                
                HStack {
                    Image(systemName: configuration.parentalPasscode.isEmpty ? "circle" : "checkmark.circle.fill")
                        .foregroundColor(configuration.parentalPasscode.isEmpty ? .gray : .green)
                    Text("Set parental passcode")
                }
                
                if !configuration.parentalPasscode.isEmpty && onSetupComplete != nil {
                    Button("Complete Setup") {
                        onSetupComplete?()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.vertical, 5)
        }
    }
    
    private var parentalControlsSection: some View {
        Section("Parental Controls") {
            Toggle("Child Mode", isOn: $configuration.isChildMode)
                .tint(.blue)
            
            if configuration.isChildMode {
                timeLimitSection
                
                Toggle("Allow Camera Switch", isOn: $configuration.allowCameraSwitch)
                    .tint(.green)
                
                Toggle("Allow Photo Capture", isOn: $configuration.allowPhotoCapture)
                    .tint(.green)
                
                Toggle("Allow Video Recording", isOn: $configuration.allowVideoRecording)
                    .tint(.green)
                
                Toggle("Auto-Start Recording", isOn: $configuration.autoStartRecording)
                    .tint(.purple)
                
                Toggle("Allow Stop Recording", isOn: $configuration.allowStopRecording)
                    .tint(.orange)
                
                Toggle("Enable Audio Recording", isOn: $configuration.enableAudioRecording)
                    .tint(.blue)
                
                videoContentSection
            }
        }
    }
    
    private var videoContentSection: some View {
        Group {
            Toggle("Restrict to Approved Content", isOn: $configuration.restrictToApprovedContent)
                .tint(.red)
            
            Toggle("Allow File Sharing", isOn: $configuration.allowFileSharing)
                .tint(.orange)
            
            Toggle("Allow NFC Sharing", isOn: $configuration.allowNFCSharing)
                .tint(.purple)
            
            Toggle("Allow AirDrop Receiving", isOn: $configuration.allowAirDropReceiving)
                .tint(.green)
        }
    }
    
    private var timeLimitSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Time Limit")
                Spacer()
                Picker("Time", selection: $configuration.timeLimitSeconds) {
                    Text("10 sec").tag(10)
                    Text("30 sec").tag(30)
                    Text("1 min").tag(60)
                    Text("2 min").tag(120)
                    Text("5 min").tag(300)
                    Text("10 min").tag(600)
                    Text("Custom").tag(-1)
                    Text("No limit").tag(0)
                }
                .pickerStyle(.menu)
                .onChange(of: configuration.timeLimitSeconds) { value in
                    if value == -1 {
                        showCustomTime = true
                    }
                }
            }
            
            if showCustomTime || configuration.timeLimitSeconds == -1 {
                customTimeSection
            }
            
            if configuration.timeLimitSeconds > 0 && configuration.timeLimitSeconds != -1 {
                Text("Current: \(timeString(from: configuration.timeLimitSeconds))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var customTimeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Enter seconds", text: $customTimeInput)
                    .textFieldStyle(.roundedBorder)
                
                Button("Set") {
                    if let seconds = Int(customTimeInput), seconds > 0 {
                        configuration.timeLimitSeconds = seconds
                        showCustomTime = false
                        customTimeInput = ""
                    }
                }
                .buttonStyle(.bordered)
            }
            
            Button("Cancel Custom") {
                configuration.timeLimitSeconds = 600
                showCustomTime = false
                customTimeInput = ""
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private var customPermissionsSection: some View {
        if !customPermissions.isEmpty {
            Section("App Permissions") {
                ForEach(customPermissions, id: \.id) { permission in
                    Toggle(permission.title, isOn: permission.binding)
                        .tint(permission.color)
                }
            }
        }
    }
    
    private var passcodeSection: some View {
        Section("Override Passcode") {
            if configuration.parentalPasscode.isEmpty {
                SecureField("New Passcode", text: $newPasscode)
                
                SecureField("Confirm Passcode", text: $confirmPasscode)
                
                if showPasscodeError {
                    Text("Passcodes don't match")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Button("Set Passcode") {
                    if newPasscode == confirmPasscode && !newPasscode.isEmpty {
                        configuration.parentalPasscode = newPasscode
                        newPasscode = ""
                        confirmPasscode = ""
                        showPasscodeError = false
                    } else {
                        showPasscodeError = true
                    }
                }
                .disabled(newPasscode.isEmpty || confirmPasscode.isEmpty)
            } else {
                HStack {
                    Text("Passcode Set")
                        .foregroundColor(.green)
                    Spacer()
                    Button("Change") {
                        configuration.parentalPasscode = ""
                    }
                    .foregroundColor(.blue)
                }
            }
            
            Text("Long press for 2 seconds when time is up to enter override passcode")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func timeString(from seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds) sec"
        } else {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            if remainingSeconds == 0 {
                return "\(minutes) min"
            } else {
                return "\(minutes)m \(remainingSeconds)s"
            }
        }
    }
}

public struct PermissionToggle {
    public let id = UUID()
    public let title: String
    public let binding: Binding<Bool>
    public let color: Color
    
    public init(title: String, binding: Binding<Bool>, color: Color = .blue) {
        self.title = title
        self.binding = binding
        self.color = color
    }
}
