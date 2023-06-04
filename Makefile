
VERSION ?= 0.0.1

.PHONY: lint test bump-chart

lint:
	ct lint --chart-dirs=. --all --validate-maintainers=false
	helm lint

unittest:
	helm unittest  . 

test:
	cd examples && bash test.sh

bump-chart-version:
	yq -i '.version = "$(VERSION)"' Chart.yaml