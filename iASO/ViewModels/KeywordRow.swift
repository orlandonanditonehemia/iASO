import SwiftUI

// MARK: - Country data

struct AppStoreCountry: Identifiable, Hashable {
    let id: String
    let name: String
    let flag: String
}

let appStoreCountries: [AppStoreCountry] = [
    .init(id: "us", name: "United States", flag: "🇺🇸"),
    .init(id: "gb", name: "United Kingdom", flag: "🇬🇧"),
    .init(id: "au", name: "Australia", flag: "🇦🇺"),
    .init(id: "ca", name: "Canada", flag: "🇨🇦"),
    .init(id: "de", name: "Germany", flag: "🇩🇪"),
    .init(id: "fr", name: "France", flag: "🇫🇷"),
    .init(id: "jp", name: "Japan", flag: "🇯🇵"),
    .init(id: "kr", name: "South Korea", flag: "🇰🇷"),
    .init(id: "cn", name: "China", flag: "🇨🇳"),
    .init(id: "in", name: "India", flag: "🇮🇳"),
    .init(id: "id", name: "Indonesia", flag: "🇮🇩"),
    .init(id: "sg", name: "Singapore", flag: "🇸🇬"),
    .init(id: "my", name: "Malaysia", flag: "🇲🇾"),
    .init(id: "th", name: "Thailand", flag: "🇹🇭"),
    .init(id: "ph", name: "Philippines", flag: "🇵🇭"),
    .init(id: "vn", name: "Vietnam", flag: "🇻🇳"),
    .init(id: "br", name: "Brazil", flag: "🇧🇷"),
    .init(id: "mx", name: "Mexico", flag: "🇲🇽"),
    .init(id: "es", name: "Spain", flag: "🇪🇸"),
    .init(id: "it", name: "Italy", flag: "🇮🇹"),
    .init(id: "nl", name: "Netherlands", flag: "🇳🇱"),
    .init(id: "se", name: "Sweden", flag: "🇸🇪"),
    .init(id: "ru", name: "Russia", flag: "🇷🇺"),
    .init(id: "sa", name: "Saudi Arabia", flag: "🇸🇦"),
    .init(id: "ae", name: "UAE", flag: "🇦🇪"),
    .init(id: "nz", name: "New Zealand", flag: "🇳🇿"),
    .init(id: "hk", name: "Hong Kong", flag: "🇭🇰"),
    .init(id: "tw", name: "Taiwan", flag: "🇹🇼"),
    .init(id: "tr", name: "Turkey", flag: "🇹🇷"),
    .init(id: "pl", name: "Poland", flag: "🇵🇱"),
]

// MARK: - Popularity tooltip data

struct PopularityLevel {
    let range: String
    let label: String
    let advice: String
    let color: Color

    static func forValue(_ v: Int) -> PopularityLevel {
        switch v {
        case 50...:  return .init(range: "50+",   label: "High demand",         advice: "Excellent",  color: .green)
        case 30..<50: return .init(range: "30–49", label: "Good search volume",  advice: "Good",       color: Color(red: 0.5, green: 0.8, blue: 0.2))
        case 15..<30: return .init(range: "15–29", label: "Moderate volume",     advice: "Fair",       color: .orange)
        case 5..<15:  return .init(range: "5–14",  label: "Low volume",          advice: "Low",        color: Color(red: 0.9, green: 0.5, blue: 0.1))
        default:      return .init(range: "<5",    label: "Very few searches",   advice: "Minimal",    color: .red)
        }
    }

    static let allLevels: [PopularityLevel] = [
        .init(range: "50+",   label: "High demand",        advice: "Excellent", color: .green),
        .init(range: "30–49", label: "Good search volume", advice: "Good",      color: Color(red: 0.5, green: 0.8, blue: 0.2)),
        .init(range: "15–29", label: "Moderate volume",    advice: "Fair",      color: .orange),
        .init(range: "5–14",  label: "Low volume",         advice: "Low",       color: Color(red: 0.9, green: 0.5, blue: 0.1)),
        .init(range: "<5",    label: "Very few searches",  advice: "Minimal",   color: .red),
    ]
}

// MARK: - Difficulty tooltip data

struct DifficultyLevel {
    let range: String
    let label: String
    let advice: String
    let color: Color

