f()
{
   sudofile="/etc/sudoers"
   sshdfile="/etc/ssh/sshd_config"
   sshdconfd="/etc/ssh/sshd_config.d"
   mkdir -p /home/backup
   if [ -f $sudofile ];then
        cp -p $sudofile /home/backup/sudoers-$now
        sa=`grep $USER $sudofile | wc -l`
        if [ $sa -gt 0 ];then
             echo "$USER user already present in $sudofile - no changes required"
             grep $USER $sudofile
        else
#             echo "$USER ALL=(ALL) ALL" >> $sudofile
             echo "$USER ALL=(ALL) NOPASSWD: ALL" >> $sudofile
             echo "updated the sudoers file successfully"
        fi
   else
        echo "could not find $sudofile"
   fi
   if [ -d $sshdconfd ];then
       if [ -f $sshdconfd/60-cloudimg-settings.conf ];then
            sed -i '/PasswordAuthentication.*no/d' $sshdconfd/60-cloudimg-settings.conf
            sed -i '/PasswordAuthentication.*yes/d' $sshdconfd/60-cloudimg-settings.conf
            echo "PasswordAuthentication yes" >> $sshdconfd/60-cloudimg-settings.conf
       else
          echo "$sshdconfd/60-cloudimg-settings.conf does not exist"  
       fi
   else
      echo "$sshdconfd does not exist... continue with $sshdfile"
   fi          
   if [ -f $sshdfile ];then
        cp -p $sshdfile /home/backup/sshd_config-$now
        sed -i '/ClientAliveInterval.*0/d' $sshdfile
        echo "ClientAliveInterval 240" >> $sshdfile
        sed -i '/PasswordAuthentication.*no/d' $sshdfile
        sed -i '/PasswordAuthentication.*yes/d' $sshdfile
        echo "PasswordAuthentication yes" >> $sshdfile
        #sed -i '/PermitRootLogin.*yes/d' $sshdfile
        #sed -i '/PermitRootLogin.*prohibit-password/d' $sshdfile
        #echo "PermitRootLogin yes" >> $sshdfile
        echo "updated $sshdfile Successfully -- restarting sshd service"
        service sshd restart
   else
        echo "could not find $sshdfile"
   fi
}

############### MAIN ###################

USER="admin"
GROUP="admin"
passw="admin@123"

if id -u "$USER" &>/dev/null; then 
   echo "$USER user exists no action required.."
   exit 0
else
  echo "$USER user missing, continue to create it.."
fi

if [ -f /etc/os-release ];then
   osname=`grep ID /etc/os-release | egrep -v 'VERSION|LIKE|VARIANT|PLATFORM' | cut -d'=' -f2 | sed -e 's/"//' -e 's/"//'`
   echo $osname
else
   echo "can not locate /etc/os-release - unable find the osname"
   exit 8
fi

case "$osname" in
  sles|amzn|ubuntu|centos)
     userdel -r $USER 
     groupdel $GROUP
     sleep 3
     groupadd $GROUP
     useradd $USER -m -d /home/$USER -s /bin/bash -g $GROUP
     setup_pass $osname
     update_conf
    ;;
  *)
    echo "could not determine the correct osname -- found $osname"
    ;;
esac
exit 0
