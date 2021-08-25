#!/bin/sh

postgres_pw=crossent12
helm_ns={{ .global.namespace }}
POD=(`kubectl get pod -n ${helm_ns} | grep postgresql-0`)
harbor=("clair" "registry" "notary_server" "notary_signer")

function postgres(){
        kubectl -n "${helm_ns}" exec ${POD[0]} -- psql postgresql://postgres:"${postgres_pw}"@localhost:5432 -c "$1"
}

echo "[INFO] Start postgresql SQL"

for i in "${harbor[@]}"
do
        postgres "create database "$i";"
        postgres "grant connect on database "$i" to postgres;"
done

output=`postgres "\l"`

for i in "${harbor[@]}"
do
	if [[ "$output" =~ "$i" ]]; then
		echo "${i} database create Succeeded!!"
	else
		echo "not complete"
	fi
done
