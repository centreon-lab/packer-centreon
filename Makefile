.PHONY: version

help:
	@echo 'Usage:'
	@echo '  make <target>'
	@echo 
	@echo 'Targets:'
	@grep -E '^[a-zA-Z_0-9.-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo

last:    ## Build Latest Centreon (18.10)
	@packer build -var-file vars/centreon-1810.json vagrant-centreon-local.json

18.10:     ## Build Centreon 18.10
	@packer build -var-file vars/centreon-1810.json vagrant-centreon-local.json

