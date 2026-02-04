import SwiftUI
internal import AppKit

enum QuickLauncherTab {
    case search
    case clipboard
}

struct QuickLauncherView: View {
    @StateObject private var viewModel = QuickLauncherViewModel()
    @ObservedObject private var clipboardService = ClipboardHistoryService.shared
    @FocusState private var isSearchFocused: Bool
    @State private var selectedIndex: Int = 0
    @State private var scrollProxy: ScrollViewProxy?
    @State private var lastTappedIndex: Int? = nil
    @State private var selectedTab: QuickLauncherTab = .search
    private let itemHeight: CGFloat = 52
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: selectedTab == .search ? "magnifyingglass" : "doc.on.clipboard")
                    .foregroundColor(.secondaryTextApp)
                    .font(.system(size: 16))
                    .frame(width: 16)
                
                if selectedTab == .search {
                    TextField("Поиск", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .font(Font.custom(CustomFonts.sansRegular.rawValue, size: 18))
                        .foregroundColor(.mainTextApp)
                        .focused($isSearchFocused)
                    .onSubmit {
                        if !viewModel.filteredCommands.isEmpty {
                            executeSelectedCommand()
                        }
                    }
                    .onKeyPress(.escape) {
                        QuickLauncherWindow.shared.hide()
                        return .handled
                    }
                    .onKeyPress(.return) {
                        if !viewModel.filteredCommands.isEmpty {
                            executeSelectedCommand()
                            return .handled
                        }
                        return .ignored
                    }
                    .onKeyPress(.downArrow) {
                        if selectedIndex < viewModel.filteredCommands.count - 1 {
                            selectedIndex += 1
                            scrollToItem(selectedIndex)
                        }
                        return .handled
                    }
                    .onKeyPress(.upArrow) {
                        if selectedIndex > 0 {
                            selectedIndex -= 1
                            scrollToItem(selectedIndex)
                        }
                        return .handled
                    }
                
                    if !viewModel.searchText.isEmpty {
                        Button(action: {
                            viewModel.clearSearch()
                            selectedIndex = 0
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondaryTextApp)
                                .font(.system(size: 14))
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Text("Буфер обмена")
                        .font(Font.custom(CustomFonts.sansSemiBold.rawValue, size: 18))
                        .foregroundColor(.mainTextApp)
                }
                
                Spacer()
                
                Button(action: {
                    selectedTab = selectedTab == .search ? .clipboard : .search
                }) {
                    Image(systemName: selectedTab == .search ? "doc.on.clipboard" : "magnifyingglass")
                        .foregroundColor(.secondaryTextApp)
                        .font(.system(size: 16))
                        .frame(width: 32, height: 32)
                        .background(Color.lightGrayApp)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            if selectedTab == .search {
                searchContent
            } else {
                clipboardContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.25), radius: 15, x: 0, y: 8)
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if selectedTab == .search {
                    isSearchFocused = true
                }
            }
            selectedIndex = 0
        }
        .onChange(of: isSearchFocused) { focused in
            if focused && viewModel.shouldSelectAll {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    selectAllText()
                    viewModel.shouldSelectAll = false
                }
            }
        }
        .onChange(of: viewModel.searchText) {
            selectedIndex = 0
            lastTappedIndex = nil
        }
        .onChange(of: viewModel.filteredCommands.count) {
            if selectedIndex >= viewModel.filteredCommands.count {
                selectedIndex = max(0, viewModel.filteredCommands.count - 1)
            }
        }
    }
    
    @ViewBuilder
    private var searchContent: some View {
        if viewModel.filteredCommands.isEmpty && !viewModel.searchText.isEmpty {
                GeometryReader { geometry in
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 28))
                            .foregroundColor(.secondaryTextApp)
                        Text("Ничего не найдено")
                            .font(customFont: .sansRegular, size: 14)
                            .foregroundColor(.secondaryTextApp)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .padding(.vertical, 30)
                }
            } else if !viewModel.filteredCommands.isEmpty {
                Divider()
                    .background(Color.borderApp.opacity(0.3))
                
                GeometryReader { geometry in
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 0) {
                                let actionsCount = viewModel.groupedCommands.actions.count
                                let appsCount = viewModel.groupedCommands.applications.count
                                let filesCount = viewModel.groupedCommands.files.count
                                
                                if actionsCount > 0 {
                                    CategorySection(
                                        title: CommandCategory.actions.rawValue,
                                        commands: viewModel.groupedCommands.actions,
                                        startIndex: 0,
                                        selectedIndex: $selectedIndex,
                                        itemHeight: itemHeight,
                                        onTap: handleItemTap
                                    )
                                }
                                
                                if appsCount > 0 {
                                    CategorySection(
                                        title: CommandCategory.applications.rawValue,
                                        commands: viewModel.groupedCommands.applications,
                                        startIndex: actionsCount,
                                        selectedIndex: $selectedIndex,
                                        itemHeight: itemHeight,
                                        onTap: handleItemTap
                                    )
                                }
                                
                                if filesCount > 0 {
                                    CategorySection(
                                        title: CommandCategory.files.rawValue,
                                        commands: viewModel.groupedCommands.files,
                                        startIndex: actionsCount + appsCount,
                                        selectedIndex: $selectedIndex,
                                        itemHeight: itemHeight,
                                        onTap: handleItemTap
                                    )
                                }
                            }
                        }
                        .frame(height: geometry.size.height)
                        .scrollIndicators(.hidden)
                        .onAppear {
                            scrollProxy = proxy
                        }
                    }
                }
            }
        }
    
    @ViewBuilder
    private var clipboardContent: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(clipboardService.items) { item in
                    ClipboardItemRow(item: item, onPaste: {
                        clipboardService.paste(item)
                        QuickLauncherWindow.shared.hide()
                    })
                }
            }
            .padding(16)
        }
    }
    
    private func executeSelectedCommand() {
        guard selectedIndex < viewModel.filteredCommands.count else { return }
        let command = viewModel.filteredCommands[selectedIndex]
        viewModel.executeCommand(command)
        QuickLauncherWindow.shared.hide()
    }
    
    private func scrollToItem(_ index: Int) {
        if let proxy = scrollProxy {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(index, anchor: .center)
            }
        }
    }
    
    private func selectAllText() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            if let window = NSApplication.shared.keyWindow as? QuickLauncherWindow,
               let contentView = window.contentView {
                findAndSelectTextField(in: contentView)
            }
        }
    }
    
    private func findAndSelectTextField(in view: NSView) {
        if let textField = view as? NSTextField {
            if textField.isEditable {
                textField.selectText(nil)
                return
            }
        }
        
        for subview in view.subviews {
            findAndSelectTextField(in: subview)
        }
    }
    
    private func handleItemTap(at index: Int, command: LauncherCommand) {
        if lastTappedIndex == index {
            viewModel.executeCommand(command)
            QuickLauncherWindow.shared.hide()
            lastTappedIndex = nil
        } else {
            selectedIndex = index
            lastTappedIndex = index
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if lastTappedIndex == index {
                    lastTappedIndex = nil
                }
            }
        }
    }
}

