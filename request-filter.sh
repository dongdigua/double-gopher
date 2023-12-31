#! /bin/sh
# inpired by the script in geomyidae

dstserver="localhost"
dstport="71"

read -r request

nc -z "${dstserver}" "${dstport}"
return=$?

if [ $return -eq 0 ];
then
	# don't use the busybox version, use the bsd one instead
	printf "%s\r\n" "${request}" | nc "${dstserver}" "${dstport}"
else
    # gophernicus don't need linebreak
	printf "${request}" | gophernicus -p 7070
fi
