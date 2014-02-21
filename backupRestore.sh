#!/bin/bash
# New Backup restoration tool 2013 11 27
#-----------------------------------------------------

# vars
username=$1
backupserver="123.123.123.123"
temphomedir="/home"

nr=`cat /root/serverBackupNr`
serverID=`hostname -a | awk '{print $1;}'`
#

echo `clear`
if [ "$username" = '' ] || [ "$username" = "*" ] || [ "$username" = "/" ] || [ -z $username ]; then
    echo "Enter the username on the account:"
    read username
fi
if [ "$username" = '' ] || [ "$username" = "*" ] || [ "$username" = "/" ] || [ -z $username ]; then
        echo "Incorrect or no username entered, quitting."
        exit 0;
fi

echo `clear`
echo "Account Backup restoration tool"
echo "--------------------------------------------"
echo "Connecting to $backupserver server.."

ssh -qt root@$backupserver -p 5522 "stat --format=%z /backup$nr/$serverID/weekly/$username/homedir | awk '{print \$1;}' > $username-homedir.txt;
stat --format=%z /backup$nr/$serverID/weekly/$username/cpmove-$username.tar.gz | awk '{print \$1;}' > $username-cpmove.txt;
echo;"

#--------------------------------------------------

scp -P 5522 root@$backupserver:/root/$username-homedir.txt $username-homedir.txt
scp -P 5522 root@$backupserver:/root/$username-cpmove.txt $username-cpmove.txt


if [ -n $username-homedir.txt ]; then homedirdate=`cat $username-homedir.txt`
else homedirdate=''
fi
if [ -n $username-cpmove.txt ]; then cpmovedate=`cat $username-cpmove.txt`
else cpmovedate=''
fi

rm -f "$username-homedir.txt"
rm -f "$username-cpmove.txt"

#--------------------------------------------------
echo `clear`
echo "Account Backup restoration tool"
echo "--------------------------------------------"
echo "Connected to $backupserver server."
echo "--------------------------------------------"
echo ""
echo ""
echo "Backup results for username $username:"
echo ""
    if [ "$cpmovedate" != '' ]; then echo "o   cPanel with MySQL archive: found, dated $cpmovedate"
        else echo "o   cPanel with MySQL archive: not found."
        fi
        if [ "$homedirdate" != '' ]; then echo "o   Home folder: found, dated $homedirdate"
        else echo "o   Home folder: not found."
        fi
echo ""
echo "--------------------------------------------"
echo ""
echo ""
echo "Press Enter and available backup contents will be restored (write q to quit)."
read pressenter
if [ "$pressenter" = 'q' ]; then exit 0;
fi
echo "Trying to download cpmove-$username.tar.gz backup.."
echo ""

if [ "$cpmovedate" != '' ] && [ "$username" != '' ] && [ "$username" != "*" ] && [ "$username" != "/" ]; then

        #---------------------------------------------------------------------
        # Download cpmove file, remove/restore user, keep old homefolder

        scp -P 9988 root@$backupserver:/backup$nr/$serverID/weekly/$username/cpmove-$username.tar.gz /home/cpmove-$username.tar.gz

           if [ -d /home/$username -o -d /home2/$username -o -d /home3/$username ]; then
                        echo "$username user already exists, launching remove script."
            echo ""
            if [ -d /home/$username ]; then
                cd /home
                mv $username $username-tmpdir
                                temphomedir="/home"
            fi
            if [ -d /home2/$username ]; then
                cd /home2
                mv $username $username-tmpdir
                                temphomedir="/home2"
            fi
            if [ -d /home3/$username ]; then
                cd /home3
                mv $username $username-tmpdir
                                temphomedir="/home3"
            fi

        fi

        echo "Homedir preserved to $temphomedir/$username-tmpdir (for faster rsync)."
        /scripts/killacct $username
        /scripts/restorepkg --force /home/cpmove-$username.tar.gz
    cd /home
    rm -f cpmove-$username.tar.gz

        #-----------------------------------------------------------------------
        # Check homepath, restore old home folder, rsync home from backup server

        homepath="/home"

                if [ -d /home/$username ]; then homepath="/home"
                fi
                if [ -d /home2/$username ]; then homepath="/home2"
                fi
                if [ -d /home3/$username ]; then homepath="/home3"
                fi

    echo "Removing empty base $homepath/$username folder.."
        cd $homepath
    if [ -d $homepath/$username-tmpdir ]; then
        echo "Not needed, skipping."
    else
                mv $username $homepath/$username-tmpdir
    fi
        echo "Done."

        if [ -d $temphomedir/$username-tmpdir ]; then
                echo "Restoring home folder from $temphomedir/$username-tmpdir to $homepath/$username.."
                cd $temphomedir
                mv $username-tmpdir $homepath/$username
                echo "Done."
        fi

        if [ "$homedirdate" != '' ] &&  [ "$homepath" != '' ] && [ "$username" != '' ] && [ -d $homepath/$username ]; then
                rsync -av --rsh="ssh -p9988" root@$backupserver:/backup$nr/$serverID/weekly/$username/homedir/ $homepath/$username/
                echo "Done."
        else echo "Failed. $username homedir backup not found on backup server, current homedir left intact."
        fi

        if [ "$homepath" != '' ] && [ "$username" != '' ] && [ -d $homepath/$username/public_html ]; then
                wronguser=`stat --format=%u $homepath/$username/public_html/`

                echo "Wrong ownership ($wronguser) on files in $homepath/$username, running fix.."
                cd $homepath
                chmod 711 $username
                cd $homepath
                chown -R $username:$username $username
                cd $homepath/$username
                chown $username:nobody public_html .htpasswds
                cd $homepath/$username
                chown $username:mail etc etc/*/shadow etc/*/passwd
                cd /usr/local/apache/domlogs
                mkdir $username
                cd /usr/local/apache/domlogs
                chown root.$username $username
                cd /usr/local/apache/domlogs
                chmod 750 $username
                echo "Done."
        fi

        echo "Backup restore for $username complete."

else echo "cpmove-$username.tar.gz is not available on backup server, or username is incorrect. Quiting."
fi
exit 0;