    static func forValue(_ v: Int) -> DifficultyLevel {
        switch v {
        case 0..<16:  return .init(range: "0–15",   label: "Very Easy",  advice: "Go for it",    color: .green)
        case 16..<36: return .init(range: "16–35",  label: "Easy",       advice: "Good chance",  color: Color(red: 0.5, green: 0.8, blue: 0.2))
        case 36..<56: return .init(range: "36–55",  label: "Moderate",   advice: "Achievable",   color: .orange)
        case 56..<76: return .init(range: "56–75",  label: "Hard",       advice: "Tough",        color: Color(red: 0.9, green: 0.4, blue: 0.1))
        case 76..<91: return .init(range: "76–90",  label: "Very Hard",  advice: "Risky",        color: .red)
        default:      return .init(range: "91–100", label: "Extreme",    advice: "Avoid",        color: Color(red: 0.7, green: 0.0, blue: 0.0))
        }
    }

    static let allLevels: [DifficultyLevel] = [
        .init(range: "0–15",   label: "Very Easy",  advice: "Go for it",   color: .green),
        .init(range: "16–35",  label: "Easy",       advice: "Good chance", color: Color(red: 0.5, green: 0.8, blue: 0.2)),
        .init(range: "36–55",  label: "Moderate",   advice: "Achievable",  color: .orange),
        .init(range: "56–75",  label: "Hard",       advice: "Tough",       color: Color(red: 0.9, green: 0.4, blue: 0.1)),
        .init(range: "76–90",  label: "Very Hard",  advice: "Risky",       color: .red),
        .init(range: "91–100", label: "Extreme",    advice: "Avoid",       color: Color(red: 0.7, green: 0.0, blue: 0.0)),
    ]
}

// MARK: - Opportunity tooltip data

struct OpportunityLevel {
    let range: String
    let label: String
    let advice: String
    let color: Color

    static func forValue(_ v: Int) -> OpportunityLevel {
        switch v {
        case 75...:   return .init(range: "75–100", label: "Excellent opportunity", advice: "Top priority",    color: .green)
        case 55..<75: return .init(range: "55–74",  label: "Good opportunity",      advice: "Worth targeting", color: Color(red: 0.5, green: 0.8, blue: 0.2))
        case 35..<55: return .init(range: "35–54",  label: "Moderate opportunity",  advice: "Consider it",    color: .orange)
        case 15..<35: return .init(range: "15–34",  label: "Low opportunity",       advice: "Risky",          color: Color(red: 0.9, green: 0.4, blue: 0.1))
        default:      return .init(range: "0–14",   label: "Poor opportunity",      advice: "Avoid",          color: .red)
        }
    }

    static let allLevels: [OpportunityLevel] = [
        .init(range: "75–100", label: "Excellent opportunity", advice: "Top priority",    color: .green),
        .init(range: "55–74",  label: "Good opportunity",      advice: "Worth targeting", color: Color(red: 0.5, green: 0.8, blue: 0.2)),
        .init(range: "35–54",  label: "Moderate opportunity",  advice: "Consider it",    color: .orange),
        .init(range: "15–34",  label: "Low opportunity",       advice: "Risky",          color: Color(red: 0.9, green: 0.4, blue: 0.1)),
        .init(range: "0–14",   label: "Poor opportunity",      advice: "Avoid",          color: .red),
    ]
}

// MARK: - Popularity bar with tooltip

// MARK: - Classification badge

struct ClassificationBadge: View {
    let cls: ScoringEngine.KeywordClass

    private var color: Color {
        switch cls {
        case .sweetSpot:       return .green
        case .hiddenGem:       return Color(red: 0.2, green: 0.6, blue: 1.0)
        case .goodTarget:      return Color(red: 0.4, green: 0.8, blue: 0.3)
        case .moderate:        return Color(red: 0.6, green: 0.6, blue: 0.6)
        case .highCompetition: return .orange
        case .lowVolume:       return .secondary
        case .avoid:           return .red
        }
    }

    var body: some View {
        Text(cls.rawValue)
            .font(.system(size: 9, weight: .medium))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

struct PopularityBar: View {
    let value: Int
    @State private var isHovered = false

    private var level: PopularityLevel { PopularityLevel.forValue(value) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2).fill(Color.secondary.opacity(0.15))
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blue.opacity(isHovered ? 1.0 : 0.7))
                    .frame(width: geo.size.width * CGFloat(value) / 100)
                    .animation(.easeInOut(duration: 0.15), value: isHovered)
            }
        }
        .onHover { hovering in isHovered = hovering }
        .popover(isPresented: $isHovered, arrowEdge: .bottom) {
            PopularityTooltip(value: value)
        }
    }
}

