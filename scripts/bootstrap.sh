#!/usr/bin/env bash

base="$(pwd)/terraform"

usage() {
    echo "usage bin/terraform (up|down)"
}

terraform_up() {
    cd $base
    terraform plan -out terraform.plan && \
    terraform apply terraform.plan
}

terraform_down() {
    cd $base
    terraform plan -destroy -out terraform.plan && \
    terraform apply terraform.plan
}

if [[ $# -eq 0 ]]; then
    usage
    exit 1
fi

if [[ $1 == 'up' ]]; then
    terraform_up
    exit 0
fi

if [[ $1 == 'down' ]]; then
    terraform_down
    exit 0
fi