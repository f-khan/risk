select distinct(symbol) from(

select p.`timeStamp` as LastUpdated, p.clientFirm, p.symbol, p.position
from do.firm_positions p, statements.symbols s
where p.symbol = s.symbol AND position <> 0 AND p.clientFirm <> 'VFX_london' AND p.clientFirm <> 'B_BOOK'
ORDER BY 
symbol

) x;

create view nop_client_symbol_matrix_temp as (
	select p.`timeStamp` as LastUpdated, p.clientFirm, p.symbol, p.position
	from do.firm_positions p, statements.symbols s
	where p.symbol = s.symbol AND position <> 0 AND p.clientFirm <> 'VFX_london' AND p.clientFirm <> 'B_BOOK'
	ORDER BY 
	clientFirm
);

create view nop_client_symbol_matrix_view as (
  select
    *,
    case when symbol = "AUD/CAD" then position end as `AUD/CAD`,
    case when symbol = "AUD/USD" then position end as `AUD/USD`,
    case when symbol = "HKC/HKD" then position end as `HKC/HKD`
  from do.nop_client_symbol_matrix_temp
  order by symbol
);

create view nop_client_symbol_matrix_pivot_view as (
	select
    clientFirm,
    sum(`AUD/CAD`) as `AUD/CAD`,
    sum(`AUD/USD`) as `AUD/USD`,
    sum(`HKC/HKD`) as `HKC/HKD`
    from do.nop_client_symbol_matrix_view
    group by clientFirm
);

create view final_view as (
	select
    clientFirm,
    coalesce(`AUD/CAD`, 0) as `AUD/CAD`,
    coalesce(`AUD/USD`, 0) as `AUD/USD`,
    coalesce(`HKC/HKD`, 0) as `HKC/HKD`
    from do.nop_client_symbol_matrix_pivot_view
    group by clientFirm
    order by symbol
);


create view nop_client_final_view as (
	select * from final_view
);
drop view do.nop_client_symbol_matrix_temp;
drop view do.nop_client_symbol_matrix_view;
drop view do.nop_client_symbol_matrix_pivot_view;




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