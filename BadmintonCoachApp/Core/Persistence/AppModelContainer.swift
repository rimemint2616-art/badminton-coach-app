import Foundation
import SwiftData

enum AppModelContainer {
    /// 実機・シミュレータ用の永続化コンテナ（端末内ローカル保存のみ、クラウド同期なし）。
    static let shared: ModelContainer = {
        let configuration = ModelConfiguration(
            schema: Schema(SchemaV1.models),
            isStoredInMemoryOnly: false
        )
        do {
            let container = try ModelContainer(
                for: Schema(SchemaV1.models),
                migrationPlan: AppMigrationPlan.self,
                configurations: [configuration]
            )
            // 初回起動時のみ既定の学年タグを流し込む（AppModelContainer.previewと同じ理由でnonisolatedなContextを使う）。
            let context = ModelContext(container)
            GradeTag.seedDefaultsIfNeeded(in: context)
            try? context.save()
            return container
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
            // container.mainContext は @MainActor 隔離されており、この静的プロパティの
            // 初期化がメインスレッド外で走るとクラッシュすることがあるため、
            // 隔離されていない ModelContext(container:) を使う。
            let context = ModelContext(container)
            SampleData.seed(into: context)
            // 明示的にsaveしないと、mainContext経由の@Queryからこのサンプルデータが
            // 見えないままになることがある（別コンテキストへの挿入はsaveするまでストアに反映されない）。
            try? context.save()
            return container
        } catch {
            fatalError("Preview用ModelContainerの作成に失敗しました: \(error)")
        }
    }()
}
