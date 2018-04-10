#!/bin/bash

DEFAULT_USER=Test
DEFAULT_PASS="123456"
DEFAULT_PORT=22

HOSTS=`cat $1`             
SSH_USER=$DEFAULT_USER
SSH_PASS=$DEFAULT_PASS
SSH_PORT=$DEFAULT_PORT


function ProduceKey()
{
#set -x
	echo -e "\033[36m Producing id_rsa keys \033[0m"	
	/usr/bin/ssh-keygen -t rsa -f $HOME/.ssh/id_rsa -P ""  1>/dev/null 
#set +x
}


function InstallSshpass()
{
#set -x
	echo -e "\033[36m Installing sshpass... \033[0m"
	rpm -ivh ./rpms/sshpass-1.06-1.el7.x86_64.rpm 1>/dev/null;
	command -v sshpass 1>/dev/null && echo -e "\033[36m sshpass install sucess\033[0m" 
#set +x
}

##把.ssh/id_rsa.pub复制到列表主机的.ssh/authorized_keys
function SshCopyId()
{
#set -x
	echo -e "\033[1;42;37m=======================Copying id_rsa.pub To Remote=======================\033[0m"
	for host in $HOSTS
	do
		echo -e "\033[36m Copying $HOME/.ssh/id_rsa.pub  ====> $host\033[0m"	
		/usr/bin/sshpass -p $SSH_PASS /usr/bin/ssh-copy-id -p $SSH_PORT -i $HOME/.ssh/id_rsa.pub -o StrictHostKeyChecking=no $SSH_USER@$host 1>/dev/null 2>&1
		
	done
#set +x
}

##如果到$host主机执行命令grep IP与$host一直则认为ssh配置OK
function Checkssh()
{
#set -x
	echo -e "\033[1;42;37m=====================Testing ssh Connection on Remote=====================\033[0m"
	for  host in $HOSTS
	do
		#echo -e "\033[32m'$host'\033[36m : Checking ssh \033[0m"	
		#ssh  $SSH_USER@$host "ip a|grep -o $host 1>/dev/null && ( echo -e '\033[36m Test ssh Sucess on \033[32m    $host \033[0m')"
		ssh  $SSH_USER@$host "grep -rn $host /etc/sysconfig/network-scripts/ 1>/dev/null && ( echo -e '\033[36m Test ssh Sucess on \033[32m    $host \033[0m')"
	done
#set +x
}


function Main()
{
	echo -e "\033[1;42;37m=====================================Start=================================\033[0m"
	ls $HOME/.ssh/id_rsa $HOME/.ssh/id_rsa.pub 1>/dev/null 2>&1 || ProduceKey ##如果已经生成，就不再生成

	command -v sshpass 1>/dev/null || InstallSshpass  ##如果安装了，就不再安装

	SshCopyId
	
	Checkssh
	
	echo -e "\033[1;42;37m=====================================Done=================================\033[0m"
}

Main




