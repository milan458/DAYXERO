import DayXeroCore
import Foundation
import SwiftData

/// Reads and writes program v2 progress and saved answers. Everything stays on the phone.
@MainActor
struct ProgramStore {
    let context: ModelContext
    let profile: UserProfile

    var content: ProgramContent? { ProgramContent.bundled }

    var clock: DayClock { DayClock(boundaryHour: profile.dayBoundaryHour) }

    var variant: ProgramVariant { ProgramVariant(profile.primaryProduct?.product ?? .cigarettes) }

    /// An NRT plan set up in the NRT co-pilot that hasn't finished yet.
    func nrtActive(now: Date = .now) -> Bool {
        profile.nrtPlans.contains { plan in
            guard let end = StepSchedule(startDate: plan.startDate, steps: plan.steps, clock: clock).end else { return false }
            return clock.day(containing: now) <= end
        }
    }

    // MARK: Sessions

    func records() -> [SessionRecord] {
        (try? context.fetch(FetchDescriptor<SessionRecord>())) ?? []
    }

    func record(_ sessionId: String) -> SessionRecord? {
        var descriptor = FetchDescriptor<SessionRecord>(predicate: #Predicate { $0.sessionId == sessionId })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    func unlockRecords() -> [String: ProgramUnlock.Record] {
        Dictionary(records().map { ($0.sessionId, ProgramUnlock.Record(startedAt: $0.startedAt, completedAt: $0.completedAt)) },
                   uniquingKeysWith: { a, _ in a })
    }

    func unlock() -> ProgramUnlock? {
        content.map { ProgramUnlock(content: $0, clock: clock) }
    }

    func states(now: Date = .now) -> [(id: String, state: ProgramUnlock.State)] {
        let records = unlockRecords()
        let states = unlock()?.states(records: records, quitDay: profile.quitDay, quitTimestamp: profile.progress?.quitTimestamp, now: now) ?? []
        guard DemoMode.isOn else { return states }
        // Demo mode: every session open at any time, in any order.
        return states.map { item -> (id: String, state: ProgramUnlock.State) in
            if case .completed = item.state { return item }
            let open: ProgramUnlock.State = records[item.id]?.startedAt != nil ? .inProgress : .available
            return (id: item.id, state: open)
        }
    }

    func state(of sessionId: String, now: Date = .now) -> ProgramUnlock.State {
        states(now: now).first { $0.id == sessionId }?.state ?? .locked
    }

    func current(now: Date = .now) -> (id: String, state: ProgramUnlock.State)? {
        states(now: now).first {
            if case .completed = $0.state { return false }
            return true
        }
    }

    /// Opens a session: its record if it has one, a new one otherwise. A session left unfinished under older content
    /// restarts from its first activity after the audio, keeping saved answers.
    func open(_ session: ProgramContent.Session, firstStepAfterAudio: Int) -> SessionRecord {
        let version = content?.version ?? ""
        if let existing = record(session.id) {
            if existing.completedAt == nil, existing.contentVersion != version {
                existing.currentStep = min(existing.currentStep, firstStepAfterAudio)
                existing.contentVersion = version
            }
            return existing
        }
        let record = SessionRecord(sessionId: session.id, contentVersion: version)
        context.insert(record)
        try? context.save()
        return record
    }

    func complete(_ sessionId: String, at date: Date = .now) {
        guard let record = record(sessionId), record.completedAt == nil else { return }
        record.completedAt = date
        try? context.save()
    }

    // MARK: Answers

    func answer(_ key: String) -> ProgramAnswerValue? {
        var descriptor = FetchDescriptor<ProgramAnswer>(predicate: #Predicate { $0.key == key })
        descriptor.fetchLimit = 1
        if let saved = try? context.fetch(descriptor).first?.value { return saved }
        // Onboarding's reasons live on the profile until the program saves its own list.
        if key == "reasons" {
            let reasons = profile.reasons.sorted { $0.createdAt < $1.createdAt }.map(\.text).filter { !$0.isEmpty }
            return reasons.isEmpty ? nil : .list(reasons)
        }
        return nil
    }

    func save(_ key: String, _ value: ProgramAnswerValue, session: String) {
        var descriptor = FetchDescriptor<ProgramAnswer>(predicate: #Predicate { $0.key == key })
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor).first {
            existing.value = value
            existing.sessionId = session
            existing.updatedAt = .now
        } else {
            context.insert(ProgramAnswer(key: key, value: value, sessionId: session))
        }
        try? context.save()
    }

    func beatRecord(session: String, beat: String) -> BeatRecord? {
        var descriptor = FetchDescriptor<BeatRecord>(predicate: #Predicate { $0.sessionId == session && $0.beatId == beat })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    func finishBeat(session: String, beat: String, skipped: Bool = false, value: ProgramAnswerValue? = nil) {
        if let existing = beatRecord(session: session, beat: beat) {
            existing.completedAt = .now
            existing.skipped = skipped
            if let value { existing.valueData = try? JSONEncoder().encode(value) }
        } else {
            context.insert(BeatRecord(sessionId: session, beatId: beat, skipped: skipped, value: value))
        }
        try? context.save()
    }

    /// Sets what a commit beat names: `quit_timestamp` starts Day Xero, `graduated_at` the graduation.
    func commit(_ key: String, at date: Date = .now) {
        let progress = profile.progress ?? {
            let p = ProgramProgress()
            profile.progress = p
            return p
        }()
        switch key {
        case "quit_timestamp":
            progress.quitTimestamp = date
            // The counter starts today if Day Xero comes later than the Quit Day first chosen.
            if clock.day(containing: date) > clock.startOfDate(profile.quitDay) { profile.quitDay = clock.day(containing: date) }
        case "graduated_at": progress.graduatedAt = date
        default: break
        }
        save(key, .date(date), session: "")
        try? context.save()
    }

    // MARK: Missions

    func missionShown(_ sessionId: String) {
        var descriptor = FetchDescriptor<MissionRecord>(predicate: #Predicate { $0.sessionId == sessionId })
        descriptor.fetchLimit = 1
        guard (try? context.fetch(descriptor).first) == nil else { return }
        context.insert(MissionRecord(sessionId: sessionId))
        try? context.save()
    }

    // MARK: Placeholders

    /// The numbers on-screen text can show. Anything unknown is left out, so its line is dropped rather than shown with braces.
    func placeholders(now: Date = .now) -> ProgramPlaceholders {
        var values: [String: String] = [:]
        let primary = profile.primaryProduct
        let product = primary?.product ?? .cigarettes
        values["unit_plural"] = String(localized: product.unit)
        values["unit_singular"] = switch product {
        case .cigarettes: String(localized: "cigarette")
        case .vape: String(localized: "puff")
        case .pouches: String(localized: "pouch")
        }
        if let primary {
            values["daily_units"] = Int(primary.unitsPerDay.rounded()).formatted()
            values["yearly_units"] = Int((primary.unitsPerDay * 365).rounded()).formatted()
        }
        values["currency"] = Currency.symbol(profile.currencyCode)
        let stats = ProgressStats(quitDay: profile.quitDay, baselines: profile.products.map(\.baseline), clock: clock)
        let yearly = NSDecimalNumber(decimal: stats.moneyPerYear).doubleValue
        if yearly > 0 { values["yearly_cost"] = Int(yearly.rounded()).formatted() }
        values["quit_date"] = profile.quitDay.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        if case let .text(reason)? = answer("primary_reason") { values["primary_reason"] = reason }
        values["days_free"] = stats.daysClear(at: now).formatted()
        values["money_kept"] = NSDecimalNumber(decimal: stats.moneyKept(at: now)).doubleValue
            .formatted(.currency(code: profile.currencyCode).precision(.fractionLength(0)))
        let cravings = (try? context.fetch(FetchDescriptor<LogEntry>())) ?? []
        values["cravings_ridden"] = cravings.filter { $0.kind == .craving && $0.outcome == .passed }.count.formatted()
        return ProgramPlaceholders(values)
    }
}
