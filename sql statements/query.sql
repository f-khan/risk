SELECT ccy,sum(qty) FROM statements.open_positions where clientfirm='VIRT1001' and busdate='2017-02-17' group by ccy;

select tradestamp from open_positions limit 5;

SELECT 
MID(tradestamp,1,10) as 'Date', 
MID(tradestamp,12,5) as 'Time', 
MID(CCY,1,3) AS 'Symbol', 
MID(CCY,5,3) AS 'rCCY', 
qty*marketRate as 'Amount', (select if(CCY=concat(rCCY,'/USD')=symbol from symbols,1,0))
FROM statements.open_positions 
WHERE clientFirm='VIRT1001'
limit 10;


-- Easwaran's query
SELECT 
tradestamp,
left(ccy,3) as symbol, 
side,
sum(qty) as volume, 
right(ccy,3) as rCcy, 
sum(qty)*marketRate as amount, 
(select ifnull((select ifnull((select ((bid+ask)/2) from symbols where symbol=concat(rCcy,'/USD')),(select 1/((bid+ask)/2) from symbols where symbol=concat('USD/',rCcy)))),1)) as ConvRate,
sum(qty)*marketrate*(select ifnull((select ifnull((select ((bid+ask)/2) from symbols where symbol=concat(rCcy,'/USD')),(select 1/((bid+ask)/2) from symbols where symbol=concat('USD/',rCcy)))),1)) as USDAmount 
FROM statements.open_positions op where clientfirm='VIRT1001' and busdate='2017-02-22' group by symbol; 

CALL GetValues();

select
s.symbol as Symbol,
s.lotSize as LotSize,
op.side as Side,
op.qty as Quantity
from symbols s, open_positions op
where s.symbol = op.ccy AND (s.symbol = 'BCO/USD' OR s.symbol = 'CRC/USD');

select
s.symbol as Symbol,
s.lotSize as LotSize,
op.side as Side,
op.qty as Quantity
from symbols s INNER JOIN open_positions op
on s.symbol = op.ccy AND (s.symbol = 'BCO/USD' OR s.symbol = 'CRC/USD');

sum(qty)*marketrate*(
select ifnull
(
	(select if
	(
		(select bid from symbols where symbol=concat(rCcy,'/USD'))
        else
			(select (bid+ask)/2 from symbols where symbol=concat(rCcy,'/USD'))
	)
    else    
		(select 1/((bid+ask)/2) from symbols where symbol=concat('USD/',rCcy)))),1))*s.lotSize as USDAmount
);
# Old query
SELECT 
busdate,
ccy as symbol, 
side,
sum(qty) as volume, 
right(ccy,3) as rCcy, 
sum(qty)*marketRate as amount, 
(select ifnull((select ifnull((select ((bid+ask)/2) from symbols where symbol=concat(rCcy,'/USD')),(select 1/((bid+ask)/2) from symbols where symbol=concat('USD/',rCcy)))),1)) as ConvRate,
sum(qty)*marketrate*(select ifnull((select if((select bid from symbols where symbol=concat(rCcy,'/USD')),(select (bid+ask)/2 from symbols where symbol=concat(rCcy,'/USD')),(select 1/((bid+ask)/2) from symbols where symbol=concat('USD/',rCcy)))),1)) as USDAmount
FROM statements.open_positions op, symbols s where clientfirm='VIRT1001' and busdate=(select max(busdate) from statements.open_positions where clientfirm='VIRT1001') and op.ccy=s.symbol group by symbol; 

# OLD Query
SELECT 
busdate,
ccy as symbol, 
side,
sum(qty) as volume, 
right(ccy,3) as rCcy, 
sum(qty)*marketRate as amount,(select ifnull((select ifnull((select ((bid+ask)/2) from symbols where symbol=concat(rCcy,'/USD')),(select 1/((bid+ask)/2) from symbols where symbol=concat('USD/',rCcy)))),1)) as ConvRate,
sum(qty)*marketrate*(select ifnull((select if((select bid from symbols where symbol=concat(rCcy,'/USD')),(select (bid+ask)/2 from symbols where symbol=concat(rCcy,'/USD')),(select 1/((bid+ask)/2) from symbols where symbol=concat('USD/',rCcy)))),1))*s.lotSize as USDAmount
FROM statements.open_positions op, symbols s where clientfirm='VIRT1001' and busdate=(select max(busdate) from statements.open_positions where clientfirm='VIRT1001') and op.ccy=s.symbol group by symbol; 

