# 親のライブ直下のterragrunt.hclを継承
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# 環境の設定
locals {
  instance_type = "t2.micro"
}