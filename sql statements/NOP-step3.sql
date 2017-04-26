# NOP Positions X Symbol Matrix query
select p.`timeStamp` as LastUpdated, p.clientFirm, p.symbol, p.position
from do.firm_positions p, statements.symbols s
where p.symbol = s.symbol AND position <> 0 AND p.clientFirm <> 'VFX_london' AND p.clientFirm <> 'B_BOOK'
ORDER BY 
clientFirm;

# NOP ABS Positions X Symbol Matrix query
select p.`timeStamp` as LastUpdated, p.clientFirm, p.symbol, abs(p.position) as `absolute position`
from do.firm_positions p, statements.symbols s
where p.symbol = s.symbol AND position <> 0 AND p.clientFirm <> 'VFX_london' AND p.clientFirm <> 'B_BOOK'
ORDER BY 
clientFirm;

# NOP SUM Positions by Symbol
select p.`timeStamp` as LastUpdated, p.symbol, sum(abs(p.position)) as sum
from do.firm_positions p, statements.symbols s
where p.symbol = s.symbol AND position <> 0 AND p.clientFirm <> 'VFX_london' AND p.clientFirm <> 'B_BOOK'
GROUP BY symbol
ORDER BY symbol;




#Pivot HARDCODED QUERY
drop view if exists `nop_client_symbol_matrix_temp`; 
create view nop_client_symbol_matrix_temp as 
( 
	select p.`timeStamp` as LastUpdated, p.clientFirm, p.symbol, p.position from do.firm_positions p, statements.symbols s where p.symbol = s.symbol AND position <> 0 AND p.clientFirm <> 'VFX_london' AND p.clientFirm <> 'B_BOOK' ORDER BY clientFirm 
);

drop view if exists `nop_client_symbol_matrix_view`; 
create view nop_client_symbol_matrix_view as 
( 
	select *,case when symbol ="AUD/CAD" then position end as `AUD/CAD`,case when symbol ="AUD/CHF" then position end as `AUD/CHF`,case when symbol ="AUD/JPY" then position end as `AUD/JPY`,case when symbol ="AUD/NZD" then position end as `AUD/NZD`,case when symbol ="AUD/SGD" then position end as `AUD/SGD`,case when symbol ="AUD/USD" then position end as `AUD/USD`,case when symbol ="AXC/AUD" then position end as `AXC/AUD`,case when symbol ="BCO/USD" then position end as `BCO/USD`,case when symbol ="CAD/CHF" then position end as `CAD/CHF`,case when symbol ="CAD/JPY" then position end as `CAD/JPY`,case when symbol ="CHF/JPY" then position end as `CHF/JPY`,case when symbol ="CRC/USD" then position end as `CRC/USD`,case when symbol ="DJC/USD" then position end as `DJC/USD`,case when symbol ="EUR/AUD" then position end as `EUR/AUD`,case when symbol ="EUR/CAD" then position end as `EUR/CAD`,case when symbol ="EUR/CHF" then position end as `EUR/CHF`,case when symbol ="EUR/GBP" then position end as `EUR/GBP`,case when symbol ="EUR/JPY" then position end as `EUR/JPY`,case when symbol ="EUR/NOK" then position end as `EUR/NOK`,case when symbol ="EUR/NZD" then position end as `EUR/NZD`,case when symbol ="EUR/SEK" then position end as `EUR/SEK`,case when symbol ="EUR/TRY" then position end as `EUR/TRY`,case when symbol ="EUR/USD" then position end as `EUR/USD`,case when symbol ="EXC/EUR" then position end as `EXC/EUR`,case when symbol ="FRC/EUR" then position end as `FRC/EUR`,case when symbol ="GBP/AUD" then position end as `GBP/AUD`,case when symbol ="GBP/CAD" then position end as `GBP/CAD`,case when symbol ="GBP/CHF" then position end as `GBP/CHF`,case when symbol ="GBP/JPY" then position end as `GBP/JPY`,case when symbol ="GBP/NZD" then position end as `GBP/NZD`,case when symbol ="GBP/SGD" then position end as `GBP/SGD`,case when symbol ="GBP/USD" then position end as `GBP/USD`,case when symbol ="GEC/EUR" then position end as `GEC/EUR`,case when symbol ="HKC/HKD" then position end as `HKC/HKD`,case when symbol ="JPC/JPY" then position end as `JPC/JPY`,case when symbol ="NAC/USD" then position end as `NAC/USD`,case when symbol ="NZD/CAD" then position end as `NZD/CAD`,case when symbol ="NZD/CHF" then position end as `NZD/CHF`,case when symbol ="NZD/JPY" then position end as `NZD/JPY`,case when symbol ="NZD/USD" then position end as `NZD/USD`,case when symbol ="SPC/USD" then position end as `SPC/USD`,case when symbol ="UKC/GBP" then position end as `UKC/GBP`,case when symbol ="USD/CAD" then position end as `USD/CAD`,case when symbol ="USD/CHF" then position end as `USD/CHF`,case when symbol ="USD/CNH" then position end as `USD/CNH`,case when symbol ="USD/JPY" then position end as `USD/JPY`,case when symbol ="USD/MXN" then position end as `USD/MXN`,case when symbol ="USD/NOK" then position end as `USD/NOK`,case when symbol ="USD/SEK" then position end as `USD/SEK`,case when symbol ="USD/SGD" then position end as `USD/SGD`,case when symbol ="USD/TRY" then position end as `USD/TRY`,case when symbol ="USD/ZAR" then position end as `USD/ZAR`,case when symbol ="XAG/AUD" then position end as `XAG/AUD`,case when symbol ="XAG/USD" then position end as `XAG/USD`,case when symbol ="XAU/AUD" then position end as `XAU/AUD`,case when symbol ="XAU/USD" then position end as `XAU/USD`from do.nop_client_symbol_matrix_temp 
);

