<!DOCTYPE html>
<html>
<head>
    <title>NOP Breakdown Tiers</title>

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
        $clientGroup = $_GET['group'];
        $clientFirm = $_GET['firm'];

        if (empty($_GET['group']) || empty($_GET['firm']) )
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
-- Tier with Base Exposures
select LastUpdated, clientGroup, clientFirm, displayCcy,  sum(tier1Exposure) as tier1BaseExposure,sum(tier1) as tier1NOP, sum(tier2Exposure) as tier2BaseExposure, sum(tier2) as tier2NOP, sum(tier3Exposure) as tier3BaseExposure, sum(tier3) as tier3NOP, sum(tier4Exposure) as tier4BaseExposure, sum(tier4) as tier4NOP, sum(tier5Exposure) as tier5BaseExposure, sum(tier5) as tier5NOP
from
(
    select LastUpdated, clientGroup, clientFirm, displayCcy, sum(USD_fx_NOP+USD_cfd_NOP+USD_metal_NOP)  as USD_NOP_sum, tier, amt,
    if(tier=1,sum(USD_fx_NOP+USD_cfd_NOP+USD_metal_NOP),0) as tier1,
    if(tier=1,amt,0) as tier1Exposure,
    if(tier=2,sum(USD_fx_NOP+USD_cfd_NOP+USD_metal_NOP),0) as tier2,
    if(tier=2,amt,0) as tier2Exposure,
    if(tier=3,sum(USD_fx_NOP+USD_cfd_NOP+USD_metal_NOP),0) as tier3,
    if(tier=3,amt,0) as tier3Exposure,
    if(tier=4,sum(USD_fx_NOP+USD_cfd_NOP+USD_metal_NOP),0) as tier4,
    if(tier=4,amt,0) as tier4Exposure,
    if(tier=5,sum(USD_fx_NOP+USD_cfd_NOP+USD_metal_NOP),0) as tier5,
    if(tier=5,amt,0) as tier5Exposure
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
        abs(round((IFNULL((SELECT(IFNULL((select ((bid+ask)/2) as rate from statements.symbols where symbol =concat(Ccy,'/USD')),(select 1/((bid+ask)/2) as rate from statements.symbols where symbol =concat('USD/',Ccy))))),1) * sum(if(symbolType = 'metal',amt,0))),0)) as USD_metal_NOP,
        max(tier) as tier
        
        from 
        ( 
            # Left FX
            select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, p.symbol, s.baseCcy displayCcy, s.baseCcy ccy, p.position, 0 as marketRate, p.position amt, s.symbolType, bt.tier as baseCcyTier, rt.tier as riskCcyTier, if(bt.tier>rt.tier,bt.tier,rt.tier) as tier
            from do.firm_positions p, statements.symbols s, do.nop_clients c, do.nop_ccytier bt, do.nop_ccytier rt
            where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND (s.symbolType = 'FX' and p.symbol not like 'X%') AND c.clientGroup = '$clientGroup' and s.baseccy=bt.ccy and p.clientFirm=bt.clientFirm and s.riskccy=rt.ccy and p.clientfirm=rt.clientfirm and p.position <> 0
            union all
            # Right FX
            select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, p.symbol, s.riskCcy displayCcy, s.riskCcy ccy, p.position, p.marketRate, -round(p.position * p.marketrate, 0) amt, s.symbolType, bt.tier as baseCcyTier, rt.tier as riskCcyTier, if(bt.tier>rt.tier,bt.tier,rt.tier) as tier
            from do.firm_positions p, statements.symbols s, do.nop_clients c, do.nop_ccytier bt, do.nop_ccytier rt
            where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND (s.symbolType = 'FX' and p.symbol not like 'X%') AND c.clientGroup = '$clientGroup' and s.baseccy=bt.ccy and p.clientFirm=bt.clientFirm and s.riskccy=rt.ccy and p.clientfirm=rt.clientfirm and p.position <> 0
            union all
            # CFD
            select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, p.symbol, left(s.symbol,3) displayCcy, s.riskCcy ccy, p.position, p.marketRate, p.position*s.lotsize*((s.bid+s.ask)/2) as amt, s.symbolType, bt.tier as baseCcyTier, rt.tier as riskCcyTier, 5 as tier
            from do.firm_positions p, statements.symbols s, do.nop_clients c, do.nop_ccytier bt, do.nop_ccytier rt
            where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND (s.symbolType = 'CFD') AND c.clientGroup = '$clientGroup' and s.baseccy=bt.ccy and p.clientFirm=bt.clientFirm and s.riskccy=rt.ccy and p.clientfirm=rt.clientfirm and p.position <> 0
            union all
            # Left Metal
            select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, p.symbol, s.baseCcy displayCcy, s.baseCcy ccy, p.position, p.marketRate, (p.position*s.lotsize) as amt, 'metal' as symbolType, bt.tier as baseCcyTier, rt.tier as riskCcyTier, if(bt.tier>rt.tier,bt.tier,rt.tier) as tier
            from do.firm_positions p, statements.symbols s, do.nop_clients c, do.nop_ccytier bt, do.nop_ccytier rt
            where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND p.symbol like 'X%' AND c.clientGroup = '$clientGroup' and s.baseccy=bt.ccy and p.clientFirm=bt.clientFirm and s.riskccy=rt.ccy and p.clientfirm=rt.clientfirm and p.position <> 0
        ) x
        where clientFirm = '$clientFirm'
        group by clientGroup, displayCcy, tier
        order by clientGroup, displayCcy
    ) x1 
    group by clientGroup, displayCcy,tier
    order by clientGroup, displayCcy
)x2
group by displayCcy;";
        $result = mysql_query($sql);

        //$sql2 = "select tier1,tier2,tier3,tier4,tier5 FROM do.nop_clients where clientGroup = '$clientGroup';";
        $sql2 = "select tier1,tier2,tier3,tier4,tier5 FROM do.nop_clients where clientFirm = '$clientFirm';";
        $result2 = mysql_query($sql2);
        $limits = mysql_fetch_array($result2);

        $query_clientFirm = "select clientFirm from do.nop_clients where clientGroup = '$clientGroup' order by clientFirm";
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

    <h1 align="center">Net Open Positions - Tiers</h1>

        <div id="buttons">
            <a href="nop.php" class="btn">Overall NOP</a>
            <a href='noptiers.php?link=<?php echo $clientGroup;?>' class="btn"><?php echo $clientGroup;?> Tiers</a>
            <a href='nopbreakdown.php?link=<?php echo $clientGroup;?>' class="btn"><?php echo $clientGroup;?> NOP</a>
        </div> 

        <h1 align="center">
        Client Firm:
        <font style='color:#dc4814;'>
        <?php echo $clientFirm;?> 
        </font>
        </h1>
    <?php 
    if ($row['LastUpdated'] != "")
    {
    ?>
    <h4 align="center">Data As At: <?php echo $time." ".$today;?></h4>
    <?php 
    } 
    ?>
    <span class="tableTiers">
    <h2>NOP Tier Breakdown by Client Firm</h2>
    <table class="bordered">
        <thead>
            <tr>     
                <th style="text-align: left;"></th>
                <th style="text-align: center;" colspan="2">Tier 1</th>
                <th style="text-align: center;" colspan="2">Tier 2</th>
                <th style="text-align: center;" colspan="2">Tier 3</th>
                <th style="text-align: center;" colspan="2">Tier 4</th>
                <th style="text-align: center;" colspan="2">Tier 5</th>
            </tr>
            <tr>     
                <th style="text-align: left;" width="80px">CCY</th>
                <th style="text-align: center;">Base Exposure</th>
                <th style="text-align: center;">NOP</th>
                <th style="text-align: center;">Base Exposure</th>
                <th style="text-align: center;">NOP</th>
                <th style="text-align: center;">Base Exposure</th>
                <th style="text-align: center;">NOP</th>
                <th style="text-align: center;">Base Exposure</th>
                <th style="text-align: center;">NOP</th>
                <th style="text-align: center;">Base Exposure</th>
                <th style="text-align: center;">NOP</th>                                                                
            </tr>            
        </thead>
        <?php

            if (mysql_num_rows($result) > 0)
            {
                $sum1 = 0;
                $sum2 = 0;
                $sum3 = 0;
                $sum4 = 0;
                $sum5 = 0;
                while($row = mysql_fetch_assoc($result))
                {
                    echo "<tr>";
                        echo "<td class='grey'>".$row['displayCcy']."</td>";
                        /*
                        echo "<td class='center-align'>".negformat(number_format($row['tier1BaseExposure']) )."</td>";
                        echo "<td class='center-align'>".number_format($row['tier1NOP'])."</td>";
                        echo "<td class='center-align'>".negformat(number_format($row['tier2BaseExposure']) )."</td>";
                        echo "<td class='center-align'>".number_format($row['tier2NOP'])."</td>";
                        echo "<td class='center-align'>".negformat(number_format($row['tier3BaseExposure']) )."</td>";
                        echo "<td class='center-align'>".number_format($row['tier3NOP'])."</td>";
                        echo "<td class='center-align'>".negformat(number_format($row['tier4BaseExposure']) )."</td>";
                        echo "<td class='center-align'>".number_format($row['tier4NOP'])."</td>";
                        echo "<td class='center-align'>".negformat(number_format($row['tier5BaseExposure']) )."</td>";
                        echo "<td class='center-align'>".number_format($row['tier5NOP'])."</td>";
                        */
                        if ($row['tier1BaseExposure'] < 0){
                            echo "<td class='center-align' width='0px' style='color:#dc4814;'>".negformat(number_format($row['tier1BaseExposure']) )."</td>";
                        }else{
                        echo "<td class='center-align' width='0px'>".negformat(number_format($row['tier1BaseExposure']) )."</td>";
                        }
                        echo "<td class='center-align'>".number_format($row['tier1NOP'])."</td>";

                        if ($row['tier2BaseExposure'] < 0){
                            echo "<td class='center-align' width='0px' style='color:#dc4814;'>".negformat(number_format($row['tier2BaseExposure']) )."</td>";
                        }else{
                        echo "<td class='center-align' width='0px'>".negformat(number_format($row['tier2BaseExposure']) )."</td>";
                        }
                        echo "<td class='center-align'>".number_format($row['tier2NOP'])."</td>";

                        if ($row['tier3BaseExposure'] < 0){
                            echo "<td class='center-align' width='0px' style='color:#dc4814;'>".negformat(number_format($row['tier3BaseExposure']) )."</td>";
                        }else{
                        echo "<td class='center-align' width='0px'>".negformat(number_format($row['tier3BaseExposure']) )."</td>";
                        }
                        echo "<td class='center-align'>".number_format($row['tier3NOP'])."</td>";

                        if ($row['tier4BaseExposure'] < 0){
                            echo "<td class='center-align' width='0px' style='color:#dc4814;'>".negformat(number_format($row['tier4BaseExposure']) )."</td>";
                        }else{
                        echo "<td class='center-align' width='0px'>".negformat(number_format($row['tier4BaseExposure']) )."</td>";
                        }
                        echo "<td class='center-align'>".number_format($row['tier4NOP'])."</td>";

                        if ($row['tier5BaseExposure'] < 0){
                            echo "<td class='center-align' width='0px' style='color:#dc4814;'>".negformat(number_format($row['tier5BaseExposure']) )."</td>";
                        }else{
                        echo "<td class='center-align' width='0px'>".negformat(number_format($row['tier5BaseExposure']) )."</td>";
                        }
                        echo "<td class='center-align'>".number_format($row['tier5NOP'])."</td>";
                    echo "</tr>";
                    $sum1 += $row['tier1NOP'];
                    $sum2 += $row['tier2NOP'];
                    $sum3 += $row['tier3NOP'];
                    $sum4 += $row['tier4NOP'];
                    $sum5 += $row['tier5NOP'];
                }
                echo "<tr>";
                    echo "<td class='grey'><b>Total</b></td>";
                    $percent1 = (($sum1/$limits['tier1'])*100);
                    $percent2 = (($sum2/$limits['tier2'])*100);
                    $percent3 = (($sum3/$limits['tier3'])*100);
                    $percent4 = (($sum4/$limits['tier4'])*100);
                    $percent5 = (($sum5/$limits['tier5'])*100);

                    echo "<td class='center-align' width='0px'></td>";
                    if ($percent1 >= 100.00)
                    {echo "<td class='center-align' width='0px' style='background-color:#dc4814;'><b>".number_format($sum1)."</b></td>";
                    }elseif ($percent1 >= 75.00)
                    {echo "<td class='center-align' width='0px' style='background-color:#e99e7c;'><b>".number_format($sum1)."</b></td>";
                    }else
                    {echo "<td class='center-align' width='0px'><b>".number_format($sum1)."</b></td>";
                    }

                    echo "<td class='center-align' width='0px'></td>";
                    if ($percent2 >= 100.00)
                    {echo "<td class='center-align' width='0px' style='background-color:#dc4814;'><b>".number_format($sum2)."</b></td>";
                    }elseif ($percent2 >= 75.00)
                    {echo "<td class='center-align' width='0px' style='background-color:#e99e7c;'><b>".number_format($sum2)."</b></td>";
                    }else
                    {echo "<td class='center-align' width='0px'><b>".number_format($sum2)."</b></td>";
                    }

                    echo "<td class='center-align' width='0px'></td>";
                    if ($percent3 >= 100.00)
                    {echo "<td class='center-align' width='0px' style='background-color:#dc4814;'><b>".number_format($sum3)."</b></td>";
                    }elseif ($percent3 >= 75.00)
                    {echo "<td class='center-align' width='0px' style='background-color:#e99e7c;'><b>".number_format($sum3)."</b></td>";
                    }else
                    {echo "<td class='center-align' width='0px'><b>".number_format($sum3)."</b></td>";
                    }

                    echo "<td class='center-align' width='0px'></td>";
                    if ($percent4 >= 100.00)
                    {echo "<td class='center-align' width='0px' style='background-color:#dc4814;'><b>".number_format($sum4)."</b></td>";
                    }elseif ($percent4 >= 75.00)
                    {echo "<td class='center-align' width='0px' style='background-color:#e99e7c;'><b>".number_format($sum4)."</b></td>";
                    }else
                    {echo "<td class='center-align' width='0px'><b>".number_format($sum4)."</b></td>";
                    }

                    echo "<td class='center-align' width='0px'></td>";
                    if ($percent5 >= 100.00)
                    {echo "<td class='center-align' width='0px' style='background-color:#dc4814;'><b>".number_format($sum5)."</b></td>";
                    }elseif ($percent5 >= 75.00)
                    {echo "<td class='center-align' width='0px' style='background-color:#e99e7c;'><b>".number_format($sum5)."</b></td>";
                    }else
                    {echo "<td class='center-align' width='0px'><b>".number_format($sum5)."</b></td>";
                    }

                echo "</tr>";

                echo "<tr>";
                    echo "<td class='grey'><b>% Used</b></td>";
                    if ($percent1 >= 75.00 && $percent1 <= 99)
                    {
                        echo "<td colspan='2' class='center-align' style='background-color:#e99e7c;' width='0px'><b>".number_format($percent1,2)."%</b></td>";
                    }
                    elseif ($percent1 >= 100.00)
                    {
                        echo "<td colspan='2' class='center-align' style='background-color:#dc4814;' width='0px'><b>".number_format($percent1,2)."%</b></td>";
                    }
                    else
                    {
                        echo "<td colspan='2' class='center-align' width='0px'><b>".number_format($percent1,2)."%</b></td>";
                    }






                    if ($percent2 >= 75.00 && $percent2 <= 99)
                    {
                        echo "<td colspan='2' class='center-align' style='background-color:#e99e7c;' width='0px'><b>".number_format($percent2,2)."%</b></td>";
                    }
                    elseif ($percent2 >= 100.00)
                    {
                        echo "<td colspan='2' class='center-align' style='background-color:#dc4814;' width='0px'><b>".number_format($percent2,2)."%</b></td>";
                    }
                    else
                    {
                        echo "<td colspan='2' class='center-align' width='0px'><b>".number_format($percent2,2)."%</b></td>";
                    }






                    if ($percent3 >= 75.00 && $percent3 <= 99)
                    {
                        echo "<td colspan='2' class='center-align' style='background-color:#e99e7c;' width='0px'><b>".number_format($percent3,2)."%</b></td>";
                    }
                    elseif ($percent3 >= 100.00)
                    {
                        echo "<td colspan='2' class='center-align' style='background-color:#dc4814;' width='0px'><b>".number_format($percent3,2)."%</b></td>";
                    }
                    else
                    {
                        echo "<td colspan='2' class='center-align' width='0px'><b>".number_format($percent3,2)."%</b></td>";
                    }






                    if ($percent4 >= 75.00 && $percent4 <= 99)
                    {
                        echo "<td colspan='2' class='center-align' style='background-color:#e99e7c;' width='0px'><b>".number_format($percent4,2)."%</b></td>";
                    }
                    elseif ($percent4 >= 100.00)
                    {
                        echo "<td colspan='2' class='center-align' style='background-color:#dc4814;' width='0px'><b>".number_format($percent4,2)."%</b></td>";
                    }
                    else
                    {
                        echo "<td colspan='2' class='center-align' width='0px'><b>".number_format($percent4,2)."%</b></td>";
                    }






                    if ($percent5 >= 75.00 && $percent5 <= 99)
                    {
                        echo "<td colspan='2' class='center-align' style='background-color:#e99e7c;' width='0px'><b>".number_format($percent5,2)."%</b></td>";
                    }
                    elseif ($percent5 >= 100.00)
                    {
                        echo "<td colspan='2' class='center-align' style='background-color:#dc4814;' width='0px'><b>".number_format($percent5,2)."%</b></td>";
                    }
                    else
                    {
                        echo "<td colspan='2' class='center-align' width='0px'><b>".number_format($percent5,2)."%</b></td>";
                    }





                echo "</tr>";

                echo "<tr>";
                    echo "<td class='grey'><b>Tier Limit</b></td>";
                    echo "<td colspan='2' class='center-align' width='0px'><b>".number_format($limits['tier1'])."</b></td>";
                    echo "<td colspan='2' class='center-align' width='0px'><b>".number_format($limits['tier2'])."</b></td>";
                    echo "<td colspan='2' class='center-align' width='0px'><b>".number_format($limits['tier3'])."</b></td>";
                    echo "<td colspan='2' class='center-align' width='0px'><b>".number_format($limits['tier4'])."</b></td>";
                    echo "<td colspan='2' class='center-align' width='0px'><b>".number_format($limits['tier5'])."</b></td>";
                echo "</tr>";
            }else
            {
                echo "<td colspan = '11'><center>No results to display</center></td>";
            }
        ?>
        <tr>
        </tr>      
    </table>
    </span>
        <center>
    <br>

 </center>
 <br>
 <center><p>&copy; Copyright Unicorn. All rights reserved.</p></center>
</body></html>