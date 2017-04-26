<?php
$db = mysql_connect("localhost:43306", "web", "web") or die("Could not connect.");

if(!$db) 

	die("no db");

if(!mysql_select_db("statements",$db))

 	die("No database selected.");
?>