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

if [ -n "${TFIMPORTSED}" ]; then
  TFIMPORTSED=${TFIMPORTSED}
else
  TFIMPORTSED="@@@@"
fi

if [ -e "terraform.tfstate" ]; then
  rm -f terraform.tfstate
fi

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

MENU=`cut -d \~ -f 1 ${TFIMPORTINI} | tr -d ' ' | tr -d '\t' | sort | uniq | ${PECO}`

if [ -z "${MENU}" ]; then
  echo "Not select.."
  exit 1  
fi

IFS=$'\n'
AWS=(`grep ${MENU} ${TFIMPORTINI}`)
#AWS="$(grep ${MENU} ${TFIMPORTINI})"
#AWS="($(grep ${MENU} ${TFIMPORTINI} | sed "s/$/\n/g"))"
#AWS="(`grep ${MENU} ${TFIMPORTINI}`)"
if [ $? -ne 0 ]; then
  echo "ini fail..."
  exit 1
fi

echo "0 ${AWS[0]}"
echo "1 ${AWS[1]}"
echo "2 ${AWS[2]}"

i=0
for AWSLINE in ${AWS[@]}
do
  echo "$i => $AWSLINE"

  RESOURCE=`echo ${AWSLINE} | cut -d \~ -f 2 | tr -d '\t' | tr -d ' '`
  LIST=`echo ${AWSLINE} | cut -d \~ -f 3 | tr -d '\t'`
  SELECT=`echo ${AWSLINE} | cut -d \~ -f 5 | tr -d '\t'`

  if [ $i -gt 0 ]; then
    echo " -- loop ${i} --  FIRST ${FIRST} -- "
    PREEXEC=`echo ${LIST} | sed "s^${TFIMPORTSED}^${FIRST}^g"`
    echo ${PREEXEC}
    EXEC=`eval ${PREEXEC}`
  else
    echo " -- loop ${i} -- LIST ${LIST} --"
    PREEXEC="${LIST} | ${PECO}"
    EXEC=`eval ${PREEXEC}`
    if [ -z "${EXEC}" ]; then
      echo "Not select.."
      exit 1  
    fi
  fi

  echo " -- EXEC -- ${EXEC} -- "

  echo " -- SELECT -- ${SELECT} -- "

  if [[ "${SELECT}" == *${TFIMPORTSED}* ]]; then
    EXEC=`echo ${SELECT} | sed "s^${TFIMPORTSED}^${EXEC}^g"`
    echo ${EXEC}
    TARGET=`eval ${EXEC}`

    if [ $i -eq 0 ]; then
      FIRST=$TARGET
    fi
  else
    TARGET=$EXEC

    if [ $i -eq 0 ]; then
      FIRST=$TARGET
    fi
  fi

  if [ -z "${TARGET}" ]; then
    echo "Not select.."
    exit 1
  fi

  if [ $i -eq 0 ]; then
    NAME=`echo ${AWSLINE} | cut -d \~ -f 4 | tr -d '\t'`
    if [[ "${NAME}" == *${TFIMPORTSED}* ]]; then
      EXEC=`echo ${NAME} | sed "s^${TFIMPORTSED}^${TARGET}^g"`
      echo ${EXEC}
      NAME=`eval ${EXEC}`
      echo "Name: ${NAME}"
      mkdir -p ${NAME}
    else
      NAME=${TARGET}
			mkdir -p ${NAME}
    fi
  fi  

  echo "Service: ${RESOURCE}"
  echo "Target: ${TARGET}"

cat << EOT > main.tf
  resource "${RESOURCE}" "this" {
  }
EOT

  # INIT="${TERRAFORM} init"
  # eval ${INIT}

  #exit 0

  DATE=`date +%Y%m%d-%H%M%S`
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
