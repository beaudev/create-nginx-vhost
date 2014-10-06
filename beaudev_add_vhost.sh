#!/bin/bash 
# add vhost for a new nginx project

# use like this : do_nginx_new_vhost new_project /path/to/your/project "toto.popo.com qsdqsd.popo.com"

function do_nginx_new_vhost() {

[ -z "$1" -o -z "$2" -o -z "$3" ] && echo "Give name, path and hosts" && return
name=$1
path=$2
hosts=$3

[ -f /etc/nginx/sites-enabled/project_$name ] && (echo "Updating vhost for project: $name" && sudo rm /etc/nginx/sites-enabled/project_$name && sudo rm /etc/nginx/sites-available/project_$name ) || echo "Creating vhost for project: $name"

sudo bash <<EOF
cat default-symfony-nginx.conf | sed "s/__project_name__/$name/g;s#__project_path__#$path#g;s/__project_hosts__/$hosts/g"  > /etc/nginx/sites-available/project_$name
EOF

sudo ln -s /etc/nginx/sites-available/project_$name /etc/nginx/sites-enabled/project_$name


result=`cat /etc/hosts | grep -v '^$\|^\s*\#' | grep $name`

if [ "x$result" != "x" ]; then
	echo "host already defined"
else
	last_local_ip=`cat /etc/hosts | grep -v '^$\|^\s*\#'|sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n | tail -1 |nawk '{print $1}' `
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
