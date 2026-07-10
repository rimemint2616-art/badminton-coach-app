import SwiftData

/// アプリの初期スキーマ。将来スキーマを変更する際は SchemaV2 を追加し、
/// AppMigrationPlan にマイグレーションステージを足していく。
enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            Student.self,
            PracticeSession.self,
            Match.self,
            Rally.self,
            Shot.self,
            Feedback.self,
            PracticeMenu.self,
            SessionDrillItem.self,
            ReportRecord.self
        ]
    }
}
