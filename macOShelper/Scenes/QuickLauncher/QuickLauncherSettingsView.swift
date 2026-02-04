import SwiftUI
internal import AppKit
import ApplicationServices


struct QuickLauncherSettingsView: View {
    @State private var hotkeyEnabled: Bool = true
    @State private var hotkeyKeyCode: UInt32 = 49
    @State private var hotkeyModifiers: UInt32 = 3
    @State private var isRecording: Bool = false
    @State private var recordingKeyCode: UInt16? = nil
    @State private var recordingModifiers: NSEvent.ModifierFlags = []
    @State private var recordingMonitor: Any? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Настройки быстрого лаунчера")
                .font(customFont: .sansBold, size: 24)
                .foregroundColor(.mainTextApp)
            
            Divider()
                .background(Color.borderApp)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Горячая клавиша")
                    .font(customFont: .sansSemiBold, size: 18)
                    .foregroundColor(.mainTextApp)
                
                Toggle("Включить быстрый лаунчер", isOn: $hotkeyEnabled)
                    .font(Font.custom(CustomFonts.sansRegular.rawValue, size: 15))
                    .foregroundColor(.mainTextApp)
                    .onChange(of: hotkeyEnabled) { newValue in
                        newValue ? registerHotkey() : unregisterHotkey()
                    }
                
                if hotkeyEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Text("Текущая комбинация:")
                                .font(customFont: .sansRegular, size: 14)
                                .foregroundColor(.secondaryTextApp)
                            
