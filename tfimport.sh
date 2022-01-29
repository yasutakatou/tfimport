#!/bin/bash

if [ -n "${TFIMPORTPATH}" ]; then
  PECO="${TFIMPORTPATH}/peco"
  TERRAFORM="${TFIMPORTPATH}/terraform"
else
  PECO="./peco"
  TERRAFORM="./terraform"
fi

if [ $# == 2 ]; then
  echo "CLI Mode:"
  MENU=$1

  if [ -z "${MENU}" ]; then
    echo "Not select.."
    exit 1  
  fi

  AWS=`cat tfimport.ini | grep $1`
  if [ $? -ne 0 ]; then
    echo "ini fail..."
    exit 1
  fi

	TARGET=$2
else
  MENU=`cut -d \~ -f 1 tfimport.ini | tr -d ' ' | tr -d '\t' | ${PECO}`

  if [ -z "${MENU}" ]; then
    echo "Not select.."
    exit 1  
  fi

  AWS=`cat tfimport.ini | grep ${MENU}`
  if [ $? -ne 0 ]; then
    echo "ini fail..."
    exit 1
  fi

  # echo ${AWS}

  LIST=`echo ${AWS} | cut -d \~ -f 2 | tr -d '\t'`
  SELECT=`echo ${AWS} | cut -d \~ -f 3 | tr -d '\t'`

  # echo ${LIST}
  # echo ${SELECT}

  PREEXEC="${LIST} | ${PECO}"
  EXEC=`eval ${PREEXEC}`

  #echo ${EXEC}

  if [[ "${SELECT}" == *@@@@* ]]; then
    EXEC=`echo ${SELECT} | sed "s/@@@@/${EXEC}/g"`
    echo ${EXEC}
    TARGET=`eval ${EXEC}`
  else
    TARGET=$EXEC
  fi
fi

if [ -z "${TARGET}" ]; then
  echo "Not select.."
  exit 1
fi

echo "Service: ${MENU}"
echo "Target: ${TARGET}"

mkdir -p ${TARGET}

cat << EOT > provider.tf
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 3.26.0"
    }
    template = {
      source = "hashicorp/template"
      version = ">= 2.2.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region  = "ap-northeast-1"
}
EOT

cat << EOT > main.tf
resource "${MENU}" "this" {
}
EOT

# INIT="${TERRAFORM} init"
# eval ${INIT}

EXEC="${TERRAFORM} import ${MENU}.this ${TARGET} >/dev/null 2>&1"
eval ${EXEC}
if [ $? -ne 0 ]; then
    echo "Import fail..."
    exit 1
fi

mv terraform.tfstate ${TARGET}/terraform.tfstate_${MENU}_`date +%Y%m%d-%H%M%S`
echo "Import success!"
rm -f provider.tf main.tf
exit 0
