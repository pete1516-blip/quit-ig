import SwiftUI

struct SOSView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let onResisted: () -> Void

    @State private var remaining = 600
    @State private var elapsed = 0
    @State private var breathe = false
    @State private var tip = Messages.tips.randomElement() ?? ""
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 16) {
            Text("หายใจช้าๆ ก่อนนะ").font(.title2.weight(.semibold)).padding(.top, 28)
            Text("ความอยากมักจะหายไปเองภายใน 10 นาที").font(.subheadline).foregroundStyle(.secondary)

            ZStack {
                Circle().fill(Color.accentPurple.opacity(0.12))
                    .scaleEffect(breathe ? 1 : 0.72)
                Circle().fill(Color.accentPurple.opacity(0.18))
                    .padding(30)
                    .scaleEffect(breathe ? 1 : 0.72)
                Text(remaining > 0 ? String(format: "%d:%02d", remaining / 60, remaining % 60) : "🎉")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .frame(width: 190, height: 190)
            .onAppear {
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) { breathe = true }
            }
            Text(remaining <= 0 ? "ครบ 10 นาทีแล้ว เก่งมาก!" : ((elapsed % 8) < 4 ? "หายใจเข้า…" : "หายใจออก…"))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.accentPurple)

            VStack(alignment: .leading, spacing: 8) {
                if !store.reason.isEmpty {
                    (Text("คุณอยากเลิกเพราะ ").foregroundStyle(.secondary) + Text(store.reason).bold())
                        .font(.footnote)
                }
                Text(tip)
                Button("ขอไอเดียอื่น →") {
                    var n = tip
                    while n == tip { n = Messages.tips.randomElement() ?? tip }
                    tip = n
                }
                .font(.footnote.weight(.medium))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 18))

            Spacer()
            BigButton(title: "💪 ผ่านไปได้แล้ว ไม่เปิด", style: .primary) {
                store.urges += 1
                dismiss()
                onResisted()
            }
            Button("ปิด") { dismiss() }.foregroundStyle(.secondary).padding(.bottom, 8)
        }
        .padding(.horizontal, 20)
        .presentationDragIndicator(.visible)
        .onReceive(ticker) { _ in
            if remaining > 0 { remaining -= 1; elapsed += 1 }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var time = Date()
    @State private var enabled = false
    @State private var busy = false
    @State private var message: String? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("ปลุกทุกวันให้มาเช็คอิน", isOn: $enabled)
                    if enabled {
                        DatePicker("เวลา", selection: $time, displayedComponents: .hourAndMinute)
                            .environment(\.locale, Locale(identifier: "th_TH"))
                    }
                } footer: {
                    Text("ปลุกแบบนาฬิกาปลุก ดังแม้ล็อกจอหรือเปิดโหมดเงียบ กด \"เช็คอิน\" บนหน้าปลุกเพื่อเปิดแอพ")
                }
                if let message {
                    Section { Text(message).font(.footnote) }
                }
            }
            .navigationTitle("นาฬิกาปลุก")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("ยกเลิก") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(busy ? "กำลังตั้ง…" : "บันทึก") { Task { await apply() } }.disabled(busy)
                }
            }
            .onAppear {
                enabled = store.alarmEnabled
                var c = DateComponents(); c.hour = store.alarmHour; c.minute = store.alarmMinute
                time = DayKey.cal.date(from: c) ?? Date()
            }
        }
    }

    private func apply() async {
        busy = true
        defer { busy = false }
        let c = DayKey.cal.dateComponents([.hour, .minute], from: time)
        let h = c.hour ?? 19, m = c.minute ?? 30
        if !enabled {
            await AlarmService.cancel(store.alarmID)
            store.alarmID = nil
            store.alarmEnabled = false
            dismiss()
            return
        }
        do {
            let (id, mode) = try await AlarmService.schedule(hour: h, minute: m, replacing: store.alarmID)
            store.alarmID = id
            store.alarmHour = h
            store.alarmMinute = m
            store.alarmEnabled = true
            if mode == .alarm {
                dismiss()
            } else {
                message = "ตั้งเป็นแจ้งเตือนธรรมดาแทน (ระบบปลุกเต็มจอใช้ไม่ได้ในเครื่องนี้ หรือยังไม่อนุญาต) ไปอนุญาตได้ที่ ตั้งค่า → เลิก IG"
            }
        } catch {
            message = "ตั้งไม่สำเร็จ: ยังไม่ได้อนุญาตให้แอพปลุกหรือแจ้งเตือน ไปเปิดได้ที่ ตั้งค่า → เลิก IG"
        }
    }
}
