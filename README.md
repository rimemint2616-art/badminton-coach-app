# バドコーチ (BadmintonCoachApp)

iPad向けバドミントンコーチ用アプリ。練習試合・大会でのラリーをコート図へのライブタグ入力で記録し、
コーチによる手動フィードバックと合わせてPDFレポートを出力・データベースに蓄積する。
日々の練習スケジュール管理、練習メニュー（ドリル）ライブラリ管理も行う。

開発計画の全体像は `C:\Users\rimem\.claude\plans\ipad-ai-pdf-abundant-moon.md` を参照。

## 現在の実装状況

計画（Phase 0〜5）はすべて実装済み。`RootTabView`から4タブ（生徒／スケジュール／ラリー記録／練習メニュー）すべてに実際の機能が配線されている。

- **Phase 0（土台）**: 完了。XcodeGenによるプロジェクト定義、`ModelContainer`設定、デザインシステム基礎。
- **Phase 1（データ層＋生徒管理）**: 完了。全SwiftDataモデル定義、生徒の一覧・詳細・新規作成・編集・アーカイブ。
- **Phase 2（ラリー記録）**: 完了。コート図タップによるライブタギング（詳細/簡易2モード）、`ScoringRulesEngine`によるスコア自動計算・サーブ権交代・ゲーム/マッチ終了判定、ショット単位/ラリー単位のUndo、試合一覧・詳細（基礎スタッツ・着地ヒートマップ）。
- **Phase 3（フィードバック＋PDF出力）**: 完了。手動フィードバック入力（`Feedback.source`は将来のAI対応に備えて`manual`/`aiGenerated`のenumで拡張可能）、`StatsAggregationService`によるスタッツ集計、`PDFReportGenerator`によるA4 4種ページ構成（表紙／サマリー・Swift Chartsグラフ／試合別詳細・ヒートマップ／フィードバック一覧）のPDF生成、`ReportRecord`としてのDB記録、`ShareLink`共有。
- **Phase 4（スケジュール管理）**: 完了。日付ごとのアジェンダ表示、練習セッションのCRUD、出席生徒の多対多管理、セッションから試合記録・フィードバック追加への導線。
- **Phase 5（練習メニュー管理）**: 完了。ドリルのCRUD・タグ絞り込み・検索・複製、セッションへの割り当て（`SessionDrillItem`、並び替え対応）。
- **Phase 6（AI解析）**: 計画通り未着手。`Feedback.source`enumと構造化済みのShot/Rally enumの上にスキーマ変更なしで追加できる設計になっている。

このプロジェクトはWindows環境で作成されたため、**一度もビルド・実行していません**。SwiftDataの`@Relationship`宣言や各Viewの型整合性は手動でレビュー済みだが、実際のSwiftコンパイラ・Xcodeでの検証はまだ行っていない。
以下の手順でMacに移してビルド・動作確認を行ってください。

## 必要なもの

- Mac（macOS Sonoma以降推奨）
- Xcode 15以降（App StoreまたはApple Developerサイトから入手）
- [Homebrew](https://brew.sh)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)（`.xcodeproj`を`project.yml`から生成するツール）

## セットアップ手順

1. このフォルダ一式（`BadmintonCoachApp/`）をMacにコピーする（AirDrop、USB、GitHub経由など何でも可）。

2. XcodeGenをインストールする（未インストールの場合）:
   ```sh
   brew install xcodegen
   ```

3. プロジェクトフォルダ（`project.yml`があるディレクトリ）に移動し、`.xcodeproj`を生成する:
   ```sh
   cd BadmintonCoachApp
   xcodegen generate
   ```
   これで `BadmintonCoachApp.xcodeproj` が生成されます。

4. `BadmintonCoachApp.xcodeproj` をXcodeで開く:
   ```sh
   open BadmintonCoachApp.xcodeproj
   ```

5. Xcode左上のスキームで「BadmintonCoachApp」を選び、実行先をiPadシミュレータ（例: iPad Pro 13-inch）に設定してビルド・実行する（⌘R）。

6. 初回ビルドで以下のようなエラーが出る可能性があります（Windows上ではSwiftコンパイラで検証していないため）。よくある原因と対処:
   - **SwiftDataの`@Relationship`関連エラー**: `inverse:`のキーパスが正しい型・プロパティ名を指しているか確認する（`Core/Models/`配下の各ファイル）。
   - **AppIconの警告**: `Resources/Assets.xcassets/AppIcon.appiconset` に実際のアイコン画像が入っていないため警告が出ますが、シミュレータでの実行は可能です。後でアイコン画像を追加してください。
   - **Bundle Identifier重複**: `project.yml`の`PRODUCT_BUNDLE_IDENTIFIER`を自分のApple Developer向けの値に変更してください（実機で動かす場合は特に）。

7. ユニットテストを実行する場合は ⌘U 。以下の3ファイルが入っている:
   - `ModelPersistenceTests.swift` — SwiftDataの保存・cascade削除・nullify削除の検証
   - `ScoringRulesEngineTests.swift` — ゲーム/マッチ終了判定、サーブ権交代の純粋ロジック検証
   - `StatsAggregationServiceTests.swift` — ショット種類分布・ラリー打数集計・簡易モードのmanualShotCount優先ロジックの検証

8. 実機での動作確認をする場合、`ラリー記録`タブから試合を1件記録してみて、以下を重点的に確認する（このアプリの最もリスクの高い画面のため）:
   - コート図タップ→ショット種類選択→Winner/Errorでスコアが正しく増え、サーブ権が交代するか
   - 「ショットを取り消し」「ラリーを取り消し」が正しく動くか（特にゲームを決めたラリーを取り消した場合にゲーム数・スコアが正しく巻き戻るか）
   - 21点（デュース、30点キャップ）でゲーム終了・次ゲーム開始・マッチ終了のアラートが正しいタイミングで出るか
   - 「続きを記録」で試合中断→再開時にスコア・サーブ権が正しく復元されるか

## プロジェクト構成を変更した場合

Swiftファイルを追加・削除・フォルダ移動した場合は、`.xcodeproj`を作り直す必要があります:

```sh
xcodegen generate
```

（`.xcodeproj`はGitにコミットせず、`project.yml`とソースファイルだけを管理するのがおすすめです。`.gitignore`に`*.xcodeproj`を追加してください。）

## 既知の制約・今後の改善候補

MVPとして計画の全機能を実装しているが、以下は意図的にスコープ外・簡略化している:

- **ダブルス**: データモデル（`MatchType.doubles`）は用意してあるが、UIはシングルスのみ対応。
- **練習メニューの図解画像**: `PracticeMenu.diagramImage`フィールドはあるが、画像ピッカーUIは未実装。
- **繰り返しスケジュール**: 週次繰り返しなどの自動生成機能はなし（1件ずつ手動作成）。
- **ラリー取り消しのゲーム境界越え**: 「次のゲームを開始」した後に前のゲーム最後のラリーを取り消すことは未対応（同一ゲーム内のUndoは対応済み）。
- **AI解析（Phase 6）**: 未着手。データモデルは対応済みなので、将来LLM API連携などを追加する際にスキーマ変更は不要な想定。
- **PDFレイアウトの微調整**: ページ内の余白・ヒートマップのサイズなどは実機での見た目を見ながらXcode上で調整が必要。

## Xcodeで最初に確認すべきこと

計画ファイル（冒頭のパス参照）にアーキテクチャの詳細がある。次にコードを触るなら、上記の既知の制約から着手するか、実機でのテスト（Undo・スコア計算・PDF出力）で見つかった不具合の修正が優先。