// MARK: - Difficulty bar with tooltip

struct DifficultyBar: View {
    let value: Int
    @State private var isHovered = false

    private var level: DifficultyLevel { DifficultyLevel.forValue(value) }

    private var barColor: Color {
        switch value {
        case 0..<36:  return .green.opacity(isHovered ? 1.0 : 0.7)
        case 36..<56: return .orange.opacity(isHovered ? 1.0 : 0.7)
        default:      return .red.opacity(isHovered ? 1.0 : 0.7)
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2).fill(Color.secondary.opacity(0.15))
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor)
                    .frame(width: geo.size.width * CGFloat(value) / 100)
                    .animation(.easeInOut(duration: 0.15), value: isHovered)
            }
        }
        .onHover { hovering in isHovered = hovering }
        .popover(isPresented: $isHovered, arrowEdge: .bottom) {
            DifficultyTooltip(value: value)
        }
    }
}

// MARK: - Popularity tooltip popover

struct PopularityTooltip: View {
    let value: Int
    private var current: PopularityLevel { PopularityLevel.forValue(value) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Popularity")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(value)")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 8)

            Divider()

            // Scale rows
            VStack(spacing: 0) {
                ForEach(PopularityLevel.allLevels, id: \.range) { level in
                    HStack(spacing: 0) {
                        Text(level.range)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(level.range == current.range ? .primary : .secondary)
                            .frame(width: 44, alignment: .leading)

                        Text(level.label)
                            .font(.system(size: 11))
                            .foregroundStyle(level.range == current.range ? .primary : .secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(level.advice)
                            .font(.system(size: 11, weight: level.range == current.range ? .semibold : .regular))
                            .foregroundStyle(level.range == current.range ? level.color : level.color.opacity(0.5))
                            .frame(width: 72, alignment: .trailing)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(level.range == current.range ? level.color.opacity(0.08) : .clear)
                }
            }
            .padding(.bottom, 6)
        }
        .frame(width: 260)
        .background(.background)
    }
}

// MARK: - Difficulty tooltip popover

struct DifficultyTooltip: View {
    let value: Int
    private var current: DifficultyLevel { DifficultyLevel.forValue(value) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Difficulty")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(value)")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 8)

            Divider()

            VStack(spacing: 0) {
                ForEach(DifficultyLevel.allLevels, id: \.range) { level in
                    HStack(spacing: 0) {
                        Text(level.range)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(level.range == current.range ? .primary : .secondary)
                            .frame(width: 52, alignment: .leading)

                        Text(level.label)
                            .font(.system(size: 11))
                            .foregroundStyle(level.range == current.range ? .primary : .secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(level.advice)
                            .font(.system(size: 11, weight: level.range == current.range ? .semibold : .regular))
                            .foregroundStyle(level.range == current.range ? level.color : level.color.opacity(0.5))
                            .frame(width: 72, alignment: .trailing)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(level.range == current.range ? level.color.opacity(0.08) : .clear)
                }
            }
            .padding(.bottom, 6)
        }
        .frame(width: 260)
        .background(.background)
    }
}


// MARK: - Opportunity tooltip popover

struct OpportunityTooltip: View {
    let value: Int
    private var current: OpportunityLevel { OpportunityLevel.forValue(value) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Opportunity")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(value)")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(current.color)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 8)

            Divider()

            VStack(spacing: 0) {
                ForEach(OpportunityLevel.allLevels, id: \.range) { level in
                    HStack(spacing: 0) {
                        Text(level.range)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(level.range == current.range ? .primary : .secondary)
                            .frame(width: 60, alignment: .leading)

                        Text(level.label)
                            .font(.system(size: 11))
                            .foregroundStyle(level.range == current.range ? .primary : .secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(level.advice)
                            .font(.system(size: 11, weight: level.range == current.range ? .semibold : .regular))
                            .foregroundStyle(level.range == current.range ? level.color : level.color.opacity(0.5))
                            .frame(width: 80, alignment: .trailing)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(level.range == current.range ? level.color.opacity(0.08) : .clear)
                }
            }
            .padding(.bottom, 6)
        }
        .frame(width: 280)
        .background(.background)
    }
}

