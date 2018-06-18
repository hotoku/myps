#!/bin/bash

print_usage(){
    echo "Usage:"
    echo ""
    echo "copy password"
    echo "$0 <num>"
    echo ""
    echo "search key"
    echo "$0 <string>"
    echo ""
    echo "OPTIONS:"
    echo "-l                       : list all keys"
    echo "-p <num>                 : copy password"
    echo "-P <num>                 : print password"
    echo "-i <num>                 : copy id"
    echo "-I <num>                 : print id"
    echo "-a 'key id password'     : add record (Do not forget quotation!)"
    echo "-u 'num key id password' : update record (Do not forget quotation!)"
    echo "-D <num>                 : delete record"
    echo "-A                       : print all"
    echo "-s <string>              : search"
}

list_all_keys(){
    decrypt | cut -f1,2,3 -d" "
}

copy_password(){
    num=$1
    decrypt | grep "^${num} " | cut -f4 -d" " | pbcopy
    decrypt | grep "^${num} " | cut -f1,2,3 -d" "
}

print_password(){
    num=$1
    decrypt | grep "^${num} " | cut -f4 -d" "
}

copy_id(){
    num=$1
    decrypt | grep "^${num} " | cut -f3 -d" " | pbcopy
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

update_record(){
    num=$1
    key=$2
    id=$3
    pass=$4
    if [ -z "${num}" ] || [ -z "${key}" ] || [ -z "${id}" ] || [ -z "${pass}" ]; then
        alert_invalid_form_exit
    fi

    do_update_record "${num}" "${key}" "${id}" "${pass}"
}

do_update_record(){
    num=$1
    key=$2
    id=$3
    pass=$4
    decrypt | grep -v "^${num} " | cat - <(echo ${num} ${key} ${id} ${pass}) | sort -k1 -n | encrypt
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

search(){
    key=$1
    decrypt | cut -f1,2,3 -d" " | grep "${key}"
    decrypt | grep "${key}" | cut -f4 -d" " | pbcopy
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

isnum(){
    str=$1
    expr ${str} + 1 > /dev/null 2>&1
    ret=$?
    test ${ret} -lt 2
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


getopts lp:P:i:I:a:u:D:As:h OPT
case ${OPT} in
    l) list_all_keys            ; exit ;;
    p) copy_password ${OPTARG}  ; exit ;;
    P) print_password ${OPTARG} ; exit ;;
    i) copy_id ${OPTARG}        ; exit ;;
    I) print_id ${OPTARG}       ; exit ;;
    a) add_record ${OPTARG}     ; exit ;;
    u) update_record ${OPTARG}  ; exit ;;
    D) delete_record ${OPTARG}  ; exit ;;
    A) decrypt                  ; exit ;;
    s) search ${OPTARG}         ; exit ;;
    h) print_usage              ; exit ;;
esac

if [ -z "$1" ]; then
    list_all_keys
elif isnum $1; then
    copy_password $1
else
    search $1
fi
