# 親のライブ直下のterragrunt.hclを継承
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# モジュールに渡す変数
inputs = {
  instance_type = "t2.micro"
}