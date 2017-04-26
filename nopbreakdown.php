<!DOCTYPE html>
<html>
<head>
    <title>NOP Breakdown by Client Group</title>

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


    <link rel="stylesheet" type="text/css" href="inc/style.css">
        <style>
@import url('https://fonts.googleapis.com/css?family=Roboto');
</style> 
</head>
<body style="background-color: #e4e1e0">
    <center><img width="300" class="logo" src="images/UnicornLogo.png"></center>
    <?php 
        include('inc/connection.php');
        $clientFirm = $_GET['link'];
        if (empty($_GET['link']))
        {
            header('Location: nop.php');
            exit;         
        }

        # Function to change negative value into (parenthesis) instead of negative sign
        function negformat($nr)
        {
        if ($nr >=0)
        return $nr;          
        else
        return $nr[0] == "-" ? "(" . substr($nr, 1) . ")" : $nr;
        }

        $sql =  "
# NOP Client Breakdown Query ONE
select LastUpdated, clientGroup, displayCcy, amt, amt*USDRate as USDEquiv, USDRate,USD_fx_NOP,USD_cfd_NOP,USD_metal_NOP, sum(USD_fx_NOP+USD_cfd_NOP+USD_metal_NOP)  as USD_NOP_sum
from
(
                select LastUpdated, clientGroup, clientFirm, displayCcy, ccy,
    sum(amt) amt, 
    #Amt FX
    sum(if(symbolType='FX',amt,0)) as AmtFX,
    #Amt CFD
    sum(if(symbolType='CFD',amt,0)) as Amt_CFD,
    #Amt Metal
    sum(if(symbolType = 'metal',amt,0)) as AmtMETAL,
    #Conversion to USD Rate
    (IFNULL((SELECT(IFNULL((select ((bid+ask)/2) as rate from statements.symbols where symbol =concat(ccy,'/USD')),(select 1/((bid+ask)/2) as rate from statements.symbols where symbol =concat('USD/',ccy))))),1)) as USDRate,
    #USD FX
    (IFNULL((SELECT(IFNULL((select ((bid+ask)/2) as rate from statements.symbols where symbol =concat(Ccy,'/USD')),(select 1/((bid+ask)/2) as rate from statements.symbols where symbol =concat('USD/',Ccy))))),1) * sum(if(symbolType='FX',amt,0))) as USD_fx,
    #USD FX NOP
    abs(round((IF((IFNULL((SELECT(IFNULL((select ((bid+ask)/2) as rate from statements.symbols where symbol =concat(Ccy,'/USD')),(select 1/((bid+ask)/2) as rate from statements.symbols where symbol =concat('USD/',Ccy))))),1) * sum(if(symbolType='FX',amt,0)))>0,0,(IFNULL((SELECT(IFNULL((select ((bid+ask)/2) as rate from statements.symbols where symbol =concat(Ccy,'/USD')),(select 1/((bid+ask)/2) as rate from statements.symbols where symbol =concat('USD/',Ccy))))),1) * sum(if(symbolType='FX',amt,0))))),0)) as USD_fx_NOP,
    #USD CFD
    (IFNULL((SELECT(IFNULL((select ((bid+ask)/2) as rate from statements.symbols where symbol =concat(Ccy,'/USD')),(select 1/((bid+ask)/2) as rate from statements.symbols where symbol =concat('USD/',Ccy))))),1) * sum(if(symbolType='CFD',amt,0))) as USD_cfd,
    #USD CFD NOP
    abs(round((IFNULL((SELECT(IFNULL((select ((bid+ask)/2) as rate from statements.symbols where symbol =concat(Ccy,'/USD')),(select 1/((bid+ask)/2) as rate from statements.symbols where symbol =concat('USD/',Ccy))))),1) * sum(if(symbolType='CFD',amt,0))),0)) as USD_cfd_NOP,
    #USD Metal
    (IFNULL((SELECT(IFNULL((select ((bid+ask)/2) as rate from statements.symbols where symbol =concat(Ccy,'/USD')),(select 1/((bid+ask)/2) as rate from statements.symbols where symbol =concat('USD/',Ccy))))),1) * sum(if(symbolType = 'metal',amt,0))) as USD_metal,
    #USD Metal NOP
    abs(round((IFNULL((SELECT(IFNULL((select ((bid+ask)/2) as rate from statements.symbols where symbol =concat(Ccy,'/USD')),(select 1/((bid+ask)/2) as rate from statements.symbols where symbol =concat('USD/',Ccy))))),1) * sum(if(symbolType = 'metal',amt,0))),0)) as USD_metal_NOP
    from 
    ( 
                                # Left FX
        select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, p.symbol, s.baseCcy displayCcy, s.baseCcy ccy, p.position, 0 as marketRate, p.position amt, s.symbolType
        from do.firm_positions p, statements.symbols s, do.nop_clients c
        where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND (s.symbolType = 'FX' and p.symbol not like 'X%') AND c.clientGroup = '$clientFirm'
        union all
        # Right FX
        select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, p.symbol, s.riskCcy displayCcy, s.riskCcy ccy, p.position, p.marketRate, -round(p.position * p.marketrate, 0) amt, s.symbolType
        from do.firm_positions p, statements.symbols s, do.nop_clients c
        where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND (s.symbolType = 'FX' and p.symbol not like 'X%') AND c.clientGroup = '$clientFirm'
        union all
        # CFD
        select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, p.symbol, left(s.symbol,3) displayCcy, s.riskCcy ccy, p.position, p.marketRate, p.position*s.lotsize*((s.bid+s.ask)/2) as amt, s.symbolType
        from do.firm_positions p, statements.symbols s, do.nop_clients c
        where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND (s.symbolType = 'CFD') AND c.clientGroup = '$clientFirm'
        union all
        # Left Metal
        select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, p.symbol, s.baseCcy displayCcy, s.baseCcy ccy, p.position, p.marketRate, (p.position*s.lotsize) as amt, 'metal' as symbolType
        from do.firm_positions p, statements.symbols s, do.nop_clients c
        where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND p.symbol like 'X%' AND c.clientGroup = '$clientFirm'
                ) x
    group by clientGroup, displayCcy
    order by clientGroup, displayCcy
) x1
group by clientGroup, displayCcy
order by clientGroup, displayCcy;

                ";

        $result = mysql_query($sql);
        $query_clientFirm = "select clientFirm from do.nop_clients where clientGroup = '$clientFirm' order by clientFirm";
        $result_clientFirm = mysql_query($query_clientFirm);

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

    <h1 align="center">Net Open Positions - Breakdown</h1>



        <div id="buttons">
            <a href="nop.php" class="btn">Overall NOP</a>
            <a href='noptiers.php?link=<?php echo $clientFirm;?>' class="btn">Tier Breakdown</a>
        </div>    
    <h1 align="center">
        Client Group:
        <font style='color:#dc4814;'><?php echo $clientFirm;?> </font>
    </h1>
        <h3 align="center">
        Client Firms:
        <font style='color:#dc4814;'>
        <?php /*
            if (mysql_num_rows($result_clientFirm) > 0)
            {
                $str = "";
                while($row = mysql_fetch_assoc($result_clientFirm))
                {
                    $str .= $row['clientFirm'].", ";
                }
                echo rtrim($str,", ");
            }
        */?> 
        </font>


        <?php 
            if (mysql_num_rows($result_clientFirm) > 0)
            {
                $str[] = "";
                $c = 1;
                echo "| ";
                while($row = mysql_fetch_assoc($result_clientFirm))
                {
                    $str[$c] .= $row['clientFirm'];
                    echo " <a href='nopBreakdownFirm.php?group=$clientFirm&firm=".$str[$c]."'>".$str[$c]."</a> | ";
                    $c++;
                }
                //echo rtrim($str,", ");
            }
            //var_dump($str[2]);
        ?> 


        </h3>
    <h4 align="center">Data As At: <?php echo $time." ".$today;?></h4>
    <h2>NOP Breakdown</h2>
    <table class="bordered table1">
        <thead>
            <tr>     
                <th style="text-align: left;">Symbol</th>
                <th style="text-align: right;">Exposure - Base CCY</th>
                <th style="text-align: right;">Conv Rate</th>
                <th style="text-align: right;">Exposure USD Equivalent</th>
                <th style="text-align: right;">NOP (USD)</th>
            </tr>
        </thead>
        <?php

            if (mysql_num_rows($result) > 0)
            {
                $total_USD_NOP_sum = 0;
                while($row = mysql_fetch_assoc($result))
                {
                    if ($row['amt'] != 0)
                    {
                        echo "<tr>";
                            echo "<td class='grey'>".$row['displayCcy']."</td>";
                            if ($row['amt'] < 0)
                            {
                                echo "<td class='left-align' width='0px' style='color:red;'>".negformat(number_format($row['amt']))."</td>";
                            }
                            else
                            {
                                echo "<td class='left-align' width='0px'>".number_format($row['amt'])."</td>";
                            }

                            if ($row['amt'] < 0)
                            {
                                echo "<td class='left-align' width='0px'>".number_format($row['USDRate'],6)."</td>";
                            }
                            else
                            {
                                echo "<td class='left-align' width='0px'>".number_format($row['USDRate'],6)."</td>";
                            }


                            //echo "<td class='left-align' width='0px'>".number_format($row['USDRate'],6)."</td>";

                            if ($row['USDEquiv'] < 0)
                            {
                                echo "<td class='left-align' width='0px' style='color:red;'>".negformat(number_format($row['USDEquiv']))."</td>";
                            }
                            else
                            {
                                echo "<td class='left-align' width='0px'>".number_format($row['USDEquiv'])."</td>";
                            }

                            echo "<td class='left-align' width='0px'>".number_format($row['USD_NOP_sum'])."</td>";

                            $total_USD_NOP_sum = $total_USD_NOP_sum + $row['USD_NOP_sum'];
                        echo "</tr>";
                    }
                }
                echo "<tr>";
                    echo "<td colspan = '4' class = 'total'><h3>Total</h3></td>";
                    echo "<td class='left-align' width='0px'><h3>".number_format($total_USD_NOP_sum)."</h3></td>";
                echo "</tr>";
            }
            else
            {
                echo "<td colspan='4'><center>No results to display</center></td>";
            }
        ?>
        <tr>
        </tr>      
    </table>

    <?php

    $sql2 = "CALL do.nop_position_breakdown('$clientFirm')";

        $result2 = mysql_query($sql2);
    ?>

    <h2>Positions</h2>
    <table class="bordered table2">
        <thead>
            <tr>     
                <th style="text-align: left;">Symbol</th>
                <th style="text-align: right;">Position</th>
                <th style="text-align: right;">Conv Rate</th>
                <th style="text-align: right;">USD Equivalent</th>

            </tr>
        </thead>
        <?php
            if (mysql_num_rows($result2) > 0)
            {
                while($row = mysql_fetch_assoc($result2))
                {
                    
                    echo "<tr>";
                        echo "<td class='grey'>".$row['symbol']."</td>";
                        if ($row['position'] < 0)
                        {
                            echo "<td class='left-align' width='0px' style='color:red;'>".negformat(number_format($row['position']))."</td>";
                        }
                        else
                        {
                        echo "<td class='left-align' width='0px'>".negformat(number_format($row['position']))."</td>";
                        }

                        echo "<td class='left-align' width='0px'>".number_format($row['USDRate'],6)."</td>";

                        /*if ($row['amt'] < 0)
                        {
                            echo "<td class='left-align' width='0px' style='color:red;'>".negformat(number_format($row['amt']))."</td>";
                        }
                        else
                        {
                        echo "<td class='left-align' width='0px'>".negformat(number_format($row['amt']))."</td>";
                        }*/

                        echo "<td class='left-align' width='0px'>".negformat(number_format($row['usd_amt']))."</td>";
                    echo "</tr>";
                }
            }else
            {
                echo "<td colspan='4'><center>No results to display</center></td>";
            }
            
        ?>     
    </table>
        <center>
    <br>

 </center>
 <br>
 <center><p>&copy; Copyright Unicorn. All rights reserved.</p></center>
</body></html>