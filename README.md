# TerraformとLocalStackを用いたAWS環境（S3, Lambda, Amplify）のIaCプロビジョニング
TerraformとLocalStackを使用してawsをコードで管理し自動作成

## 概要
このプロジェクトは、**Infrastructure as Code (IaC)** の原則に基づき、**Terraform** と **LocalStack** を活用してAWS環境のプロビジョニングを自動化します。特に、S3バケット、Lambda関数、Amplifyアプリケーションといった主要なAWSリソースの定義とデプロイをコードで管理することで、開発・検証プロセスの効率化と一貫性の確保を目指します。

LocalStackを用いることで、ローカル環境でAWSサービスをエミュレートし、本番環境へのデプロイ前に安全かつ迅速なテストを行うことが可能です。

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
│   ├── environments/ # 環境ごとのプロバイダー
│   │   ├── local/      
│   │   │   ├── provider.tf      
│   │   │   ├── main.tf # モジュール呼び出し(terraform/main.tf)
│   │   │   └── variables.tf  
│   │   ├── dev/      
│   │   │   ├── provider.tf      
│   │   │   ├── main.tf
│   │   │   └── variables.tf  
│   │   └── prod/      
│   │       ├── provider.tf      
│   │       ├── main.tf
│   │       └── variables.tf  
│   ├── modules/
│   │   ├── s3/                 # S3モジュールのディレクトリ
│   │   │   ├── main.tf         # S3モジュールのリソース定義 (s3バケットなど)
│   │   │   ├── variables.tf    # S3モジュール固有の変数定義
│   │   │   └── outputs.tf      # S3モジュール固有の出力定義
│   │   ├── lambda/
│   │   │   ├── main.tf         # Lambda関数、IAMロール、ポリシー
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── s3-lambda-integration/ # S3とLambdaの連携モジュールのディレクトリ
│   │   │   ├── main.tf         # S3通知設定、Lambda権限
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── amplify/            # Amplifyモジュールのディレクトリ
│   │   │   ├── main.tf         # Amplifyアプリケーション、ブランチなどの定義
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── ecr/                # コンテナイメージのリポジトリ
│   │   │   ├── main.tf         # ECRリポジトリとライフサイクルポリシーなど
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── ecs-cluster/        # ECS クラスター定義 (EC2/Fargate 両対応)
│   │   │   ├── main.tf         # クラスター、CloudWatchログ設定など
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── ecs-service-fargate/  # Fargateサービス専用
│   │   │   ├── main.tf         # Fargateタスク定義、サービス、ALBターゲット登録等
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   └── network/            # VPC・ネットワーク関連一式（サブネット, SG等含む）
│   │       ├── main.tf         # VPC, IGW, Subnet, Route Table, Security Groupなどの構成
│   │       ├── variables.tf
│   │       └── outputs.tf
│   ├── main.tf                 # ルートモジュールのmain.tf (modules/ を呼び出す)
│   ├── variables.tf            # ルートモジュールの変数定義
│   └── outputs.tf              # ルートモジュールの出力定義
├── README.md
├── Makefile
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

- 特定S3バケットからのイベント（例: temp_uploadsバケットへのオブジェクト作成）をトリガーとしてLambda関数を呼び出すためのS3イベント通知とLambdaパーミッション

**Amplifyアプリケーション:**

- Webアプリケーションのホスティングとデプロイを管理するためのAmplifyアプリケーション。

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

## S3静的ホスティングにおける環境変数とシークレット管理

AWS S3の静的ホスティングでは、環境変数やシークレットの設定機能がありません。
フロントエンドアプリケーションをS3で公開する場合、環境変数の値は以下の方法で設定できます：

1. **ビルド時埋め込み**: CI/CDパイプラインでビルド時に環境変数を直接埋め込む
2. **ランタイム取得**: アプリケーション起動時にAPI（Lambda/Edge等）から動的に取得する

### セキュリティ上の注意点

フロントエンドで機密情報を環境変数に設定することは推奨されません。もし現在そのような設計になっている場合は、以下の点を見直してください：

- **外部サービスのAPIキー**: 公開しても安全かを確認し、必要に応じてドメイン制限やスコープ制限を設定
- **データベースアクセス**: Supabaseのanon keyなど、公開前提のキーでもRLS（Row Level Security）等でセキュリティを確保
- **認証やサービスキーなどの機密情報**: サーバーサイドでのみ使用し、フロントエンドには含めない

### 推奨アプローチ

