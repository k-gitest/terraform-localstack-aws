.PHONY: init apply plan destroy

TF_DIR=terraform

init:
	cd $(TF_DIR) && tflocal init

plan:
	cd $(TF_DIR) && tflocal plan

apply:
	cd $(TF_DIR) && tflocal apply

destroy:
	cd $(TF_DIR) && tflocal destroy