select sum(qty) as volume from do.open_positions where clientfirm = 'VIRT1001';

# old Query
SELECT 
				busdate,
				ccy as symbol, 
				side,
				marketrate,
				s.lotSize,
				sum(qty) as volume, 
				right(ccy,3) as rCcy, 
				sum(qty)*marketRate*s.lotSize as amount, 
				(select ifnull((select ifnull((select ((bid+ask)/2) from symbols where symbol=concat(rCcy,'/USD')),(select 1/((bid+ask)/2) from symbols where symbol=concat('USD/',rCcy)))),1)) as ConvRate,
				sum(qty)*marketrate*(select ifnull((select if((select bid from symbols where symbol=concat(rCcy,'/USD')),(select (bid+ask)/2 from symbols where symbol=concat(rCcy,'/USD')),(select 1/((bid+ask)/2) from symbols where symbol=concat('USD/',rCcy)))),1))*s.lotSize as USDAmount,
				s.lotSize
				FROM statements.open_positions op, symbols s where clientfirm='VIRT1001' and busdate=(select max(busdate) from statements.open_positions where clientfirm='VIRT1001') and op.ccy=s.symbol group by symbol;

select sum(do.firm_positions.position) from do.firm_positions where do.firm_positions.symbol = 'GEC/EUR';

# Putting a JOIN for static values of 4 products
select SUM(fp.position) + fpsd.position
FROM do.firm_positions as fp INNER JOIN do.firm_positions_seed_data as fpsd
ON fp.symbol = fpsd.symbol AND fp.symbol = 'GEC/EUR';

SELECT SUM(t.position) AS position
FROM (SELECT position FROM do.firm_positions where symbol='HKC/HKD'
UNION ALL
SELECT position FROM do.firm_positions_seed_data where symbol='HKC/HKD') t;

SELECT t.a, t.symbol,null,null,null,null,null,null,null,null,null
FROM (select null as a,symbol from do.firm_positions group by symbol
UNION ALL
select null as a,ccy from statements.open_positions where clientFirm = 'VIRT1001' and busdate = '2017-02-22' group by ccy) t
group by t.symbol;

SELECT timeStamp as timeNow FROM do.firm_positions limit 1;


#Test OP union Symbols
select t1.busdate,t1.symbol,t1.side,t1.marketrate,t1.lotSize,sum(t1.volume),t1.rCcy,t1.amount,t1.ConvRate,t1.USDAmount
from
(
	SELECT 
	busdate,
	ccy as symbol, 
	side,
	marketrate,
	s.lotSize,
	sum(qty) as volume, 
	right(ccy,3) as rCcy, 
	sum(qty)*marketRate*s.lotSize as amount, 
	(
		select ifnull((select ifnull((select ((bid+ask)/2) from symbols where symbol=concat(rCcy,'/USD')),(select 1/((bid+ask)/2) from symbols where symbol=concat('USD/',rCcy)))),1)) as ConvRate,
		sum(qty)*marketrate*(select ifnull((select if((select bid from symbols where symbol=concat(rCcy,'/USD')),(select (bid+ask)/2 from symbols where symbol=concat(rCcy,'/USD')),(select 1/((bid+ask)/2) from symbols where symbol=concat('USD/',rCcy)))),1))*s.lotSize as USDAmount
		FROM statements.open_positions op, symbols s where clientfirm='VIRT1001' and busdate=(select max(busdate) from statements.open_positions where clientfirm='VIRT1001') and op.ccy=s.symbol group by symbol
		UNION ALL
		SELECT t.a, t.symbol,null,null,null,null,null,null,null,null
		FROM (select null as a,symbol from do.firm_positions group by symbol
		UNION ALL
		select null as a,ccy from statements.open_positions where clientFirm = 'VIRT1001' and busdate = (select max(busdate) from statements.open_positions where clientfirm='VIRT1001') group by ccy
        ) t
		group by t.symbol
) t1
group by t1.symbol
;


