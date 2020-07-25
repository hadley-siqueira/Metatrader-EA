//+------------------------------------------------------------------+
//|                                                          M20.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Expert\Expert.mqh>
//--- available signals
#include <Expert\Signal\SignalAC.mqh>
//--- available trailing
#include <Expert\Trailing\TrailingNone.mqh>
//--- available money management
#include <Expert\Money\MoneyFixedLot.mqh>

input int hourBegin = 10;
input int minBegin = 0;
input int hourEnd = 17;
input int minEnd = 40;
input int contratos = 1;

#define BUY 1
#define SELL -1
#define NONE 0

int m20h;
double m20[];
int n_candles = 10;
MqlRates candles[];
CTrade trade;
int dir = NONE;

bool hasPosition() {
   return PositionSelect(Symbol());
}

void closeAllPositions() {
   int i = PositionsTotal() - 1;
   
   while (i >= 0) {
      if (trade.PositionClose(PositionGetSymbol(i))) i--;
   }
}

bool marketOpen() {
   MqlDateTime mdt;
   TimeToStruct(TimeCurrent(), mdt);
   int currentTime = mdt.hour * 60 + mdt.min;
   
   return currentTime >= hourBegin * 60 + minBegin && currentTime <= hourEnd * 60 + minEnd;
}

int OnInit() {
   m20h = iMA(Symbol(), PERIOD_M5, 20, 0, MODE_SMA, PRICE_CLOSE);
   ArraySetAsSeries(m20, true);
   ArraySetAsSeries(candles, true);
   
   return INIT_SUCCEEDED;
}

double findLastTop() {
   int i;
   double max = -999999;
   
   for (i = 0; i < n_candles; ++i) {
      if (max < candles[i].high) {
         max = candles[i].high;
      }
   }
   
   return max;
}

double findLastBottom() {
   int i;
   double min = 5000000;
   
   for (i = 0; i < n_candles; ++i) {
      if (min > candles[i].low) {
         min = candles[i].low;
      }
   }
   
   return min;
}

bool rising() {
   return m20[1] > m20[2] && candles[1].close > m20[1];
}

bool falling() {
   return m20[1] < m20[2] && candles[1].close < m20[1];
}

bool touched() {
   double diff = candles[0].close - m20[0];
   diff = diff > 0 ? diff : -diff;
   
   Print(diff + " " + candles[0].close + " " + m20[0]);
   return diff < 20;
}

double round5(double i, double v) {
   return MathFloor(i/v) * v;
}

void OnTick() {
   if (!marketOpen()) {
      if (hasPosition()) {
         closeAllPositions();
      }
     
      return;
   }
   
   CopyBuffer(m20h, 0, 0, 10, m20);
   CopyRates(Symbol(), PERIOD_M5, 0, n_candles, candles);
   
   if (hasPosition()) {
      if (dir == BUY && candles[1].close < m20[1]) {
         closeAllPositions();
      } else if (dir == SELL && candles[1].close > m20[1]) {
         closeAllPositions();
      }
   } else {
      if (touched()) {
         if (rising()) {
            double top = findLastTop();
            double tp = top - candles[0].close;
            double sl = round5(tp / 2, 5);
            double price = candles[0].close;
            trade.Buy(contratos, Symbol(), price, price - sl, price + tp);
            dir = BUY;
         } else if (falling()) {
            double bottom = findLastBottom();
            double price = candles[0].close;
            double tp = price - bottom;
            double sl = round5(tp / 2, 5);
            trade.Sell(contratos, Symbol(), price, price + sl, price - tp);
            dir = SELL;
         }
      }
   }
}