drop view if exists `nop_client_symbol_matrix_pivot_view`; 
create view nop_client_symbol_matrix_pivot_view as 
( 
	select clientFirm,sum(`AUD/CAD`) as `AUD/CAD`,sum(`AUD/CHF`) as `AUD/CHF`,sum(`AUD/JPY`) as `AUD/JPY`,sum(`AUD/NZD`) as `AUD/NZD`,sum(`AUD/SGD`) as `AUD/SGD`,sum(`AUD/USD`) as `AUD/USD`,sum(`AXC/AUD`) as `AXC/AUD`,sum(`BCO/USD`) as `BCO/USD`,sum(`CAD/CHF`) as `CAD/CHF`,sum(`CAD/JPY`) as `CAD/JPY`,sum(`CHF/JPY`) as `CHF/JPY`,sum(`CRC/USD`) as `CRC/USD`,sum(`DJC/USD`) as `DJC/USD`,sum(`EUR/AUD`) as `EUR/AUD`,sum(`EUR/CAD`) as `EUR/CAD`,sum(`EUR/CHF`) as `EUR/CHF`,sum(`EUR/GBP`) as `EUR/GBP`,sum(`EUR/JPY`) as `EUR/JPY`,sum(`EUR/NOK`) as `EUR/NOK`,sum(`EUR/NZD`) as `EUR/NZD`,sum(`EUR/SEK`) as `EUR/SEK`,sum(`EUR/TRY`) as `EUR/TRY`,sum(`EUR/USD`) as `EUR/USD`,sum(`EXC/EUR`) as `EXC/EUR`,sum(`FRC/EUR`) as `FRC/EUR`,sum(`GBP/AUD`) as `GBP/AUD`,sum(`GBP/CAD`) as `GBP/CAD`,sum(`GBP/CHF`) as `GBP/CHF`,sum(`GBP/JPY`) as `GBP/JPY`,sum(`GBP/NZD`) as `GBP/NZD`,sum(`GBP/SGD`) as `GBP/SGD`,sum(`GBP/USD`) as `GBP/USD`,sum(`GEC/EUR`) as `GEC/EUR`,sum(`HKC/HKD`) as `HKC/HKD`,sum(`JPC/JPY`) as `JPC/JPY`,sum(`NAC/USD`) as `NAC/USD`,sum(`NZD/CAD`) as `NZD/CAD`,sum(`NZD/CHF`) as `NZD/CHF`,sum(`NZD/JPY`) as `NZD/JPY`,sum(`NZD/USD`) as `NZD/USD`,sum(`SPC/USD`) as `SPC/USD`,sum(`UKC/GBP`) as `UKC/GBP`,sum(`USD/CAD`) as `USD/CAD`,sum(`USD/CHF`) as `USD/CHF`,sum(`USD/CNH`) as `USD/CNH`,sum(`USD/JPY`) as `USD/JPY`,sum(`USD/MXN`) as `USD/MXN`,sum(`USD/NOK`) as `USD/NOK`,sum(`USD/SEK`) as `USD/SEK`,sum(`USD/SGD`) as `USD/SGD`,sum(`USD/TRY`) as `USD/TRY`,sum(`USD/ZAR`) as `USD/ZAR`,sum(`XAG/AUD`) as `XAG/AUD`,sum(`XAG/USD`) as `XAG/USD`,sum(`XAU/AUD`) as `XAU/AUD`,sum(`XAU/USD`) as `XAU/USD` from nop_client_symbol_matrix_view group by clientFirm 
);

