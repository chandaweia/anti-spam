#!/bin/bash
#echo "1111start"  >> /usr/sbin/file1.txt  
#str1 is the top line of junk email

#echo "1和2的变量" >> /usr/sbin/file1.txt
#echo "$1" >> /usr/sbin/file1.txt
#echo "$2" >> /usr/sbin/file1.txt
#echo "1和2的变量end" >> /usr/sbin/file1.txt

str1="Received: from localhost by ubuntu"
timestamp=$(date +%s.%N)
maildata=""
newline=$'\r\n'
sendmailpath="/home/spamd/sendmailcont"

#read -r data
read
if [[ $REPLY =~ $str1 ]];then
		#maildata+=$data
		#cp $sendmailpath /home/spamd/Makedir1/$2
		maildata+=$REPLY
		while read 
		do
		    maildata+="$newline"
			maildata+=$REPLY
		done
		if [ -d "/home/spamd/Makedir1/$2" ];then
           	#echo "创建的文件名:$timestamp"
           		echo "$maildata" > /home/spamd/Makedir1/$2/$timestamp
        	else
            	#echo "创建目录，创建的文件名：$timestamp"
            		mkdir -p /home/spamd/Makedir1/$2
            		echo "$maildata" > /home/spamd/Makedir1/$2/$timestamp
        fi

		#echo maildata > /usr/sbin/file1.txt

else
	#echo "不是垃圾邮件" >> /home/spamd/Makedir1/file1.txt
	/usr/sbin/sendmail -f $1 $2
fi

