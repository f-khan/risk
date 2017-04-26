-- Jon's query
select clientFirm, ccy, sum(amt) amt, null USDRate, null USDAmount
from 
( 
	select p.clientFirm, p.symbol, s.baseCcy ccy, p.position amt, s.symbolType
	from firm_positions p, statements.symbols s
	where 1=1
	and p.clientFirm = 'FXTCR001'
	-- and p.busDate = '2017-02-02'
	and p.symbol = s.symbol
	union all
	select p.clientFirm, p.symbol, s.riskCcy ccy, -round(p.position * p.marketrate, 0) amt, s.symbolType
	from firm_positions p, statements.symbols s
	where 1=1
	and p.clientFirm = 'FXTCR001'
	-- and p.busDate = '2017-02-02'
	and p.symbol = s.symbol
) x
where amt <= 0
group by clientFirm, ccy
order by clientFirm, ccy;




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
order by utilisation desc, clientGroup , clientGroup;
#order by USD_Overall_NOP desc, clientGroup;




# New Query Main Page WITH MarginRequired column
select LastUpdated, clientGroup, (sum(USD_fx_NOP)+sum(USD_cfd_NOP)+sum(USD_metal_NOP)) as USD_Overall_NOP, clientLimit, round(((sum(USD_fx_NOP)+sum(USD_cfd_NOP)+sum(USD_metal_NOP))/clientLimit)*100,2) as utilisation, sum(marginRequired) as marginRequired
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
    abs(round((IFNULL((SELECT(IFNULL((select ((bid+ask)/2) as rate from statements.symbols where symbol =concat(Ccy,'/USD')),(select 1/((bid+ask)/2) as rate from statements.symbols where symbol =concat('USD/',Ccy))))),1) * sum(if(symbolType = 'metal',amt,0))),0)) as USD_metal_NOP,
    sum(marginRequired) as marginRequired
                from 
                ( 
                                # Left FX
                                select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, c.clientLimit, p.symbol, s.baseCcy ccy, p.position, 0 as marketRate, p.position amt, s.symbolType, p.marginRequired
                                from do.firm_positions p, statements.symbols s, do.nop_clients c
                                where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND (s.symbolType = 'FX' and p.symbol not like 'X%')
                                union all
                                # Right FX
                                select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, c.clientLimit, p.symbol, s.riskCcy ccy, p.position, p.marketRate, -round(p.position * p.marketrate, 0) amt, s.symbolType, p.marginRequired
                                from do.firm_positions p, statements.symbols s, do.nop_clients c
                                where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND (s.symbolType = 'FX' and p.symbol not like 'X%')
                                union all
                                # CFD
                                select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, c.clientLimit, p.symbol, s.riskCcy ccy, p.position, p.marketRate, p.position*s.lotsize*((s.bid+s.ask)/2) as amt, s.symbolType, p.marginRequired
                                from do.firm_positions p, statements.symbols s, do.nop_clients c
                                where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND (s.symbolType = 'CFD')
        union all
        # Left Metal
                                select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, c.clientLimit, p.symbol, s.baseCcy ccy, p.position, p.marketRate, (p.position*s.lotsize) as amt, 'metal' as symbolType, p.marginRequired
                                from do.firm_positions p, statements.symbols s, do.nop_clients c
                                where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND p.symbol like 'X%'
                ) x
                group by clientGroup, ccy
                order by clientGroup, ccy
) x1
group by clientGroup
order by clientGroup;





set @clientFirm = 'VANTAGE';
# NOP Client Breakdown Query ONE
select LastUpdated, clientGroup, clientFirm, displayCcy, amt, amt*USDRate as USDEquiv, USDRate,USD_fx_NOP,USD_cfd_NOP,USD_metal_NOP, sum(USD_fx_NOP+USD_cfd_NOP+USD_metal_NOP)  as USD_NOP_sum
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
        where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND (s.symbolType = 'FX' and p.symbol not like 'X%') AND c.clientGroup = @clientFirm
        union all
        # Right FX
        select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, p.symbol, s.riskCcy displayCcy, s.riskCcy ccy, p.position, p.marketRate, -round(p.position * p.marketrate, 0) amt, s.symbolType
        from do.firm_positions p, statements.symbols s, do.nop_clients c
        where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND (s.symbolType = 'FX' and p.symbol not like 'X%') AND c.clientGroup = @clientFirm
        union all
        # CFD
        select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, p.symbol, left(s.symbol,3) displayCcy, s.riskCcy ccy, p.position, p.marketRate, p.position*s.lotsize*((s.bid+s.ask)/2) as amt, s.symbolType
        from do.firm_positions p, statements.symbols s, do.nop_clients c
        where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND (s.symbolType = 'CFD') AND c.clientGroup = @clientFirm
        union all
        # Left Metal
        select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, p.symbol, s.baseCcy displayCcy, s.baseCcy ccy, p.position, p.marketRate, (p.position*s.lotsize) as amt, 'metal' as symbolType
        from do.firm_positions p, statements.symbols s, do.nop_clients c
        where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND p.symbol like 'X%' AND c.clientGroup = @clientFirm
                ) x
    group by clientGroup, displayCcy
    order by clientGroup, displayCcy
) x1
group by clientGroup, displayCcy
order by clientGroup, displayCcy;



