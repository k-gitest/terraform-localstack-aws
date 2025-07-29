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

## 準備
- github access token
- aws access_key
- aws secret_key
- Lambda関数のZIPファイル
- フロントエンドビルド成果物
- Amplify用のGitHubリポジトリ
- terraform cloudプロジェクト（dev, prod）
- cloudでの変数設定
- SSMパラメータ
- CORS用ドメイン名の更新
- ECR用のDockerイメージ

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

### 環境ごとのプロバイダー設定とリソース作成の制御

このプロジェクトでは、開発環境（LocalStack）と本番環境で異なるプロバイダー設定とリソースセットを使用するため、**Terraform実行コンテキストを環境ごとに分離する**設計を採用しています。

各環境ディレクトリ（`environments/local`、`environments/dev`、`environments/prod`）は、それぞれが独立したTerraformの実行ポイントとなります。これらのディレクトリ内には、その環境固有のプロバイダー設定と、共通の**ルートTerraform構成 (`../..` に位置する `terraform/` ディレクトリ全体)** をモジュールとして呼び出す設定が含まれています。

**LocalStack 環境でのプロバイダー設定:**
- `terraform/environments/local` ディレクトリでTerraformを実行した場合、`terraform/environments/local/providers.tf`内で定義されている`endpoints`ブロックが有効になり、AWSの各サービスは`http://localhost:4566` (LocalStack) を参照するようになります。   

- LocalStackでS3を使用する場合、`s3_use_path_style = true` の設定が必要です。これは、S3のURLスタイルを以下のように変更します：

- **Virtual hosted-style** (AWS標準): `https://bucket-name.s3.amazonaws.com/key`
- **Path-style** (LocalStack用): `https://s3.amazonaws.com/bucket-name/key`

例：
```terraform
endpoints {
    s3_use_path_style = true # LocalStack S3の推奨設定
    content {
      s3       = "http://localhost:4566"
```

### workspaceを使用してリソース作成を除外する場合
Terraformの**ワークスペース (`terraform workspace`)** 機能を利用して、開発環境 (LocalStack) と本番環境で同じTerraformコードを使用することもできます。   
terraform workspace new localでlocalワークスペースを作成し、LocalStackでサポートされていないリソースの作成自体を制御しています。

例：
```
count = terraform.workspace == "local" ? 0 : 1
```

**注意**:
terraform workspaceはディレクトリ単位で設定します。   
environments内の環境ごとで分けている場合、ルートではなくlocal内でterraform workspace new localをしなければ環境が切り替わりませんので注意しましょう。

### workspaceを使用しない場合
workspaceなどで分岐しない場合、個別にenvironment変数などで条件分岐をする必要があります。   
その際、親側でリソースを作成するかどうかを確定させる必要があります。

```terraform
// 以下のように、変数の値自体が真偽値である場合、
// その条件が示す環境が不明瞭になるため推奨されません。
// count = var.some_boolean_flag ? 1 : 0

count = var.environment == "local" ? 1 : 0 // これはOK
```

**注意**
countメタ引数を用いてリソースが条件付きで作成される場合、Terraformはそのリソースを常に配列として扱います。そのため、たとえ count=1でリソースが作成されても、その属性を参照する際には配列インデックス ([0]) を指定する必要があります。

また、count=0のためにリソースが作成されない場合、[0]インデックスでの直接参照はエラーになります。この問題を避けるためには、try(aws_resource_type.name[0].attribute, null) や length(aws_resource_type.name) > 0 ? aws_resource_type.name[0].attribute : null のような詳細な条件分岐が必要となり、Terraformコード全体が複雑化するため、特にルート構成で多数のリソースに適用される場合は、複雑さが増大する可能性があります。

## 設計によるコードの一元管理とヒューマンエラーの削減
本プロジェクトでは、各環境ディレクトリで必要なモジュールを直接呼び出す代わりに、共通のルートTerraform構成 (terraform/ ディレクトリ) をモジュールとして呼び出し、その中でリソースの作成を制御する設計を採用しています。このアプローチは、以下の課題を解決するために選択されました。

**コードの重複とメンテナンスコストの増大**:
もし各環境ディレクトリ（environments/local、environments/dev、environments/prod）のmain.tfで個別にS3バケットやLambda関数などのモジュールを呼び出す場合、多くのコードが重複します。例えば、ある共通モジュールの入力変数を追加したり、その設定を変更したりするたびに、すべての環境のmain.tfを手動で修正する必要が生じます。これは大規模なプロジェクトになるほど、非常に手間がかかり、非効率的です。

**環境間の一貫性欠如とヒューマンエラーのリスク**:
手動での複数ファイルの修正は、環境間での設定の不一致を引き起こしやすくなります。特定の環境で修正が漏れたり、誤った設定をしてしまったりするリスクが高まり、インフラの信頼性を損なう原因となります。また、プルリクエストのレビューでも、共通の変更がすべての環境で正しく適用されているかを確認する作業が複雑化します。

### 現在の設計のメリット:

**コードの一元化**: ほとんどのリソースモジュールの呼び出しと設定がルートのterraform/main.tfに集約されています。これにより、共通のインフラ構成を変更する際の修正箇所が最小限に抑えられ、単一の場所で全体像を把握し、管理できます。

**ヒューマンエラーの削減**: 共通部分の変更は一箇所に集中するため、環境間での設定の不一致や修正漏れといったヒューマンエラーのリスクが大幅に低減されます。

### トレードオフと考慮事項:

この設計には、ルートmain.tfがvar.environmentに基づくcountの条件分岐で複雑になる可能性があるというトレードオフが存在します。しかし、この「一箇所に集約された複雑さ」は、各環境にコードが散らばることによる「分散した複雑さ」よりも、デバッグや全体像の把握がしやすいと判断しています。try()関数などのTerraformの組み込み機能を利用して、条件付きのリソース参照も安全に行っています。