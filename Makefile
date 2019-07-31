.PHONY: version

help:
	@echo 'Usage:'
	@echo '  make <target>'
	@echo 
	@echo 'Targets:'
	@grep -E '^[a-zA-Z_0-9.-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo

last:    ## Build Latest Centreon (19.04)
	@packer build -var-file vars/centreon-19.04.json centreon-local.json

18.10:     ## Build Centreon 18.10
	@packer build -var-file vars/centreon-1810.json centreon-local.json

19.04:     ## Build Centreon 19.04
	@packer build -var-file vars/centreon-1904.json centreon-local.json