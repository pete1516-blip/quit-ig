import SwiftUI

extension Color {
    static let okGreen = Color(red: 0.12, green: 0.62, blue: 0.42)
    static let okLight = Color(red: 0.37, green: 0.83, blue: 0.63)
    static let badRed = Color(red: 0.88, green: 0.34, blue: 0.31)
    static let accentPurple = Color(red: 0.42, green: 0.30, blue: 0.96)
}

struct DayRef: Identifiable {
    let date: Date
    var id: String { DayKey.key(date) }
}

struct ContentView: View {
    @EnvironmentObject var store: Store
    @Environment(\.scenePhase) private var scenePhase
    @State private var today = DayKey.today()
    @State private var editDay: DayRef? = nil
    @State private var showSOS = false
    @State private var showMonth = false
    @State private var showReason = false
    @State private var showSettings = false
    @State private var toast: String? = nil

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 14) {
                        heroCard
                        todayCard
                        weekCard
                        statsRow
                        reasonCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 110)
                }
                .background(Color(.systemGroupedBackground))

                Button {
                    showSOS = true
                } label: {
                    Text("😣 อยากเปิด IG ตอนนี้")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 58)
                        .foregroundStyle(.white)
                        .background(Color.accentPurple, in: RoundedRectangle(cornerRadius: 20))
                        .shadow(color: Color.accentPurple.opacity(0.35), radius: 14, y: 8)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

                if let toast {
                    VStack {
                        Text(toast)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(.thinMaterial, in: Capsule())
                        Spacer()
                    }
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .navigationTitle("เลิก IG")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: store.alarmEnabled ? "alarm.fill" : "alarm")
                    }
                }
            }
            .sheet(item: $editDay) { d in
                DayEditSheet(date: d.date) { msg in flash(msg) }
                    .environmentObject(store)
                    .presentationDetents([.height(330)])
            }
            .sheet(isPresented: $showSOS) { SOSView { flash("💪 ห้ามใจได้อีกครั้ง!") }.environmentObject(store) }
            .sheet(isPresented: $showMonth) { MonthView(onTap: { d in showMonth = false; DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { editDay = DayRef(date: d) } }).environmentObject(store) }
            .sheet(isPresented: $showReason) { ReasonSheet().environmentObject(store).presentationDetents([.medium]) }
            .sheet(isPresented: $showSettings) { SettingsView().environmentObject(store) }
        }
        .tint(Color.accentPurple)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { today = DayKey.today() }
        }
    }

    private func flash(_ s: String) {
        withAnimation { toast = s }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { withAnimation { toast = nil } }
    }

    // MARK: Hero ring

    private var heroCard: some View {
        let s = store.streak
        let g = store.nextGoal(s), p = store.prevGoal(s)
        let frac: Double = s == 0 ? 0 : max(0.02, Double(s - p) / Double(max(1, g - p)))
        return VStack(spacing: 10) {
            ZStack {
                Circle().stroke(Color(.systemFill), lineWidth: 16)
                Circle()
                    .trim(from: 0, to: frac)
                    .stroke(LinearGradient(colors: [.okLight, .okGreen], startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.6), value: frac)
                VStack(spacing: 2) {
                    Text("\(s)").font(.system(size: 68, weight: .bold, design: .rounded))
                    Text("วันติดต่อกัน").font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .frame(width: 200, height: 200)
            .padding(.top, 6)
            Group {
                if s == 0 { Text("เริ่มนับวันแรกกันเลย") }
                else { Text("อีก **\(g - s) วัน** ถึงเป้าหมาย \(g) วัน") }
            }
            .font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .card()
    }

    // MARK: Today

    private var todayCard: some View {
        let st = store.status(today)
        return VStack(spacing: 12) {
            if let st {
                HStack(spacing: 14) {
                    Text(st == .ok ? "🎉" : "🌱")
                        .font(.system(size: 30))
                        .frame(width: 58, height: 58)
                        .background((st == .ok ? Color.okGreen : Color.badRed).opacity(0.14), in: RoundedRectangle(cornerRadius: 18))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(st == .ok ? "วันนี้เลิกได้!" : "วันนี้ยังเลิกไม่ได้")
                            .font(.title3.bold())
                            .foregroundStyle(st == .ok ? Color.okGreen : Color.badRed)
                        Text(Messages.pick(st == .ok ? Messages.ok : Messages.bad, seed: DayKey.key(today)))
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                Button("แก้คำตอบวันนี้") { editDay = DayRef(date: today) }
                    .font(.footnote).foregroundStyle(.secondary)
            } else {
                Text(DayKey.thaiDate(today)).font(.footnote).foregroundStyle(.secondary)
                Text("วันนี้เปิด IG ไหม?").font(.title2.weight(.semibold))
                BigButton(title: "💪 ไม่เปิดเลย", style: .ok) {
                    store.set(today, .ok); flash("🎉 บันทึกแล้ว เก่งมาก!")
                }
                BigButton(title: "😅 เผลอเปิด", style: .bad) {
                    store.set(today, .bad); flash("🌱 บันทึกแล้ว พรุ่งนี้เอาใหม่")
                }
                Text("แนะนำให้กดตอนก่อนนอน").font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .card()
        .sensoryFeedback(.success, trigger: store.status(today))
    }

    // MARK: Week

    private var weekCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("7 วันล่าสุด").font(.headline)
                Spacer()
                Button("ดูทั้งเดือน") { showMonth = true }.font(.subheadline.weight(.medium))
            }
            HStack(spacing: 0) {
                ForEach((0..<7).reversed(), id: \.self) { i in
                    let d = DayKey.add(today, -i)
                    Button { editDay = DayRef(date: d) } label: {
                        VStack(spacing: 6) {
                            Text(DayKey.shortDays[DayKey.cal.component(.weekday, from: d) - 1])
                                .font(.caption).foregroundStyle(.secondary)
                            DayDot(day: DayKey.cal.component(.day, from: d), status: store.status(d), isToday: i == 0)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            Legend()
        }
        .padding(20)
        .card()
    }

    // MARK: Stats

    private var statsRow: some View {
        HStack(spacing: 10) {
            StatTile(n: store.best, label: "สถิติสูงสุด")
            StatTile(n: store.totalOK, label: "วันที่เลิกได้")
            StatTile(n: store.urges, label: "ครั้งที่ห้ามใจได้")
        }
    }

    // MARK: Reason

    private var reasonCard: some View {
        Button { showReason = true } label: {
            HStack(alignment: .top, spacing: 12) {
                Text("💭").font(.title3)
                    .frame(width: 42, height: 42)
                    .background(Color.accentPurple.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text("เหตุผลที่อยากเลิก").font(.footnote).foregroundStyle(.secondary)
                    if store.reason.isEmpty {
                        Text("+ เพิ่มเหตุผลของคุณ").foregroundStyle(Color.accentPurple).fontWeight(.medium)
                    } else {
                        Text(store.reason).foregroundStyle(.primary).multilineTextAlignment(.leading)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(18)
            .card()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Components

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
extension View { func card() -> some View { modifier(CardModifier()) } }

struct BigButton: View {
    enum Style { case ok, bad, primary }
    let title: String
    let style: Style
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 19, weight: .semibold))
                .frame(maxWidth: .infinity, minHeight: 60)
                .foregroundStyle(fg)
                .background(bg, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
    private var fg: Color { style == .bad ? .badRed : .white }
    private var bg: Color {
        switch style {
        case .ok: return .okGreen
        case .bad: return Color.badRed.opacity(0.13)
        case .primary: return .accentPurple
        }
    }
}

struct DayDot: View {
    let day: Int
    let status: DayStatus?
    var isToday: Bool = false
    var future: Bool = false
    var size: CGFloat = 40
    var body: some View {
        Text("\(day)")
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(status == nil ? Color.primary : .white)
            .frame(width: size, height: size)
            .background(fill, in: Circle())
            .overlay(Circle().stroke(isToday ? Color.accentPurple : .clear, lineWidth: 2.5).padding(-4))
            .opacity(future ? 0.3 : 1)
    }
    private var fill: Color {
        switch status {
        case .ok: return .okGreen
        case .bad: return .badRed
        case nil: return Color(.tertiarySystemFill)
        }
    }
}

struct Legend: View {
    var body: some View {
        HStack(spacing: 14) {
            Label { Text("เลิกได้") } icon: { Circle().fill(Color.okGreen).frame(width: 9, height: 9) }
            Label { Text("เผลอเปิด") } icon: { Circle().fill(Color.badRed).frame(width: 9, height: 9) }
            Text("แตะวันเพื่อแก้")
        }
        .font(.caption).foregroundStyle(.secondary)
    }
}

struct StatTile: View {
    let n: Int
    let label: String
    var body: some View {
        VStack(spacing: 2) {
            Text("\(n)").font(.system(size: 26, weight: .bold, design: .rounded))
            Text(label).font(.caption).foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .card()
    }
}

enum Messages {
    static let ok = ["อีกหนึ่งวันที่เวลาเป็นของคุณเอง", "ไม่ได้ไถฟีดเลย เก่งมาก!", "สมองจะอยากเล่นน้อยลงทุกวัน", "ทำได้! พรุ่งนี้มาเช็คอีกนะ"]
    static let bad = ["ไม่เป็นไร พรุ่งนี้เริ่มใหม่ได้เสมอ", "พลาดวันเดียวไม่ได้แปลว่าล้มเหลว", "ลองออกจากระบบ IG ไว้ จะเปิดยากขึ้น", "ยังไม่สาย เริ่มนับใหม่พรุ่งนี้"]
    static let tips = ["วางมือถือไว้อีกห้อง แล้วลุกไปดื่มน้ำสักแก้ว", "ทักเพื่อนสักคนโดยตรงแทนการดูสตอรี่", "ออกไปเดินสัก 5 นาที", "หยิบหนังสือขึ้นมาอ่านสัก 2 หน้า", "ยืดเส้นยืดสาย 1 นาที", "จดสิ่งที่อยากดูไว้ แล้วถามตัวเองว่าสำคัญจริงไหม"]
    static func pick(_ a: [String], seed: String) -> String {
        var h: Int32 = 0
        for u in seed.unicodeScalars { h = h &* 31 &+ Int32(truncatingIfNeeded: u.value) }
        return a[Int(h.magnitude) % a.count]
    }
}

// MARK: - Sheets

struct DayEditSheet: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let date: Date
    let done: (String) -> Void
    var body: some View {
        VStack(spacing: 12) {
            Text(DayKey.key(date) == DayKey.key(DayKey.today()) ? "วันนี้" : DayKey.thaiDate(date))
                .font(.title3.weight(.semibold)).padding(.top, 24)
            Text("วันนั้นเปิด IG ไหม?").font(.subheadline).foregroundStyle(.secondary)
            BigButton(title: "💪 ไม่เปิดเลย", style: .ok) { store.set(date, .ok); dismiss(); done("บันทึกแล้ว") }
            BigButton(title: "😅 เปิด", style: .bad) { store.set(date, .bad); dismiss(); done("บันทึกแล้ว") }
            if store.status(date) != nil {
                Button("ล้างคำตอบวันนี้") { store.set(date, nil); dismiss() }
                    .foregroundStyle(.secondary).padding(.top, 4)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .presentationDragIndicator(.visible)
    }
}

struct ReasonSheet: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    var body: some View {
        VStack(spacing: 12) {
            Text("เหตุผลที่อยากเลิก").font(.title3.weight(.semibold)).padding(.top, 24)
            Text("จะโผล่มาเตือนทุกครั้งที่กดปุ่ม \"อยากเปิด IG\"").font(.footnote).foregroundStyle(.secondary)
            TextField("เช่น อยากนอนเร็วขึ้น, เลิกเปรียบเทียบตัวเองกับคนอื่น", text: $text, axis: .vertical)
                .lineLimit(3...6)
                .padding(14)
                .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 16))
            BigButton(title: "บันทึก", style: .primary) {
                store.reason = text.trimmingCharacters(in: .whitespacesAndNewlines); dismiss()
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .onAppear { text = store.reason }
        .presentationDragIndicator(.visible)
    }
}

struct MonthView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let onTap: (Date) -> Void
    @State private var offset = 0

    var body: some View {
        let cal = DayKey.cal
        let today = DayKey.today()
        let comps = cal.dateComponents([.year, .month], from: today)
        let thisMonth = cal.date(from: comps) ?? today
        let first = cal.date(byAdding: .month, value: offset, to: thisMonth) ?? thisMonth
        let lead = cal.component(.weekday, from: first) - 1
        let days = cal.range(of: .day, in: .month, for: first)?.count ?? 30
        let cols = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

        NavigationStack {
            VStack(spacing: 16) {
                HStack {
                    Button { offset -= 1 } label: { Image(systemName: "chevron.left").frame(width: 40, height: 40) }
                    Spacer()
                    Text(DayKey.thaiMonth.string(from: first)).font(.headline)
                    Spacer()
                    Button { offset += 1 } label: { Image(systemName: "chevron.right").frame(width: 40, height: 40) }
                        .opacity(offset < 0 ? 1 : 0).disabled(offset >= 0)
                }
                LazyVGrid(columns: cols, spacing: 8) {
                    ForEach(DayKey.shortDays.map { "h" + $0 }, id: \.self) { h in
                        Text(String(h.dropFirst())).font(.caption).foregroundStyle(.secondary)
                    }
                    ForEach((0..<lead).map { "b\($0)" }, id: \.self) { _ in Color.clear.frame(height: 40) }
                    ForEach(Array(1...days), id: \.self) { n in
                        let d = cal.date(byAdding: .day, value: n - 1, to: first) ?? first
                        let fut = d > today
                        Button { if !fut { onTap(d) } } label: {
                            DayDot(day: n, status: store.status(d), isToday: DayKey.key(d) == DayKey.key(today), future: fut, size: 40)
                        }
                        .buttonStyle(.plain)
                        .disabled(fut)
                    }
                }
                Legend()
                Spacer()
            }
            .padding(20)
            .navigationTitle("ปฏิทิน")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("เสร็จ") { dismiss() } } }
        }
    }
}
