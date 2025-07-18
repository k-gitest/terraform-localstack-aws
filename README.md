# TerraformとLocalStackでawsのプロビジョニング
TerraformとLocalStackを使用してawsをコードで管理し自動作成

## 概要
このプロジェクトは、IaCに基づき、awsのs3バケットのプロビジョニングを自動化します。

## 使用技術
- Terraform
- Terraform Cloud
- aws s3
- LocalStack
- Codespaces

## 構成
```text
/
├── .devcontainer/
│   ├── devcontainer.json
│   └── setup.sh
├── terraform/
│   ├── modules/
│   │   ├── s3/                 # S3モジュールのディレクトリ
│   │   │   ├── main.tf         # S3モジュールのリソース定義 (s3バケットなど)
│   │   │   ├── variables.tf    # S3モジュール固有の変数定義
│   │   │   └── outputs.tf      # S3モジュール固有の出力定義
│   │   ├── lambda/
│   │   │   ├── main.tf         # Lambda関数、IAMロール、ポリシー
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   └── s3-lambda-integration/
│   │       ├── main.tf         # S3通知設定、Lambda権限
│   │       ├── variables.tf
│   │       └── outputs.tf
│   ├── main.tf                 # ルートモジュールのmain.tf (modules/s3 を呼び出す)
│   ├── variables.tf            # ルートモジュールの変数定義
│   ├── outputs.tf              # ルートモジュールの出力定義
│   └── provider.tf             # ルートモジュールのプロバイダー定義
├── README.md
└── .gitignore

```

### モジュール

**S3バケット:**

- フロントエンドアプリケーション用の静的ホスティングS3バケット

- ユーザーコンテンツ（プロフィール画像、ユーザー文書、一時アップロードファイル）を保存するための複数のS3バケット（バージョン管理、暗号化、ライフサイクルルールを含む）

**Lambda関数:**

- S3バケットからのイベント（オブジェクト作成など）をトリガーとして実行される、ユーザーコンテンツ処理用のLambda関数

**IAMロールとポリシー:**

- Lambda関数が実行に必要な権限（Basic Execution、S3アクセス）を持つためのIAMロールとポリシー

**S3-Lambda統合:**

- 特定S3バケットからのイベント（例: temp_uploads バケットへのオブジェクト作成）をトリガーとしてLambda関数を呼び出すためのS3イベント通知とLambdaパーミッション

## object_ownershipの分離
aws providerのバージョンアップによりAWS Provider v4.9.0以降はobject_ownershipが単独リソースとなっています。

```terraform
resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.example.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}
```

## aws_s3_bucket_objectが非推奨へ
AWS Provider v4.0以降、aws_s3_bucket_objectが非推奨となりましたので、機能が同じaws_s3_objectを使用する。

```terraform
resource "aws_s3_object" "example" {
  key    = "example.txt"  # aws_s3_objectでは"key"は有効
  bucket = aws_s3_bucket.this.id
}
```

## depends_onで値を保証する
countまたはfor_eachの条件式が、plan実行時に確定できない値に依存している場合、Error: Invalid count argument:が発生します。   
depends_onを使用して値を保証すると解消されますが、使いすぎると複雑な依存関係となるので注意が必要です。

```terraform
depends_on = [aws_lambda_permission.allow_s3_to_invoke_lambda]
```
