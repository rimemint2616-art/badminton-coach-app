import SwiftData

enum AppModelContainer {
    /// 実機・シミュレータ用の永続化コンテナ（端末内ローカル保存のみ、クラウド同期なし）。
    static let shared: ModelContainer = {
        let configuration = ModelConfiguration(
            schema: Schema(SchemaV1.models),
            isStoredInMemoryOnly: false
        )
        do {
            return try ModelContainer(
                for: Schema(SchemaV1.models),
                migrationPlan: AppMigrationPlan.self,
                configurations: [configuration]
            )
        } catch {
            fatalError("ModelContainerの作成に失敗しました: \(error)")
        }
    }()

    /// SwiftUI Preview / テスト用のインメモリコンテナ。サンプルデータを流し込んで使う。
    static var preview: ModelContainer = {
        let configuration = ModelConfiguration(
            schema: Schema(SchemaV1.models),
            isStoredInMemoryOnly: true
        )
        do {
            let container = try ModelContainer(
                for: Schema(SchemaV1.models),
                migrationPlan: AppMigrationPlan.self,
                configurations: [configuration]
            )
            SampleData.seed(into: container.mainContext)
            return container
        } catch {
            fatalError("Preview用ModelContainerの作成に失敗しました: \(error)")
        }
    }()
}
