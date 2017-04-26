<?php 
	include('inc/connection.php');

	$currentTime = time();
	$time = date('H:i',$currentTime);  
	$date = date('h:i:s a', time());
	$timestamp = strtotime($date);
	$day = date('D', $timestamp);

	# if it is weekday then truncate table otherwise display previous day's data until Monday 10am
	/*if ( ( ($day == "Sat") && ($time < 11) ) || ($day == "Mon" && $time > 9) )

	{
		$sql="truncate table do.firm_positions;";
		mysql_query($sql) or die(mysql_error());
	}*/

	//$clientName = "VFX_london";
	// Getting file from BAT file
	$ldcsv_file = $argv[1];
	$nycsv_file = $argv[2];

	$q="select max(timeStamp) FROM do.firm_positions;";
	$dbFileDate = mysql_query($q);
	$timeStamp1 = substr($argv[1],19,11);

	if ($timeStamp1 > $dbFileDate) # Checking imported file name against max date value in firm positions table, if there's a file in import folder than run query
	{
		$sql="truncate table do.firm_positions;";
		mysql_query($sql) or die(mysql_error());

		for ($i=1; $i<3;$i++) # Two times for each file (NY and LD)
		{
			# Getting Location and TimeStamp fields from the newly loaded file
			$loc = substr($argv[$i],15,3);
			$timeStamp = substr($argv[$i],19,11);

			if (($handle = fopen($argv[$i], "r")) !== FALSE) 
			{
			   fgetcsv($handle);   
			   while (($data = fgetcsv($handle, 1000, ",")) !== FALSE) 
			   {
			        $num = count($data);
			        for ($c=0; $c < $num; $c++) 
			        {
			          $col[$c] = $data[$c];
			        }
					 $clientFirm = $col[0];
					 $symbol = $col[1];
					 $position = $col[2];
					 $marketRate = $col[3];	
					 $marginRequired = $col[8];
					 	# SQL Query to insert data into Database			 
						$query = "INSERT INTO do.firm_positions(clientFirm,symbol,position,marketRate,location,timeStamp,marginRequired) VALUES('$clientFirm','$symbol','$position','$marketRate','$loc','$timeStamp','$marginRequired')";
						$s     = mysql_query($query);
			 	}
			    fclose($handle);
			}
		}
	}
?>