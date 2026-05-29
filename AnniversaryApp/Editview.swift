//
//  Editview.swift
//  AnniversaryApp
//
//  Created by higurashi on 2026/05/29.
//

import SwiftUI
import PhotosUI

struct EditView: View {
    let store: AnniversaryStore
    var existing: Anniversary?

    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var date: Date = Date()
    @State private var note: String = ""
    @State private var selectedColor: String = "FF6B6B"
    @State private var selectedImage: UIImage?
    @State private var photoItem: PhotosPickerItem?
    @State private var category: AnniversaryCategory = .anniversary
    @State private var repeatRule: RepeatRule = .yearly
    @State private var isPinned: Bool = false
    @State private var notifyEnabled: Bool = false
    @State private var notifyDaysBefore: Int = 1
    @State private var tagText: String = ""
    @State private var tags: [String] = []

    private let palette: [String] = [
        "FF6B6B", "FF8E53", "FFCC02", "4ECDC4",
        "45B7D1", "96CEB4", "DDA0DD", "F7AEF8"
    ]

    var isEditing: Bool { existing != nil }
    var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "111111").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        photoPicker

                        VStack(spacing: 16) {
                            fieldSection("タイトル") {
                                TextField("例: 結婚記念日", text: $title)
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                            }

                            fieldSection("日付") {
                                DatePicker("", selection: $date, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            fieldSection("メモ（任意）") {
                                TextField("コメントを入力...", text: $note, axis: .vertical)
                                    .foregroundColor(.white)
                                    .font(.system(size: 15))
                                    .lineLimit(3, reservesSpace: true)
                            }
                        }
                        .padding(.horizontal, 20)

                        categorySection
                        repeatSection
                        colorSection
                        tagSection
                        optionsSection

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle(isEditing ? "編集" : "新しい記念日")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") { save() }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(canSave ? .white : .white.opacity(0.3))
                        .disabled(!canSave)
                }
            }
        }
        .onAppear { prefill() }
        .onChange(of: photoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    selectedImage = img
                }
            }
        }
    }

    // MARK: - Photo Picker

    var photoPicker: some View {
        PhotosPicker(selection: $photoItem, matching: .images) {
            ZStack {
                if let img = selectedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipped()
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                                .padding(12)
                        }
                } else {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(hex: selectedColor).opacity(0.25))
                        .frame(height: 160)
                        .overlay {
                            VStack(spacing: 10) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 36))
                                    .foregroundColor(Color(hex: selectedColor))
                                Text("背景写真を選択")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 20)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .topTrailing) {
            if selectedImage != nil {
                Button {
                    selectedImage = nil
                    photoItem = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .padding(10)
                }
            }
        }
    }

    // MARK: - Category

    var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("カテゴリー")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(AnniversaryCategory.allCases) { cat in
                        Button {
                            Haptics.selection()
                            category = cat
                            // adopt the category's default color unless an image is set
                            if selectedImage == nil { selectedColor = cat.defaultColor }
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: cat.icon)
                                    .font(.system(size: 18))
                                Text(cat.label)
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .frame(width: 64, height: 64)
                            .background(category == cat
                                        ? Color(hex: cat.defaultColor).opacity(0.9)
                                        : Color.white.opacity(0.07))
                            .foregroundColor(category == cat ? .black : .white.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Repeat

    var repeatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("繰り返し")
            Picker("繰り返し", selection: $repeatRule) {
                ForEach(RepeatRule.allCases) { rule in
                    Text(rule.label).tag(rule)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Color Section

    var colorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("テーマカラー")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(palette, id: \.self) { hex in
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 40, height: 40)
                            .overlay {
                                if selectedColor == hex {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .onTapGesture {
                                Haptics.selection()
                                selectedColor = hex
                            }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Tags

    var tagSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("タグ")
            VStack(spacing: 10) {
                HStack {
                    TextField("タグを追加", text: $tagText)
                        .foregroundColor(.white)
                        .font(.system(size: 15))
                        .onSubmit(addTag)
                    Button(action: addTag) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color(hex: selectedColor))
                    }
                    .disabled(tagText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                if !tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(tags, id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text("#\(tag)").font(.system(size: 13))
                                    Button {
                                        tags.removeAll { $0 == tag }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 13))
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.1))
                                .foregroundColor(.white.opacity(0.85))
                                .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Options (pin + notifications)

    var optionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("オプション")
            VStack(spacing: 0) {
                Toggle(isOn: $isPinned) {
                    Label("ピン留めして上部に固定", systemImage: "pin.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                }
                .tint(Color(hex: selectedColor))
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                Divider().background(Color.white.opacity(0.1))

                Toggle(isOn: $notifyEnabled) {
                    Label("リマインド通知", systemImage: "bell.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                }
                .tint(Color(hex: selectedColor))
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .onChange(of: notifyEnabled) { _, on in
                    if on { NotificationManager.shared.requestAuthorization() }
                }

                if notifyEnabled {
                    Divider().background(Color.white.opacity(0.1))
                    Stepper(value: $notifyDaysBefore, in: 0...30) {
                        Text(notifyDaysBefore == 0 ? "当日の朝9時に通知"
                                                   : "\(notifyDaysBefore)日前の朝9時に通知")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Helpers

    func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white.opacity(0.5))
            .padding(.horizontal, 20)
    }

    @ViewBuilder
    func fieldSection<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.45))
                .textCase(.uppercase)
            content()
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    func addTag() {
        let t = tagText.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty, !tags.contains(t) else { return }
        tags.append(t)
        tagText = ""
        Haptics.selection()
    }

    func prefill() {
        guard let item = existing else { return }
        title = item.title
        date = item.date
        note = item.note
        selectedColor = item.colorHex
        category = item.category
        repeatRule = item.repeatRule
        isPinned = item.isPinned
        notifyEnabled = item.notifyEnabled
        notifyDaysBefore = item.notifyDaysBefore
        tags = item.tags
        if let data = item.imageData {
            selectedImage = UIImage(data: data)
        }
    }

    func save() {
        let imageData = selectedImage?.jpegData(compressionQuality: 0.7)
        var item = Anniversary(
            title: title.trimmingCharacters(in: .whitespaces),
            date: date,
            note: note,
            imageData: imageData,
            colorHex: selectedColor,
            category: category,
            repeatRule: repeatRule,
            isPinned: isPinned,
            notifyEnabled: notifyEnabled,
            notifyDaysBefore: notifyDaysBefore,
            tags: tags,
            createdAt: existing?.createdAt ?? Date()
        )
        if let existing {
            item.id = existing.id
            store.update(item)
        } else {
            store.add(item)
        }
        Haptics.success()
        dismiss()
    }
}
