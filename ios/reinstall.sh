#!/bin/sh

if [[ $EUID -ne 0 ]]; then
    clear
    echo "Error: This script must be run as root!" 1>&2
    exit 1
fi

function CopyRight() {
  clear
  echo "########################################################"
  echo "#                                                      #"
  echo "#  New Reinstall Script V4.0                           #"
  echo "#                                                      #"
  echo "#  Author: YUCHEN 815494.COM                           #"
  echo "#  Last Modified: 2022-01-11                           #"
  echo "#                                                      #"
  echo "#                                                      #"
  echo "#                                                      #"
  echo "########################################################"
  echo -e "\n"
}

function isValidIp() {
  local ip=$1
  local ret=1
  if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    ip=(${ip//\./ })
    [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
    ret=$?
  fi
  return $ret
}

function ipCheck() {
  isLegal=0
  for add in $MAINIP $GATEWAYIP $NETMASK; do
    isValidIp $add
    if [ $? -eq 1 ]; then
      isLegal=1
    fi
  done
  return $isLegal
}

function GetIp() {
  MAINIP=$(ip route get 1 | awk -F 'src ' '{print $2}' | awk '{print $1}')
  GATEWAYIP=$(ip route | grep default | awk '{print $3}')
  SUBNET=$(ip -o -f inet addr show | awk '/scope global/{sub(/[^.]+\//,"0/",$4);print $4}' | head -1 | awk -F '/' '{print $2}')
  value=$(( 0xffffffff ^ ((1 << (32 - $SUBNET)) - 1) ))
  NETMASK="$(( (value >> 24) & 0xff )).$(( (value >> 16) & 0xff )).$(( (value >> 8) & 0xff )).$(( value & 0xff ))"
}

function UpdateIp() {
  read -r -p "Your IP: " MAINIP
  read -r -p "Your Gateway: " GATEWAYIP
  read -r -p "Your Netmask: " NETMASK
}

function SetNetwork() {
  isAuto='0'
  if [[ -f '/etc/network/interfaces' ]];then
    [[ ! -z "$(sed -n '/iface.*inet static/p' /etc/network/interfaces)" ]] && isAuto='1'
    [[ -d /etc/network/interfaces.d ]] && {
      cfgNum="$(find /etc/network/interfaces.d -name '*.cfg' |wc -l)" || cfgNum='0'
      [[ "$cfgNum" -ne '0' ]] && {
        for netConfig in `ls -1 /etc/network/interfaces.d/*.cfg`
        do 
          [[ ! -z "$(cat $netConfig | sed -n '/iface.*inet static/p')" ]] && isAuto='1'
        done
      }
    }
  fi
  
  if [[ -d '/etc/sysconfig/network-scripts' ]];then
    cfgNum="$(find /etc/network/interfaces.d -name '*.cfg' |wc -l)" || cfgNum='0'
    [[ "$cfgNum" -ne '0' ]] && {
      for netConfig in `ls -1 /etc/sysconfig/network-scripts/ifcfg-* | grep -v 'lo$' | grep -v ':[0-9]\{1,\}'`
      do 
        [[ ! -z "$(cat $netConfig | sed -n '/BOOTPROTO.*[sS][tT][aA][tT][iI][cC]/p')" ]] && isAuto='1'
      done
    }
  fi
}

function NetMode() {
  CopyRight

  if [ "$isAuto" == '0' ]; then
    read -r -p "Using DHCP to configure network automatically? [Y/n]:" input
    case $input in
      [yY][eE][sS]|[yY]) NETSTR='' ;;
      [nN][oO]|[nN]) isAuto='1' ;;
      *) clear; echo "Canceled by user!"; exit 1;;
    esac
  fi

  if [ "$isAuto" == '1' ]; then
    GetIp
    ipCheck
    if [ $? -ne 0 ]; then
      echo -e "Error occurred when detecting ip. Please input manually.\n"
      UpdateIp
    else
      CopyRight
      echo "IP: $MAINIP"
      echo "Gateway: $GATEWAYIP"
      echo "Netmask: $NETMASK"
      echo -e "\n"
      read -r -p "Confirm? [Y/n]:" input
      case $input in
        [yY][eE][sS]|[yY]) ;;
        [nN][oO]|[nN])
          echo -e "\n"
          UpdateIp
          ipCheck
          [[ $? -ne 0 ]] && {
            clear
            echo -e "Input error!\n"
            exit 1
          }
        ;;
        *) clear; echo "Canceled by user!"; exit 1;;
      esac
    fi
    NETSTR="--ip-addr ${MAINIP} --ip-gate ${GATEWAYIP} --ip-mask ${NETMASK}"
  fi
}

