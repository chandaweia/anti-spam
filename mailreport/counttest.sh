#!/bin/bash
DIR="/home/spamd/Makedir1"  # Define Root DIR
DIR_BAK="/home/spamd/Makedir1.bak"
#ls -l ${DIR} | grep "^-" | wc -l
#let "filenum=0"
sendmailname="sendmailcont"
mail_templet_path="/home/spamd/mailreport/sendmailcont"
spamasscont="sendcont"
spamasscontbase="sendcontbase"

function getcont_base64()
{
	#$1 目录 $2用户 $3文件名
	filedir=$1/$2/$3
	echo "filedir=$filedir"
	keywords="Content-Type:"
	boundary=$(grep -n "$keywords" "$filedir" | head -1 | cut -d '"' -f 2)
	
	let a=1
	let num=0
	newline=""
	while read -r line
	do
		if [[ $line =~ $boundary ]]; then
			array[num]=$a
			let num+=1
			let a+=1
			#echo "num=${num} "
		else
			let a+=1
		fi
	done < $filedir
	echo "array所有内容："${array[@]}
	len=${#array[@]}
	start_n=`expr $len - 2`
	end_n=`expr $len - 1`
	echo "start_n:$start_n"
	echo "end_n:$end_n"
	let array[${start_n}]+=6
	let array[${end_n}]-=1
	start_line=${array[${start_n}]}
	echo "start_line:$start_line"
	end_line=${array[${end_n}]}
	echo "end_line:$end_line"

	content=$(cat $filedir|sed -n "${start_line},${end_line}p")
	echo "$content" > $1/$2/$spamasscont
	basecont=$(cat $1/$2/$spamasscont|base64)
	echo "$basecont" > $1/$2/$spamasscontbase
}

function filetomail()
{
	sendfile=$1/$2/$sendmailname
	#cp $1/$2/$3 /root/
	#content=`getcont_base64 ${DIR} ${file} ${file1}	`
	#将内容逐个保存到send_mail中
	#getcont_base64 ${DIR} ${file} ${file1}
	#mail_templet=$1/$2/$sendmailname
	if [ ! -f "$sendfile" ];then
		cp $mail_templet_path $1/$2
	fi
	getcont_base64 $1 $2 $3
	
	echo "Content-Type: application/octet-stream;" >> $sendfile
	echo "    name=\"junk$4.eml\" "  >> $sendfile
	echo "Content-Transfer-Encoding: base64" >> $sendfile
	echo "Content-Disposition: attachment;" >> $sendfile
	echo "    filename=\"junk$4.eml\"" >> $sendfile
	echo "" >> $sendfile
	cat $1/$2/$spamasscontbase >> $sendfile

	echo "$newline" >> $sendfile
	echo "$newline" >> $sendfile
	echo "------=_001_NextPart358747382538_=----" >> $sendfile

}

function altermail()
{
	datenow=`date -R`
	line="Date: "$datenow
	sed -i "1c $line" $1/$2/$sendmailname

	#修改Today you receive filenum junk mails
	formerwords="Today you receive 3 "
	laterwords="Today you receive $3 "
	sed -i "s/${formerwords}/${laterwords}/g" $1/$2/$sendmailname
}

function sendmailreport()
{
	bakdir=$DIR_BAK"/"$2
	altermail $1 $2 $3 
	echo "sendmailreport发送-》$2"
	cat $1/$2/$sendmailname |/usr/sbin/sendmail -t $2
	#发送完邮件应该删除
	rm $1/$2/$sendmailname $1/$2/$spamasscont $1/$2/$spamasscontbase	
	if [ -d $bakdir ];then
		echo "拷贝"
		cp -R $1/$2/* $bakdir
		rm -rf $1/$2
	else
		echo "创建$bakdir"
		mkdir -p $bakdir
		cp -R $1/$2/* $bakdir
		rm -rf $1/$2
	fi
	
}

function readfile ()
{
  #这里`为esc下面的按键符号
  filepath=""
  echo "总目录1=$DIR"
  let "filenum=0"
  for file in `ls $DIR`
  do
	#echo "收件人file=$file"
    #这里的-d表示是一个directory，即目录/子文件夹
    if [ -d $DIR"/"$file ];then
		echo $file
		res=$?
		if [ $res -eq 0 ];then
		  for file1 in `ls ${DIR}/${file}`
		  do
			#echo "file1=$file1"
			#let filenum+=1
			#$filepath="${DIR}/${file}"
			if [ "$file1"x != "sendcont"x ] && [ "$file1"x != "sendcontbase"x ] && [ "$file1"x != "sendmailcont"x ];then
				#echo "file名不是sendcont"
				echo "file1=$file1"
				let filenum+=1
				filetomail ${DIR} ${file} ${file1} ${filenum}
			fi
		  done
	   	  echo "用户：${file} 数量:${filenum}"
	 	  echo -e "\n"
		else
			rm $DIR/$file/*
	  	  #sendmailreport ${DIR} ${file} ${filenum}
		fi

		if [ ${filenum} -gt 0 ];then
			echo "shuliang:${filenum} 发送邮件-》${file}"
			sendmailreport ${DIR} ${file} ${filenum}
		fi
     fi
	 #sendmailreport ${DIR} ${file}
     let filenum=0
  done
}

#函数定义结束，这里用来运行函数
#folder="/home/spamd/Makedir1"
readfile 

