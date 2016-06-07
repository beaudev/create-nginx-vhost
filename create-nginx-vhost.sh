#!/bin/bash 
# add vhost for a new nginx project

# use like this : do_nginx_new_vhost new_project symfony-php5-fpm-nginx /path/to/your/project "toto.popo.com qsdqsd.popo.com"

function do_nginx_new_vhost() {

cur_dir=$( dirname "${BASH_SOURCE[0]}" )

[ -z "$1" -o -z "$2" -o -z "$3" -o -z "$4" ] && echo "Give name, type, path and hosts" && return
name=$1
type=$2
path=$3
hosts=$4

if [ ! -f ${cur_dir}/profiles/${type}.conf ]; then
  echo -e "profile ${type} doesn't exist\nChoose one profile among :\n`ls ${cur_dir}/profiles/`" && return
fi

[ -f /etc/nginx/sites-enabled/project_$name.conf ] && (echo "Updating vhost for project: $name" && sudo rm /etc/nginx/sites-enabled/project_$name.conf && sudo rm /etc/nginx/sites-available/project_$name.conf ) || echo "Creating vhost for project: $name"

sudo bash <<EOF
cat ${cur_dir}/profiles/${type}.conf | sed "s/__project_name__/$name/g;s#__project_path__#$path#g;s/__project_hosts__/$hosts/g"  > /etc/nginx/sites-available/project_$name.conf
EOF

sudo ln -s /etc/nginx/sites-available/project_$name.conf /etc/nginx/sites-enabled/project_$name.conf


result=`cat /etc/hosts | grep -v '^$\|^\s*\#' | grep $hosts`

if [ "x$result" != "x" ]; then
	echo "host already defined"
else
	last_local_ip=`cat /etc/hosts | grep 127 | grep -v '^$\|^\s*\#'|sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n | tail -1 |nawk '{print $1}' `
	[ -z "$last_local_ip" ] && echo "No Ips in your hosts file, strange..." && exit
	baseaddr="$(echo $last_local_ip | cut -d. -f1-3)"
	next_ip=$(echo $last_local_ip | cut -d. -f4)

	if [ $((next_ip+1)) -gt 255 ]; then
		echo "no more available ip, consider cleaning"
		exit
	else
		echo "$baseaddr."$((next_ip+1))" "$hosts | sudo tee -a /etc/hosts
	fi
fi
sudo service nginx restart
}
