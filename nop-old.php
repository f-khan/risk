<!DOCTYPE html>
<!--
Author: Fahad Khan (fkhan@invast.com.au)
After changes
 -->
<html>
<head>
    <title>NOP - Overall</title>

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
</head>
<body>
    <center><img width="300" class="logo" src="images/UnicornLogo.png"></center>
    <?php 
        include('inc/connection.php');

        # Sorting conditions
        $sortVar = $_GET['sort'];
        if ($_GET['sort'] == "clientGroup")
        {
            $sortVar = "clientGroup, USD_Overall_NOP desc";
        }
        elseif ($_GET['sort'] == "USD_Overall_NOP") 
        {
            $sortVar = "USD_Overall_NOP desc, clientGroup";
        }
        elseif ($_GET['sort'] == "clientLimit") 
        {
            $sortVar = "clientLimit desc, USD_Overall_NOP desc, clientGroup";
        }
        elseif ($_GET['sort'] == "utilisation") 
        {
            $sortVar = "utilisation desc, USD_Overall_NOP desc, clientGroup";
        }
        else
        {
            $sortVar = "utilisation desc, USD_Overall_NOP desc, clientGroup";
        }

        # Main query
        $sql =  "
# New Query Main Page
select LastUpdated, clientGroup, (sum(USD_fx_NOP)+sum(USD_cfd_NOP)+sum(USD_metal_NOP)) as USD_Overall_NOP, clientLimit, round(((sum(USD_fx_NOP)+sum(USD_cfd_NOP)+sum(USD_metal_NOP))/clientLimit)*100,2) as utilisation
from
(
            select LastUpdated, clientGroup, clientFirm, clientLimit, ccy, 
    sum(amt) amt, 
    #Amt FX
                sum(if(symbolType='FX',amt,0)) as AmtFX,
    #Amt CFD
    sum(if(symbolType='CFD',amt,0)) as Amt_CFD,
    #Amt Metal
                sum(if(symbolType = 'metal',amt,0)) as AmtMETAL,
    #Conversion to USD Rate
                round((IFNULL((SELECT(IFNULL((select ((bid+ask)/2) as rate from statements.symbols where symbol =concat(ccy,'/USD')),(select 1/((bid+ask)/2) as rate from statements.symbols where symbol =concat('USD/',ccy))))),1)),4) as USDRate,
                #USD FX
    (IFNULL((SELECT(IFNULL((select ((bid+ask)/2) as rate from statements.symbols where symbol =concat(Ccy,'/USD')),(select 1/((bid+ask)/2) as rate from statements.symbols where symbol =concat('USD/',Ccy))))),1) * sum(if(symbolType='FX',amt,0))) as USD_fx,
                #USD FX NOP
    abs(round((IF((IFNULL((SELECT(IFNULL((select ((bid+ask)/2) as rate from statements.symbols where symbol =concat(Ccy,'/USD')),(select 1/((bid+ask)/2) as rate from statements.symbols where symbol =concat('USD/',Ccy))))),1) * sum(if(symbolType='FX',amt,0)))>0,0,(IFNULL((SELECT(IFNULL((select ((bid+ask)/2) as rate from statements.symbols where symbol =concat(Ccy,'/USD')),(select 1/((bid+ask)/2) as rate from statements.symbols where symbol =concat('USD/',Ccy))))),1) * sum(if(symbolType='FX',amt,0))))),0)) as USD_fx_NOP,
    #USD CFD NOP
    abs(round((IFNULL((SELECT(IFNULL((select ((bid+ask)/2) as rate from statements.symbols where symbol =concat(Ccy,'/USD')),(select 1/((bid+ask)/2) as rate from statements.symbols where symbol =concat('USD/',Ccy))))),1) * sum(if(symbolType='CFD',amt,0))),0)) as USD_cfd_NOP,
    #USD Metal
    (IFNULL((SELECT(IFNULL((select ((bid+ask)/2) as rate from statements.symbols where symbol =concat(Ccy,'/USD')),(select 1/((bid+ask)/2) as rate from statements.symbols where symbol =concat('USD/',Ccy))))),1) * sum(if(symbolType = 'metal',amt,0))) as USD_metal,
    #USD Metal NOP
    abs(round((IFNULL((SELECT(IFNULL((select ((bid+ask)/2) as rate from statements.symbols where symbol =concat(Ccy,'/USD')),(select 1/((bid+ask)/2) as rate from statements.symbols where symbol =concat('USD/',Ccy))))),1) * sum(if(symbolType = 'metal',amt,0))),0)) as USD_metal_NOP
                from 
                ( 
                                # Left FX
                                select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, c.clientLimit, p.symbol, s.baseCcy ccy, p.position, 0 as marketRate, p.position amt, s.symbolType
                                from do.firm_positions p, statements.symbols s, do.nop_clients c
                                where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND (s.symbolType = 'FX' and p.symbol not like 'X%')
                                union all
                                # Right FX
                                select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, c.clientLimit, p.symbol, s.riskCcy ccy, p.position, p.marketRate, -round(p.position * p.marketrate, 0) amt, s.symbolType
                                from do.firm_positions p, statements.symbols s, do.nop_clients c
                                where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND (s.symbolType = 'FX' and p.symbol not like 'X%')
                                union all
                                # CFD
                                select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, c.clientLimit, p.symbol, s.riskCcy ccy, p.position, p.marketRate, p.position*s.lotsize*((s.bid+s.ask)/2) as amt, s.symbolType
                                from do.firm_positions p, statements.symbols s, do.nop_clients c
                                where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND (s.symbolType = 'CFD')
        union all
        # Left Metal
                                select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, c.clientLimit, p.symbol, s.baseCcy ccy, p.position, p.marketRate, (p.position*s.lotsize) as amt, 'metal' as symbolType
                                from do.firm_positions p, statements.symbols s, do.nop_clients c
                                where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND p.symbol like 'X%'
                ) x
                group by clientGroup, ccy
                order by clientGroup, ccy
) x1
group by clientGroup
order by ".$sortVar.", clientGroup;

        ";

        $result = mysql_query($sql);

        $query = mysql_query($sql);
        $row = mysql_fetch_array($query);
        $date = $row['LastUpdated'];
        $year = substr($date,0,4);
        $month = substr($date,4,2);
        $day = substr($date,6,2);
        $hour = substr($date,9,2).":00 AU";
        $time = $hour;
        $today = "(".$day."-".$month."-".$year.")";


    ?>

    <h1 align="center">Net Open Positions - Overall</h1>
    <h4 align="center">Data As At: <?php echo $time." ".$today;?></h4>
    <table class="bordered">
        <thead>
            <tr>
                <th style="text-align: center;"><a href="nop.php?sort=clientGroup">Client Group</a></th>        
                <th style="text-align: center;"><a href="nop.php?sort=USD_Overall_NOP">USD Amount</a></th>
                <th style="text-align: center;"><a href="nop.php?sort=clientLimit">Limit</a></th>
                <th style="text-align: center;"><a href="nop.php?sort=utilisation">Utilisation</a></th>
                <th style="text-align: center;">Breakdown</th>
                <th style="text-align: center;">Tiers</th>
            </tr>
        </thead>
        <?php

            # Displaying Rows
            if (mysql_num_rows($result) > 0)
            {
                while($row = mysql_fetch_assoc($result))
                {
                    $client = $row['clientGroup'];
                    $utilisation = (($row['USD_Overall_NOP']/$row['clientLimit'])*100);
                    echo "<tr>";
                    echo "<td>".$client."</td>";

                    if ($utilisation >= 75.00 && $utilisation <= 99)
                    {
                        echo "<td class='left-align' style='color:orange;'>".number_format($row['USD_Overall_NOP'],0)."</td>";
                    }
                    elseif ($utilisation >= 100.00)
                    {
                        echo "<td class='left-align' style='color:red;'>".number_format($row['USD_Overall_NOP'],0)."</td>";
                    }
                    else
                    {
                        echo "<td class='left-align'>".number_format($row['USD_Overall_NOP'],0)."</td>";
                    }
                    
                    echo "<td class='left-align'>".number_format($row['clientLimit'],0)."</td>";

                    if ($utilisation >= 75.00 && $utilisation <= 99)
                    {
                        echo "<td class='left-align' style='color:orange;'>".number_format($utilisation,2)."%</td>";
                    }
                    elseif ($utilisation >= 100.00)
                    {
                        echo "<td class='left-align' style='color:red;'>".number_format($utilisation,2)."%</td>";
                    }
                    else
                    {
                        echo "<td class='left-align'>".number_format($utilisation,2)."%</td>";
                    }                    
                    //echo "<td class='left-align'>".number_format($utilisation,2)."%</td>";
                    echo "<td><a href = 'nopbreakdown.php?link=".$client."'>view</a></td>";
                    echo "<td><a href = 'noptiers.php?link=".$client."'>view</a></td>";
                    echo "</tr>";
                }
                
            }else
            {
                echo "<td><center>No results to display</center></td>";
            }
        ?>   
    </table>
</body>
</html>