#!/bin/bash
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
NC='\e[0m'

ECHO_CUR=0
ECHO_TOTAL=$(grep "^echo_create" $0 | wc -l)

ECHO_TOTAL_CREATE=$(grep "^echo_create" $0 | wc -l)

ECHO_API_CUR=0
ECHO_INSTALL_CUR=0

ECHO_API_TOTAL=$(grep "echo_api" $0  | wc -l)
ECHO_INSTALL_TOTAL=$(grep "echo_install" $0 | wc -l)

#/
# <pre>
# echo에 색을 입히는 기능
# </pre>
#
# @authors 크로센트
# @see
#/


function echo_blue(){
	MSG=$1
	ECHO_CUR=$(($ECHO_CUR + 1))
	echo -e "${YELLOW}[${ECHO_CUR}/${ECHO_TOTAL}]${BLUE}${MSG} Start.${NC}"
}

function echo_green(){
	MSG=$1
	ECHO_CUR=$(($ECHO_CUR + 1))
	echo -e "${YELLOW}[${ECHO_CUR}/${ECHO_TOTAL}]${GREEN}${MSG} Success.${NC}"
}

function echo_create(){
	MSG=$1
	ECHO_CUR=$(($ECHO_CUR + 1))
	echo -e "${YELLOW}[${ECHO_CUR}/${ECHO_TOTAL_CREATE}]${GREEN}${MSG} Create.${NC}"
}

function echo_red(){
	MSG=$1
	ECHO_CUR=$(($ECHO_CUR + 1))
	echo -e "${YELLOW}[${ECHO_CUR}/${ECHO_TOTAL}]${RED}${MSG} Failed.${NC}"
}

function echo_yellow(){
	MSG=$1
	ECHO_CUR=$(($ECHO_CUR + 1))
	echo -e "${YELLOW}[${ECHO_CUR}/${ECHO_TOTAL}]${YELLOW}${MSG} Exit.${NC}"
}

function echo_err(){
	MSG=$1
	echo -e "${RED}${MSG}${NC}" >${ERR_OUT}
}

function echo_api_blue(){
	MSG=$1
	ECHO_API_CUR=$(($ECHO_API_CUR + 1))
	echo -e "${YELLOW}[${ECHO_API_CUR}/${ECHO_API_TOTAL}]${BLUE}${MSG} Start.${NC}"
}

function echo_install_green(){
	MSG=$1
	ECHO_INSTALL_CUR=$(($ECHO_INSTALL_CUR + 1))
	echo -e "${YELLOW}[${ECHO_INSTALL_CUR}/${ECHO_INSTALL_TOTAL}]${GREEN}${MSG} Success.${NC}"
}

function echo_error_red(){
	MSG=$1
	echo -e "${RED}${MSG} Failed.${NC}"
}

function echo_api_blue_stop(){
	MSG=$1
	echo -e "${BLUE}${MSG} Stop.${NC}"
}

function echo_install_green_stop(){
	MSG=$1
	echo -e "${GREEN}${MSG} Stop.${NC}"
}

function echo_api_blue_no_num(){
	MSG=$1
	echo -e "${BLUE}${MSG} Start.${NC}"
}


function echo_api_green_no_num(){
	MSG=$1
	echo -e "${GREEN}${MSG} Start.${NC}"
}


function echo_api_red_no_num(){
	MSG=$1
	echo -e "${RED}${MSG} Start.${NC}"
}