# Alternative query
select 
t1.busdate,
t1.symbol,
t1.side,
t1.marketrate,
t1.lotSize,
sum(t1.volume),
t1.rCcy,
sum(t1.amount),
t1.ConvRate,
sum(t1.USDAmount)
from
(
				SELECT 
				busdate,
				ccy as symbol, 
				side,
				marketrate,
				s.lotSize,
				qty as volume, 
				right(ccy,3) as rCcy, 
				qty*marketRate*s.lotSize as amount, 
				(select ifnull((select ifnull((select ((bid+ask)/2) from symbols where symbol=concat(rCcy,'/USD')),(select 1/((bid+ask)/2) from symbols where symbol=concat('USD/',rCcy)))),1)) as ConvRate,
				qty*marketrate*(select ifnull((select if((select bid from symbols where symbol=concat(rCcy,'/USD')),(select (bid+ask)/2 from symbols where symbol=concat(rCcy,'/USD')),(select 1/((bid+ask)/2) from symbols where symbol=concat('USD/',rCcy)))),1))*s.lotSize as USDAmount
				FROM statements.open_positions op, symbols s where clientfirm='VIRT1001' and busdate=(select max(busdate) from statements.open_positions where clientfirm='VIRT1001') and op.ccy=s.symbol 
                UNION ALL
                SELECT t.a, t.symbol,null,null,null,null,right(t.symbol,3),null,null,null
				FROM 
                (
					select null as a,symbol from do.firm_positions group by symbol
					UNION ALL
					select null as a,ccy from statements.open_positions where clientFirm = 'VIRT1001' and busdate = (select max(busdate) from statements.open_positions where clientfirm='VIRT1001') group by ccy
				) t
) t1
group by t1.symbol
;                








# old query
select 
t1.busdate,
t1.symbol,
t1.side,
t1.marketrate,
sum(t1.volume),
t1.rCcy,
t1.amount,
t1.ConvRate,
t1.USDAmount,
t1.lotSize
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
(select ifnull((select ifnull((select ((bid+ask)/2) from symbols where symbol=concat(rCcy,'/USD')),(select 1/((bid+ask)/2) from symbols where symbol=concat('USD/',rCcy)))),1)) as ConvRate,
qty*marketrate*(select ifnull((select if((select bid from symbols where symbol=concat(rCcy,'/USD')),(select (bid+ask)/2 from symbols where symbol=concat(rCcy,'/USD')),(select 1/((bid+ask)/2) from symbols where symbol=concat('USD/',rCcy)))),1))*s.lotSize as USDAmount,
s.lotSize
FROM statements.open_positions op, symbols s where clientfirm='VIRT1001' and busdate=(select max(busdate) from statements.open_positions where clientfirm='VIRT1001') and op.ccy=s.symbol 
UNION ALL
SELECT 
t.a as busdate, 
t.symbol,
null as side,
t.marketRate,
null,
right(t.symbol,3),
null,
(select ifnull((select ifnull((select ((bid+ask)/2) from symbols where symbol=concat(right(t.symbol,3),'/USD')),(select 1/((bid+ask)/2) from symbols where symbol=concat('USD/',right(t.symbol,3))))),1)) as ConvRate,
null,
s.lotsize
FROM 
(
select null as a,symbol,null as side, marketRate from do.firm_positions group by symbol
UNION ALL
select null as a,ccy, null as side, null as marketRate from statements.open_positions where clientFirm = 'VIRT1001' and busdate = (select max(busdate) from statements.open_positions where clientfirm='VIRT1001') group by ccy
) t, symbols s where t.symbol=s.symbol
) t1
group by t1.symbol
;

