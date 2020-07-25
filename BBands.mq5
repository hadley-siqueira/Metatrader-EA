#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"


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

int bh;
double m20[];
int n_candles = 10;
MqlRates candles[];
double upper[];
double lower[];
double base[];
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
   bh = iBands(Symbol(), PERIOD_M5, 20, 0, 2, PRICE_CLOSE);
   ArraySetAsSeries(base, true);
   ArraySetAsSeries(upper, true);
   ArraySetAsSeries(lower, true);
   ArraySetAsSeries(candles, true);
   
   return INIT_SUCCEEDED;
}

void copyBuffers() {
   CopyRates(Symbol(), PERIOD_M5, 0, 10, candles);
   CopyBuffer(bh, 0, 0, 10, base);
   CopyBuffer(bh, 1, 0, 10, upper);
   CopyBuffer(bh, 2, 0, 10, lower);
}

bool touchedUpper() {
   double diff = candles[0].close - upper[0];
   diff = diff > 0 ? diff : -diff;
   
   return diff < 30;
}

bool touchedLower() {
   double diff = candles[0].close - lower[0];
   diff = diff > 0 ? diff : -diff;
   
   return diff < 30;
}

bool touchedBase() {
   double diff = candles[0].close - base[0];
   diff = diff > 0 ? diff : -diff;
   
   return diff < 30;
}

void makeSell() {
   double price = candles[0].close;
   //double sl = round5(price + (upper[0] - lower[0]), 5);
   double sl = round5(price + (upper[0] - base[0]), 5);
   trade.Sell(1, Symbol(), price, sl);
   //trade.Sell(1, Symbol(), price);
   dir = SELL;
}

void makeBuy() {
   double price = candles[0].close;
   //double sl = round5(price - (upper[0] - lower[0]), 5);
   double sl = round5(price - (base[0] - lower[0]), 5);
   trade.Buy(1, Symbol(), price, sl);
   //trade.Buy(1, Symbol(), price);
   dir = BUY;
}

double round5(double i, double v) {
   return MathFloor(i/v) * v;
}

void OnTick() {
   if (!marketOpen()) {
      if (hasPosition()) {
         closeAllPositions();
         dir = NONE;
      }
     
      return;
   }

   copyBuffers();
   
   if (hasPosition()) {
      if (dir == BUY && touchedUpper()) {
         makeSell();
         makeSell();
      } else if (dir == SELL && touchedLower()) {
         makeBuy();
         makeBuy();
      }
   } else {
      dir = NONE;
      if (touchedUpper()) {
         makeSell();
      } else if (touchedLower()) {
         makeBuy();
      }
   }
}

