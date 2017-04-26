set @clientFirm = 'VANTAGE';
# NOP TIER FINAL CLIENT GROUP do/noptiers.php
select lastupdated, clientGroup, displayCcy, sum(tier1) as tier1, sum(tier2) as tier2, sum(tier3) as tier3, sum(tier4) as tier4, sum(tier5) as tier5
from
(
	select LastUpdated, clientGroup, clientFirm, displayCcy, sum(USD_fx_NOP+USD_cfd_NOP+USD_metal_NOP)  as USD_NOP_sum, tier, amt,
	if(tier=1,sum(USD_fx_NOP+USD_cfd_NOP+USD_metal_NOP),0) as tier1,
	if(tier=2,sum(USD_fx_NOP+USD_cfd_NOP+USD_metal_NOP),0) as tier2,
	if(tier=3,sum(USD_fx_NOP+USD_cfd_NOP+USD_metal_NOP),0) as tier3,
	if(tier=4,sum(USD_fx_NOP+USD_cfd_NOP+USD_metal_NOP),0) as tier4,
	if(tier=5,sum(USD_fx_NOP+USD_cfd_NOP+USD_metal_NOP),0) as tier5
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
			where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND (s.symbolType = 'FX' and p.symbol not like 'X%') AND c.clientGroup = @clientFirm and s.baseccy=bt.ccy and p.clientFirm=bt.clientFirm and s.riskccy=rt.ccy and p.clientfirm=rt.clientfirm and p.position <> 0
			union all
			# Right FX
			select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, p.symbol, s.riskCcy displayCcy, s.riskCcy ccy, p.position, p.marketRate, -round(p.position * p.marketrate, 0) amt, s.symbolType, bt.tier as baseCcyTier, rt.tier as riskCcyTier, if(bt.tier>rt.tier,bt.tier,rt.tier) as tier
			from do.firm_positions p, statements.symbols s, do.nop_clients c, do.nop_ccytier bt, do.nop_ccytier rt
			where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND (s.symbolType = 'FX' and p.symbol not like 'X%') AND c.clientGroup = @clientFirm and s.baseccy=bt.ccy and p.clientFirm=bt.clientFirm and s.riskccy=rt.ccy and p.clientfirm=rt.clientfirm and p.position <> 0
			union all
			# CFD
			select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, p.symbol, left(s.symbol,3) displayCcy, s.riskCcy ccy, p.position, p.marketRate, p.position*s.lotsize*((s.bid+s.ask)/2) as amt, s.symbolType, bt.tier as baseCcyTier, rt.tier as riskCcyTier, 5 as tier
			from do.firm_positions p, statements.symbols s, do.nop_clients c, do.nop_ccytier bt, do.nop_ccytier rt
			where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND (s.symbolType = 'CFD') AND c.clientGroup = @clientFirm and s.baseccy=bt.ccy and p.clientFirm=bt.clientFirm and s.riskccy=rt.ccy and p.clientfirm=rt.clientfirm and p.position <> 0
			union all
			# Left Metal
			select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, p.symbol, s.baseCcy displayCcy, s.baseCcy ccy, p.position, p.marketRate, (p.position*s.lotsize) as amt, 'metal' as symbolType, bt.tier as baseCcyTier, rt.tier as riskCcyTier, if(bt.tier>rt.tier,bt.tier,rt.tier) as tier
			from do.firm_positions p, statements.symbols s, do.nop_clients c, do.nop_ccytier bt, do.nop_ccytier rt
			where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND p.symbol like 'X%' AND c.clientGroup = @clientFirm and s.baseccy=bt.ccy and p.clientFirm=bt.clientFirm and s.riskccy=rt.ccy and p.clientfirm=rt.clientfirm and p.position <> 0
		) x
		group by clientGroup, displayCcy, tier
		order by clientGroup, displayCcy
	) x1 
	group by clientGroup, displayCcy,tier
	order by clientGroup, displayCcy
)x2
group by displayCcy;

-- --------------------------------------------------------------

