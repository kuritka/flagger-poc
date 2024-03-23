
# https://docs.flagger.app/install/flagger-install-on-kubernetes#install-flagger-with-helm
# https://artifacthub.io/packages/helm/flagger/flagger
install:
	helm repo add flagger https://flagger.app
	kubectl apply -f https://raw.githubusercontent.com/fluxcd/flagger/main/artifacts/flagger/crd.yaml
	helm upgrade -i flagger flagger/flagger \
		--namespace=ingress-nginx \
		--set meshProvider=nginx \
		--set prometheus.install=false

uninstall:
	helm delete flagger

lint-init:
	brew install yamllint

lint:
	yamllint . -c .yamllint

include ./.platform/colima.mk
