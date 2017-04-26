<!DOCTYPE html>
<!--
Author: Fahad Khan (fkhan@invast.com.au)
After changes
 -->
<html>
<head>
    <title>NOP</title>

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
    <center><img class="logo" src="images/Invast.jpg"></center>
    <?php 
        include('inc/connection.php');

        # Main query
        /*$sql =  "
select p.`timeStamp` as LastUpdated, p.symbol, sum(abs(p.position)) as sum
from do.firm_positions p, do.nop_clients c, statements.symbols s
where p.clientFirm = c.clientFirm AND p.symbol = s.symbol AND position <> 0 
GROUP BY symbol
ORDER BY symbol;
        ";*/
        $query_symbol_list = "
                select distinct(symbol) from(

                select p.`timeStamp` as LastUpdated, p.clientFirm, p.symbol, p.position
                from do.firm_positions p, statements.symbols s
                where p.symbol = s.symbol AND position <> 0 AND p.clientFirm <> 'VFX_london' AND p.clientFirm <> 'B_BOOK'
                ORDER BY 
                symbol

                ) x;
                ";
        $symbol_list = mysql_query($query_symbol_list);
        //var_dump($symbol_list);die();


 /*       $result = mysql_query($sql);

        $query = mysql_query($sql);
        $row = mysql_fetch_array($query);
        $date = $row['LastUpdated'];
        $year = substr($date,0,4);
        $month = substr($date,4,2);
        $day = substr($date,6,2);
        $hour = substr($date,9,2).":00 AU";
        $time = $hour;
        $today = "(".$day."-".$month."-".$year.")";
*/

    ?>

    <h1 align="center">ClientGroup vs Symbol Pivot</h1>
        <div id="buttons">
            <a href="nop.php" class="btn blue">Back to Overall Positions Page</a>
        </div>
    <h4 align="center">Data As At: <?php echo $time." ".$today;?></h4>
    <table class="bordered">
        <thead>
            <th style="text-align: center;">Symbols / Client Groups</th>
            <?php
                $array_symbol = array();
                $array_count = 0;
                if (mysql_num_rows($symbol_list) > 0)
                {
                    while($row = mysql_fetch_assoc($symbol_list))
                    {
                        echo "<th style='text-align: center;'>".$row['symbol']."</th>";
                        $array_symbol[$array_count] = $row['symbol'];
                        $array_count ++;
                    }
                $array_length = count($array_symbol);
                }
                
            ?>
            <!--<th style="text-align: center;">Symbols</th> 
            <th style="text-align: center;">Sum</th> -->
        </thead>
        <?php
        $query_rows = "
                    drop view if exists `nop_client_symbol_matrix_temp`;
                    create view nop_client_symbol_matrix_temp as (
                        select p.`timeStamp` as LastUpdated, p.clientFirm, p.symbol, p.position
                        from do.firm_positions p, statements.symbols s
                        where p.symbol = s.symbol AND position <> 0 AND p.clientFirm <> 'VFX_london' AND p.clientFirm <> 'B_BOOK'
                        ORDER BY 
                        clientFirm
                    );
                    drop view if exists `nop_client_symbol_matrix_view`;
                    create view nop_client_symbol_matrix_view as (
                      select
                        *";
                        for($x = 0; $x < $array_length; $x++) 
                        {
                            $query_rows .= ",case when symbol =\"".$array_symbol[$x]."\" then position end as `".$array_symbol[$x]."`";
                            
                        }
                        $query_rows .="from do.nop_client_symbol_matrix_temp
                    );
                    drop view if exists `nop_client_symbol_matrix_pivot_view`;
                    create view nop_client_symbol_matrix_pivot_view as (
                        select
                        clientFirm";
                        for($x = 0; $x < $array_length; $x++) 
                        {
                            $query_rows .= ",sum(`".$array_symbol[$x]."`) as `".$array_symbol[$x]."`";
                            
                        }
                        $query_rows .="
                        from nop_client_symbol_matrix_view
                        group by clientFirm
                    );

                    drop view if exists `nop_client_final_view`;
                    create view nop_client_final_view as (
                        select
                        clientFirm";
                        for($x = 0; $x < $array_length; $x++) 
                        {
                            $query_rows .= ",coalesce(`".$array_symbol[$x]."`, 0) as `".$array_symbol[$x]."`";
                            
                        }
                        $query_rows .="
                        from nop_client_symbol_matrix_pivot_view
                        group by clientFirm
                    );
                    
        ";

        echo $query_rows;die();
        $result_final = mysql_query($query_rows);
        $display = "select * from nop_client_symbol_matrix_pivot_view;";
        $result_display = mysql_query($display);
        var_dump($result_display);die();  

            # Displaying Rows
            if (mysql_num_rows($result_display) > 0)
            {
                while($row = mysql_fetch_assoc($result_display))
                {
                    echo "<tr>";
                    echo "<td>".$row['clientFirm']."</td>";
                    //echo "<td class='left-align'>";
                        for($x = 0; $x < $array_length; $x++) 
                        {
                            echo "<td class='left-align'>";
                            echo $array_symbol[$x];
                            echo "</td>";
                            
                        }                    
                    //echo "</td>";
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