AWS公式では、S3単体でのホスティングよりもAmplifyでの統合ホスティングを推奨しています。   
AmplifyもS3をベースとした静的ホスティングサービスですが、CloudflareやNetlify、Vercelなどと同様の環境変数・シークレット管理機能を提供しています：

- **Amplify Gen2**: 統合された環境変数・シークレット管理機能
- **Amplify Gen1**: AWS Systems Manager Parameter Storeとの連携

これにより、セキュアな設定管理とシンプルなデプロイを両立できます。
S3からParameter Storeへのアクセス、CI環境からS3へのアクセス権などのIAM管理も煩雑になりません。

### S3でのSSR
S3は静的なファイル配信に特化しているため、Node.jsなどのサーバー実行環境を必要とするSSRには直接対応していません。

* **JAMStackやBFFなど、バックエンドと明確に分離された構成のSSR**:
    この場合は、S3で静的アセットをホストしつつ、SSRのロジックは別のサーバーレスサービス（Lambda@Edgeなど）で実行することで対応可能です。
* **Next.jsのApp Routerなど、サーバーサイドの実行環境を必要とする機能**:
    これらの機能を含むアプリケーションをS3で静的ホスティングすることはできません。これらの機能で機密情報を扱う場合は、VercelやNetlifyのような専用のサーバー環境、またはAWS Amplifyのような統合ホスティングサービスへの移行を検討する必要があります。

## Terraform CloudとLocalStackの接続エラー

**問題**: Terraform Cloudの実行環境から`localhost:4566`にアクセスできない。`connection refused`エラーがでます。

**解決方法**:
1. プロバイダーからcloudブロック削除/コメントアウト
2. `terraform init`（出来ない場合は`.terraform`削除してから再実行）
3. Terraform Cloud上の変数をターミナルに手動入力

```bash
# cloudブロック削除後
rm -rf .terraform
terraform init
export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"
```

## LocalStackでのサービス制限について

このプロジェクトではLocalStackを利用したローカル開発・テストをサポートしていますが、LocalStackの無料コミュニティ版では一部のAWSサービスが未サポートまたは機能が限定されているため、`terraform apply`時にエラーが発生する可能性があります。

**エラー例**:
```
Error: creating Amplify App: StatusCode: 501, api error InternalFailure: 
The API for service 'amplify' is either not included in your current license plan

Error: creating ECR Repository: operation error ECR: CreateRepository, https response error StatusCode: 501, RequestID: xxx, api error InternalFailure: The API for service 'ecr' is either not included in your current license plan or has not yet been emulated by LocalStack.

Error: creating ECS Cluster: operation error ECS: CreateCluster, https response error StatusCode: 501, RequestID: xxx, api error InternalFailure: The API for service 'ecs' is either not included in your current license plan or has not yet been emulated by LocalStack. 
```

### workspaceを使用してリソース作成を除外
このプロジェクトでは、Terraformの**ワークスペース (`terraform workspace`)** 機能を利用して、開発環境 (LocalStack) と本番環境で同じ Terraformコードを使用できるようにしています。   
terraform workspace new localでlocalワークスペースを作成し、LocalStackでサポートされていないリソースの作成自体を制御しています。

例：
```
count = terraform.workspace == "local" ? 0 : 1
```

**LocalStack 環境でのプロバイダー設定:**
`terraform workspace select local` を実行した場合、`providers.tf` 内で定義されている `endpoints`ブロックが有効になり、AWS の各サービスは `http://localhost:4566` (LocalStack) を参照するようになります。

例：
```
dynamic "endpoints" {
    for_each = terraform.workspace == "local" ? ["local"] : []
    content {
      s3       = "http://localhost:4566"
```

**注意**:
terraform workspaceはディレクトリ単位で設定します。   
environments内の環境ごとで分けている場合、ルートではなくlocal内でterraform workspace new localをしなければ環境が切り替わりませんので注意しましょう。

### workspaceを使用しない場合
workspaceなどで分岐しない場合、個別にenvironment変数などで条件分岐をする必要があります。   
この場合、各リソースやモジュールの出力の参照時に配列インデックス ([0]) や try() 関数を用いた詳細な条件分岐が必要となり、Terraformコード全体が複雑化するため、あまり推奨されません。

## LocalStack固有の設定

### s3_use_path_style の設定
LocalStackでS3を使用する場合、`s3_use_path_style = true` の設定が必要です。これは、S3のURLスタイルを以下のように変更します：

- **Virtual hosted-style** (AWS標準): `https://bucket-name.s3.amazonaws.com/key`
- **Path-style** (LocalStack用): `https://s3.amazonaws.com/bucket-name/key`

この設定により、LocalStackのS3エミュレーターが正常に動作します。