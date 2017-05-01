# ----------------------------------------------------------------------
#
# -------------------------	INVAST NOP Query ---------------------------
#
# ----------------------------------------------------------------------
select LastUpdated, displayCcy, amt, amt*USDRate as USDEquiv, USDRate,USD_fx_NOP,USD_cfd_NOP,USD_metal_NOP, sum(USD_fx_NOP+USD_cfd_NOP+USD_metal_NOP)  as USD_NOP_sum
from
(
	select LastUpdated, displayCcy, ccy,
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
        where p.symbol = s.symbol AND (s.symbolType = 'FX' and p.symbol not like 'X%')
        union all
	# Right FX
        select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, p.symbol, s.riskCcy displayCcy, s.riskCcy ccy, p.position, p.marketRate, -round(p.position * p.marketrate, 0) amt, s.symbolType
        from do.firm_positions p, statements.symbols s, do.nop_clients c
        where p.symbol = s.symbol AND (s.symbolType = 'FX' and p.symbol not like 'X%')
        union all
	# CFD
        select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, p.symbol, left(s.symbol,3) displayCcy, s.riskCcy ccy, p.position, p.marketRate, p.position*s.lotsize*((s.bid+s.ask)/2) as amt, s.symbolType
        from do.firm_positions p, statements.symbols s, do.nop_clients c
        where p.symbol = s.symbol AND (s.symbolType = 'CFD')
        union all
	# Left Metal
        select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, p.symbol, s.baseCcy displayCcy, s.baseCcy ccy, p.position, p.marketRate, (p.position*s.lotsize) as amt, 'metal' as symbolType
        from do.firm_positions p, statements.symbols s, do.nop_clients c
        where p.symbol = s.symbol AND p.symbol like 'X%'
	) x
    group by displayCcy
    order by displayCcy
) x1
group by displayCcy
order by displayCcy;