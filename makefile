SHELL              := $(shell which bash)

NO_COLOR           := \033[0m
OK_COLOR           := \033[32;01m
ERR_COLOR          := \033[31;01m
WARN_COLOR         := \033[36;01m
ATTN_COLOR         := \033[33;01m

BIN_DIR            := ./bin
EXT_DIR            := ./.ext
EXT_BIN_DIR        := ${EXT_DIR}/bin
EXT_TMP_DIR        := ${EXT_DIR}/tmp

GOOS               := $(shell go env GOOS)
GOARCH             := $(shell go env GOARCH)

POLICY_VER         := latest
SVU_VER 	         := 3.1.0
YQ_VER             := 4.45.1

RELEASE_TAG        := $$(${EXT_BIN_DIR}/svu current)

POLICY_FQN         := $$(yq '.server' .github/config.yaml)/$$(yq '.repo' .github/config.yaml)

.DEFAULT_GOAL      := build

.PHONY: deps
deps: info install-policy install-svu install-yq
	@echo -e "$(ATTN_COLOR)==> $@ $(NO_COLOR)"

.PHONY: build
build:
	@echo -e "$(ATTN_COLOR)==> $@ $(NO_COLOR)"
	@${EXT_BIN_DIR}/policy build src --tag ${POLICY_FQN}:latest

.PHONY: tag
tag:
	@echo -e "$(ATTN_COLOR)==> $@ $(svu patch) $(NO_COLOR)"
	@${EXT_BIN_DIR}/policy tag ${POLICY_FQN}:latest ${POLICY_FQN}:$$(svu patch)

.PHONY: push
push:
	@echo -e "$(ATTN_COLOR)==> $@ $(svu patch) $(NO_COLOR)"
	@${EXT_BIN_DIR}/policy push ${POLICY_FQN}:latest ${POLICY_FQN}:$$(svu patch)

.PHONY: release
release:
	@echo -e "$(ATTN_COLOR)==> $@ $(NO_COLOR)"
	@git tag $$(svu patch) && git push --tags

.PHONY: policy-login
policy-login:
	@echo -e "$(ATTN_COLOR)==> $@ $(NO_COLOR)"
	@gh auth token | policy login -s $$(yq '.server' .github/config.yaml) -u ${USER} --password-stdin

.PHONY: info
info:
	@echo -e "$(ATTN_COLOR)==> $@ $(NO_COLOR)"
	@echo "GOOS:        ${GOOS}"
	@echo "GOARCH:      ${GOARCH}"
	@echo "BIN_DIR:     ${BIN_DIR}"
	@echo "EXT_DIR:     ${EXT_DIR}"
	@echo "EXT_BIN_DIR: ${EXT_BIN_DIR}"
	@echo "EXT_TMP_DIR: ${EXT_TMP_DIR}"
	@echo "RELEASE_TAG: ${RELEASE_TAG}"
	@echo "POLICY_FQN:  ${POLICY_FQN}"

.PHONY: install-policy
install-policy: ${EXT_TMP_DIR} ${EXT_BIN_DIR}
	@echo -e "$(ATTN_COLOR)==> $@ $(NO_COLOR)"
	@gh release download $$(gh release view --repo https://github.com/opcr-io/policy --json tagName | jq -r .tagName) --repo https://github.com/opcr-io/policy --pattern "policy*_${GOOS}_${GOARCH}.zip" --output "${EXT_TMP_DIR}/policy.zip" --clobber
	@unzip -o ${EXT_TMP_DIR}/policy.zip policy -d ${EXT_BIN_DIR}/  &> /dev/null
	@chmod +x ${EXT_BIN_DIR}/policy
	@${EXT_BIN_DIR}/policy version

.PHONY: install-svu
install-svu: install-svu-${GOOS}
	@echo -e "$(ATTN_COLOR)==> $@ $(NO_COLOR)"
	@chmod +x ${EXT_BIN_DIR}/svu
	@${EXT_BIN_DIR}/svu --version

.PHONY: install-svu-darwin
install-svu-darwin: ${EXT_TMP_DIR} ${EXT_BIN_DIR}
	@echo -e "$(ATTN_COLOR)==> $@ $(NO_COLOR)"
	@gh release download v${SVU_VER} --repo https://github.com/caarlos0/svu --pattern "*darwin_all.tar.gz" --output "${EXT_TMP_DIR}/svu.tar.gz" --clobber
	@tar -xvf ${EXT_TMP_DIR}/svu.tar.gz --directory ${EXT_BIN_DIR} svu &> /dev/null

.PHONY: install-svu-linux
install-svu-linux: ${EXT_TMP_DIR} ${EXT_BIN_DIR}
	@echo -e "$(ATTN_COLOR)==> $@ $(NO_COLOR)"
	@gh release download v${SVU_VER} --repo https://github.com/caarlos0/svu --pattern "*linux_${GOARCH}.tar.gz" --output "${EXT_TMP_DIR}/svu.tar.gz" --clobber
	@tar -xvf ${EXT_TMP_DIR}/svu.tar.gz --directory ${EXT_BIN_DIR} svu &> /dev/null

.PHONY: install-yq
install-yq: install-yq-${GOOS}
	@echo -e "$(ATTN_COLOR)==> $@ $(NO_COLOR)"
	@chmod +x ${EXT_BIN_DIR}/yq
	@${EXT_BIN_DIR}/yq --version

.PHONY: install-yq-darwin
install-yq-darwin: ${EXT_TMP_DIR} ${EXT_BIN_DIR}
	@echo -e "$(ATTN_COLOR)==> $@ $(NO_COLOR)"
	@gh release download v${YQ_VER} --repo https://github.com/mikefarah/yq --pattern "yq_${GOOS}_${GOARCH}.tar.gz" --output "${EXT_TMP_DIR}/yq.tar.gz" --clobber
	@tar -xvf ${EXT_TMP_DIR}/yq.tar.gz --directory ${EXT_TMP_DIR} &> /dev/null
	@mv ${EXT_TMP_DIR}/yq_${GOOS}_${GOARCH} ${EXT_BIN_DIR}/yq
	@chmod +x ${EXT_BIN_DIR}/yq

.PHONY: install-yq-linux
install-yq-linux: ${EXT_TMP_DIR} ${EXT_BIN_DIR}
	@echo -e "$(ATTN_COLOR)==> $@ $(NO_COLOR)"
	@gh release download v${YQ_VER} --repo https://github.com/mikefarah/yq --pattern "yq_${GOOS}_${GOARCH}.tar.gz" --output "${EXT_TMP_DIR}/yq.tar.gz" --clobber
	@tar -xvf ${EXT_TMP_DIR}/yq.tar.gz --directory ${EXT_TMP_DIR} &> /dev/null
	@mv ${EXT_TMP_DIR}/yq_${GOOS}_${GOARCH} ${EXT_BIN_DIR}/yq
	@chmod +x ${EXT_BIN_DIR}/yq

.PHONY: clean
clean:
	@echo -e "$(ATTN_COLOR)==> $@ $(NO_COLOR)"
	@rm -rf ${EXT_DIR}
	@rm -rf ${BIN_DIR}

${BIN_DIR}:
	@echo -e "$(ATTN_COLOR)==> $@ $(NO_COLOR)"
	@mkdir -p ${BIN_DIR}

${EXT_BIN_DIR}:
	@echo -e "$(ATTN_COLOR)==> $@ $(NO_COLOR)"
	@mkdir -p ${EXT_BIN_DIR}

${EXT_TMP_DIR}:
	@echo -e "$(ATTN_COLOR)==> $@ $(NO_COLOR)"
	@mkdir -p ${EXT_TMP_DIR}
