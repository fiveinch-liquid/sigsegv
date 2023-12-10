#!/bin/bash

if [ -z "$1" ]; then
    echo "No argument supplied" >&2
    exit 1
fi

ROOT=/
if ! [ -z "$2" ]; then
    ROOT="$2"
fi

READELF=readelf
INPUT="$1"


SimplePath() {
    echo "$1" | sed 's/\/\/*/\//g'
}

GenSoBase() {
    ${READELF} -n /proc/self/fd/0 | grep -zPo '0x[0-9a-fA-F]+\s+0x[0-9a-fA-F]+\s+0x[0-9a-fA-F]+\n\s+.+?\n' | tr '\n' ' ' | tr '\0' '\n' | sed 's/[ \t][ \t]*/ /g' | cut -d ' ' -f 1,4 | uniq -f1 | awk '{print $2,$1}'
}

echo "so name,so base,so .text offset,load to,command"
GenSoBase <"${INPUT}" | while read LINE; do 
    PAIR=(${LINE})
    LOCATION=$(SimplePath "${ROOT}/${PAIR[0]}")
    OFFS=0x$(${READELF} -S ${LOCATION} | grep -P '^\s+\[[0-9]+\]\s+\.text\s+[A-Z]+\s+[0-9a-fA-F]+\s+[0-9a-fA-F]+$' | sed 's/[ \t][ \t]*/ /g' | sed -e 's/^ *//' | cut -d ' ' -f 5)
    ABS=$((${PAIR[1]}+${OFFS}))
    COMMAND=$(printf "add-symbol-file %s 0x%x" ${LOCATION} ${ABS})
    printf "%s,%s,%s,0x%x,%s\n" "${LOCATION}" "${PAIR[1]}" "${OFFS}" ${ABS} "${COMMAND}"
done
