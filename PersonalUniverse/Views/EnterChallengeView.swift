//
//  EnterChallengeView.swift
//  PersonalUniverse
//
//  Created by Minjae Son on 8/12/26.
//

import SwiftUI
import SwiftData

struct EnterChallengeView: View {
    // MARK: - Environment

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var modelContext

    // MARK: - State

    @State private var step = 0
    @State private var title = ""
    @State private var totalDays = 30
    @State private var selectedGalaxy: GalaxyStyle = .expanding

    // MARK: - Reminder

    @State private var reminderEnabled = true
    @State private var reminderTime: Date = {
        let calendar = Calendar.current
        return calendar.date(
            bySettingHour: calendar.component(.hour, from: .now),
            minute: calendar.component(.minute, from: .now),
            second: 0,
            of: .now
        ) ?? .now
    }()

    // These store the actual selected hour/minute values.

    @State private var selectedHour: Int =
        Calendar.current.component(
            .hour,
            from: .now
        )

    @State private var selectedMinute: Int =
        Calendar.current.component(
            .minute,
            from: .now
        )

    @State private var isCreating = false

    // MARK: - Constants

    private let availableDays = [
        7,
        14,
        30,
        50,
        100
    ]

    private let selectionAnimation =
        Animation.easeInOut(duration: 0.25)

    // MARK: - Body

