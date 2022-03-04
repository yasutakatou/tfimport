#!/bin/bash

if [ -n "${TFIMPORTINI}" ]; then
  TFIMPORTINI=${TFIMPORTPATH}
else
  TFIMPORTINI="./tfimport.ini"
fi

if [ -n "${TFIMPORTPATH}" ]; then
  PECO="${TFIMPORTPATH}/peco"
  TERRAFORM="${TFIMPORTPATH}/terraform"
else
  PECO="./peco"
  TERRAFORM="./terraform"
fi

if [ -n "${TFIMPORTPECOSED}" ]; then
  TFIMPORTPECOSED=${TFIMPORTPECOSED}
else
  TFIMPORTPECOSED="@@PECO@@"
fi

if [ -n "${TFIMPORTSED}" ]; then
  TFIMPORTSED=${TFIMPORTSED}
else
  TFIMPORTSED="@@@@"
fi

if [ -n "${TFIMPORTINIT}" ]; then
  INIT="${TERRAFORM} init"
  eval ${INIT}
fi

if [ -n "${TFIMPORTREGION}" ]; then
  TFIMPORTREGION=${TFIMPORTREGION}
else
  TFIMPORTREGION="ap-northeast-1"
fi

if [ -n "${TFIMPORTPROVIDER}" ]; then
  TFIMPORTPROVIDER=${TFIMPORTPROVIDER}
else
  TFIMPORTPROVIDER=">= 3.26.0"
fi

DATE=`date +%Y%m%d-%H%M%S`

if [ -e "./terraform.tfstate" ]; then
  mv ./terraform.tfstate terraform.tfstate_${DATE}
  rm -f ./terraform.tfstate
fi

cat << EOT > provider.tf
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "${TFIMPORTPROVIDER}"
    }
    template = {
      source = "hashicorp/template"
      version = ">= 2.2.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region  = "${TFIMPORTREGION}"
}
EOT

CLI="no"
if [ $# == 2 ]; then
  echo "CLI Mode:"
  CLI="yes"
        MENU=$1
else
  MENU=`cut -d \~ -f 1 ${TFIMPORTINI} | tr -d ' ' | tr -d '\t' | sort | uniq | ${PECO}`

  if [ -z "${MENU}" ]; then
    echo "Not select.."
    exit 1
  fi
fi

echo "Service: ${MENU}"

IFS=$'\n'
AWS=(`grep ^${MENU}.*~ ${TFIMPORTINI}`)
if [ $? -ne 0 ]; then
  echo "ini fail..."
  exit 1
fi

i=0
for AWSLINE in ${AWS[@]}
do
  # echo "$i => $AWSLINE"

  RESOURCE=`echo ${AWSLINE} | cut -d \~ -f 2 | tr -d '\t' | tr -d ' '`
  LIST=`echo ${AWSLINE} | cut -d \~ -f 3 | tr -d '\t'`
  SELECT=`echo ${AWSLINE} | cut -d \~ -f 5 | tr -d '\t'`

  if [ $i -gt 0 ]; then
    # echo " -- ${i} -- FIRST: ${FIRST} -- "
    PREEXEC=`echo ${LIST} | sed "s^${TFIMPORTSED}^${FIRST}^g"`
    SELECTED=`eval ${PREEXEC}`
  else
    # echo " -- ${i} -- LIST: ${LIST} --"
    if [[ "${CLI}" == *yes* ]]; then
      SELECTED=$2
    else
      PREEXEC="${LIST} | ${PECO}"
      SELECTED=`eval ${PREEXEC}`
      if [ -z "${SELECTED}" ]; then
        echo "Not select.."
        exit 1
      fi
    fi
  fi

  # echo " -- SELECTED: ${SELECTED} -- "
  # echo " -- SELECT: ${SELECT} -- "

  if [[ "${SELECT}" == *${TFIMPORTPECOSED}* ]]; then
    SELECT=`echo ${SELECT} | sed "s^${TFIMPORTPECOSED}^${PECO}^g"`
  fi

  if [[ "${SELECT}" == *${TFIMPORTSED}* ]]; then
    EXEC=`echo ${SELECT} | sed "s^${TFIMPORTSED}^${SELECTED}^g"`
    TARGET=`eval ${EXEC}`

    if [ $i -eq 0 ]; then
      FIRST=$TARGET
    fi
  else
    TARGET=$SELECTED

    if [ $i -eq 0 ]; then
      FIRST=$TARGET
    fi
  fi

  if [ -z "${TARGET}" ]; then
    echo "Not select.."
    exit 1
  fi

  if [ $i -eq 0 ]; then
    #echo "AWS Resouce: ${RESOURCE}"
    echo "Target: ${TARGET}"
    NAME=`echo ${AWSLINE} | cut -d \~ -f 4 | tr -d '\t'`
    if [[ "${NAME}" == *${TFIMPORTPECOSED}* ]]; then
      NAME=`echo ${NAME} | sed "s^${TFIMPORTPECOSED}^${PECO}^g"`
    fi

    if [[ "${NAME}" == *${TFIMPORTSED}* ]]; then
      EXEC=`echo ${NAME} | sed "s^${TFIMPORTSED}^${SELECTED}^g"`
      NAME=`eval ${EXEC}`
      # echo "Name: ${NAME}"
      mkdir -p ${NAME}
    else
      NAME=${TARGET}
      mkdir -p ${NAME}
    fi
  fi

cat << EOT > main.tf
  resource "${RESOURCE}" "this" {
  }
EOT

  EXEC="${TERRAFORM} import ${RESOURCE}.this ${TARGET} > ${RESOURCE}-${DATE}"
  eval ${EXEC}
  if [ $? -ne 0 ]; then
      echo "Import fail..."
      echo " - - - - - "
      cat ${RESOURCE}-${DATE}
      echo " - - - - - "
      rm -f ${RESOURCE}-${DATE}
      exit 1
  else
    rm -f ${RESOURCE}-${DATE}
  fi

  mv terraform.tfstate ${NAME}/terraform.tfstate-${RESOURCE}-${DATE}

  let i++
done
rm -f provider.tf main.tf
echo "Import success!"
exit 0
