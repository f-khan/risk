<!DOCTYPE html>
<html>
<!-- GitHub -->
<head>
	<title>Virtu Gross Exposure</title>

	<!-- Auto page load after every 15min -->
	<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js">
	</script>
	<script>
	$(document).ready(function(){
	setInterval(function(){cache_clear()},900000);
	});
	function cache_clear()
	{
	window.location.reload(true);
	}
	</script>
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css" />
    <link rel="stylesheet" type="text/css" href="inc/style-virtu.css">
	<style>
		@import url('https://fonts.googleapis.com/css?family=Roboto');
	</style> 
</head>

<body style="background-color: #e4e1e0">
<center><img width="300" class="logo" src="images/UnicornLogo.png"></center>
	<?php 
		$count = 0;
		$countHourly = 0;
		include('inc/connection.php');
    	
    	# Function to change negative value into (parenthesis) instead of negative sign
    	function negformat($nr)
    	{
    		if ($nr >=0)
            	return $nr;          
    		else
                return $nr[0] == "-" ? "(" . substr($nr, 1) . ")" : $nr;
		}	

		# Query to fetch data from open_positions union firm_positions
		$sql = "
				select 
				t1.busdate,
				t1.symbol,
				t1.side,
				t1.marketrate,
				t1.lotSize,
				sum(t1.volume) as volume,
				t1.rCcy,
				sum(t1.amount) as amount,
				t1.ConvRate,
				sum(t1.USDAmount) as USDAmount
				from
				(
				SELECT 
				busdate,
				ccy as symbol, 
				side,
				marketrate,
				qty as volume, 
				right(ccy,3) as rCcy, 
				qty*marketRate*s.lotSize as amount, 
				(select ifnull((select ifnull((select ((bid+ask)/2) from statements.symbols where symbol=concat(rCcy,'/USD')),(select 1/((bid+ask)/2) from statements.symbols where symbol=concat('USD/',rCcy)))),1)) as ConvRate,
				qty*marketrate*(select ifnull((select if((select bid from statements.symbols where symbol=concat(rCcy,'/USD')),(select (bid+ask)/2 from statements.symbols where symbol=concat(rCcy,'/USD')),(select 1/((bid+ask)/2) from statements.symbols where symbol=concat('USD/',rCcy)))),1))*s.lotSize as USDAmount,
				s.lotSize
				FROM statements.open_positions op, statements.symbols s where clientfirm='VIRT1001' and busdate=(select case dayofweek(curdate()) -- yesterday
			when 2 then curdate() - interval 3 day -- when monday, go 3 more days before
			else curdate() - interval 1 day -- yesterday
			end
			as lastdate)  and op.ccy=s.symbol 
				UNION ALL
				SELECT 
				t.a as busdate, 
				t.symbol,
				null as side,
				t.marketRate,
				null,
				right(t.symbol,3),
				null,
				(select ifnull((select ifnull((select ((bid+ask)/2) from statements.symbols where symbol=concat(right(t.symbol,3),'/USD')),(select 1/((bid+ask)/2) from statements.symbols where symbol=concat('USD/',right(t.symbol,3))))),1)) as ConvRate,
				null,
				s.lotsize
				FROM 
				(
				select null as a,symbol,null as side, marketRate from do.firm_positions where clientFirm = 'VFX_London' group by symbol
				UNION ALL
				select null as a,ccy, null as side, null as marketRate from statements.open_positions where clientFirm = 'VIRT1001' and busdate = (select case dayofweek(curdate()) -- yesterday
			when 2 then curdate() - interval 3 day -- when monday, go 3 more days before
			else curdate() - interval 1 day -- yesterday
			end
			as lastdate)  group by ccy
				) t, statements.symbols s where t.symbol=s.symbol
				) t1
				group by t1.symbol
				;";

		$result = mysql_query($sql);

		# Query to fetch max/latest date from open_positions for VIRT1001 for EOD latest day
		$sqlForDate = mysql_query("select case dayofweek(curdate()) -- yesterday
			when 2 then curdate() - interval 3 day -- when monday, go 3 more days before
			else curdate() - interval 1 day -- yesterday
			end
			as lastdate");
		
		# Query to fetch max/latest date from firm_positions for VIRT1001 for current date
		//$query = "select timeStamp as timeNow FROM do.firm_positions where clientFirm = 'VFX_London'";
		$query = "select timeStamp as timeNow FROM do.firm_positions";
	?>


	<h1 align="center">Virtu Gross Exposure</h1>
	<center><A HREF="javascript:history.go(0)">Refresh Page</A></center>
	<br>
	<table class="bordered" border="2" cellspacing="1" cellpadding="10" style="font-size:16px">
	<thead>
	<tr style="background-color: #ddd;">
			<th height="20px" colspan="3" align="right">
			<th height="20px" colspan="3" align="center">
				<?php
					# Displaying EOD Date in correct format
					$resultForDate = mysql_fetch_row($sqlForDate);
					$eodDate = $resultForDate[0];
					$eodYear = substr($eodDate,0,4);
					$eodMonthNum = substr($eodDate,5,2);
					$eodDay = substr($eodDate,8,2);
					$eodTimeStamp = mktime(0, 0, 0, $eodMonthNum, 1);
					$eodMonthName = date('M', $eodTimeStamp );
					echo 'EOD: '.$eodDay.'-'.$eodMonthName.'-'.$eodYear;
				?>
			</th>
			
			<th colspan="4" align="center">As at: 
				<?php  
					# Displaying Current/Hourly Date in correct format
					$resultSet = mysql_query($query);
					$timeNow = mysql_fetch_row($resultSet);
					$currentYear = substr($timeNow[0],0,4);
					$currentMonthNum = substr($timeNow[0],4,2);
					$currentDay = substr($timeNow[0],6,2);
					$currentTime = substr($timeNow[0],9,2).":00";
					$currentTimeStamp = mktime(0, 0, 0, $currentMonthNum, 1);
					$currentMonthName = date('M', $currentTimeStamp );
					echo $currentDay.'-'.$currentMonthName.'-'.$currentYear.' '.$currentTime.' AU';
				?>
			</th>
		</tr>
	

	<!-- Table headings -->	
	<tr height="40px" style="background-color: #ddd;">
		<th>Symbol</th>
		<th>CCY</th>
		<th>Conv Rate</th>
		<th height="30px" width="100px">Quantity</th>
		<th width="150px">Terms Amount</th>
		<th width="150px">USD Amount</th>
		<th width="100px">Quantity</th>
		<th width="150px">Terms Amount</th>
		<th width="150px">USD Amount</th>
		<th width="150px">Limits</th>
	</tr>
</thead>
	<?php  
		if (mysql_num_rows($result) > 0) # Fetching data from main complex query
		{
		    // output data of each row
		    while($row = mysql_fetch_assoc($result))
		    {
		    	echo "<tr>";
			    	$symbol=$row["symbol"];
			    	$querylimit = mysql_query("select `limit` FROM do.virtu_limit where do.virtu_limit.symbol = '".$symbol."'");
			    	$limit = mysql_fetch_row($querylimit);
			        echo "<td>".$symbol."</td>"; # Symbol Coumn data
			        echo "<td>".$row["rCcy"]."</td>"; # CCY Column data
			        echo "<td align='right'>".number_format($row["ConvRate"],5)."</td>"; #ConvRate Column data
			        
			        # EOD Quantity
			        if ($row["side"] == "B") # Set values in red 
			        {	        	
			        	echo "<td align='right' style='color:red;'>(".number_format($row["volume"]).")</td>";
			        } 
			        else 
			        {
			        	echo "<td align='right'>".number_format($row["volume"])."</td>";
			        }

			        echo "<td align='right'>".number_format($row["amount"])."</td>"; # EDO Terms Amount Column data
			        echo "<td align='right'>".number_format(abs($row["USDAmount"]))."</td>"; # EOD USD Amount Column data
			        
			        $count = $count + abs($row["USDAmount"]); # Total counter for EOD USD Amount

			        # Query to fetch Current Quantitycolumn from firm_positions UNION firm_positions_seed_data
			        # firm_positions_seed_data table used to explicitely set/add manual values to those 4 symbols 
			        $sql = mysql_query("select SUM(t.position) AS position
										FROM (SELECT position FROM do.firm_positions where symbol='$symbol' AND clientFirm = 'VFX_London'
										UNION ALL
										SELECT position FROM do.firm_positions_seed_data where symbol='$symbol' and active = 1) t;");
					
			        /*$sql = mysql_query("select SUM(t.position) AS position
										FROM (SELECT position FROM do.firm_positions where symbol='$symbol' AND clientFirm = 'VFX_London'");
					*/
			        $cmrow = mysql_fetch_row($sql);

			        # Current Quantity
			        if ($cmrow[0] != 0) # If values are fetched
			        {
			        	if ($cmrow[0] > 0) # if number is positive then make it negative
			        	{
			        		$cmrow[0] = (-1*$cmrow[0]);
			        	}
			        	else 
			        	{
			        		$cmrow[0] = (-1*$cmrow[0]);
			        	}

			        	$value = negformat(number_format($cmrow[0])); # function calling to turn negative values into (parenthesis)

			        	if ($cmrow[0]<0) # If value is negative make it in RED
			        	{
			        		$valueTemp = $cmrow[0]*-1; #valueTemp is the positive of the value
							if ($valueTemp > $limit[0]) #if value is greater than limit change bg color
							{
								echo "<td align='right' style='color:red;'>".$value."</td>";
							}
							else #if value is greater than limit no bg color
							{
								echo "<td align='right'>".$value."</td>";
							}	
			        	}
						else
						{	
							if ($cmrow[0] > $limit[0]) #if value is greater than limit change bg color
							{
								echo "<td align='right' style='color:red;'>".$value."</td>";
							}
							else #if value is greater than limit no bg color
							{
								echo "<td align='right'>".$value."</td>";
							}
						}
					}
					else #if no values are pulled from db
					{
						echo "<td align='right'>"."0"."</td>";
					}
			        
			        # Current Terms Amount Column
			        $currTermsAmount = ($cmrow[0]*$row["lotSize"]*$row["marketrate"]);
			        echo "<td align='right'>".number_format(abs($currTermsAmount))."</td>";

			        # Current/hourly USD Amount
			        $hourlyUSDAmount=$cmrow[0]*$row["lotSize"]*$row["marketrate"]*round($row["ConvRate"],5);
			        echo "<td align='right'>".number_format(abs($hourlyUSDAmount))."</td>";

			        
			        echo "<td align='right'>".number_format($limit[0])."</td>";

			        # Total counter for Current/Hourly USD Amount
			        $countHourly = $countHourly + abs($hourlyUSDAmount);
		        echo "</tr>";
		    }
		} 

	?>
	</tr> 
	<tr>
		<td class = 'total' height="30px" colspan="5" align="center"></td>
		<td class = 'total' height="30px" align="right"><b><?php echo number_format(abs($count)); ?></b></td>
		<td class = 'total' height="30px" colspan="2" align="center"></td>
		<td class = 'total' height="30px" align="right"><b><?php echo number_format(abs($countHourly)); ?></b></td>
		<td class = 'total' height="30px" align="center"></td>
	</tr>
	</table>
</br>
</font>
 <br>
 <center><p>&copy; Copyright Unicorn. All rights reserved.</p></center>
</body>
</html>