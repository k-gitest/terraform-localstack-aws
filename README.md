# TerraformとLocalStackでawsのプロビジョニング
TerraformとLocalStackを使用してawsをコードで管理し自動作成

## 概要
このプロジェクトは、IaCに基づき、awsのs3のプロビジョニングを自動化します。

## 使用技術
- Terraform
- Terraform Cloud
- LocalStack
- Codespaces

```text
/
├── .devcontainer/
│   ├── devcontainer.json
│   └── setup.sh
├── main.tf                 # ルートモジュールのmain.tf (modules/s3 を呼び出す)
├── variables.tf            # ルートモジュールの変数定義
├── outputs.tf              # ルートモジュールの出力定義
├── modules/
│   └── s3/                 # S3モジュールのディレクトリ
│       ├── main.tf         # S3モジュールのリソース定義 (s3バケットなど)
│       ├── variables.tf    # S3モジュール固有の変数定義
│       └── outputs.tf      # S3モジュール固有の出力定義
├── README.md
└── .gitignore

```

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

