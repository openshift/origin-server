<?php
# Connection Info
$hostname="HOSTNAME";
$user="USER";
$password="PASSWORD";
$database="mysql";

# Queries
$table_sql="CREATE TABLE test2(id int(6) NOT NULL auto_increment, name varchar(15) NOT NULL, PRIMARY KEY(id))";
$insert_sql="INSERT INTO test2 VALUES ('', 'Success')";
$select_sql="SELECT * from test2";

# MySQL verification
mysql_connect($hostname, $user, $password) or die(mysql_error());
mysql_select_db($database) or die(mysql_error());
mysql_query($table_sql);
mysql_query($insert_sql);
$result=mysql_query($select_sql) or die(mysql_error());
mysql_close();
echo mysql_result($result,0,"name")
?>
