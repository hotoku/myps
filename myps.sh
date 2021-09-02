#!/bin/bash


print_usage(){
    cat<<EOF
Usage:
copy password
$0 <num>


search key
$0 <string>


OPTIONS:
-l                  : list all keys
-p <num>            : copy password
-P <num>            : print password
-i <num>            : copy id
-I <num>            : print id
-a                  : add record
-u                  : update record
-c <num> <password> : change password
-D <num>            : delete record
-A                  : print all
-s <string>         : search
-g                  : generate password
EOF
}


list_all_keys(){
    decrypt | cut -f1,2,3 -d" "
}


copy_password(){
    num=$1
    decrypt | grep "^${num} " | cut -f4 -d" " | tr -d "\n" | pbcopy
    decrypt | grep "^${num} " | cut -f1,2,3 -d" "
}


print_password(){
    num=$1
    decrypt | grep "^${num} " | cut -f4 -d" "
}


copy_id(){
    num=$1
    decrypt | grep "^${num} " | cut -f3 -d" " | tr -d "\n" | pbcopy
}


print_id(){
    num=$1
    decrypt | grep "^${num} " | cut -f3 -d" "
}


exit_if_empty(){
    var="$1"
    if [ -z "${var}" ]; then
        exit 1
    fi
}


add_record(){
    read -p "key?: " key
    exit_if_empty "${key}"


    read -p "id?: " id
    exit_if_empty "${id}"


    read -p "password? empty -> random password: " pass
    if [ -z "${pass}" ]; then
        pass=$(do_generate_password)
    fi


    num=$(min_miss)
    if [ -z "${num}" ]; then
        num=$(num_record)
        num=$(($num + 1))
    fi
    do_add_record "${num}" "${key}" "${id}" "${pass}"
}


do_add_record(){
    num=$1
    key=$2
    id=$3
    pass=$4
    decrypt | cat - <(echo "${num}" "${key}" "${id}" "${pass}") | sort -k1 -n | encrypt
}


update_record(){
    num=$1
    exit_if_empty "${num}"


    msg=`cat<<EOF
what item is updated?
1: key
2: id
3: password
input:
EOF`


    read -p "${msg}" item
    exit_if_empty "${item}"


    line=$(decrypt | grep "^${num} " | tr -d "\n")
    exit_if_empty "${line}"


    key=$(echo ${line} | cut -f2 -d" ")
    id=$(echo ${line} | cut -f3 -d" ")
    pass=$(echo ${line} | cut -f4 -d" ")


    if [ ${item} -eq 1 ]; then
        read -p "new key: " key
        exit_if_empty "${key}"
    elif [ ${item} -eq 2 ]; then
        read -p "new id: " id
        exit_if_empty "${id}"
    elif [ ${item} -eq 3 ]; then
        read -p "new password (if empty, randomly generated): " pass
        if [ -z ${pass} ]; then
            pass=$(do_generate_password)
        fi
    else
        echo "invalid input: " ${input}
        exit 1
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


change_password(){
    num=$1
    pass=$2
    key=`decrypt | grep "^${num} " | cut -f2 -d " "`
    id=`decrypt | grep "^${num} " | cut -f3 -d " "`
    echo num="${num}"
    echo key="${key}"
    echo id="${id}"
    echo pass="${pass}"
    update_record "${num}" "${key}" "${id}" "${pass}"
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
    decrypt | grep "^${num} " | tr -d "\n" | pbcopy
    echo "the record for '${num}' is copied in clipboard"
    decrypt | grep -v "^${num} " | encrypt
}


search(){
    key=$1
    decrypt | cut -f1,2,3 -d" " | grep -E "${key}"


    ids=($(decrypt | cut -f1,2,3 -d" " | grep -E "${key}" | cut -f1 -d" "))
    if [ ${#ids[@]} = 1 ]; then
        copy_password ${ids[0]} > /dev/null
    fi
}


generate_password(){
    do_generate_password | pbcopy
}


do_generate_password(){
    openssl rand -base64 12 | fold -w 10 | head -1 | tr -d "\n"
}


decrypt(){
    gpg --decrypt ${DATAFILE} 2> /dev/null
}


encrypt(){
    gpg -e -r "myps2" -o ${DATAFILE}
}


isnum(){
    str=$1
    expr ${str} + 1 > /dev/null 2>&1
    ret=$?
    test ${ret} -lt 2
}


min_miss(){
    decrypt | awk 'NR!=$1{print NR; exit}'
}


num_record(){
    decrypt | wc -l
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
    echo ${DATAFILE} does not exists.
    cat <<EOF
It is necessary to create data file manually. Run the next command.
$ echo | tr -d "\n" | gpg -e -r myps -o ${DATAFILE}
EOF
    exit 1
fi


if [ $# -eq 0 ]; then
    list_all_keys
    exit 0
elif isnum $1; then
    copy_password $1
    exit 0
elif [ ! "${1:0:1}" = "-" ]; then
    search $1
    exit 0
fi


getopts lp:P:i:I:au:c:D:As:gh OPT
case ${OPT} in
    l) list_all_keys                   ; exit ;;
    p) copy_password ${OPTARG}         ; exit ;;
    P) print_password ${OPTARG}        ; exit ;;
    i) copy_id ${OPTARG}               ; exit ;;
    I) print_id ${OPTARG}              ; exit ;;
    a) add_record ${OPTARG}            ; exit ;;
    u) update_record ${OPTARG}         ; exit ;;
    c) shift 1; change_password "$@"   ; exit ;; # -cを捨てている
    D) delete_record ${OPTARG}         ; exit ;;
    A) decrypt                         ; exit ;;
    s) search ${OPTARG}                ; exit ;;
    g) generate_password               ; exit ;;
    h) print_usage                     ; exit ;;
    ?) print_usage                     ; exit ;;
esac