drop view if exists `nop_client_final_view`; 
create view nop_client_final_view as 
( 
	select clientFirm,coalesce(`AUD/CAD`, 0) as `AUD/CAD`,coalesce(`AUD/CHF`, 0) as `AUD/CHF`,coalesce(`AUD/JPY`, 0) as `AUD/JPY`,coalesce(`AUD/NZD`, 0) as `AUD/NZD`,coalesce(`AUD/SGD`, 0) as `AUD/SGD`,coalesce(`AUD/USD`, 0) as `AUD/USD`,coalesce(`AXC/AUD`, 0) as `AXC/AUD`,coalesce(`BCO/USD`, 0) as `BCO/USD`,coalesce(`CAD/CHF`, 0) as `CAD/CHF`,coalesce(`CAD/JPY`, 0) as `CAD/JPY`,coalesce(`CHF/JPY`, 0) as `CHF/JPY`,coalesce(`CRC/USD`, 0) as `CRC/USD`,coalesce(`DJC/USD`, 0) as `DJC/USD`,coalesce(`EUR/AUD`, 0) as `EUR/AUD`,coalesce(`EUR/CAD`, 0) as `EUR/CAD`,coalesce(`EUR/CHF`, 0) as `EUR/CHF`,coalesce(`EUR/GBP`, 0) as `EUR/GBP`,coalesce(`EUR/JPY`, 0) as `EUR/JPY`,coalesce(`EUR/NOK`, 0) as `EUR/NOK`,coalesce(`EUR/NZD`, 0) as `EUR/NZD`,coalesce(`EUR/SEK`, 0) as `EUR/SEK`,coalesce(`EUR/TRY`, 0) as `EUR/TRY`,coalesce(`EUR/USD`, 0) as `EUR/USD`,coalesce(`EXC/EUR`, 0) as `EXC/EUR`,coalesce(`FRC/EUR`, 0) as `FRC/EUR`,coalesce(`GBP/AUD`, 0) as `GBP/AUD`,coalesce(`GBP/CAD`, 0) as `GBP/CAD`,coalesce(`GBP/CHF`, 0) as `GBP/CHF`,coalesce(`GBP/JPY`, 0) as `GBP/JPY`,coalesce(`GBP/NZD`, 0) as `GBP/NZD`,coalesce(`GBP/SGD`, 0) as `GBP/SGD`,coalesce(`GBP/USD`, 0) as `GBP/USD`,coalesce(`GEC/EUR`, 0) as `GEC/EUR`,coalesce(`HKC/HKD`, 0) as `HKC/HKD`,coalesce(`JPC/JPY`, 0) as `JPC/JPY`,coalesce(`NAC/USD`, 0) as `NAC/USD`,coalesce(`NZD/CAD`, 0) as `NZD/CAD`,coalesce(`NZD/CHF`, 0) as `NZD/CHF`,coalesce(`NZD/JPY`, 0) as `NZD/JPY`,coalesce(`NZD/USD`, 0) as `NZD/USD`,coalesce(`SPC/USD`, 0) as `SPC/USD`,coalesce(`UKC/GBP`, 0) as `UKC/GBP`,coalesce(`USD/CAD`, 0) as `USD/CAD`,coalesce(`USD/CHF`, 0) as `USD/CHF`,coalesce(`USD/CNH`, 0) as `USD/CNH`,coalesce(`USD/JPY`, 0) as `USD/JPY`,coalesce(`USD/MXN`, 0) as `USD/MXN`,coalesce(`USD/NOK`, 0) as `USD/NOK`,coalesce(`USD/SEK`, 0) as `USD/SEK`,coalesce(`USD/SGD`, 0) as `USD/SGD`,coalesce(`USD/TRY`, 0) as `USD/TRY`,coalesce(`USD/ZAR`, 0) as `USD/ZAR`,coalesce(`XAG/AUD`, 0) as `XAG/AUD`,coalesce(`XAG/USD`, 0) as `XAG/USD`,coalesce(`XAU/AUD`, 0) as `XAU/AUD`,coalesce(`XAU/USD`, 0) as `XAU/USD` from nop_client_symbol_matrix_pivot_view group by clientFirm 
);

select * from nop_client_final_view;




# Prepared statement try
SET @sql = NULL;
SET group_concat_max_len = 8000;
SELECT
  GROUP_CONCAT(DISTINCT
    CONCAT(
      "MAX(IF(symbol = '
      ",symbol,"
      ', position, NULL)) AS ",
      symbol
    )
  ) INTO @sql
FROM nop_client_symbol_matrix_temp;
#select @sql;
SET @sql = CONCAT("SELECT clientFirm, ", @sql, " 
                   FROM nop_client_symbol_matrix_temp");

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;







SET @sql = NULL;
SET group_concat_max_len = 8000;
SELECT
  GROUP_CONCAT(DISTINCT
    CONCAT(
      "MAX(IF(symbol = ''",
      symbol,
      "'', position, NULL)) AS ",
      symbol
    )
  ) INTO @sql
FROM do.nop_client_symbol_matrix_temp;
SET @sql = CONCAT("SELECT clientFirm, ", @sql, " FROM do.nop_client_symbol_matrix_temp GROUP BY clientFirm");
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;





SET @sql = NULL;
SET group_concat_max_len = 8000;
SELECT
	GROUP_CONCAT(DISTINCT
		CONCAT(
		  MAX(IF(symbol = 
		  symbol,
		  position, NULL)), 'AS ',
		  symbol
		)
    ) INTO @sql
FROM do.nop_client_symbol_matrix_temp;

SET @sql = CONCAT("SELECT LastUpdated
                    , clientFirm
                    , symbol, position ", @sql, " 
                   FROM do.nop_client_symbol_matrix_temp
                   GROUP BY clientFirm");
                   
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
# Prepared statement try END