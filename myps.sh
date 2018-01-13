#!/bin/bash

print_usage(){
    echo "Usage: " $0 "<args>"
    echo "-l: list all keys"
    echo "-p: <key> copy password"
    echo "-P: <key> print password"
    echo "-i: <key> print id"
    echo "-a: 'key id password' add record(Do not forget quotation!)"
    echo "-D: <key> delete record"
    echo "-A: print all"
}

list_all_keys(){
    decrypt | cut -f1,2,3 -d" "
}

copy_password(){
    num=$1
    decrypt | grep "^${num} " | cut -f4 -d" " | pbcopy
}

print_password(){
    num=$1
    decrypt | grep "^${num} " | cut -f4 -d" "
}

print_id(){
    num=$1
    decrypt | grep "^${num} " | cut -f3 -d" "
}

add_record(){
    key=$1
    id=$2
    pass=$3
    if [ -z "${key}" ] || [ -z "${id}" ] || [ -z "${pass}" ]; then
        alert_invalid_form_exit
    fi

    num=$(decrypt | tail -n1 | cut -f1 -d" ")
    num2=$((${num} + 1))
    
    do_add_record "${num2}" "${key}" "${id}" "${pass}"
}

do_add_record(){
    num=$1
    key=$2
    id=$3
    pass=$4
    decrypt | cat - <(echo "${num}" "${key}" "${id}" "${pass}") | encrypt
}

alert_invalid_form_exit(){
    echo "invalid form"
    print_usage
    exit 1
}

delete_record(){
    num=$1
    if [ -z "${num}" ]; then
        echo "num is empty"
        exit 1        
    fi
    do_delete_record ${num}
}

do_delete_record(){
    num=$1
    decrypt | grep "^${num} " | pbcopy
    echo "the record for '${num}' is copied in clipboard"
    decrypt | grep -v "^${num} " | encrypt
}

decrypt(){
    gpg --decrypt ${DATAFILE} 2> /dev/null
}

encrypt(){
    gpg -e -r "myps" -o ${DATAFILE}
}

initialize(){
    echo | grep -v "^$" | encrypt
}

if ! [ -r ~/.myps ]; then
    echo "missing ~/.myps file"
    exit 1
fi

source ~/.myps
if [ -z ${DATAFILE} ]; then
    echo "variable 'DATAFILE' is not defined"
    exit 1
fi

if ! [ -r ${DATAFILE} ]; then
    initialize
fi


getopts lp:P:i:a:D:Ah OPT
case ${OPT} in
    l) list_all_keys            ;;
    p) copy_password ${OPTARG}  ;;
    P) print_password ${OPTARG} ;;
    i) print_id ${OPTARG}       ;;
    a) add_record ${OPTARG}     ;;
    D) delete_record ${OPTARG}  ;;
    A) decrypt                  ;;
    h) print_usage              ;;
esac

if [ -z "$1" ]; then
    list_all_keys
else
    copy_password $1
fi