set @clientGroup = 'VANTAGE';
set @clientFirm = 'MXT51001';
# NOP TIER CLIENT FIRM do/noptiers.php
select lastupdated, clientGroup, clientFirm, displayCcy, sum(tier1) as tier1, sum(tier2) as tier2, sum(tier3) as tier3, sum(tier4) as tier4, sum(tier5) as tier5
from
(
	select LastUpdated, clientGroup, clientFirm, displayCcy, sum(USD_fx_NOP+USD_cfd_NOP+USD_metal_NOP)  as USD_NOP_sum, tier, amt,
	if(tier=1,sum(USD_fx_NOP+USD_cfd_NOP+USD_metal_NOP),0) as tier1,
	if(tier=2,sum(USD_fx_NOP+USD_cfd_NOP+USD_metal_NOP),0) as tier2,
	if(tier=3,sum(USD_fx_NOP+USD_cfd_NOP+USD_metal_NOP),0) as tier3,
	if(tier=4,sum(USD_fx_NOP+USD_cfd_NOP+USD_metal_NOP),0) as tier4,
	if(tier=5,sum(USD_fx_NOP+USD_cfd_NOP+USD_metal_NOP),0) as tier5
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
			where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND (s.symbolType = 'FX' and p.symbol not like 'X%') AND c.clientGroup = @clientGroup and s.baseccy=bt.ccy and p.clientFirm=bt.clientFirm and s.riskccy=rt.ccy and p.clientfirm=rt.clientfirm and p.position <> 0
			union all
			# Right FX
			select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, p.symbol, s.riskCcy displayCcy, s.riskCcy ccy, p.position, p.marketRate, -round(p.position * p.marketrate, 0) amt, s.symbolType, bt.tier as baseCcyTier, rt.tier as riskCcyTier, if(bt.tier>rt.tier,bt.tier,rt.tier) as tier
			from do.firm_positions p, statements.symbols s, do.nop_clients c, do.nop_ccytier bt, do.nop_ccytier rt
			where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND (s.symbolType = 'FX' and p.symbol not like 'X%') AND c.clientGroup = @clientGroup and s.baseccy=bt.ccy and p.clientFirm=bt.clientFirm and s.riskccy=rt.ccy and p.clientfirm=rt.clientfirm and p.position <> 0
			union all
			# CFD
			select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, p.symbol, left(s.symbol,3) displayCcy, s.riskCcy ccy, p.position, p.marketRate, p.position*s.lotsize*((s.bid+s.ask)/2) as amt, s.symbolType, bt.tier as baseCcyTier, rt.tier as riskCcyTier, 5 as tier
			from do.firm_positions p, statements.symbols s, do.nop_clients c, do.nop_ccytier bt, do.nop_ccytier rt
			where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND (s.symbolType = 'CFD') AND c.clientGroup = @clientGroup and s.baseccy=bt.ccy and p.clientFirm=bt.clientFirm and s.riskccy=rt.ccy and p.clientfirm=rt.clientfirm and p.position <> 0
			union all
			# Left Metal
			select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, p.symbol, s.baseCcy displayCcy, s.baseCcy ccy, p.position, p.marketRate, (p.position*s.lotsize) as amt, 'metal' as symbolType, bt.tier as baseCcyTier, rt.tier as riskCcyTier, if(bt.tier>rt.tier,bt.tier,rt.tier) as tier
			from do.firm_positions p, statements.symbols s, do.nop_clients c, do.nop_ccytier bt, do.nop_ccytier rt
			where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND p.symbol like 'X%' AND c.clientGroup = @clientGroup and s.baseccy=bt.ccy and p.clientFirm=bt.clientFirm and s.riskccy=rt.ccy and p.clientfirm=rt.clientfirm and p.position <> 0
		) x
        where clientFirm = @clientFirm
		group by clientGroup, displayCcy, tier
		order by clientGroup, displayCcy
	) x1 
	group by clientGroup, displayCcy,tier
	order by clientGroup, displayCcy
)x2
group by displayCcy;

-- --------------------------------------------------------------
-- Tier with Base Exposures
set @clientFirm = 'GOLDLAND';
# NOP TIER FINAL CLIENT GROUP do/noptiers.php
-- Tier with Base Exposures
select lastupdated, clientGroup, displayCcy,  sum(tier1Exposure) as tier1BaseExposure,sum(tier1) as tier1NOP, sum(tier2Exposure) as tier2BaseExposure, sum(tier2) as tier2NOP, sum(tier3Exposure) as tier3BaseExposure, sum(tier3) as tier3NOP, sum(tier4Exposure) as tier4BaseExposure, sum(tier4) as tier4NOP, sum(tier5Exposure) as tier5BaseExposure, sum(tier5) as tier5NOP
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
			where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND (s.symbolType = 'FX' and p.symbol not like 'X%') AND c.clientGroup = @clientFirm and s.baseccy=bt.ccy and p.clientFirm=bt.clientFirm and s.riskccy=rt.ccy and p.clientfirm=rt.clientfirm and p.position <> 0
			union all
			# Right FX
			select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, p.symbol, s.riskCcy displayCcy, s.riskCcy ccy, p.position, p.marketRate, -round(p.position * p.marketrate, 0) amt, s.symbolType, bt.tier as baseCcyTier, rt.tier as riskCcyTier, if(bt.tier>rt.tier,bt.tier,rt.tier) as tier
			from do.firm_positions p, statements.symbols s, do.nop_clients c, do.nop_ccytier bt, do.nop_ccytier rt
			where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND (s.symbolType = 'FX' and p.symbol not like 'X%') AND c.clientGroup = @clientFirm and s.baseccy=bt.ccy and p.clientFirm=bt.clientFirm and s.riskccy=rt.ccy and p.clientfirm=rt.clientfirm and p.position <> 0
			union all
			# CFD
			select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, p.symbol, left(s.symbol,3) displayCcy, s.riskCcy ccy, p.position, p.marketRate, p.position*s.lotsize*((s.bid+s.ask)/2) as amt, s.symbolType, bt.tier as baseCcyTier, rt.tier as riskCcyTier, 5 as tier
			from do.firm_positions p, statements.symbols s, do.nop_clients c, do.nop_ccytier bt, do.nop_ccytier rt
			where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND (s.symbolType = 'CFD') AND c.clientGroup = @clientFirm and s.baseccy=bt.ccy and p.clientFirm=bt.clientFirm and s.riskccy=rt.ccy and p.clientfirm=rt.clientfirm and p.position <> 0
			union all
			# Left Metal
			select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, p.symbol, s.baseCcy displayCcy, s.baseCcy ccy, p.position, p.marketRate, (p.position*s.lotsize) as amt, 'metal' as symbolType, bt.tier as baseCcyTier, rt.tier as riskCcyTier, if(bt.tier>rt.tier,bt.tier,rt.tier) as tier
			from do.firm_positions p, statements.symbols s, do.nop_clients c, do.nop_ccytier bt, do.nop_ccytier rt
			where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND p.symbol like 'X%' AND c.clientGroup = @clientFirm and s.baseccy=bt.ccy and p.clientFirm=bt.clientFirm and s.riskccy=rt.ccy and p.clientfirm=rt.clientfirm and p.position <> 0
		) x
		group by clientGroup, displayCcy, tier
		order by clientGroup, displayCcy
	) x1 
	group by clientGroup, displayCcy,tier
	order by clientGroup, displayCcy
)x2
group by displayCcy;

