#!/bin/bash
no=1
current_time=`date +%s`
nice_date=`date +"%Y-%m-%d"`
allowed_age=5200000 

echo " ";
echo "+---------------------------------------------------------------+";
echo "| BACKUP SERVER CLEANUP                                         |";
echo "| REMOVING BACKUPS OLDER THAN 60 DAYS                           |";
echo "| DATE: $nice_date                                              |";
echo "+---------------------------------------------------------------+";
echo " ";

while [ -d /backup$no ]; do
cd /backup$no;
 for server in *; do
 
  if [ -d /backup$no/$server/weekly ]; then
  echo "+---------------------------------------------------------------+";
  echo "|  CHECKING SERVER $server BACKUPS                                |";
  echo "+---------+-------+----------+------------+--------+------------+";
  echo "| HDD     | SRV   | USERNAME | LAST RUN   | AGE    | ACTION     |";
  echo "+---------+-------+----------+------------+--------+------------+";  
        cd /backup$no/$server/weekly;
		
        for user in *; do
                if [ -a /backup$no/$server/weekly/$user/$user_lastrun ]; then
					 echo -n "| backup$no | $server | ";
					 printf "%-8s" "$user";
					 echo -n " | ";
					 echo -n `stat --format=%y /backup$no/$server/weekly/$user/$user_lastrun | awk '{print $1;}';`;
					 echo -n " | ";
					 
					 age=`stat --format=%Y /backup$no/$server/weekly/$user/$user_lastrun`;
					 age_permitted=$[$age+$allowed_age];
					 age_current=$[$current_time-$age];
					 age_days=$[$age_current/86400];
					 
					 printf "%-3s" "$age_days";
					 
					 if [ $age_permitted -lt $current_time ]; then
						echo " d. | Deleting.. |";
						rm -rf /backup$no/$server/weekly/$user;
					 else
						echo " d. |     --     |";
					 fi
				 
                fi
        done
  fi
 done
 no=$[$no+1];
done

exit 0;
