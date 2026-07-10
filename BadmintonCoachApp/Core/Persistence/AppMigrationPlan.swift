import SwiftData

enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    /// v1のみなのでステージなし。将来 SchemaV2 を追加したらここに
    /// MigrationStage.lightweight/custom を追加する。
    static var stages: [MigrationStage] {
        []
    }
}