// MARK: - Hoverable opportunity number

struct OpportunityNumber: View {
    let value: Int
    @State private var isHovered = false

    private var color: Color {
        switch value {
        case 75...:   return .green
        case 55..<75: return Color(red: 0.6, green: 0.8, blue: 0.2)
        case 35..<55: return .orange
        default:      return .secondary
        }
    }

    var body: some View {
        Text("\(value)")
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .foregroundStyle(isHovered ? .primary : color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(isHovered ? color.opacity(0.12) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .animation(.easeInOut(duration: 0.1), value: isHovered)
            .onHover { isHovered = $0 }
            .popover(isPresented: $isHovered, arrowEdge: .bottom) {
                OpportunityTooltip(value: value)
            }
    }
}

// MARK: - Hoverable popularity number + bar

struct PopularityNumber: View {
    let value: Int
    @State private var isHovered = false

    private var level: PopularityLevel { PopularityLevel.forValue(value) }
    private var barColor: Color { Color.blue.opacity(isHovered ? 1.0 : 0.7) }

    var body: some View {
        HStack(spacing: 6) {
            Text("\(value)")
                .font(.system(size: 12, design: .monospaced))
                .frame(width: 24, alignment: .trailing)
                .foregroundStyle(isHovered ? level.color : .primary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.secondary.opacity(0.15))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor)
                        .frame(width: geo.size.width * CGFloat(value) / 100)
                }
            }
            .frame(width: 80, height: 4)
        }
        .padding(.horizontal, 6).padding(.vertical, 4)
        .background(isHovered ? level.color.opacity(0.08) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .animation(.easeInOut(duration: 0.12), value: isHovered)
        .onHover { isHovered = $0 }
        .popover(isPresented: $isHovered, arrowEdge: .bottom) {
            PopularityTooltip(value: value)
        }
    }
}

// MARK: - Hoverable difficulty number + bar

struct DifficultyNumber: View {
    let value: Int
    @State private var isHovered = false

    private var level: DifficultyLevel { DifficultyLevel.forValue(value) }
    private var barColor: Color {
        switch value {
        case 0..<36:  return .green.opacity(isHovered ? 1.0 : 0.7)
        case 36..<56: return .orange.opacity(isHovered ? 1.0 : 0.7)
        default:      return .red.opacity(isHovered ? 1.0 : 0.7)
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Text("\(value)")
                .font(.system(size: 12, design: .monospaced))
                .frame(width: 24, alignment: .trailing)
                .foregroundStyle(isHovered ? level.color : .primary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.secondary.opacity(0.15))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor)
                        .frame(width: geo.size.width * CGFloat(value) / 100)
                }
            }
            .frame(width: 80, height: 4)
        }
        .padding(.horizontal, 6).padding(.vertical, 4)
        .background(isHovered ? level.color.opacity(0.08) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .animation(.easeInOut(duration: 0.12), value: isHovered)
        .onHover { isHovered = $0 }
        .popover(isPresented: $isHovered, arrowEdge: .bottom) {
            DifficultyTooltip(value: value)
        }
    }
}

// MARK: - Keyword table

struct KeywordTableView: View {
    let keywords: [Keyword]
    @Binding var country: String
    let isAddingKeyword: Bool
    let onAddKeyword: (String) -> Void
    let onCountryChange: (String) -> Void
    var scoringProgress: String? = nil
    @Binding var useGPT: Bool

    @State private var showAddPopover = false
    @State private var showCountryPicker = false
    @State private var newKeywordText = ""
    @State private var countrySearch = ""

