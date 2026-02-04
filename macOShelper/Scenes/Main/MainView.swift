import SwiftUI
internal import AppKit

enum Tab: String, Hashable {
    case taskManager = "Задачи"
    case timeManager = "Помодоро"
    case quickLauncher = "Быстрый поиск"
    case exchangeBuffer = "Буфер обмена"
}

struct MainView: View {
    @State var selectedTab: Tab = .taskManager
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                Button(action: {
                    QuickLauncherWindow.shared.toggle()
                }) {
                    Label("🧪 TEST Hotkey", systemImage: "play")
                }
                
                NavigationLink(value: Tab.taskManager) {
                    Label(Tab.taskManager.rawValue, systemImage: "checklist")
                }
                
                NavigationLink(value: Tab.timeManager) {
                    Label(Tab.timeManager.rawValue, systemImage: "timer")
                }
                
                NavigationLink(value: Tab.quickLauncher) {
                    Label(Tab.quickLauncher.rawValue, systemImage: "magnifyingglass")
                }
                
                NavigationLink(value: Tab.exchangeBuffer) {
                    Label(Tab.exchangeBuffer.rawValue, systemImage: "doc.on.clipboard")
                }
            }
            .navigationSplitViewColumnWidth(min: 140, ideal: 160, max: 170)
            .background(Color(NSColor.windowBackgroundColor))
            .foregroundStyle(Color.mainTextApp)
        } detail: {
            Group {
                switch selectedTab {
                case .taskManager:
                    TaskManagerView()
                case .timeManager:
                    TimeManagerView()
                case .quickLauncher:
                    QuickLauncherSettingsView()
                case .exchangeBuffer:
                    ExchangeBufferView()
                }
            }
            .navigationTitle(selectedTab.rawValue)
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToTab)) { notification in
            if let tab = notification.object as? Tab {
                selectedTab = tab
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}

struct ExchangeBufferView: View {
    @ObservedObject private var service = ClipboardHistoryService.shared
    @State private var hoveredId: ClipboardItem.ID?
    @State private var editingHotkeyItemId: ClipboardItem.ID?
    @State private var pressedPreviewItemId: ClipboardItem.ID?
    @State private var previewWorkItem: DispatchWorkItem?
    @State private var skipPasteItemId: ClipboardItem.ID?
    @State private var showingOnboarding = false

    private let maxHotkeyIndex = 9

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.blackApp)
        .sheet(item: hotkeySheetBinding) { item in
            HotkeyAssignmentView(
                item: item,
                onSetHotkey: { hotkey in
                    service.setHotkey(hotkey, for: item)
                },
                onClearHotkey: {
                    service.setHotkey(nil, for: item)
                }
            )
        }
        .sheet(isPresented: $showingOnboarding) {
            ClipboardOnboardingView()
        }
        .overlay(previewOverlay)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("История буфера обмена")
                        .font(Font.custom("HSESans-Bold", size: 22))
                        .foregroundColor(.mainTextApp)

                    Text("Выберите запись или нажмите сочетание клавиш, чтобы вставить содержимое в активное окно.")
                        .font(Font.custom("HSESans-Regular", size: 13))
                        .foregroundColor(.secondaryTextApp)
                }

                Spacer()

                HStack(spacing: 10) {
                    Button {
                        showingOnboarding = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondaryTextApp)
                            .padding(8)
                            .background(Color.grayApp.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    if !service.items.isEmpty {
                        Button {
                            editingHotkeyItemId = nil
                            service.clearAll()
                        } label: {
                            Label("Очистить", systemImage: "trash")
                                .font(Font.custom("HSESans-Regular", size: 13))
                        }
                        .applySecondaryButton()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if service.items.isEmpty {
            emptyState
        } else {
            historyList
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("Пока здесь пусто")
                .font(Font.custom("HSESans-SemiBold", size: 16))
                .foregroundColor(.secondaryTextApp)

            Text("Скопируйте текст в любом приложении — он появится в истории.")
                .font(Font.custom("HSESans-Regular", size: 13))
                .foregroundColor(.secondaryTextApp)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var historyList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(service.items.enumerated()), id: \.element.id) { index, item in
                    row(for: item, index: index)
                }
            }
        }
    }

    @ViewBuilder
    private func row(for item: ClipboardItem, index: Int) -> some View {
        let isHovered = hoveredId == item.id
        let customShortcut = item.hotkey?.display

        ZStack(alignment: .topTrailing) {
            Button {
                if skipPasteItemId == item.id {
                    skipPasteItemId = nil
                    return
                }
                service.paste(item)
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    leadingContent(for: item)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(itemPreview(item))
                            .font(Font.custom("HSESans-Regular", size: 14))
                            .foregroundColor(.mainTextApp)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if let secondary = secondaryDescription(for: item) {
                            Text(secondary)
                                .font(Font.custom("HSESans-Regular", size: 12))
                                .foregroundColor(.secondaryTextApp)
                        }

                        Text(item.capturedAt, style: .time)
                            .font(Font.custom("HSESans-Regular", size: 12))
                            .foregroundColor(.secondaryTextApp)
                    }
                }
                .padding(EdgeInsets(top: 14, leading: 14, bottom: 20, trailing: 90))
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(isHovered ? Color.grayApp : Color.cardBackgroundApp)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                hoveredId = hovering ? item.id : nil
            }
            .onLongPressGesture(minimumDuration: 0.01, maximumDistance: 10, pressing: { pressing in
                guard item.previewImage != nil else { return }

                if pressing {
                    previewWorkItem?.cancel()
                    let work = DispatchWorkItem {
                        if pressedPreviewItemId != item.id {
                            skipPasteItemId = item.id
                            pressedPreviewItemId = item.id
                        }
                    }
                    previewWorkItem = work
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: work)
                } else {
                    previewWorkItem?.cancel()
                    previewWorkItem = nil
                    if pressedPreviewItemId == item.id {
                        pressedPreviewItemId = nil
                    }
                    DispatchQueue.main.async {
                        if skipPasteItemId == item.id && pressedPreviewItemId == nil {
                            skipPasteItemId = nil
                        }
                    }
                }
            }, perform: { })

            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 6) {
                    Button {
                        editingHotkeyItemId = item.id
                    } label: {
                        Image(systemName: "keyboard")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondaryTextApp)
                            .padding(8)
                            .background(Color.grayApp.opacity(isHovered ? 0.9 : 0.6))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Button {
                        if editingHotkeyItemId == item.id {
                            editingHotkeyItemId = nil
                        }
                        service.remove(item)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondaryTextApp)
                            .padding(8)
                            .background(Color.grayApp.opacity(isHovered ? 0.9 : 0.6))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                if let customShortcut {
                    shortcutBadge(customShortcut, isPrimary: true)
                }
            }
            .padding(.top, 6)
            .padding(.trailing, 6)
        }
    }

    private func shortcutBadge(_ text: String, isPrimary: Bool) -> some View {
        Text(text)
            .font(Font.custom("HSESans-SemiBold", size: 12))
            .foregroundColor(isPrimary ? .black : .secondaryTextApp)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isPrimary ? Color.yellowAccent : Color.grayApp.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func itemPreview(_ item: ClipboardItem) -> String {
        let preview = item.preview
        if preview.isEmpty {
            return "Пустая строка"
        }
        return preview
    }

    private func secondaryDescription(for item: ClipboardItem) -> String? {
        if item.primaryString != nil { return nil }
        var seen = Set<String>()
        var ordered: [String] = []

        for representation in item.allRepresentations {
            let name = representation.displayName
            if seen.insert(name).inserted {
                ordered.append(name)
            }
        }

        guard !ordered.isEmpty else { return nil }

        if ordered.count > 3 {
            let head = ordered.prefix(3).joined(separator: ", ")
            return "\(head) + ещё \(ordered.count - 3)"
        } else {
            return ordered.joined(separator: ", ")
        }
    }

    private func leadingIcon(for item: ClipboardItem) -> String? {
        if item.allRepresentations.contains(where: { $0.isImage }) {
            return "photo"
        }
        if item.allRepresentations.contains(where: { $0.fileURL != nil }) {
            return "doc"
        }
        if item.primaryString != nil {
            return "text.alignleft"
        }
        return "rectangle.and.paperclip"
    }

    private var hotkeySheetBinding: Binding<ClipboardItem?> {
        Binding(
            get: {
                guard let id = editingHotkeyItemId else { return nil }
                return service.items.first(where: { $0.id == id })
            },
            set: { newValue in
                editingHotkeyItemId = newValue?.id
            }
        )
    }

    @ViewBuilder
    private func leadingContent(for item: ClipboardItem) -> some View {
        if let preview = item.previewImage {
            Image(nsImage: preview)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.grayApp.opacity(0.6), lineWidth: 1)
                )
        } else if let iconName = leadingIcon(for: item) {
            Image(systemName: iconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.secondaryTextApp)
                .frame(width: 36, height: 36)
                .background(Color.grayApp.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            Spacer()
                .frame(width: 0)
        }
    }

    @ViewBuilder
    private var previewOverlay: some View {
        if let id = pressedPreviewItemId,
           let item = service.items.first(where: { $0.id == id }),
           let image = item.previewImage {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .overlay(
                    VStack(spacing: 16) {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 520, maxHeight: 520)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 12)

                        Text("Отпустите, чтобы закрыть")
                            .font(Font.custom("HSESans-Regular", size: 13))
                            .foregroundColor(.secondaryTextApp)
                    }
                    .padding()
                )
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.15), value: pressedPreviewItemId)
                .onTapGesture {
                    pressedPreviewItemId = nil
                    skipPasteItemId = nil
                }
        }
    }
}
