import SwiftUI
import SwiftData

/// ビルダー左側。大カテゴリ→（中カテゴリ）→小カテゴリメニューをたどり、タップで本日の練習メニューに追加する。
struct CategoryBrowserView: View {
    @Query(sort: [SortDescriptor(\PracticeMenu.name)]) private var allMenus: [PracticeMenu]

    /// メニューがタップされたときに呼ばれる（本日の練習メニューへ追加）。
    let onAdd: (PracticeMenu) -> Void

    @State private var selectedMajor: MajorCategory?
    @State private var selectedMiddle: MiddleCategory?
    @State private var newMenuContext: NewMenuContext?

    private struct NewMenuContext: Identifiable {
        let id = UUID()
        let major: MajorCategory
        let middle: MiddleCategory?
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            ScrollView {
                if selectedMajor == nil {
                    majorGrid
                } else if let major = selectedMajor, major.hasMiddleCategory, selectedMiddle == nil {
                    middleGrid(major: major)
                } else if let major = selectedMajor {
                    menuList(major: major, middle: selectedMiddle)
                }
            }
        }
        .background(Color(.secondarySystemBackground))
        .sheet(item: $newMenuContext) { ctx in
            NavigationStack {
                MenuEditView(menu: nil, presetMajor: ctx.major, presetMiddle: ctx.middle)
            }
        }
    }

    // MARK: - Header (breadcrumb)

    private var header: some View {
        HStack(spacing: 8) {
            if selectedMajor != nil {
                Button {
                    if selectedMiddle != nil {
                        selectedMiddle = nil
                    } else {
                        selectedMajor = nil
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                }
            }
            Text(breadcrumb)
                .font(.headline)
            Spacer()
        }
        .padding()
    }

    private var breadcrumb: String {
        var parts: [String] = ["カテゴリ"]
        if let major = selectedMajor { parts = [major.displayName] }
        if let middle = selectedMiddle { parts.append(middle.displayName) }
        return parts.joined(separator: " › ")
    }

    // MARK: - Level 1: major categories

    private var majorGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
            ForEach(MajorCategory.allCases) { major in
                Button {
                    selectedMajor = major
                    selectedMiddle = nil
                } label: {
                    categoryCard(title: major.displayName, systemImage: major.systemImage)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }

    // MARK: - Level 2: middle categories

    private func middleGrid(major: MajorCategory) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
            ForEach(MiddleCategory.allCases) { middle in
                Button {
                    selectedMiddle = middle
                } label: {
                    categoryCard(title: middle.displayName, systemImage: "person.2")
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }

    // MARK: - Level 3: menu list

    private func menuList(major: MajorCategory, middle: MiddleCategory?) -> some View {
        let menus = allMenus.filter { menu in
            menu.majorCategory == major &&
            (!major.hasMiddleCategory || menu.middleCategory == middle)
        }
        return VStack(spacing: 10) {
            if menus.isEmpty {
                Text("このカテゴリにはまだメニューがありません")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ForEach(menus) { menu in
                    Button {
                        onAdd(menu)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(menu.name).font(.headline)
                                if !menu.descriptionText.isEmpty {
                                    Text(menu.descriptionText)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.accent)
                        }
                        .padding()
                        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                newMenuContext = NewMenuContext(major: major, middle: middle)
            } label: {
                Label("このカテゴリに新規メニューを作成", systemImage: "plus")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private func categoryCard(title: String, systemImage: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 30))
                .foregroundStyle(.accent)
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding()
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }
}
