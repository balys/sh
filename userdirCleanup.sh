#!/bin/bash
# cPanel user cleanup script
# Last Update : 2013-01-17



<?
//
// $start_from = "a4138606";
//
if ($start_from=="") $started = true; else $started = false;
$source_dir = '/home';
$max_load = "10";
$max_file_lenght = 8;
$mix_file_lenght = 2;
$i=0;

passthru("rm -rf cleanup.txt");
passthru("touch cleanup.txt");

$handle=opendir($source_dir);
while (($file = readdir($handle))!==false) {
        if ( (!$started) and ($file==$start_from)) $started = true;

        if (is_dir("/$source_dir/$file/public_html"))
        if ( (strlen($file)>=$mix_file_lenght) and (strlen($file)<=$max_file_lenght) and ($started) ){
                $i++;
                $load = file_get_contents("/proc/loadavg");
                $load = explode(' ', $load);
                $load = $load[0];
                if ($load>=$max_load) {
                        print "Load High.. Sleep for 30s..\n";
                        sleep(30);
                }
                print "$i. Checking $source_dir/$file ..\n";

                $time_start = time();
                exec("/usr/bin/find $source_dir/$file/ -size +50000k -exec echo {} \; -exec rm {} \;",$rc,$status);
                $count = count($rc);
                if ($count!=0){
                        print_r($rc);
                }
                unset($rc);
                $time_end = time();
                $how_long = $time_end - $time_start;
                if ($how_long>120) {
                        print "Check $source_dir/$file (took $how_long sec. to scan)\n";
                        file_put_contents("cleanup.txt","Check $source_dir/$file (scan took $how_long sec.)\n",FILE_APPEND);
                }

        }
}

closedir($handle);
?>