                            Button(action: { startRecording() }) {
                                HStack(spacing: 4) {
                                    if isRecording {
                                        Image(systemName: "record.circle.fill")
                                            .foregroundColor(.redAccent)
                                            .font(.system(size: 10))
                                        Text(recordingKeyCode != nil ? KeyboardModifiers.formatKeyCombo(keyCode: recordingKeyCode!, modifiers: recordingModifiers) : "Нажмите комбинацию...")
                                            .font(customFont: .sansSemiBold, size: 14)
                                            .foregroundColor(.mainTextApp)
                                    } else {
                                        Text(KeyboardModifiers.formatKeyCombo(keyCode: UInt16(hotkeyKeyCode), modifiers: KeyboardModifiers.toNSEventModifiers(hotkeyModifiers)))
                                            .font(customFont: .sansSemiBold, size: 14)
                                            .foregroundColor(.mainTextApp)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(isRecording ? Color.redAccent.opacity(0.2) : Color.lightGrayApp)
                                .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                            
                            if isRecording {
                                Button("Отмена") { cancelRecording() }
                                    .font(customFont: .sansRegular, size: 12)
                                    .foregroundColor(.secondaryTextApp)
                            }
                        }
                        
                        if isRecording {
                            Text("Нажмите новую комбинацию клавиш, затем Enter для сохранения")
                                .font(customFont: .sansRegular, size: 12)
                                .foregroundColor(.secondaryTextApp)
                        }
                    }
                    .padding(.leading, 20)
                }
            }
            
            Divider()
                .background(Color.borderApp)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Доступные команды")
                    .font(customFont: .sansSemiBold, size: 18)
                    .foregroundColor(.mainTextApp)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        CommandCategoryView(
                            icon: "checkmark.square",
                            title: "Задачи",
                            commands: [
                                ("task add <текст>", "Создать новую задачу"),
                                ("задача создать <текст>", "Создать новую задачу"),
                                ("task", "Открыть список задач")
                            ]
                        )
                        
                        CommandCategoryView(
                            icon: "timer",
                            title: "Помодоро",
                            commands: [
                                ("pomodoro <минуты>", "Запустить таймер (1-180 мин)"),
                                ("помодоро <минуты>", "Запустить таймер"),
                                ("pomodoro stop", "Остановить таймер"),
                                ("помодоро", "Открыть экран таймера")
                            ]
                        )
                        
                        CommandCategoryView(
                            icon: "doc.on.clipboard",
                            title: "Буфер обмена",
                            commands: [
                                ("clipboard clear", "Очистить историю"),
                                ("буфер очистить", "Очистить историю"),
                                ("clipboard", "Открыть историю буфера")
                            ]
                        )
                    }
                }
                .frame(maxHeight: 300)
            }
            
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.blackApp)
        .onAppear {
            hotkeyEnabled = GlobalHotKeyService.shared.isRegistered
            loadHotkeySettings()
        }
        .onDisappear {
            if isRecording { cancelRecording() }
        }
    }
    
    private func loadHotkeySettings() {
        if let savedKeyCode = UserDefaults.standard.object(forKey: "hotkeyKeyCode") as? UInt32 {
            hotkeyKeyCode = savedKeyCode
        }
        if let savedModifiers = UserDefaults.standard.object(forKey: "hotkeyModifiers") as? UInt32 {
            hotkeyModifiers = savedModifiers
        }
    }
    
    private func saveHotkeySettings() {
        UserDefaults.standard.set(hotkeyKeyCode, forKey: "hotkeyKeyCode")
        UserDefaults.standard.set(hotkeyModifiers, forKey: "hotkeyModifiers")
    }
    
    private func startRecording() {
        isRecording = true
        recordingKeyCode = nil
        recordingModifiers = []
        
        if hotkeyEnabled {
            GlobalHotKeyService.shared.unregisterHotKey()
        }
        
        recordingMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            guard self.isRecording else { return event }
            
            if event.keyCode == 36 && event.type == .keyDown {
                if let keyCode = recordingKeyCode {
                    hotkeyKeyCode = UInt32(keyCode)
                    hotkeyModifiers = KeyboardModifiers.toCarbonModifiers(recordingModifiers)
                    saveHotkeySettings()
                    
                    if hotkeyEnabled {
                        registerHotkey()
                    }
                    
                    cancelRecording()
                    return nil
                }
            }
            
            if event.keyCode == 53 && event.type == .keyDown {
                cancelRecording()
                return nil
            }
            
            if event.type == .keyDown {
                let modifiers = event.modifierFlags.intersection([.command, .control, .option, .shift])
                
                if !modifiers.isEmpty && event.keyCode != 0 {
                    recordingKeyCode = event.keyCode
                    recordingModifiers = modifiers
                }
            }
            
            return event
        }
    }
    
    private func cancelRecording() {
        isRecording = false
        recordingKeyCode = nil
        recordingModifiers = []
        
        if let monitor = recordingMonitor {
            NSEvent.removeMonitor(monitor)
            recordingMonitor = nil
        }
        
        if hotkeyEnabled {
            registerHotkey()
        }
    }
    
    private func registerHotkey() {
        guard AXIsProcessTrusted() else {
            return
        }
        
        GlobalHotKeyService.shared.registerHotKey(
            keyCode: hotkeyKeyCode,
            modifiers: hotkeyModifiers,
            callback: {
                QuickLauncherWindow.shared.toggle()
            }
        )
    }
    
    private func unregisterHotkey() {
        GlobalHotKeyService.shared.unregisterHotKey()
    }
}

struct CommandCategoryView: View {
    let icon: String
    let title: String
    let commands: [(command: String, description: String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.blueAccent)
                
                Text(title)
                    .font(customFont: .sansSemiBold, size: 15)
                    .foregroundColor(.mainTextApp)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                ForEach(commands, id: \.command) { command in
                    HStack(alignment: .top, spacing: 8) {
                        Text(command.command)
                            .font(customFont: .sansRegular, size: 13)
                            .foregroundColor(.blueAccent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blueAccent.opacity(0.1))
                            .cornerRadius(4)
                        
                        Text("—")
                            .font(customFont: .sansRegular, size: 13)
                            .foregroundColor(.secondaryTextApp)
                        
                        Text(command.description)
                            .font(customFont: .sansRegular, size: 13)
                            .foregroundColor(.secondaryTextApp)
                    }
                }
            }
            .padding(.leading, 22)
        }
    }
}
