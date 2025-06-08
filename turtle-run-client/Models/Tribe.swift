import SwiftUI

struct Tribe: Identifiable {
    let id: String
    let name: String
    let subtitle: String
    let color: Color
    let icon: String
    let buffs: [Buff]
    let isRecommended: Bool
    
    struct Buff {
        let name: String
        let description: String
        let value: String
    }
}

extension Tribe {
    static let allTribes: [Tribe] = [
        Tribe(
            id: "red",
            name: "붉은귀거북",
            subtitle: "빠른 속도와 민첩성 특화",
            color: Color(red: 0.91, green: 0.3, blue: 0.24), // #e74c3c
            icon: "🔥",
            buffs: [
                Buff(name: "기본 버프", description: "3Km 이상 달릴 시 Shell layer 획득", value: "50%"),
                Buff(name: "페이스 버프", description: "평균 페이스 6'30\"/km 이하 달성 시", value: "35%"),
                Buff(name: "거리 버프", description: "5km 이상 달릴 시 Shell layer 획득", value: "15%")
            ],
            isRecommended: true
        ),
        Tribe(
            id: "yellow",
            name: "사막거북",
            subtitle: "장거리와 지구력 특화",
            color: Color(red: 0.95, green: 0.77, blue: 0.06), // #f1c40f
            icon: "🏜️",
            buffs: [
                Buff(name: "기본 버프", description: "3Km 이상 달릴 시 Shell layer 획득", value: "50%"),
                Buff(name: "페이스 버프", description: "평균 페이스 6'30\"/km 이하 달성 시", value: "20%"),
                Buff(name: "거리 버프", description: "5km 이상 달릴 시 Shell layer 획득", value: "30%")
            ],
            isRecommended: false
        ),
        Tribe(
            id: "blue",
            name: "그리스거북",
            subtitle: "다양한 경로 탐색 특화",
            color: Color(red: 0.2, green: 0.6, blue: 0.86), // #3498db
            icon: "🧭",
            buffs: [
                Buff(name: "기본 버프", description: "3Km 이상 달릴 시 Shell layer 획득", value: "50%"),
                Buff(name: "페이스 버프", description: "평균 페이스 6'30\"/km 이하 달성 시", value: "25%"),
                Buff(name: "거리 버프", description: "5km 이상 달릴 시 Shell layer 획득", value: "15%"),
                Buff(name: "탐사 버프", description: "새로운 경로 30% 이상 포함 시", value: "10%")
            ],
            isRecommended: false
        )
    ]
} 