#!/bin/bash
folderToTransfer=$1
getFolder(){
	if [ "$folderToTransfer" = "" ]; then
		echo "enter"
 	elif [ -d "$folderToTransfer" ]; then
		echo "$folderToTransfer"
	else 
		echo "error"
	fi
}
folder="$(getFolder)"

if [ "$folder" = "error" ]; then
	echo "Folder does not exists"
	exit 0
elif [ "$folder" = "enter" ]; then
	echo "Please ented folder path, example: /var/www/html/mysite"
	exit 0
fi
dateVar=$(date +%d-%b-%H_%M)
folderVar=~/migate-files-sql-${dateVar}

rm -rf ${folderVar}
mkdir ${folderVar}

read -p "Please type mysql user: " mysqlUser 


databases=$(mysql -u $mysqlUser -p -N  <<<"show databases")
if [ $? -ne 0 ]; then
		echo "Error found during backup"
		rm -rf ${folderVar}
		exit 1
	fi
getDb(){
	select db in $databases; do
 	echo $db
 		break
	done
}
echo "Please select database"
database="$(getDb)"

checkDB(){
	if [ "$database" = "" ];then 
		echo "notgood"
		exit 1
	else
		for i in $databases
			do
				if [ $i = $database ];then
				echo "allgood"
				break
			fi
		done
	fi
}

if [ "$(checkDB)" = "allgood" ];then
	echo "Please confirm mysql password."
	mysqldump -u ${mysqlUser} -p ${database} > $folderVar/$database.sql
	if [ $? -eq 0 ]; then
		echo "Database backup successfully completed"
	else
		echo "Error found during backup"
		rm -rf ${folderVar}
		exit 1
	fi
else 
	echo "wrong database selected"
	exit 0
fi

read -p "Remote mysql host:" remoteMySqlHost
read -p "Remote mysql port:" remoteMySqlPort
read -p "Remote mysql user:" remoteMySqlUser
read -p "Remote mysql database:" remoteMySqlDatabase

mysqldump -p ${remoteMySqlPort} -h ${remoteHost} -u ${remoteMySqlUser} -p ${remoteMySqlDatabase} < $folderVar/$database.sql
if [ $? -eq 0 ]; then
		echo "Database successfult uploaded"
	else
		echo "Error occured."
		rm -rf ${folderVar}
		exit 1
	fi
fi

read -p "Remote server ssh user": remoteSshUser
read -p "Remote server ssh ip": remoteSshIp
read -p "Remote server ssh port": remoteSshPort
read -p "Remote server directory": remoteSshDir

scp -r -P ${remoteSshPort} ${folderVar} ${remoteSshUser}@${remoteSshIp}:/${remoteSshDir}
if [$? -eq 0]; then 
		echo "Filer uploaded"
	else 
		echo "Error occured while uploading files"
		rm -rf ${folderVar}
		exit 1
	fi
fi

