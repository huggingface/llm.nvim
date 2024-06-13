GREEN="\033[00;32m"
RESTORE="\033[0m"

# makes the output of the message appear green
define style_calls
	$(eval $@_msg = $(1))
	echo ${GREEN}${$@_msg}
	echo ${RESTORE}
endef

lint:
	@$(call style_calls,"Linting lua files")
	@selene --display-style quiet --config ./selene.toml lua/llm
	@$(call style_calls,"Running stylua check")
	@stylua --color always -f ./.stylua.toml --check .
	@$(call style_calls,"Done!")

format:
	@$(call style_calls,"Running stylua format")
	@stylua --color always -f ./.stylua.toml .
	@$(call style_calls,"Done!")

.PHONY: lint format