# Current query
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
	(select ifnull((select ifnull((select ((bid+ask)/2) from symbols where symbol=concat(rCcy,'/USD')),(select 1/((bid+ask)/2) from symbols where symbol=concat('USD/',rCcy)))),1)) as ConvRate,
	qty*marketrate*(select ifnull((select if((select bid from symbols where symbol=concat(rCcy,'/USD')),(select (bid+ask)/2 from symbols where symbol=concat(rCcy,'/USD')),(select 1/((bid+ask)/2) from symbols where symbol=concat('USD/',rCcy)))),1))*s.lotSize as USDAmount,
	s.lotSize
	FROM statements.open_positions op, symbols s where clientfirm='VIRT1001' and busdate=(select max(busdate) from statements.open_positions where clientfirm='VIRT1001') and op.ccy=s.symbol 
	UNION ALL
	SELECT 
	t.a as busdate, 
	t.symbol,
	null as side,
	t.marketRate,
	null,
	right(t.symbol,3),
	null,
	(select ifnull((select ifnull((select ((bid+ask)/2) from symbols where symbol=concat(right(t.symbol,3),'/USD')),(select 1/((bid+ask)/2) from symbols where symbol=concat('USD/',right(t.symbol,3))))),1)) as ConvRate,
	null,
	s.lotsize
	FROM 
	(
	select null as a,symbol,null as side, marketRate from do.firm_positions group by symbol
	UNION ALL
	select null as a,ccy, null as side, null as marketRate from statements.open_positions where clientFirm = 'VIRT1001' and busdate = (select max(busdate) from statements.open_positions where clientfirm='VIRT1001') group by ccy
	) t, symbols s where t.symbol=s.symbol
	) t1
group by t1.symbol
;

sum(qty)*marketrate*(
select ifnull
(
	(select if
	(
		(select bid from symbols where symbol=concat(rCcy,'/USD'))
        else
			(select (bid+ask)/2 from symbols where symbol=concat(rCcy,'/USD'))
	)
    else    
		(select 1/((bid+ask)/2) from symbols where symbol=concat('USD/',rCcy)))),1))*s.lotSize as USDAmount
);



# Current query
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
                
#old query                 
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
	(select ifnull
    (
		(select ifnull
        (
			(select ((bid+ask)/2) from symbols where symbol=concat(rCcy,'/USD')),(select 1/((bid+ask)/2) from symbols where symbol=concat('USD/',rCcy)))
		),1)
	) as ConvRate,
	qty*marketrate*(select ifnull
    (
		(select if
        (
			(select bid from symbols where symbol=concat(rCcy,'/USD')),(select (bid+ask)/2 from symbols where symbol=concat(rCcy,'/USD')),(select 1/((bid+ask)/2) from symbols where symbol=concat('USD/',rCcy)))
		),1)
	)*s.lotSize as USDAmount,
	s.lotSize
	FROM statements.open_positions op, symbols s where clientfirm='VIRT1001' and busdate=(select max(busdate) from statements.open_positions where clientfirm='VIRT1001') and op.ccy=s.symbol 
	
    UNION ALL
	
    SELECT 
	t.a as busdate, 
	t.symbol,
	null as side,
	t.marketRate,
	null,
	right(t.symbol,3),
	null,
	(select ifnull((select ifnull((select ((bid+ask)/2) from symbols where symbol=concat(right(t.symbol,3),'/USD')),(select 1/((bid+ask)/2) from symbols where symbol=concat('USD/',right(t.symbol,3))))),1)) as ConvRate,
	null,
	s.lotsize
	FROM 
	(
	select null as a,symbol,null as side, marketRate from do.firm_positions group by symbol
	UNION ALL
	select null as a,ccy, null as side, null as marketRate from statements.open_positions where clientFirm = 'VIRT1001' and busdate = (select max(busdate) from statements.open_positions where clientfirm='VIRT1001') group by ccy
	) t, symbols s where t.symbol=s.symbol
	) t1
group by t1.symbol
;
