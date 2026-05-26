infra-init:
    cd terraform && terraform init

infra-plan:
    cd terraform && terraform plan

infra-apply:
    cd terraform && terraform apply
    cd terraform && \
    gh secret set ECR_REGISTRY --body "$$(terraform output -raw ecr_repository_url)" && \
    gh secret set EC2_PUBLIC_IP --body "$$(terraform output -raw server_public_ip)"