    private var currentCountry: AppStoreCountry {
        appStoreCountries.first { $0.id == country } ?? .init(id: "us", name: "United States", flag: "🇺🇸")
    }
    private var filteredCountries: [AppStoreCountry] {
        countrySearch.isEmpty ? appStoreCountries :
        appStoreCountries.filter {
            $0.name.localizedCaseInsensitiveContains(countrySearch) ||
            $0.id.localizedCaseInsensitiveContains(countrySearch)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            HStack {
                Text("Keywords")
                    .font(.system(size: 13, weight: .semibold))

                if let progress = scoringProgress {
                    HStack(spacing: 5) {
                        ProgressView().controlSize(.mini)
                        Text(progress)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(.secondary.opacity(0.08))
                    .clipShape(Capsule())
                }

                Spacer()

                Button { showAddPopover.toggle() } label: {
                    if isAddingKeyword {
                        ProgressView().controlSize(.mini).frame(width: 16, height: 16)
                    } else {
                        Label("Add Keyword", systemImage: "plus").font(.system(size: 12))
                    }
                }
                .buttonStyle(.bordered).controlSize(.small)
                .popover(isPresented: $showAddPopover, arrowEdge: .bottom) {
                    AddKeywordPopover(text: $newKeywordText,
                        onAdd: {
                            let kw = newKeywordText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !kw.isEmpty else { return }
                            onAddKeyword(kw); newKeywordText = ""; showAddPopover = false
                        },
                        onCancel: { newKeywordText = ""; showAddPopover = false }
                    )
                }

                Button { showCountryPicker.toggle() } label: {
                    HStack(spacing: 4) {
                        Text(currentCountry.flag).font(.system(size: 13))
                        Text(currentCountry.id.uppercased()).font(.system(size: 12, weight: .medium))
                        Image(systemName: "chevron.down").font(.system(size: 9)).foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.bordered).controlSize(.small)
                .popover(isPresented: $showCountryPicker, arrowEdge: .bottom) {
                    CountryPickerPopover(
                        selected: country, searchText: $countrySearch,
                        countries: filteredCountries,
                        onSelect: { c in country = c.id; showCountryPicker = false; countrySearch = ""; onCountryChange(c.id) }
                    )
                }
            }
            .padding(.bottom, 10)

            if keywords.isEmpty && scoringProgress == nil {
                Text("No keywords found")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
            } else {
                HStack(spacing: 0) {
                    Text("Keyword").frame(maxWidth: .infinity, alignment: .leading)
                    Text("Popularity").frame(width: 130, alignment: .leading)
                    Text("Difficulty").frame(width: 130, alignment: .leading)
                    Text("Opportunity").frame(width: 90, alignment: .leading)
                    Text("Position").frame(width: 70, alignment: .leading)
                    Text("Apps in Ranking").frame(width: 160, alignment: .leading)
                }
                .font(.system(size: 11)).foregroundStyle(.secondary)
                .padding(.horizontal, 12).padding(.vertical, 6)

                Divider()

                ForEach(keywords) { kw in
                    KeywordRow(keyword: kw)
                    Divider().padding(.leading, 12)
                }

                if scoringProgress != nil {
                    ForEach(0..<3, id: \.self) { _ in
                        SkeletonRow()
                        Divider().padding(.leading, 12)
                    }
                }
            }
        }
    }
}

// MARK: - Skeleton row

struct SkeletonRow: View {
    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3).fill(.secondary.opacity(0.15))
                .frame(width: 120, height: 10).frame(maxWidth: .infinity, alignment: .leading)
            RoundedRectangle(cornerRadius: 3).fill(.secondary.opacity(0.12))
                .frame(width: 80, height: 4).frame(width: 130, alignment: .leading)
            RoundedRectangle(cornerRadius: 3).fill(.secondary.opacity(0.12))
                .frame(width: 80, height: 4).frame(width: 130, alignment: .leading)
            RoundedRectangle(cornerRadius: 3).fill(.secondary.opacity(0.12))
                .frame(width: 30, height: 10).frame(width: 90, alignment: .leading)
            Spacer()
        }
        .padding(.horizontal, 12).padding(.vertical, 10).opacity(0.6)
    }
}

// MARK: - Add keyword popover

struct AddKeywordPopover: View {
    @Binding var text: String
    let onAdd: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add keyword").font(.system(size: 13, weight: .semibold))
            TextField("e.g. meditation sleep", text: $text)
                .textFieldStyle(.roundedBorder).frame(width: 220)
                .onSubmit { if !text.isEmpty { onAdd() } }
            Text("Keyword will be scored against the current store country.")
                .font(.system(size: 11)).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true).frame(width: 220)
            HStack {
                Button("Cancel", action: onCancel).buttonStyle(.bordered).controlSize(.small)
                Spacer()
                Button("Add") { onAdd() }.buttonStyle(.borderedProminent).controlSize(.small)
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(16)
    }
}

// MARK: - Country picker

