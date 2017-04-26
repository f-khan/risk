<!DOCTYPE html>
<html>
<head>
    <title>NOP - Sum by Symbol</title>

    <!-- Auto page load after every 15min -->
    <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js">
    </script>
    <script>
    $(document).ready(function(){
    setInterval(function(){cache_clear()},300000);
    });
    function cache_clear()
    {
    window.location.reload(true);
    }
    </script>
    <style>
        @import url('https://fonts.googleapis.com/css?family=Roboto');
    </style> 
    <link rel="stylesheet" type="text/css" href="inc/style_unicorn.css">
</head>
<body style="background-color: #e4e1e0">
    <center><img width="300" class="logo" src="images/UnicornLogo.png"></center>
    <?php 
        include('inc/connection.php');

        # Main query
        $sql = "
select p.`timeStamp` as LastUpdated, p.symbol, sum(abs(p.position)) as sum
from do.firm_positions p, statements.symbols s
where p.symbol = s.symbol AND position <> 0 AND p.clientFirm <> 'VFX_london' AND p.clientFirm <> 'B_BOOK'
GROUP BY symbol
ORDER BY symbol;
        ";


        $result = mysql_query($sql);

        $query = mysql_query($sql);
        $row = mysql_fetch_array($query);
        $date = $row['LastUpdated'];
        $year = substr($date,0,4);
        $month = substr($date,4,2);
        $TimeStamp = mktime(0, 0, 0, $month, 1);
        $month = date('M', $TimeStamp );
        $day = substr($date,6,2);
        $hour = substr($date,9,2).":00 AU";
        $time = $hour;
        $today = "(".$day."-".$month."-".$year.")";


    ?>

    <h1 align="center">Sum By Symbol</h1>
            <div id="buttons">
            <a href="nop.php" class="btn">Back to Overall Positions Page</a>
        </div>
    <h4 align="center">Data As At: <?php echo $time." ".$today;?></h4>
    <table class="bordered" style="float: left 0px;">
        <thead>
<th style="text-align: center;">Symbols</th> 
<th style="text-align: center;">Sum</th> 


        </thead>
        <?php

            # Displaying Rows
            if (mysql_num_rows($result) > 0)
            {
                while($row = mysql_fetch_assoc($result))
                {
                    echo "<tr>";
                    echo "<td class='center-align'>".$row['symbol']."</td>";
                    echo "<td class='right-align'>".number_format($row['sum'],0)."</td>";
                    echo "</tr>";
                }
                
            }else
            {
                echo "<td><center>No results to display</center></td>";
            }
        ?>   
    </table>
<br>
<center><a class="btn" href="../risk">MAIN MENU</a></center>
<br>
<center><p>&copy; Copyright Unicorn. All rights reserved.</p></center>
</body>
</html>