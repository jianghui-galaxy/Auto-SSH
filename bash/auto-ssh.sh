#!/bin/bash


ADDMODE=true

##Remote Default
DEFAULT_USER=root
DEFAULT_PASS="root123"
DEFAULT_PORT=22

##Local
LOCAL_USER=root
LOCAL_PASS="root123"
LOCAL_IP=10.110.200.153

HOST=`cat $1`             ##第一个参数（文件）中的IP作为集群中的IP
USER=$DEFAULT_USER
PASS=$DEFAULT_PASS
PORT=$DEFAULT_PORT


##01如果已经存在.ssh文件夹，先做一次备份，然后生成.ssh/id_rsa
#	 /不存在，直接生成.ssh/id_rsa
#.ssh		  			/不存在
#	 \存在,判断.ssh.bak
#			  			\存在，删除
function BackupDir()
{
#set -x
	echo -e "\033[32m'$LOCAL_IP'\033[36m : Backing up $HOME/.ssh \033[0m"	
	test -d  $HOME/.ssh && ( test -d $HOME/.ssh.bak && rm -rf $HOME/.ssh.bak ; mv $HOME/.ssh $HOME/.ssh.bak ) 1>/dev/null
#set +x
}

##02生成.ssh/id_rsa
function ProduceKey()
{
#set -x
	echo -e "\033[32m'$LOCAL_IP'\033[36m : Producing id_rsa keys \033[0m"	
	ssh-keygen -t rsa -f $HOME/.ssh/id_rsa -P ""  1>/dev/null #2> >( while read line; do echo -e "\e[01;31m$line\e[0m" >&2; done )
	
#set +x
}

##安装sshpass-1.06-1.el7.x86_64.rpm
function InstallSshpass()
{
#set -x
	echo -e "\033[32m'$LOCAL_IP'\033[36m : Checking sshpass \033[0m"	
	command -v sshpass 1>/dev/null && echo -e "\033[36m sshpass existing\033[0m" || (echo -e "\033[36m Installing sshpass... \033[0m"; rpm -ivh ./rpms/sshpass-1.06-1.el7.x86_64.rpm 1>/dev/null;  command -v sshpass 1>/dev/null && echo -e "\033[36m sshpass install sucess\033[0m" )
#set +x
}

##把.ssh/id_rsa.pub复制到列表主机的.ssh/authorized_keys
function SshCopyId()
{
#set -x
	echo -e "\033[1;42;37m=======================Copying id_rsa.pub To Remote=======================\033[0m"
	for host in $HOST
	do
	#	if [[ $host == $LOCAL_IP ]] ;then 
	#		continue
	#	fi
		echo -e "\033[36m Copying $HOME/.ssh/id_rsa.pub  \033[32m $LOCAL_IP ====> $host\033[0m"	
		/usr/bin/sshpass -p $PASS /usr/bin/ssh-copy-id -p $PORT -i $HOME/.ssh/id_rsa.pub -o StrictHostKeyChecking=no $USER@$host 1>/dev/null 2>&1
		
	done
#set +x
}

##如果到$host主机执行命令grep IP与$host一直则认为ssh配置OK
function Checkssh()
{
#set -x
	echo -e "\033[1;42;37m=====================Testing ssh Connection on Remote=====================\033[0m"
	for  host in $HOST
	do
	#	if [[ $host == $LOCAL_IP ]]; then
	#		continue
	#	fi
		echo -e "\033[32m'$host'\033[36m : Checking ssh \033[0m"	
		ssh  $USER@$host "ip a|grep -o $host 1>/dev/null && ( echo -e '\033[36m Test ssh Sucess on \033[32m    $host \033[0m')"
	done
#set +x
}

function RemoteProduceKey()
{
#set -x
	echo -e "\033[1;42;37m=======================Generating ssh-key on Remote=======================\033[0m"
	for host in $HOST
	do
		if [[ $host == $LOCAL_IP ]]; then 
			continue
		fi
		echo -e "\033[32m'$host'\033[36m : Producing id_rsa keys \033[0m"	
		ssh  $USER@$host 'ssh-keygen -t rsa -f $HOME/.ssh/id_rsa -P "" 1>/dev/null'
		echo -e "\033[36m ssh-key Generating on \033[32m    '$host' \033[0m"
	done
#set +x
}

function RemoteInstallSshpass()
{
#set -x
	echo -e "\033[1;42;37m========================Checking sshpass on Remote========================\033[0m"
	for host in $HOST
	do
		if [[ $host == $LOCAL_IP ]] ;then
			 continue
		fi
		echo -e "\033[32m'$host'\033[36m : Checking sshpass \033[0m"
		ssh  $USER@$host "command -v sshpass 1>/dev/null" || ( scp ./rpms/sshpass-1.06-1.el7.x86_64.rpm  $USER@$host:$HOME 1>/dev/null; ssh  $USER@$host "rpm -ivh $HOME/sshpass-1.06-1.el7.x86_64.rpm 1>/dev/null")
	done
#set +x
}
function RemoteSshCopyId()
{
#set -x
	echo -e "\033[1;42;37m==================Copying id_rsa.pub From Remote To Local=================\033[0m"
	for host in $HOST
	do
		if [[ $host == $LOCAL_IP ]] ;then 
			continue
		fi
		echo -e "\033[36m Copying $HOME/.ssh/id_rsa.pub  \033[32m $host ====> $LOCAL_IP\033[0m"	
		ssh $USER@$host "/usr/bin/sshpass -p $LOCAL_PASS /usr/bin/ssh-copy-id -p $PORT -i $HOME/.ssh/id_rsa.pub  -o StrictHostKeyChecking=no  $LOCAL_USER@$LOCAL_IP " 1>/dev/null 2>&1
	done
#set +x
}


function Deloy()
{
#set -x
	echo -e "\033[1;42;37m=====================Copying authorized_keys To Remote====================\033[0m"
	for  host in $HOST
	do
		if [[ $host == $LOCAL_IP ]] ;then
			continue
		fi
		echo -e "\033[36m Copying $HOME/.ssh/authorized_keys  \033[32m $LOCAL_IP ====> $host\033[0m"	
		scp $HOME/.ssh/authorized_keys  $USER@$host:$HOME/.ssh/authorized_keys 1>/dev/null
	done
#set +x
}


BackupDir
#if ($ADDMODE==true ){
#	ProduceKey
#}
#else{
#	echo -e "\033[36mAdding Hosts Mode\033[0m"
#}
ProduceKey
InstallSshpass
SshCopyId
Checkssh
RemoteProduceKey
RemoteInstallSshpass
RemoteSshCopyId
Deloy

echo -e "\033[1;42;37m=====================================Done=================================\033[0m"