function Start() {
  CopyRight
  
  isCN='0'
  geoip=$(wget --no-check-certificate -qO- https://api.ip.sb/geoip | grep "\"country_code\":\"CN\"")
  if [[ "$geoip" != "" ]];then
    isCN='1'
  fi

  if [ "$isAuto" == '0' ]; then
    echo "Using DHCP mode."
  else
    echo "IP: $MAINIP"
    echo "Gateway: $GATEWAYIP"
    echo "Netmask: $NETMASK"
  fi

  [[ "$isCN" == '1' ]] && echo "Using domestic mode."

  if [ -f "/tmp/InstallNET.sh" ]; then
    rm -f /tmp/InstallNET.sh
  fi
  wget --no-check-certificate -qO /tmp/InstallNET.sh 'https://www.815494.com/html/shell/dd/InstallNET.sh' && chmod a+x /tmp/InstallNET.sh

  
  CMIRROR=''
  CVMIRROR=''
  DMIRROR=''
  UMIRROR=''
  SYSMIRROR1='http://os.815494.xyz/centos/CentOS-7.img.gz'
  SYSMIRROR2='https://odc.cxthhhhh.com/SyStem/CentOS/CentOS_7.X_NetInstallation_Final_v9.2.vhd.gz'
  SYSMIRROR3='http://os.815494.xyz/centos/CentOS_8.X_NetInstallation_Stable_v4.2.vhd.gz'
  SYSMIRROR12='http://share.815494.xyz/windows/2019/Disk_Windows_Server_2019_DataCenter_CN_v5.1.vhd.gz'
  SYSMIRROR13='http://os.815494.xyz/windows/2016/winsrv2016-data-x64-cn.vhd.gz'
  SYSMIRROR14='http://share.815494.xyz/windows/2012/Disk_Windows_Server_2012R2_DataCenter_CN_v4.29.vhd.gz'
  SYSMIRROR15='http://os.815494.xyz/windows/2012/winsrv2012r2-data-x64-cn.vhd.gz'
  SYSMIRROR16='http://share.815494.xyz/windows/2008/Disk_Windows_Server_2008R2_DataCenter_CN_v3.27.vhd.gz'
  SYSMIRROR17='http://os.815494.xyz/windows/2008/winsrv2008r2-data-sp1-x64-cn.vhd.gz'
  SYSMIRROR18='http://share.815494.xyz/windows/2003/Disk_Windows_Server_2003_DataCenter_CN_v7.1.vhd.gz'
  SYSMIRROR19='http://os.815494.xyz/windows/2003/WinSrv2003x86-Chinese.vhd.gz'
  SYSMIRROR20='http://os.815494.xyz/windows/win10/Disk_Windows_10_x64_Lite_by_CXT.vhd.gz'
  SYSMIRROR21='http://os.815494.xyz/windows/win10/win10-ent-2016-ltsb-x64-cn-efi.vhd.gz'
  SYSMIRROR22='http://os.815494.xyz/windows/win7/win7-ent-sp1-x64-cn.vhd.gz'
  SYSMIRROR23='http://os.815494.xyz/windows/win7/win7-ent-sp1-x64-efi.vhd.gz'
  SYSMIRROR24='http://os.815494.xyz/windows/2008/winsrv2008r2-data-sp1-x64-efi.vhd.gz'
  SYSMIRROR25='http://os.815494.xyz/windows/2012/winsrv2012r2-data-x64-cn-efi.vhd.gz'

  if [[ "$isCN" == '1' ]];then
    CMIRROR="--mirror http://mirrors.tencent.com/centos/"
    CVMIRROR="--mirror http://mirrors.tuna.tsinghua.edu.cn/centos-vault/"
    DMIRROR="--mirror http://mirrors.tencent.com/debian/"
    UMIRROR="--mirror http://mirrors.tencent.com/ubuntu/"
    SYSMIRROR1='http://os.815494.xyz/centos/CentOS-7.img.gz'
    SYSMIRROR2='https://odc.cxthhhhh.com/SyStem/CentOS/CentOS_7.X_NetInstallation_Final_v9.2.vhd.gz'
    SYSMIRROR3='http://os.815494.xyz/centos/CentOS_8.X_NetInstallation_Stable_v4.2.vhd.gz'
    SYSMIRROR12='http://share.815494.xyz/windows/2019/Disk_Windows_Server_2019_DataCenter_CN_v5.1.vhd.gz'
    SYSMIRROR13='http://os.815494.xyz/windows/2016/winsrv2016-data-x64-cn.vhd.gz'
    SYSMIRROR14='http://share.815494.xyz/windows/2012/Disk_Windows_Server_2012R2_DataCenter_CN_v4.29.vhd.gz'
    SYSMIRROR15='http://os.815494.xyz/windows/2012/winsrv2012r2-data-x64-cn.vhd.gz'
    SYSMIRROR16='http://share.815494.xyz/windows/2008/Disk_Windows_Server_2008R2_DataCenter_CN_v3.27.vhd.gz'
    SYSMIRROR17='http://os.815494.xyz/windows/2008/winsrv2008r2-data-sp1-x64-cn.vhd.gz'
    SYSMIRROR18='http://share.815494.xyz/windows/2003/Disk_Windows_Server_2003_DataCenter_CN_v7.1.vhd.gz'
    SYSMIRROR19='http://os.815494.xyz/windows/2003/WinSrv2003x86-Chinese.vhd.gz'
    SYSMIRROR20='http://os.815494.xyz/windows/win10/Disk_Windows_10_x64_Lite_by_CXT.vhd.gz'
    SYSMIRROR21='http://os.815494.xyz/windows/win10/win10-ent-2016-ltsb-x64-cn-efi.vhd.gz'
    SYSMIRROR22='http://os.815494.xyz/windows/win7/win7-ent-sp1-x64-cn.vhd.gz'
    SYSMIRROR23='http://os.815494.xyz/windows/win7/win7-ent-sp1-x64-efi.vhd.gz'
    SYSMIRROR24='http://os.815494.xyz/windows/2008/winsrv2008r2-data-sp1-x64-efi.vhd.gz'
    SYSMIRROR25='http://os.815494.xyz/windows/2012/winsrv2012r2-data-x64-cn-efi.vhd.gz'

  fi

  echo -e "\nPlease select an OS:"
  echo "   1) CentOS 7.7 (ext4)"
  echo "   2) CentOS 7 (cxthhhh)"
  echo "   3) CentOS 8 (cxthhhh)"
  echo "   4) CentOS 6"
  echo "   5) Debian 11"
  echo "   6) Debian 10"
  echo "   7) Debian 9"
  echo "   8) Debian 8"
  echo "   9) Ubuntu 20.04"
  echo "  10) Ubuntu 18.04"
  echo "  11) Ubuntu 16.04"
  echo "  12) Windows Server 2019"
  echo "  13) Windows Server 2016"
  echo "  14) Windows Server 2012"
  echo "  15) Windows Server 2012 精简版"
  echo "  16) Windows Server 2008"
  echo "  17) Windows Server 2008 精简版"
  echo "  18) Windows Server 2003"
  echo "  19) Windows Server 2003 精简版"
  echo "  20) Windows 10 LTSC 精简版"
  echo "  21) Windows 10 LSTB (UEFI)"
  echo "  22) Windows 7 Ent 精简版"
  echo "  23) Windows 7 Ent 精简版(UEFI)"
  echo "  24) Windows Server 2008 精简版(UEFI)"
  echo "  25) Windows Server 2012 精简版(UEFI)"
  echo "  99) Custom install"
  echo "   0) Exit"
  echo -ne "\nYour option: "
  read N
  case $N in
    1) echo -e "\nPassword: Pwd@CentOS\n"; read -s -n1 -p "Press any key to continue..." ; bash /tmp/InstallNET.sh $NETSTR -dd $SYSMIRROR1 $DMIRROR ;;
    2) echo -e "\nPassword: cxthhhhh.com\n"; read -s -n1 -p "Press any key to continue..." ; bash /tmp/InstallNET.sh $NETSTR -dd $SYSMIRROR2 $DMIRROR ;;
    3) echo -e "\nPassword: cxthhhhh.com\n"; read -s -n1 -p "Press any key to continue..." ; bash /tmp/InstallNET.sh $NETSTR -dd $SYSMIRROR3 $DMIRROR ;;
    4) 
       echo -e "\n"
       read -r -p "Custom Password? [Y/n]: " input
       case $input in
         [yY][eE][sS]|[yY])
	 echo -e "\n"
         read -r -p "Press input Password(More than 8 characters and numbers. eg: 815494COM): " mypasswd
	 if [[ "$mypasswd" =~ ^[a-zA-Z0-9]{8,}$ ]]; then
            MYPASSWORD="-p ${mypasswd}"
         else
	    clear; echo "The password must exceed 8 characters and numbers!"; exit 1
         fi
         echo -e "\nPassword: $mypasswd\n"; read -s -n1 -p "Press any key to continue..." ; bash /tmp/InstallNET.sh -c 6.10 -v 64 $MYPASSWORD $NETSTR $CMIRROR;;
        *) echo -e "\nPassword: 815494.com\n"; read -s -n1 -p "Press any key to continue..." ; bash /tmp/InstallNET.sh -c 6.10 -v 64 -a -p 815494.com $NETSTR $CMIRROR;;
      esac
      ;;      
    5) 
       echo -e "\n"
       read -r -p "Custom Password? [Y/n]: " input
       case $input in
         [yY][eE][sS]|[yY])
	 echo -e "\n"
         read -r -p "Press input Password(More than 8 characters and numbers. eg: 815494COM): " mypasswd
	 if [[ "$mypasswd" =~ ^[a-zA-Z0-9]{8,}$ ]]; then
            MYPASSWORD="-p ${mypasswd}"
         else
	    clear; echo "The password must exceed 8 characters and numbers!"; exit 1
         fi
         echo -e "\nPassword: $mypasswd\n"; read -s -n1 -p "Press any key to continue..." ; bash /tmp/InstallNET.sh -d 11 -v 64 $MYPASSWORD $NETSTR $DMIRROR;;
        *) echo -e "\nPassword: 815494.com\n"; read -s -n1 -p "Press any key to continue..." ; bash /tmp/InstallNET.sh -d 11 -v 64 -a -p 815494.com $NETSTR $DMIRROR;;
      esac
      ;; 
    6) 
       echo -e "\n"
       read -r -p "Custom Password? [Y/n]: " input
       case $input in
         [yY][eE][sS]|[yY])
	 echo -e "\n"
         read -r -p "Press input Password(More than 8 characters and numbers. eg: 815494COM): " mypasswd
	 if [[ "$mypasswd" =~ ^[a-zA-Z0-9]{8,}$ ]]; then
            MYPASSWORD="-p ${mypasswd}"
         else
	    clear; echo "The password must exceed 8 characters and numbers!"; exit 1
         fi
         echo -e "\nPassword: $mypasswd\n"; read -s -n1 -p "Press any key to continue..." ; bash /tmp/InstallNET.sh -d 10 -v 64 $MYPASSWORD $NETSTR $DMIRROR;;
        *) echo -e "\nPassword: 815494.com\n"; read -s -n1 -p "Press any key to continue..." ; bash /tmp/InstallNET.sh -d 10 -v 64 -a -p 815494.com $NETSTR $DMIRROR;;
      esac
      ;; 
    7) 
       echo -e "\n"
       read -r -p "Custom Password? [Y/n]: " input
       case $input in
         [yY][eE][sS]|[yY])
	 echo -e "\n"
         read -r -p "Press input Password(More than 8 characters and numbers. eg: 815494COM): " mypasswd
	 if [[ "$mypasswd" =~ ^[a-zA-Z0-9]{8,}$ ]]; then
            MYPASSWORD="-p ${mypasswd}"
         else
	    clear; echo "The password must exceed 8 characters and numbers!"; exit 1
         fi
         echo -e "\nPassword: $mypasswd\n"; read -s -n1 -p "Press any key to continue..." ; bash /tmp/InstallNET.sh -d 9 -v 64 $MYPASSWORD $NETSTR $DMIRROR;;
        *) echo -e "\nPassword: 815494.com\n"; read -s -n1 -p "Press any key to continue..." ; bash /tmp/InstallNET.sh -d 9 -v 64 -a -p 815494.com $NETSTR $DMIRROR;;
      esac
      ;; 
    8)
       echo -e "\n"
       read -r -p "Custom Password? [Y/n]: " input
       case $input in
         [yY][eE][sS]|[yY])
	 echo -e "\n"
         read -r -p "Press input Password(More than 8 characters and numbers. eg: 815494COM): " mypasswd
	 if [[ "$mypasswd" =~ ^[a-zA-Z0-9]{8,}$ ]]; then
            MYPASSWORD="-p ${mypasswd}"
         else
	    clear; echo "The password must exceed 8 characters and numbers!"; exit 1
         fi
         echo -e "\nPassword: $mypasswd\n"; read -s -n1 -p "Press any key to continue..." ; bash /tmp/InstallNET.sh -d 8 -v 64 $MYPASSWORD $NETSTR $DMIRROR;;
        *) echo -e "\nPassword: 815494.com\n"; read -s -n1 -p "Press any key to continue..." ; bash /tmp/InstallNET.sh -d 8 -v 64 -a -p 815494.com $NETSTR $DMIRROR;;
      esac
      ;; 
    9) 
       echo -e "\n"
       read -r -p "Custom Password? [Y/n]: " input
       case $input in
         [yY][eE][sS]|[yY])
	 echo -e "\n"
         read -r -p "Press input Password(More than 8 characters and numbers. eg: 815494COM): " mypasswd
	 if [[ "$mypasswd" =~ ^[a-zA-Z0-9]{8,}$ ]]; then
            MYPASSWORD="-p ${mypasswd}"
         else
	    clear; echo "The password must exceed 8 characters and numbers!"; exit 1
         fi
         echo -e "\nPassword: $mypasswd\n"; read -s -n1 -p "Press any key to continue..." ; bash /tmp/InstallNET.sh -u 20.04 -v 64 $MYPASSWORD $NETSTR $UMIRROR;;
        *) echo -e "\nPassword: 815494.com\n"; read -s -n1 -p "Press any key to continue..." ; bash /tmp/InstallNET.sh -u 20.04 -v 64 -a -p 815494.com $NETSTR $UMIRROR;;
      esac
      ;; 
    10) 
       echo -e "\n"
       read -r -p "Custom Password? [Y/n]: " input
       case $input in
         [yY][eE][sS]|[yY])
	 echo -e "\n"
         read -r -p "Press input Password(More than 8 characters and numbers. eg: 815494COM): " mypasswd
	 if [[ "$mypasswd" =~ ^[a-zA-Z0-9]{8,}$ ]]; then
            MYPASSWORD="-p ${mypasswd}"
         else
	    clear; echo "The password must exceed 8 characters and numbers!"; exit 1
         fi
         echo -e "\nPassword: $mypasswd\n"; read -s -n1 -p "Press any key to continue..." ; bash /tmp/InstallNET.sh -u 18.04 -v 64 $MYPASSWORD $NETSTR $UMIRROR;;
        *) echo -e "\nPassword: 815494.com\n"; read -s -n1 -p "Press any key to continue..." ; bash /tmp/InstallNET.sh -u 18.04 -v 64 -a -p 815494.com $NETSTR $UMIRROR;;
      esac
      ;; 
    11) 
       echo -e "\n"
       read -r -p "Custom Password? [Y/n]: " input
       case $input in
         [yY][eE][sS]|[yY])
	 echo -e "\n"
         read -r -p "Press input Password(More than 8 characters and numbers. eg: 815494COM): " mypasswd
	 if [[ "$mypasswd" =~ ^[a-zA-Z0-9]{8,}$ ]]; then
            MYPASSWORD="-p ${mypasswd}"
         else
	    clear; echo "The password must exceed 8 characters and numbers!"; exit 1
         fi
         echo -e "\nPassword: $mypasswd\n"; read -s -n1 -p "Press any key to continue..." ; bash /tmp/InstallNET.sh -u 16.04 -v 64 $MYPASSWORD $NETSTR $UMIRROR;;
        *) echo -e "\nPassword: 815494.com\n"; read -s -n1 -p "Press any key to continue..." ; bash /tmp/InstallNET.sh -u 16.04 -v 64 -a -p 815494.com $NETSTR $UMIRROR;;
      esac
      ;; 
    12) echo -e "\nPassword: cxthhhhh.com\n"; read -s -n1 -p "Press any key to continue..." ; bash /tmp/InstallNET.sh $NETSTR -dd $SYSMIRROR12 $DMIRROR ;;
    13) echo -e "\nPassword: cxthhhhh.com\n"; read -s -n1 -p "Press any key to continue..." ; bash /tmp/InstallNET.sh $NETSTR -dd $SYSMIRROR13 $DMIRROR ;;
    14) echo -e "\nPassword: cxthhhhh.com\n"; read -s -n1 -p "Press any key to continue..." ; bash /tmp/InstallNET.sh $NETSTR -dd $SYSMIRROR14 $DMIRROR ;;
    15) echo -e "\nPassword: nat.ee\n"; read -s -n1 -p "Press any key to continue..." ; bash /tmp/InstallNET.sh $NETSTR -dd $SYSMIRROR15 $DMIRROR ;;
    16) echo -e "\nPassword: cxthhhhh.com\n"; read -s -n1 -p "Press any key to continue..." ; bash /tmp/InstallNET.sh $NETSTR -dd $SYSMIRROR16 $DMIRROR ;;
    17) echo -e "\nPassword: nat.ee\n"; read -s -n1 -p "Press any key to continue..." ; bash /tmp/InstallNET.sh $NETSTR -dd $SYSMIRROR17 $DMIRROR ;;
    18) echo -e "\nPassword: cxthhhhh.com\n"; read -s -n1 -p "Press any key to continue..." ; bash /tmp/InstallNET.sh $NETSTR -dd $SYSMIRROR18 $DMIRROR ;;
    19) echo -e "\nPassword: WinSrv2003x86-Chinese\n"; read -s -n1 -p "Press any key to continue..." ; bash /tmp/InstallNET.sh $NETSTR -dd $SYSMIRROR19 $DMIRROR ;;
    20) echo -e "\nPassword: cxthhhhh.com\n"; read -s -n1 -p "Press any key to continue..." ; bash /tmp/InstallNET.sh $NETSTR -dd $SYSMIRROR20 $DMIRROR ;;
    21) echo -e "\nPassword: nat.ee\n"; read -s -n1 -p "Press any key to continue..." ; bash /tmp/InstallNET.sh $NETSTR -dd $SYSMIRROR21 $DMIRROR ;;
    22) echo -e "\nPassword: nat.ee\n"; read -s -n1 -p "Press any key to continue..." ; bash /tmp/InstallNET.sh $NETSTR -dd $SYSMIRROR22 $DMIRROR ;;   
    23) echo -e "\nPassword: nat.ee\n"; read -s -n1 -p "Press any key to continue..." ; bash /tmp/InstallNET.sh $NETSTR -dd $SYSMIRROR23 $DMIRROR ;;   
    24) echo -e "\nPassword: nat.ee\n"; read -s -n1 -p "Press any key to continue..." ; bash /tmp/InstallNET.sh $NETSTR -dd $SYSMIRROR24 $DMIRROR ;;   
    25) echo -e "\nPassword: nat.ee\n"; read -s -n1 -p "Press any key to continue..." ; bash /tmp/InstallNET.sh $NETSTR -dd $SYSMIRROR25 $DMIRROR ;;   
    99)
      echo -e "\n"
      read -r -p "Custom image URL: " imgURL
      echo -e "\n"
      read -r -p "Are you sure start reinstall? [Y/n]: " input
      case $input in
        [yY][eE][sS]|[yY]) bash /tmp/InstallNET.sh $NETSTR -dd $imgURL $DMIRROR ;;
        *) clear; echo "Canceled by user!"; exit 1;;
      esac
      ;;
    0) exit 0;;
    *) echo "Wrong input!"; exit 1;;
  esac
}

SetNetwork
NetMode
Start
