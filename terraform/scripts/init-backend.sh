#!/usr/bin/env bash
# Crea (si no existe) el bucket S3 donde Terraform guarda su estado y ejecuta
# `terraform init` apuntando a el. Sin estado remoto, cada ejecucion de GitHub
# Actions empezaria de cero e intentaria crear de nuevo recursos que ya existen.
#
# Uso (desde la carpeta terraform/):  AWS_REGION=us-east-1 ./scripts/init-backend.sh
set -euo pipefail

: "${AWS_REGION:?Falta AWS_REGION}"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET="tfstate-${ACCOUNT_ID}-${AWS_REGION}"
KEY="actividad-api/terraform.tfstate"

if ! aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  echo "Creando bucket de estado s3://$BUCKET"
  if [ "$AWS_REGION" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "$BUCKET" --region "$AWS_REGION"
  else
    aws s3api create-bucket --bucket "$BUCKET" --region "$AWS_REGION" \
      --create-bucket-configuration LocationConstraint="$AWS_REGION"
  fi
  aws s3api put-bucket-versioning --bucket "$BUCKET" \
    --versioning-configuration Status=Enabled
  aws s3api put-public-access-block --bucket "$BUCKET" \
    --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
fi

terraform init -input=false \
  -backend-config="bucket=${BUCKET}" \
  -backend-config="key=${KEY}" \
  -backend-config="region=${AWS_REGION}" \
  -backend-config="use_lockfile=true" \
  -backend-config="encrypt=true"