-- ------------------------------------------------------------------------------------------------
-- Tier with Base Exposures
set @clientGroup = 'VANTAGE';
set @clientFirm = 'MXT';
-- Tier with Base Exposures
# NOP TIER BY CLIENT FIRM do/noptiers.php
select lastupdated, clientGroup, clientFirm, displayCcy,  sum(tier1Exposure) as tier1BaseExposure,sum(tier1) as tier1NOP, sum(tier2Exposure) as tier2BaseExposure, sum(tier2) as tier2NOP, sum(tier3Exposure) as tier3BaseExposure, sum(tier3) as tier3NOP, sum(tier4Exposure) as tier4BaseExposure, sum(tier4) as tier4NOP, sum(tier5Exposure) as tier5BaseExposure, sum(tier5) as tier5NOP
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
			where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND (s.symbolType = 'FX' and p.symbol not like 'X%') AND c.clientGroup = @clientGroup and s.baseccy=bt.ccy and p.clientFirm=bt.clientFirm and s.riskccy=rt.ccy and p.clientfirm=rt.clientfirm and p.position <> 0
			union all
			# Right FX
			select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, p.symbol, s.riskCcy displayCcy, s.riskCcy ccy, p.position, p.marketRate, -round(p.position * p.marketrate, 0) amt, s.symbolType, bt.tier as baseCcyTier, rt.tier as riskCcyTier, if(bt.tier>rt.tier,bt.tier,rt.tier) as tier
			from do.firm_positions p, statements.symbols s, do.nop_clients c, do.nop_ccytier bt, do.nop_ccytier rt
			where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND (s.symbolType = 'FX' and p.symbol not like 'X%') AND c.clientGroup = @clientGroup and s.baseccy=bt.ccy and p.clientFirm=bt.clientFirm and s.riskccy=rt.ccy and p.clientfirm=rt.clientfirm and p.position <> 0
			union all
			# CFD
			select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, p.symbol, left(s.symbol,3) displayCcy, s.riskCcy ccy, p.position, p.marketRate, p.position*s.lotsize*((s.bid+s.ask)/2) as amt, s.symbolType, bt.tier as baseCcyTier, rt.tier as riskCcyTier, 5 as tier
			from do.firm_positions p, statements.symbols s, do.nop_clients c, do.nop_ccytier bt, do.nop_ccytier rt
			where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND (s.symbolType = 'CFD') AND c.clientGroup = @clientGroup and s.baseccy=bt.ccy and p.clientFirm=bt.clientFirm and s.riskccy=rt.ccy and p.clientfirm=rt.clientfirm and p.position <> 0
			union all
			# Left Metal
			select p.`timeStamp` as 'LastUpdated', c.clientGroup, p.clientFirm, p.symbol, s.baseCcy displayCcy, s.baseCcy ccy, p.position, p.marketRate, (p.position*s.lotsize) as amt, 'metal' as symbolType, bt.tier as baseCcyTier, rt.tier as riskCcyTier, if(bt.tier>rt.tier,bt.tier,rt.tier) as tier
			from do.firm_positions p, statements.symbols s, do.nop_clients c, do.nop_ccytier bt, do.nop_ccytier rt
			where c.clientFirm=p.clientFirm and p.symbol = s.symbol AND p.symbol like 'X%' AND c.clientGroup = @clientGroup and s.baseccy=bt.ccy and p.clientFirm=bt.clientFirm and s.riskccy=rt.ccy and p.clientfirm=rt.clientfirm and p.position <> 0
		) x
        where clientFirm = @clientFirm
		group by clientGroup, displayCcy, tier
		order by clientGroup, displayCcy
	) x1 
	group by clientGroup, displayCcy,tier
	order by clientGroup, displayCcy
)x2
group by displayCcy;