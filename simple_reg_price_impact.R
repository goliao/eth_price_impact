require(data.table)
require(ggplot2)
require(magrittr)
require(lubridate)
source('gllib/glutil.r')
require(lfe)


dt <- fread('eth_exchange_volume_sum.csv')
dt[,date:=ymd(date)]

dt[,.(amt=sum(amt)*mean(vwap)),date] %>% gpltw()
dt[,.(amt=sum(amt)),date] %>% summary()

#451772.7*2000/1e6

dtreg=dt[, .(price = mean(vwap), sv = sum(amt * (1 * (side == 'buy') - 1 * (side != 'buy')))), by = date]


dtreg2=dtreg %>% genlns() %>% tssets.array(periods=c(1,2,3,4,5))
require(stargazer)

dtreg2[,sv_sd:=sv/sd(sv)]
dtreg2[,logret:=D.lnprice*10000]

dtreg2 %>% felm(D.lnprice~sv_sd,.) 

dtreg2 %>% felm(D.lnprice~sv,.) %>% stargazer(type='text')
dtreg2 %>% felm(D.lnprice~sv+L.sv+L2.sv+L3.sv+L4.sv+L5.sv,.) %>% stargazer(type='text')


list(dtreg2 %>% felm(logret~sv_sd,.),
     dtreg2[sv>0] %>% felm(logret~sv_sd,.),
     dtreg2[sv<0] %>% felm(logret~sv_sd,.)
     ) %T>% stargazer(type='text') %>% stargazer(type='latex')

list(dtreg2 %>% felm(logret~sv_sd,.),
     dtreg2[sv>0] %>% felm(logret~sv_sd,.),
     dtreg2[sv<0] %>% felm(logret~sv_sd,.)
) %T>% stargazer(type='text') %>% stargazer(type='text')


dtreg2[, .(logret, sv_sd)] %>%
  ggplot(aes(x = sv_sd, y = logret)) +
  geom_point() +
  geom_smooth(method = "lm", se = T)  # Adds the regression line without the confidence interval


p=dtreg2[sv<=0] %>% regformat(.,'D.lnprice~sv')
p

sd(dtreg2$sv)

regout()


dtreg2[,.(D.lnprice,sv)] %>% sd(na.rm=T)
dtreg2[,.(D.lnprice,sv)] %>% summary()
dtreg2[,.(date,D.lnprice)] %>% gpltw()
dtreg2[,.(date,sv)] %>% gpltw()


dtreg2[,.(sd(sv))]
install.packages('psych')
library(psych)
describe(dtreg2)

sd(dtreg2$sv)*2000/1e6
# 1 sd is going to have 87 bps price impact
4.48e-07*sd(dtreg2$sv)*10000


# 1 sd is about $40mm-80mm of net volume during this time period
sd(dtreg2$sv)*3000/1e6

# downside only
106.609/(sd(dtreg2$sv)*3000/1e6)
