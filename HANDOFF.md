# 開発引き継ぎドキュメント（Windows → Mac）

このドキュメントは、Windows環境で書き進めてきた「バドコーチ (BadmintonCoachApp)」の開発を、
Mac環境に引き継いで続けるための情報をまとめたものです。Macで作業を始める人は、まずこのファイルを読んでください。

## 1. このアプリは何か

iPad向けバドミントンコーチ用アプリ。

- 練習試合・大会でのラリーを、コート図へのライブタグ入力で記録
- コーチによる手動フィードバック入力（AI解析は将来追加予定、今回はスコープ外）
- 記録データ＋フィードバックからPDFレポートを生成、DBにも記録として蓄積
- 日々の練習スケジュール管理
- 練習メニュー（ドリル）のライブラリ管理

技術スタック: **iPadネイティブアプリ（Swift / SwiftUI / SwiftData、iOS 17+）**。クラウド同期なし、端末内ローカル保存のみ。

元になった開発計画: `C:\Users\rimem\.claude\plans\ipad-ai-pdf-abundant-moon.md`（Windows機のこのパスにあります。Macに移す場合はこのファイルも一緒にコピーすると経緯が分かりやすいです）。

## 2. 現在の状態（正直な進捗）

**コードは計画のPhase 0〜5（データ層／生徒管理／ラリー記録／フィードバック＋PDF出力／スケジュール管理／練習メニュー管理）を全て実装済みです。43本のSwiftファイルで4タブ全てに実際の機能が配線されています。**

しかし、次の点を必ず認識しておいてください：

- **このコードは一度も実機・シミュレータで動かせていません。** Windows環境で書いたため、Swiftコンパイラそのものが一度も走っていません。手動でのレビューはしましたが、実際にビルドが通るかは未検証です。
- SwiftDataの`@Relationship`宣言、View間の型整合性などは目視で入念にチェックしましたが、保証はできません。**Macでの最初の作業は「ともかく一度ビルドを通すこと」です。**

## 3. 未解決の問題：`xcodegen generate` のエラー

Macを使わずWindowsから検証する手段として、GitHub Actions（macOSランナー）でのCIビルドを試みましたが、**未解決のまま中断しています**。ここでの経緯と矛盾点を正直に記録します。

### 経緯

1. 初回コミット（`a4ff64d`）をpushしてCIを実行 → `xcodegen generate` の段階で失敗。
   ```
   Parsing project spec failed: Decoding failed at "path": Nothing found
   ```
2. XcodeGenの`info:`ブロック（`project.yml`のtargetの中）に`path:`が無かったことが原因ではと考え、`path: Generated/Info.plist`を追加（コミット`e16ff49`）。
3. GitHub Actions REST APIで直接そのCI実行結果を確認したところ、**`Generate Xcode project`ステップは成功（success）と表示されており**、実際に失敗していたのは次の`Build for iPad Simulator`ステップだった。
4. ところがユーザーがGitHub上のActions画面を直接見たところ、**「エラーが出ているのはGenerate Xcode projectのところ」**という報告があり、APIで見た結果と食い違っている。

### この矛盾をどう扱うべきか

原因ははっきりしません。考えられる可能性：

- ユーザーが見ていたのが古い実行結果（`a4ff64d`時点のもの）だった
- ブラウザのキャッシュ表示
- 実際に`Generate Xcode project`が別の理由で不安定（毎回同じ結果にならない）

**Macで最初にやるべきこと**は、GitHub Actionsの結果を推測するのをやめて、ローカルで直接確認することです：

```sh
cd BadmintonCoachApp   # project.yml があるディレクトリ
brew install xcodegen
xcodegen generate
```

もしここで同じエラー（`Decoding failed at "path": Nothing found`）が再現したら、以下を疑って`project.yml`を見直してください（XcodeGenの仕様上、`path`が必須なブロック）：

- `targets.*.sources[]` の `path`
- `targets.*.info.path`（Info.plistの出力先。すでに`Generated/Info.plist`を指定済み）
- `targets.*.entitlements.path`（未使用）
- `packages.*.path` / `projectReferences.*.path`（未使用）

現状の`project.yml`は上記すべてに`path`を指定しているように見えるため、それでも失敗する場合は：

- `xcodegen version` で実際のバージョンを確認し、リリースノートで`sources`/`info`まわりの破壊的変更がないか確認する
- `targets.BadmintonCoachApp.scheme:`ブロック（`testTargets`をtarget内に書く書き方）を、より一般的なトップレベルの`schemes:`ブロックに書き換えて切り分ける
- 最悪の場合、`project.yml`を最小構成（1ターゲットのみ、sourcesとinfoだけ）まで削ってから機能を1つずつ足し戻し、どのブロックが原因か二分探索する

### CI自体について

`.github/workflows/ios-build.yml` に、GitHub Actions（`macos-15`ランナー）でXcodeGen生成→ビルド→ユニットテストを自動実行するワークフローを用意してあります。Macでの開発と並行して、pushするたびに自動チェックが走る状態になっています（Actionsタブで確認可能）。ただし前述の通り、この自動チェック自体がまだ安定して成功した実績がないので、過信しないでください。