struct CountryPickerPopover: View {
    let selected: String
    @Binding var searchText: String
    let countries: [AppStoreCountry]
    let onSelect: (AppStoreCountry) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary).font(.system(size: 12))
                TextField("Search country…", text: $searchText).font(.system(size: 13))
            }
            .padding(.horizontal, 10).padding(.vertical, 8)
            Divider()
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(countries) { country in
                        Button { onSelect(country) } label: {
                            HStack(spacing: 8) {
                                Text(country.flag).font(.system(size: 15))
                                Text(country.name).font(.system(size: 13)).foregroundStyle(.primary)
                                Spacer()
                                if country.id == selected {
                                    Image(systemName: "checkmark").font(.system(size: 11, weight: .semibold)).foregroundStyle(.blue)
                                }
                            }
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(country.id == selected ? Color.blue.opacity(0.08) : .clear)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.leading, 40)
                    }
                }
            }
            .frame(width: 260, height: 320)
        }
    }
}

// MARK: - Keyword row

struct KeywordRow: View {
    let keyword: Keyword
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                HStack(spacing: 6) {
                    Text(keyword.term).font(.system(size: 13))
                    ClassificationBadge(cls: keyword.classification)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                PopularityNumber(value: keyword.popularity)
                    .frame(width: 130, alignment: .leading)

                DifficultyNumber(value: keyword.difficulty)
                    .frame(width: 130, alignment: .leading)

                OpportunityNumber(value: keyword.opportunity)
                    .frame(width: 90, alignment: .leading)

                Group {
                    if let pos = keyword.position {
                        HStack(spacing: 3) {
                            Image(systemName: "trophy.fill").font(.system(size: 9))
                                .foregroundStyle(pos <= 3 ? .yellow : .secondary)
                            Text("\(pos)").font(.system(size: 12, weight: .medium))
                                .foregroundStyle(pos <= 5 ? .green : .secondary)
                        }
                    } else {
                        Text("# —").font(.system(size: 12)).foregroundStyle(.tertiary)
                    }
                }.frame(width: 70, alignment: .leading)

                HStack(spacing: -6) {
                    ForEach(keyword.topApps.prefix(5)) { app in
                        AsyncImage(url: URL(string: app.artworkUrl60 ?? "")) { img in img.resizable() }
                        placeholder: { RoundedRectangle(cornerRadius: 6).fill(.quaternary) }
                        .frame(width: 24, height: 24)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(nsColor: .windowBackgroundColor), lineWidth: 1.5))
                    }
                    if keyword.topApps.count > 5 {
                        Text("+\(min(keyword.topApps.count - 5, 999))")
                            .font(.system(size: 10)).foregroundStyle(.secondary).padding(.leading, 10)
                    }
                }.frame(width: 160, alignment: .leading)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .contentShape(Rectangle())
            .onTapGesture { withAnimation(.easeInOut(duration: 0.15)) { isExpanded.toggle() } }

            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(keyword.topApps.enumerated()), id: \.element.id) { index, app in
                        HStack(spacing: 10) {
                            Text("#\(index + 1)").font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.tertiary).frame(width: 28, alignment: .trailing)
                            AsyncImage(url: URL(string: app.artworkUrl60 ?? "")) { img in img.resizable() }
                            placeholder: { RoundedRectangle(cornerRadius: 8).fill(.quaternary) }
                            .frame(width: 32, height: 32).clipShape(RoundedRectangle(cornerRadius: 8))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(app.trackName).font(.system(size: 12, weight: .medium)).lineLimit(1)
                                Text(app.artistName).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(1)
                            }
                            Spacer()
                            if let count = app.userRatingCount, count > 0 {
                                HStack(spacing: 3) {
                                    Image(systemName: "star.fill").font(.system(size: 9)).foregroundStyle(.yellow)
                                    Text(formatCount(count)).font(.system(size: 11)).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        if index < keyword.topApps.count - 1 { Divider().padding(.leading, 52) }
                    }
                }
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(.horizontal, 12).padding(.bottom, 8)
            }
        }
        .background(isExpanded ? Color(nsColor: .controlBackgroundColor).opacity(0.3) : .clear)
    }

    private func oppColor(_ v: Int) -> Color {
        v >= 80 ? .green : v >= 60 ? Color(red: 0.6, green: 0.8, blue: 0.2) : v >= 40 ? .orange : .secondary
    }
    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 { return String(format: "%.1fM", Double(count) / 1_000_000) }
        if count >= 1_000 { return String(format: "%.1fK", Double(count) / 1_000) }
        return "\(count)"
    }
}
