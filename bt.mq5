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

enum TopBottomKind {
   TOP,
   BOTTOM,
   UNKNOWN
};

struct TopBottom {
   MqlRates candle;
   TopBottomKind kind;
};

class TopsBottoms {
   private:
      TopBottom tbs[100];
      int top;
      
   public:
      TopsBottoms();
      
   public:
      TopBottom get(int i);
      void clear();
      int size();
      bool trendingUp();
      bool trendingDown();
      bool lateral();
      
   public:
      void insertTop(MqlRates& candle);
      void insertBottom(MqlRates& candle);
};


bool TopsBottoms::trendingUp(void) {
   if (size() >= 4) {
      if (tbs[top].kind == TOP) {
         return tbs[top].candle.high > tbs[top - 2].candle.high &&
                tbs[top - 1].candle.low > tbs[top - 3].candle.low;
      } else {
         return tbs[top].candle.low > tbs[top - 2].candle.low &&
                tbs[top - 1].candle.high > tbs[top - 3].candle.high;
      }
   }
   
   return false;
}

bool TopsBottoms::trendingDown(void) {
   if (size() >= 4) {
      if (tbs[top].kind == TOP) {
         return tbs[top].candle.high < tbs[top - 2].candle.high &&
                tbs[top - 1].candle.low < tbs[top - 3].candle.low;
      } else {
         return tbs[top].candle.low < tbs[top - 2].candle.low &&
                tbs[top - 1].candle.high < tbs[top - 3].candle.high;
      }
   }
   
   return false;
}

bool TopsBottoms::lateral(void) {
   return !trendingDown() && !trendingUp();
}

TopsBottoms::TopsBottoms() {
   top = -1;
}

void TopsBottoms::clear(void) {
   top = -1;
}

int TopsBottoms::size() {
   return top + 1;
}

TopBottom TopsBottoms::get(int i) {
   TopBottom b;
   
   b.kind = UNKNOWN;
   
   if (i <= top) {
      return tbs[i];
   }
   
   return b;
}

void TopsBottoms::insertTop(MqlRates &candle) {
   if (top == -1) {
      ++top;
      tbs[top].candle = candle;
      tbs[top].kind = TOP;
   } else {
      if (tbs[top].kind == TOP) {
         if (candle.high >= tbs[top].candle.high) {
            tbs[top].candle = candle;
         }
      } else {
         ++top;
         tbs[top].candle = candle;
         tbs[top].kind = TOP;      
      }
   }
}

void TopsBottoms::insertBottom(MqlRates &candle) {
   if (top == -1) {
      ++top;
      tbs[top].candle = candle;
      tbs[top].kind = BOTTOM;
   } else {
      if (tbs[top].kind == BOTTOM) {
         if (candle.low <= tbs[top].candle.low) {
            tbs[top].candle = candle;
         }
      } else {
         ++top;
         tbs[top].candle = candle;
         tbs[top].kind = BOTTOM;      
      }
   }
}

int bh;
double m20[];
int n_candles = 10;
MqlRates candles[];
double upper[];
double lower[];
double base[];
CTrade trade;
int dir = NONE;
TopsBottoms tbs;

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

bool isBlack(MqlRates& candle) {
   return candle.close < candle.open;
}

bool isWhite(MqlRates& candle) {
   return candle.close > candle.open;
}

int OnInit() {
   bh = iBands(Symbol(), PERIOD_M5, 20, 0, 2, PRICE_CLOSE);
   ArraySetAsSeries(base, true);
   ArraySetAsSeries(upper, true);
   ArraySetAsSeries(lower, true);
   ArraySetAsSeries(candles, true);
   
   Print("I'M ALIVE");
   
   return INIT_SUCCEEDED;
}

void copyBuffers() {
   CopyRates(Symbol(), PERIOD_M5, 0, 100, candles);
   CopyBuffer(bh, 0, 0, 10, base);
   CopyBuffer(bh, 1, 0, 10, upper);
   CopyBuffer(bh, 2, 0, 10, lower);
}