set @clientGroup = 'VANTAGE';
set @clientFirm = 'MXT';
# NOP Client Breakdown Query ONE WITH CLIENT FIRM
select LastUpdated, clientGroup, clientFirm, displayCcy, amt, amt*USDRate as USDEquiv, USDRate,USD_fx_NOP,USD_cfd_NOP,USD_metal_NOP, sum(USD_fx_NOP+USD_cfd_NOP+USD_metal_NOP)  as USD_NOP_sum
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
        where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND (s.symbolType = 'FX' and p.symbol not like 'X%') AND c.clientGroup = @clientGroup
        union all
        # Right FX
        select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, p.symbol, s.riskCcy displayCcy, s.riskCcy ccy, p.position, p.marketRate, -round(p.position * p.marketrate, 0) amt, s.symbolType
        from do.firm_positions p, statements.symbols s, do.nop_clients c
        where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND (s.symbolType = 'FX' and p.symbol not like 'X%') AND c.clientGroup = @clientGroup
        union all
        # CFD
        select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, p.symbol, left(s.symbol,3) displayCcy, s.riskCcy ccy, p.position, p.marketRate, p.position*s.lotsize*((s.bid+s.ask)/2) as amt, s.symbolType
        from do.firm_positions p, statements.symbols s, do.nop_clients c
        where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND (s.symbolType = 'CFD') AND c.clientGroup = @clientGroup
        union all
        # Left Metal
        select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, p.symbol, s.baseCcy displayCcy, s.baseCcy ccy, p.position, p.marketRate, (p.position*s.lotsize) as amt, 'metal' as symbolType
        from do.firm_positions p, statements.symbols s, do.nop_clients c
        where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND p.symbol like 'X%' AND c.clientGroup = @clientGroup
                ) x
	where clientFirm = @clientFirm
    group by clientGroup, displayCcy
    order by clientGroup, displayCcy
) x1
group by clientGroup, displayCcy
order by clientGroup, displayCcy;





set @clientFirm = 'VANTAGE';
# NOP Client Breakdown Query TWO
select clientGroup, p.clientFirm, p.symbol, sum(position) as position, (bid+ask)/2 as EODRate, symbolType,
(IFNULL((SELECT(IFNULL((select ((bid+ask)/2) as rate from statements.symbols where symbol =concat(s.baseCcy,'/USD')),(select 1/((bid+ask)/2) as rate from statements.symbols where symbol =concat('USD/',s.baseCcy))))),1)) as USDRate,

CASE
WHEN symbolType = 'FX' AND p.symbol NOT LIKE 'X%' 	THEN -(sum(position*((bid+ask)/2)*lotSize))
WHEN symbolType = 'CFD' 							THEN sum(position*((bid+ask)/2)*lotSize)
WHEN p.symbol LIKE 'X%' AND symbolType = 'FX' 		THEN sum(position*((bid+ask)/2)*lotSize)
END 
as amt,

CASE
WHEN symbolType = 'FX' OR p.symbol LIKE 'X%' 	THEN abs(sum(position)) * (IFNULL((SELECT(IFNULL((select ((bid+ask)/2) as rate from statements.symbols where symbol =concat(s.baseCcy,'/USD')),(select 1/((bid+ask)/2) as rate from statements.symbols where symbol =concat('USD/',s.baseCcy))))),1))
WHEN symbolType = 'CFD' 						THEN abs(sum(position) * ((bid+ask)/2)* lotSize) * (IFNULL((SELECT(IFNULL((select ((bid+ask)/2) as rate from statements.symbols where symbol =concat(s.riskCcy,'/USD')),(select 1/((bid+ask)/2) as rate from statements.symbols where symbol =concat('USD/',s.riskCcy))))),1))
END 
as usd_amt

from do.firm_positions p, do.nop_clients c, statements.symbols s
where p.clientFirm = c.clientFirm AND p.symbol = s.symbol AND clientGroup = @clientFirm AND position <> 0 
GROUP BY p.symbol
ORDER BY symbol;

set @clientGroup = 'VANTAGE';
set @clientFirm = 'MXT51002';
# NOP Client Breakdown Query TWO with CLIENT FIRM
select clientGroup, p.clientFirm, p.symbol, sum(position) as position, (bid+ask)/2 as EODRate, symbolType,
(IFNULL((SELECT(IFNULL((select ((bid+ask)/2) as rate from statements.symbols where symbol =concat(s.baseCcy,'/USD')),(select 1/((bid+ask)/2) as rate from statements.symbols where symbol =concat('USD/',s.baseCcy))))),1)) as USDRate,

CASE
WHEN symbolType = 'FX' AND p.symbol NOT LIKE 'X%' 	THEN -(sum(position*((bid+ask)/2)*lotSize))
WHEN symbolType = 'CFD' 							THEN sum(position*((bid+ask)/2)*lotSize)
WHEN p.symbol LIKE 'X%' AND symbolType = 'FX' 		THEN sum(position*((bid+ask)/2)*lotSize)
END 
as amt,

CASE
WHEN symbolType = 'FX' OR p.symbol LIKE 'X%' 	THEN abs(sum(position)) * (IFNULL((SELECT(IFNULL((select ((bid+ask)/2) as rate from statements.symbols where symbol =concat(s.baseCcy,'/USD')),(select 1/((bid+ask)/2) as rate from statements.symbols where symbol =concat('USD/',s.baseCcy))))),1))
WHEN symbolType = 'CFD' 						THEN abs(sum(position) * ((bid+ask)/2)* lotSize) * (IFNULL((SELECT(IFNULL((select ((bid+ask)/2) as rate from statements.symbols where symbol =concat(s.riskCcy,'/USD')),(select 1/((bid+ask)/2) as rate from statements.symbols where symbol =concat('USD/',s.riskCcy))))),1))
END 
as usd_amt

from do.firm_positions p, do.nop_clients c, statements.symbols s
where p.clientFirm = c.clientFirm AND p.symbol = s.symbol AND clientGroup = @clientGroup AND position <> 0 AND p.clientFirm = @clientFirm
GROUP BY p.symbol
ORDER BY symbol;