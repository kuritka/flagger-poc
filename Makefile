# https://docs.flagger.app/tutorials/nginx-progressive-delivery
# https://docs.flagger.app/install/flagger-install-on-kubernetes#install-flagger-with-helm
# https://artifacthub.io/packages/helm/flagger/flagger
# https://artifacthub.io/packages/helm/flagger/loadtester


SHELL := bash
PAW_PRINTS=\U1F43E
DOG=\U1F43A
ifndef NO_COLOR
YELLOW=\033[0;33m
CYAN=\033[1;36m
# no color
NC=\033[0m
endif

# kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 8081:80
# http://test.cloud.example.com:8081/
# for i in {1..100}; do curl http://test.cloud.example.com:8081/status/200; sleep 10; done
# kubectl -n test get canaries --watch
promote:
	@echo -e " $(YELLOW)Bump to v6.0.1$(NC) "
	kubectl -n test set image deployment/podinfo podinfod=ghcr.io/stefanprodan/podinfo:6.0.1

promote2:
	@echo -e " $(YELLOW)Bump podinfo to v6.6.1$(NC) "
	kubectl -n test set image deployment/podinfo podinfod=ghcr.io/stefanprodan/podinfo:6.6.1

application:
	@echo -e "$(DOG)  $(YELLOW)Installing application$(NC) "
	kubectl delete namespace test --ignore-not-found=true
	kubectl create ns test
	kubectl apply -k https://github.com/fluxcd/flagger//kustomize/podinfo?ref=main
	kubectl apply -f ./svc.yaml
	kubectl apply -f ./podinfo-ingress.yaml
	helm upgrade -i flagger-loadtester flagger/loadtester --namespace=flagger --create-namespace

install:
	@echo -e "$(DOG)  $(YELLOW)Installing prerequisities $(PAW_PRINTS)$(NC) "
	@echo -e "  $(CYAN)ingress-nginx$(NC) "
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	helm upgrade -i ingress-nginx ingress-nginx/ingress-nginx \
		--namespace ingress-nginx \
		--set controller.metrics.enabled=true \
		--set controller.podAnnotations."prometheus\.io/scrape"=true \
		--set controller.podAnnotations."prometheus\.io/port"=10254 \
		--create-namespace --namespace ingress-nginx

	@echo -e "  $(CYAN)Flagger$(NC) "
	helm repo add flagger https://flagger.app
	helm upgrade -i flagger flagger/flagger \
		--namespace flagger \
		--set prometheus.install=true \
		--set meshProvider=nginx \
		--create-namespace


bg:
	kubectl apply -f ./podinfo-bluegreen.yaml


uninstall:
	helm delete flagger

lint-init:
	brew install yamllint

lint:
	yamllint . -c .yamllint


reset: with-colima install-local-platform install application

include ./.platform/colima.mk