void makeSell() {
   double price = candles[0].close;
   //double sl = round5(price + (upper[0] - lower[0]), 5);
   double sl = round5(price + (upper[0] - base[0]), 5);
   double sz = candles[1].high - candles[1].low;
   //trade.Sell(1, Symbol(), price, sl);
   trade.Sell(1, Symbol(), price, candles[1].high, price - sz * 3);
   dir = SELL;
}

void makeBuy() {
   double price = candles[0].close;
   //double sl = round5(price - (upper[0] - lower[0]), 5);
   double sl = round5(price - (base[0] - lower[0]), 5);
   double sz = candles[1].high - candles[1].low;
   //trade.Buy(1, Symbol(), price, sl);
   trade.Buy(1, Symbol(), price, candles[1].low, price + sz * 3);
   dir = BUY;
}

double round5(double i, double v) {
   return MathFloor(i/v) * v;
}

bool isTop(int i) {
   if (i < ArraySize(candles) - 3 && i > 1) {
      /*return candles[i].high >= candles[i + 1].high &&
             candles[i].high >= candles[i + 2].high &&
             candles[i].high >= candles[i - 1].high &&
             candles[i].high >= candles[i - 2].high;*/
             
      return candles[i].high >= candles[i + 1].high &&
             candles[i].high >= candles[i - 1].high;
   }
   
   return false;
}

bool isBottom(int i) {
   if (i < ArraySize(candles) - 3 && i > 1) {
      /*return candles[i].low <= candles[i + 1].low &&
             candles[i].low <= candles[i + 2].low &&
             candles[i].low <= candles[i - 1].low &&
             candles[i].low <= candles[i - 2].low;*/
             
      return candles[i].low <= candles[i + 1].low &&
             candles[i].low <= candles[i - 1].low;
   }
          
   return false;
}

int ctt = 0;

void drawBT() {
   ObjectsDeleteAll(0);
   tbs.clear();
   
   for (int i = 0; i < ArraySize(candles); ++i) {
      if (isTop(i)) {
         tbs.insertTop(candles[i]);
      }
      
      if (isBottom(i)) {
         tbs.insertBottom(candles[i]);
      }
   }
   
   for (int i = 0; i < tbs.size(); ++i) {
      if (tbs.get(i).kind == TOP) {
         ObjectCreate(0, "Arrow" + i, OBJ_ARROW_SELL, 0, tbs.get(i).candle.time, tbs.get(i).candle.high);
      }
      
      if (tbs.get(i).kind == BOTTOM) {
         ObjectCreate(0, "Arrow" + i, OBJ_ARROW_BUY, 0, tbs.get(i).candle.time, tbs.get(i).candle.low);
      }
   }
   
   if (tbs.trendingDown()) {
      Comment("DOWN");
   }
   
   if (tbs.trendingUp()) {
      Comment("UP");
   }
   
   if (tbs.lateral()) {
      Comment("LATERAL");
   }
}

void OnTick() {
   /*if (!marketOpen()) {
      if (hasPosition()) {
         closeAllPositions();
         dir = NONE;
      }
     
      return;
   }*/

   copyBuffers();
   drawBT();
   
   //if (hasPosition()) {
   //   /*if (touchedBase()) {
   //      closeAllPositions();
   //   }*/
   //} else {
   //   dir = NONE;
   //   if (touchedUpper()) {
   //      if (isBlack(candles[1]) && candles[0].close == candles[1].low && candles[0].close - base[0] > 100) {
   //         makeSell();
   //      }
   //   } else if (touchedLower()) {
   //      if (isWhite(candles[1]) && candles[0].close == candles[1].high && base[0] - candles[0].close > 100) {
   //         makeBuy();
   //      }
   //   }
   //}
}