struct CategorySection: View {
    let title: String
    let commands: [LauncherCommand]
    let startIndex: Int
    @Binding var selectedIndex: Int
    let itemHeight: CGFloat
    let onTap: (Int, LauncherCommand) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(customFont: .sansSemiBold, size: 12)
                .foregroundColor(.secondaryTextApp)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor))
            
            ForEach(Array(commands.enumerated()), id: \.element.id) { localIndex, command in
                let globalIndex = startIndex + localIndex
                CommandRowView(
                    command: command,
                    isSelected: globalIndex == selectedIndex
                )
                .frame(height: itemHeight)
                .id(globalIndex)
                .onTapGesture {
                    onTap(globalIndex, command)
                }
            }
        }
    }
}

struct CommandRowView: View {
    let command: LauncherCommand
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            if let appIcon = command.appIcon {
                Image(nsImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
            } else {
                Image(systemName: command.icon)
                    .font(.system(size: 16))
                    .foregroundColor(.blueAccent)
                    .frame(width: 32, height: 32)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(command.name)
                    .font(customFont: .sansSemiBold, size: 15)
                    .foregroundColor(.mainTextApp)
                
                if !command.description.isEmpty {
                    Text(command.description)
                        .font(customFont: .sansRegular, size: 12)
                        .foregroundColor(.secondaryTextApp)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(isSelected ? Color.blueAccent.opacity(0.15) : Color.clear)
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.1), value: isSelected)
    }
}

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let onPaste: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            if let image = item.previewImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .cornerRadius(6)
            } else {
                Image(systemName: "doc.text")
                    .font(.system(size: 20))
                    .foregroundColor(.blueAccent)
                    .frame(width: 40, height: 40)
                    .background(Color.blueAccent.opacity(0.1))
                    .cornerRadius(6)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.preview)
                    .font(customFont: .sansRegular, size: 14)
                    .foregroundColor(.mainTextApp)
                    .lineLimit(2)
                
                Text(formatDate(item.capturedAt))
                    .font(customFont: .sansRegular, size: 11)
                    .foregroundColor(.secondaryTextApp)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.lightGrayApp.opacity(0.3))
        .cornerRadius(8)
        .onTapGesture {
            onPaste()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    QuickLauncherView()
        .background(Color.blackApp)
}
