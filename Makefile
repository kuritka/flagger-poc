# https://docs.flagger.app/tutorials/nginx-progressive-delivery
# https://docs.flagger.app/install/flagger-install-on-kubernetes#install-flagger-with-helm
# https://artifacthub.io/packages/helm/flagger/flagger



SHELL := bash
PAW_PRINTS=\U1F43E
DOG=\U1F43A
ifndef NO_COLOR
YELLOW=\033[0;33m
CYAN=\033[1;36m
# no color
NC=\033[0m
endif

# kubectl port-forward deploy/podinfo-primary 8080:9898
# kubectl port-forward deploy/podinfo 8081:9898
# http://app.example.com:8080/  http://app.example.com:8081/
# for i in {1..100}; do curl http://localhost:8080/status/500; sleep 1; done
# kubectl get canaries --watch
promote:
	@echo -e " $(YELLOW)Bump podinfo from v6.0.0 to v6.0.2$(NC) "
	kubectl -n test set image deployment/podinfo podinfod=ghcr.io/stefanprodan/podinfo:6.0.1

rollback:


application:
	kubectl delete namespace test --ignore-not-found=true
	kubectl create ns test
	kubectl apply -k https://github.com/fluxcd/flagger//kustomize/podinfo?ref=main
	helm upgrade -i flagger-loadtester flagger/loadtester --namespace=test
	kubectl apply -f ./podinfo-canary.yaml
	kubectl apply -f ./podinfo-ingress.yaml

install:
	@echo -e "$(DOG)  $(YELLOW)Installing prerequisities $(PAW_PRINTS)$(NC) "
	@echo -e "  $(CYAN)ingress-nginx$(NC) "
	kubectl delete namespace ingress-nginx --ignore-not-found=true
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
		--namespace ingress-nginx \
		--set prometheus.install=true \
		--set meshProvider=nginx

uninstall:
	helm delete flagger

lint-init:
	brew install yamllint

lint:
	yamllint . -c .yamllint

include ./.platform/colima.mk