    var body: some View {
        ZStack {
            SpaceBackground()
                .ignoresSafeArea()

            Color.black
                .opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topNavigation

                Group {
                    switch step {
                    case 0:
                        titleStep
                    case 1:
                        durationStep
                    case 2:
                        reminderStep
                    case 3:
                        galaxyStep
                    default:
                        EmptyView()
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )

                bottomNavigation
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Top Navigation

    private var topNavigation: some View {
        HStack {
            Button {
                previousStep()
            } label: {
                Image(systemName: "chevron.left")
                    .font(
                        .system(
                            size: 17,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(
                        width: 44,
                        height: 44
                    )
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: 5) {
                ForEach(
                    0..<4,
                    id: \.self
                ) { index in
                    Capsule()
                        .fill(
                            .white.opacity(
                                index == step
                                    ? 0.8
                                    : 0.15
                            )
                        )
                        .frame(
                            width: index == step ? 30 : 12,
                            height: 2
                        )
                }
            }

            Spacer()

            Color.clear
                .frame(
                    width: 44,
                    height: 44
                )
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    // MARK: - Bottom Navigation

    private var bottomNavigation: some View {
        HStack {
            Spacer()

            Button {
                nextStep()
            } label: {
                if step == 3 && isCreating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "chevron.right")
                        .font(
                            .system(
                                size: 17,
                                weight: .medium
                            )
                        )
                        .foregroundStyle(
                            canContinue
                                ? .white
                                : .white.opacity(0.3)
                        )
                }
            }
            .buttonStyle(.plain)
            .frame(
                width: 44,
                height: 44
            )
            .disabled(
                !canContinue ||
                isCreating
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }

    // MARK: - Continue State

    private var canContinue: Bool {
        if step == 0 {
            return !title
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty
        }

        return true
    }

    // MARK: - Step 1

    private var titleStep: some View {
        VStack(spacing: 28) {
            Spacer()

            Text("What will you explore?")
                .font(
                    .system(
                        size: 24,
                        weight: .medium
                    )
                )
                .foregroundStyle(.white)

            TextField(
                "",
                text: $title
            )
            .font(.system(size: 20))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .tint(.white)
            .padding(.vertical, 14)
            .overlay(
                Rectangle()
                    .fill(.white.opacity(0.2))
                    .frame(height: 1),
                alignment: .bottom
            )
            .padding(.horizontal, 50)
            .placeholder(
                when: title.isEmpty
            ) {
                Text("Enter here")
                    .font(.system(size: 20))
                    .foregroundStyle(.white.opacity(0.25))
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Step 2

    private var durationStep: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 10) {
                Text("How long will you\ngive it?")
                    .font(
                        .system(
                            size: 24,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                VStack(spacing: 2) {
                    Text("\(totalDays)")
                        .font(
                            .system(
                                size: 58,
                                weight: .light
                            )
                        )
                        .foregroundStyle(.white)
                        .frame(
                            width: 150,
                            alignment: .center
                        )
                        .contentTransition(.numericText())
                        .animation(
                            selectionAnimation,
                            value: totalDays
                        )

                    Text("days")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.45))
                }
                .padding(.top, 18)
            }

            Spacer()

            durationSelector

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Duration Selector

    private var durationSelector: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(
                    availableDays.indices,
                    id: \.self
                ) { index in
                    let isSelected =
                        index == selectedDurationIndex

                    Text("\(availableDays[index])")
                        .font(
                            .system(
                                size: isSelected ? 24 : 18,
                                weight: isSelected
                                    ? .medium
                                    : .regular
                            )
                        )
                        .foregroundStyle(
                            .white.opacity(
                                isSelected ? 0.95 : 0.30
                            )
                        )
                        .frame(
                            maxWidth: .infinity,
                            minHeight: 44
                        )
                }
            }
            .overlay(
                Color.clear
                    .frame(
                        width: geometry.size.width,
                        height: 140
                    )
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                let usableWidth =
                                    geometry.size.width

                                guard usableWidth > 0 else {
                                    return
                                }

                                let x = max(
                                    0,
                                    min(
                                        usableWidth,
                                        gesture.location.x
                                    )
                                )

                                let percentage =
                                    x / usableWidth

                                let index = Int(
                                    round(
                                        percentage *
                                        CGFloat(
                                            availableDays.count - 1
                                        )
                                    )
                                )

                                let clampedIndex = max(
                                    0,
                                    min(
                                        availableDays.count - 1,
                                        index
                                    )
                                )

                                let newDays =
                                    availableDays[clampedIndex]

                                if totalDays != newDays {
                                    withAnimation(
                                        selectionAnimation
                                    ) {
                                        totalDays = newDays
                                    }

                                    HapticManager.shared.selection()
                                }
                            }
                    )
            )
        }
        .frame(height: 44)
        .padding(.horizontal, 4)
    }

    private var selectedDurationIndex: Int {
        availableDays.firstIndex(of: totalDays) ?? 2
    }

    // MARK: - Step 3 — Reminder

    private var reminderStep: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 10) {
                Text("When will you\ncheck in?")
                    .font(
                        .system(
                            size: 24,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                if reminderEnabled {
                    reminderTimeDisplay
                } else {
                    Text("No reminder")
                        .font(
                            .system(
                                size: 40,
                                weight: .light
                            )
                        )
                        .foregroundStyle(.white.opacity(0.65))
                        .frame(height: 72)
                        .padding(.top, 18)
                }
            }

            Spacer()

            if reminderEnabled {
                reminderTimePicker
            } else {
                Color.clear
                    .frame(height: 230)
            }

            Spacer()

            reminderToggle

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Large Time Display

    private var reminderTimeDisplay: some View {
        HStack(spacing: 0) {
            Text(
                String(
                    format: "%02d",
                    selectedHour
                )
            )
            .frame(
                width: 82,
                alignment: .trailing
            )

            Text(":")
                .frame(
                    width: 30,
                    alignment: .center
                )
                .foregroundStyle(.white.opacity(0.35))

            Text(
                String(
                    format: "%02d",
                    selectedMinute
                )
            )
            .frame(
                width: 82,
                alignment: .leading
            )
        }
        .font(
            .system(
                size: 58,
                weight: .light
            )
        )
        .foregroundStyle(.white)
        .contentTransition(.numericText())
        .frame(
            width: 194,
            height: 72
        )
        .padding(.top, 18)
    }

    // MARK: - Time Picker

    private var reminderTimePicker: some View {
        HStack(
            alignment: .center,
            spacing: 12
        ) {
            // MARK: Hour Wheel

            CustomWheelComponent(
                range: 0..<24,
                selection: $selectedHour
            )

            // MARK: Colon

            Text(":")
                .font(
                    .system(
                        size: 28,
                        weight: .light
                    )
                )
                .foregroundStyle(.white.opacity(0.35))
                .frame(width: 14)
                .padding(.bottom, 2)

            // MARK: Minute Wheel

            CustomWheelComponent(
                range: 0..<60,
                selection: $selectedMinute
            )
        }
        .frame(height: 230)
        .clipped()
        .onChange(
            of: selectedHour
        ) { _, newValue in
            updateReminderTime(
                hour: newValue,
                minute: selectedMinute
            )

            HapticManager.shared.selection()
        }
        .onChange(
            of: selectedMinute
        ) { _, newValue in
            updateReminderTime(
                hour: selectedHour,
                minute: newValue
            )

            HapticManager.shared.selection()
        }
    }

    // MARK: - Update Time

    private func updateReminderTime(
        hour: Int,
        minute: Int
    ) {
        let calendar = Calendar.current

        guard let newDate =
            calendar.date(
                bySettingHour: hour,
                minute: minute,
                second: 0,
                of: reminderTime
            )
        else {
            return
        }

        withAnimation(
            .easeOut(duration: 0.2)
        ) {
            reminderTime = newDate
        }
    }

    // MARK: - Reminder Toggle

    private var reminderToggle: some View {
        Button {
            withAnimation(
                selectionAnimation
            ) {
                reminderEnabled.toggle()
            }

            HapticManager.shared.light()
        } label: {
            Text(
                reminderEnabled
                    ? "No reminder"
                    : "Set a reminder"
            )
            .font(
                .system(
                    size: 15,
                    weight: .regular
                )
            )
            .foregroundStyle(.white.opacity(0.45))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 4 — Galaxy

    private var galaxyStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("How will your\nuniverse form?")
                .font(
                    .system(
                        size: 24,
                        weight: .medium
                    )
                )
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            GalaxyView(
                style: selectedGalaxy,
                progress: 0,
                isCurrent: true,
                isAnimated: true
            )
            .frame(
                width: 230,
                height: 230
            )
            .id(selectedGalaxy)

            HStack(spacing: 24) {
                ForEach(
                    GalaxyStyle.allCases,
                    id: \.self
                ) { galaxy in
                    let isSelected =
                        selectedGalaxy == galaxy

                    Button {
                        withAnimation(
                            selectionAnimation
                        ) {
                            selectedGalaxy = galaxy
                        }

                        HapticManager.shared.selection()
                    } label: {
                        VStack(spacing: 6) {
                            Circle()
                                .fill(
                                    .white.opacity(
                                        isSelected
                                            ? 0.9
                                            : 0.25
                                    )
                                )
                                .frame(
                                    width: isSelected ? 8 : 5,
                                    height: isSelected ? 8 : 5
                                )

                            Text(galaxy.name)
                                .font(
                                    .system(size: 15)
                                )
                                .foregroundStyle(
                                    .white.opacity(
                                        isSelected
                                            ? 1
                                            : 0.35
                                    )
                                )
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
    }

    // MARK: - Navigation

    private func previousStep() {
        if step > 0 {
            withAnimation(
                .easeInOut(duration: 0.3)
            ) {
                step -= 1
            }
        } else {
            dismiss()
        }
    }

    private func nextStep() {
        if step == 0 {
            withAnimation(
                .easeInOut(duration: 0.3)
            ) {
                step = 1
            }

            return
        }

        if step == 1 {
            withAnimation(
                .easeInOut(duration: 0.3)
            ) {
                step = 2
            }

            return
        }

        if step == 2 {
            requestNotificationPermissionAndContinue()
            return
        }

        if step == 3 {
            createChallenge()
            return
        }
    }

    // MARK: - Notification Permission

    private func requestNotificationPermissionAndContinue() {
        Task { @MainActor in
            if reminderEnabled {
                let granted =
                    await NotificationManager.shared
                        .requestPermission()

                if !granted {
                    print(
                        "Reminder enabled, but notification permission " +
                        "was not granted."
                    )
                }
            }

            withAnimation(
                .easeInOut(duration: 0.3)
            ) {
                step = 3
            }
        }
    }

    // MARK: - Create

    private func createChallenge() {
        guard !isCreating else {
            return
        }

        let cleanTitle =
            title.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleanTitle.isEmpty else {
            return
        }

        isCreating = true

        let calendar = Calendar.current

        let reminderComponents =
            calendar.dateComponents(
                [
                    .hour,
                    .minute
                ],
                from: reminderTime
            )

        let reminderHour =
            reminderComponents.hour
            ?? calendar.component(
                .hour,
                from: .now
            )

        let reminderMinute =
            reminderComponents.minute
            ?? calendar.component(
                .minute,
                from: .now
            )

        // MARK: Complete Existing Active Challenges

        let descriptor = FetchDescriptor<UniverseChallenge>()

        if let existingChallenges =
            try? modelContext.fetch(descriptor) {
            for challenge
            in existingChallenges
            where challenge.status == .active {
                challenge.status = .completed

                NotificationManager.shared
                    .cancelAllReminders(
                        for: challenge
                    )
            }
        }

        // MARK: Start Date

        // The challenge begins at the start of
        // the current calendar day.
        //
        // This means the day boundary is always
        // 00:00 rather than the exact creation time.

        let startDate = calendar.startOfDay(for: .now)

        // MARK: Create Challenge

        let length = ChallengeLength(rawValue: totalDays) ?? .thirty

        let challenge =
            UniverseChallenge(
                title: cleanTitle,
                length: length,
                startDate: startDate,
                galaxy: selectedGalaxy,
                reminderEnabled: reminderEnabled,
                reminderHour: reminderHour,
                reminderMinute: reminderMinute
            )

        modelContext.insert(challenge)

        // MARK: Save

        do {
            try modelContext.save()

            // -------------------------------------------------
            // Widget
            // -------------------------------------------------
            // SwiftData remains the source of truth.
            // WidgetDataWriter creates the widget snapshot
            // from the newly persisted challenge.
            // -------------------------------------------------

            WidgetSyncManager.save(
                challenge: challenge
            )

            // -------------------------------------------------
            // Reminder
            // -------------------------------------------------
            // Only schedule a reminder when the user enabled it.
            // The notification manager checks whether today's
            // challenge day is still upcoming and whether the
            // selected time has already passed.
            // -------------------------------------------------

            if reminderEnabled {
                Task { @MainActor in
                    await NotificationManager.shared
                        .scheduleCurrentReminder(
                            for: challenge
                        )
                }
            }

            dismiss()
        } catch {
            print("Failed to create challenge: \(error)")
            isCreating = false
        }
    }
}

// MARK: - Placeholder

extension View {
    /// Custom placeholder for text fields

    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .center,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder()
                .opacity(
                    shouldShow ? 1 : 0
                )
                .allowsHitTesting(false)

            self
        }
    }
}

// MARK: - Custom Wheel Component

struct CustomWheelComponent: View {
    let range: Range<Int>
    @Binding var selection: Int
    @State private var localSelection: Int?

    private let itemHeight: CGFloat = 46
    private let visibleItems: Int = 5

    private var items: [Int] {
        Array(range)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(
                .vertical,
                showsIndicators: false
            ) {
                VStack(spacing: 0) {
                    // ⚠️ [제거됨] Color.clear 상단 패딩 제거 (범핑의 주원인)

                    ForEach(
                        items,
                        id: \.self
                    ) { value in
                        let currentSelection =
                            localSelection ?? selection

                        let isSelected =
                            currentSelection == value

                        Text(
                            String(
                                format: "%02d",
                                value
                            )
                        )
                        .font(
                            .system(
                                size: 22, // 폰트 크기 고정 (레이아웃 틀 비틀림 방지)
                                weight: isSelected
                                    ? .semibold
                                    : .regular
                            )
                        )
                        .scaleEffect(
                            isSelected ? 1.09 : 1.0
                        ) // 시각적 스케일링 적용
                        .animation(
                            .easeOut(duration: 0.15),
                            value: isSelected
                        )
                        .foregroundStyle(
                            isSelected
                                ? .white
                                : .white.opacity(0.3)
                        )
                        .frame(
                            width: 70,
                            height: itemHeight
                        )
                        .contentShape(Rectangle())
                        .id(value)
                        .geometryGroup() // 개별 기하학적 정렬 보존
                    }

                    // ⚠️ [제거됨] Color.clear 하단 패딩 제거
                }
                .scrollTargetLayout()
            }
            // -------------------------------------------------
            // FIX: 안전 영역 패딩을 지정하여 투명 공백을 완벽 대체합니다.
            // -------------------------------------------------
            // 상단과 하단에 각각 2개 아이템 분량(itemHeight * 2)의 패딩을 주어
            // 00과 마지막 아이템이 정확히 정중앙에 위치할 수 있도록 스크롤 한계를 제한합니다.
            // -------------------------------------------------

            .safeAreaPadding(
                .vertical,
                itemHeight * 2
            )
            .scrollPosition(
                id: Binding<Int?>(
                    get: {
                        localSelection ?? selection
                    },
                    set: { newValue in
                        guard let newValue else {
                            return
                        }

                        guard items.contains(newValue) else {
                            return
                        }

                        localSelection = newValue

                        if selection != newValue {
                            var transaction = Transaction()
                            transaction.disablesAnimations = true

                            withTransaction(transaction) {
                                selection = newValue
                            }
                        }
                    }
                ),
                anchor: .center
            )
            // 정렬 정밀도 고정

            .scrollTargetBehavior(.viewAligned)

            // 휠 관성 오버스크롤 제한

            .scrollBounceBehavior(.basedOnSize)
            .frame(
                width: 65,
                height: itemHeight * CGFloat(visibleItems)
            )
            .clipped()

            // -------------------------------------------------
            // INITIAL POSITION
            // -------------------------------------------------

            .onAppear {
                let initialValue = selection
                localSelection = initialValue

                DispatchQueue.main.async {
                    proxy.scrollTo(
                        initialValue,
                        anchor: .center
                    )
                }
            }

            // -------------------------------------------------
            // EXTERNAL CHANGES
            // -------------------------------------------------

            .onChange(
                of: selection
            ) { oldValue, newValue in
                guard
                    newValue >= range.lowerBound,
                    newValue < range.upperBound
                else {
                    return
                }

                if localSelection == newValue {
                    return
                }

                localSelection = newValue

                DispatchQueue.main.async {
                    proxy.scrollTo(
                        newValue,
                        anchor: .center
                    )
                }
            }

            // -------------------------------------------------
            // TOUCH AREA
            // -------------------------------------------------

            .overlay(
                Color.clear
                    .frame(
                        width: 200,
                        height: itemHeight * CGFloat(visibleItems)
                    )
                    .contentShape(Rectangle())
                    .allowsHitTesting(false)
            )
        }
    }
}

// MARK: - Preview

#Preview("Enter Challenge") {
    NavigationStack {
        EnterChallengeView()
    }
    .modelContainer(
        for: [
            UniverseChallenge.self,
            ChallengeDay.self
        ],
        inMemory: true
    )
}