**未コミットの変更が1つあります**: `.github/workflows/ios-build.yml` に、Homebrewの「tap trust」警告を無効化する環境変数（`HOMEBREW_NO_REQUIRE_TAP_TRUST`など）を追加する変更をローカルで行いましたが、ユーザーの意向でコミットしていません（`git diff`で確認できます）。必要であれば取り込むか、破棄するか判断してください。

## 4. Macでのセットアップ手順

1. このフォルダ（`BadmintonCoachApp/`）一式をMacにコピーする。**推奨は`git clone`** （GitHubにpush済みのため）:
   ```sh
   git clone https://github.com/rimemint2616-art/badminton-coach-app.git
   ```
   もしくはAirDrop等でフォルダを直接コピーしてもよい（その場合`.git`ごとコピーすればこれまでの履歴も引き継げる）。

2. Homebrew・XcodeGenをインストール:
   ```sh
   brew install xcodegen
   ```

3. プロジェクト生成:
   ```sh
   cd BadmintonCoachApp
   xcodegen generate
   ```
   **ここが最初の関門です。** エラーが出たら上記セクション3を参照。

4. Xcodeで開く:
   ```sh
   open BadmintonCoachApp.xcodeproj
   ```

5. スキーム「BadmintonCoachApp」を選択、実行先をiPadシミュレータ（例: iPad Pro 13-inch）にしてビルド・実行（⌘R）。

6. ユニットテスト実行（⌘U）。`Tests/UnitTests/`に3ファイルあります:
   - `ModelPersistenceTests.swift` — SwiftDataの保存・cascade削除・nullify削除
   - `ScoringRulesEngineTests.swift` — スコア計算・サーブ権交代の純粋ロジック
   - `StatsAggregationServiceTests.swift` — スタッツ集計ロジック

7. ファイルを追加・削除・移動したら`xcodegen generate`をやり直す（`.xcodeproj`はGit管理外、`.gitignore`参照）。

## 5. Git/GitHub情報

- リモートリポジトリ: https://github.com/rimemint2616-art/badminton-coach-app （public）
- ブランチ: `main`
- 直近のコミット:
  - `e16ff49` Fix XcodeGen project.yml: add required info.path, add CI diagnostics step
  - `a4ff64d` Initial commit: BadmintonCoachApp iPad app (Phase 0-5)
- Windows機のローカルパス: `C:\Users\rimem\OneDrive\デスクトップ\Python\BadmintonCoachApp`（OneDrive配下なので同期に注意）

## 6. アーキテクチャ概要

詳細は計画ファイル参照。要点のみ：

- **パターン**: MVVM + 薄いServiceレイヤー（過度な抽象化はしない方針）
- **永続化**: SwiftData。`Core/Persistence/SchemaV1.swift`と`AppMigrationPlan.swift`で将来のマイグレーションに備えた構成済み
- **データモデル**（`Core/Models/`）: Student, PracticeSession, Match, Rally, Shot, Feedback, PracticeMenu, SessionDrillItem, ReportRecord
  - Match→Rally→Shotはcascade削除、Student→Match/Feedbackはnullify削除（履歴を残す設計）
  - `Feedback.source`（manual/aiGenerated）は将来のAI解析追加に備えたenum。今回はmanualのみ使用
- **ラリー記録**（`Features/RallyRecording/`）: コート図タップ→ショット種類選択→Winner/Errorのライブタギング。`ScoringRulesEngine`（`Core/Services/`）がスコア・サーブ権・ゲーム/マッチ終了を判定する純粋ロジック
- **PDF生成**（`Core/Services/PDFReportGenerator.swift`）: `ImageRenderer`を`UIGraphicsPDFRenderer`に直接描画する方式。ページViewは`Features/FeedbackReports/Views/ReportPageViews/`
- **プロジェクト生成**: XcodeGen（`project.yml`から`.xcodeproj`を生成、`.xcodeproj`自体はGit管理外）

## 7. 既知の制約・今後の改善候補

- **ダブルス未対応**（データモデルはあるがUIはシングルスのみ）
- **練習メニューの図解画像**: フィールドはあるがピッカーUI未実装
- **繰り返しスケジュール**: 自動生成なし（都度手動作成）
- **ラリー取り消しのゲーム境界越え**: 次のゲームを開始した後に前のゲーム最後のラリーを取り消すことは未対応
- **AI解析（Phase 6）**: 未着手。データモデルは対応済み

## 8. 次にやること（優先順）

1. `xcodegen generate` → Xcodeビルドをローカルで通す（セクション3参照、最優先）
2. ビルドが通ったら、まずラリー記録画面（`LiveTaggingView`）を実機/シミュレータで操作し、スコア計算・Undo・ゲーム終了判定が正しいか確認する（最もリスクの高いUIのため）
3. PDF生成（`ReportGeneratorView`）を試し、レイアウト崩れがあれば`ReportPageViews/`配下のpadding等を調整する
4. 上記で見つかった不具合を修正
5. 余裕があれば「既知の制約」セクションの項目に着手
