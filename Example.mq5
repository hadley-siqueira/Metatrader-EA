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

int bands_handle;
MqlRates candles[];
double upper[];
double lower[];
double base[];
CTrade trade;

bool hasPosition() {
   return PositionSelect(Symbol());
}

int OnInit() {
   bands_handle = iBands(Symbol(), PERIOD_M5, 108, 0, 2, PRICE_CLOSE);
   
   ArraySetAsSeries(base, true);
   ArraySetAsSeries(upper, true);
   ArraySetAsSeries(lower, true);
   ArraySetAsSeries(candles, true);
   
   return INIT_SUCCEEDED;
}

int abs(int a) {
   return a > 0 ? a : -a;
}

void OnTick() {
   CopyBuffer(bands_handle, 0, 0, 10, base);
   CopyBuffer(bands_handle, 1, 0, 10, upper); 
   CopyBuffer(bands_handle, 2, 0, 10, lower);
   CopyRates(Symbol(), PERIOD_M5, 0, 10, candles);
   
   if (!hasPosition()) {
      if (abs(candles[0].close - base[0]) < 20) {
         trade.Buy(1, Symbol(), candles[0].close);
      }
   } else {
      if (abs(candles[0].close - upper[0]) < 20) {
         trade.Sell(1, Symbol(), candles[0].close);
      }
   }
}
