import SwiftUI

public struct ParentalOverrideView: View {
    @ObservedObject public var configuration: ChildModeConfiguration
    @Binding public var isTimeLimitReached: Bool
    @Binding public var timeRemaining: TimeInterval
    @Binding public var timer: Timer?
    @Environment(\.dismiss) var dismiss
    
    @State private var enteredPasscode = ""
    @State private var showError = false
    @State private var showActions = false
    @FocusState private var isPasscodeFocused: Bool
    
    public var onSessionEnd: (() -> Void)?
    
    public init(
        configuration: ChildModeConfiguration,
        isTimeLimitReached: Binding<Bool>,
        timeRemaining: Binding<TimeInterval>,
        timer: Binding<Timer?>,
        onSessionEnd: (() -> Void)? = nil
    ) {
        self.configuration = configuration
        self._isTimeLimitReached = isTimeLimitReached
        self._timeRemaining = timeRemaining
        self._timer = timer
        self.onSessionEnd = onSessionEnd
    }
    
    public var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 10) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("Parental Override")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Enter passcode for timer control")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if !showActions {
                VStack(spacing: 20) {
                    SecureField("Passcode", text: $enteredPasscode)
                        .textFieldStyle(.roundedBorder)
                        .focused($isPasscodeFocused)
                        .onSubmit {
                            verifyPasscode()
                        }
                    
                    if showError {
                        Text("Incorrect passcode")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    HStack(spacing: 20) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Verify") {
                            verifyPasscode()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(enteredPasscode.isEmpty)
                    }
                }
                .padding(.horizontal)
            } else {
                VStack(spacing: 20) {
                    Text("Timer Actions")
                        .font(.headline)
                    
                    Button("Reset Timer") {
                        resetTimer()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: 200)
                    
                    Button("Add 5 Minutes") {
                        addTime(seconds: 300)
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: 200)
                    
                    Button("End Session Now") {
                        endSession()
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .frame(maxWidth: 200)
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .padding(.top)
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .onAppear {
            isPasscodeFocused = true
        }
    }
    
    private func verifyPasscode() {
        if configuration.isValidPasscode(enteredPasscode) {
            showActions = true
            showError = false
        } else {
            showError = true
            enteredPasscode = ""
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showError = false
            }
        }
    }
    
    private func resetTimer() {
        isTimeLimitReached = false
        timeRemaining = TimeInterval(configuration.timeLimitSeconds)
        dismiss()
    }
    
    private func addTime(seconds: Int) {
        isTimeLimitReached = false
        timeRemaining += TimeInterval(seconds)
        dismiss()
    }
    
    private func endSession() {
        timer?.invalidate()
        timer = nil
        timeRemaining = 0
        isTimeLimitReached = false
        configuration.isChildMode = false
        onSessionEnd?()
        dismiss()
    }
}