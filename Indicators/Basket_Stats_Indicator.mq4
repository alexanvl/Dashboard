//+------------------------------------------------------------------+
//|                                        Basket_Stats_Time_Sub.mq4 |
//|                          Copyright © 2011-2013, Patrick M. White |
//|                     https://sites.google.com/site/marketformula/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011-2013, Patrick M. White"
#property link      "https://sites.google.com/site/marketformula/"
// late edited January 9, 2013
/*
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program. If not, see <http://www.gnu.org/licenses/>.
    
    If you need a commercial license, please send me an email:
    market4mula@gmail.com
*/

#property indicator_chart_window

extern int MagicNumber = -1;
extern int UniqueNumber = 0; // change this to safely add multiple indicators at the same time
extern bool useopentime = true;
extern int columnwidth = 40;
extern int decimals = 1;
extern string CORNER= "--Screen Corner: 0=upper left, 1=upper right, 2=lower left, 3=lower right--";
extern int corner = 1;
extern string LROffset= "--lroffset = Use multiples of 300+, left or right offset (depending on the corner chosen).--";
extern int lroffset = 0;
extern string TBOffset= "--tboffset = top or bottom offset (depending on corner chosen). A single line height is 14. There are 2 top lines and one summation line + symbols * 14 or 42 + 14*(symbol count)--";
extern int tboffset =0;
//--------------------------------------------------------------------
double BeginningBalance = 0;
string symbols[20];
string s;
double tothour[24];
color pcolor;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()


  {
   string timesub = "sub";
   s = corner;
   s = s + tboffset;
   s = s + (lroffset) + timesub + (UniqueNumber) + "u" + (MagicNumber) + "mn";
   DeleteObjects();
   BeginningBalance = CalcBeginningBalance();
   IndicatorShortName("Basket_Stats_Time_Sub" + (MagicNumber) + (UniqueNumber));
//---- indicators
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   DeleteObjects();
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
   ArrayInitialize(tothour, 0.0);
   if(useopentime==true) {
      SetLabel(s+"objTitle", "Magic Number:" + MagicNumber + " Unique Number:" + UniqueNumber + "   Open Time", DarkGray, 13*columnwidth + lroffset, 11 + tboffset, corner);
   } else {
      SetLabel(s+"objTitle", "Magic Number:" + MagicNumber + " Unique Number:" + UniqueNumber + " | Close Time", DarkGray, 13*columnwidth + lroffset, 11 + tboffset, corner);
   }
   
   SetLabel(s+"objSymbol", "Symbol", DimGray, 26*columnwidth + lroffset, 25 + tboffset, corner);
   SetLabel(s+"objHour"+24, "Tot" , Yellow, 25*columnwidth + lroffset - 24*columnwidth, 25 + tboffset, corner);
   
   Assign_Symbols();
   for (int i =0; i <20; i++) {
      if(StringLen(symbols[i])==0) break;
      Output_Time(i, symbols[i]);
   }
   int row = i;
   double totpnl =0.0;
   SetLabel(s+"objTotalsAll" + (row), "Totals", Yellow, 26*columnwidth + lroffset, 25+ (row + 1)*14 + tboffset, corner);
   for (i = 0; i < 24; i++) {
      
      totpnl += tothour[i];
      if (tothour[i]>0.0) {
         // highlight the hour as profitable
         SetLabel(s+"objHourColumn" +(i) + (row) , i , Cyan, 25*columnwidth + lroffset - i*columnwidth, 25 + tboffset, corner);
         SetLabel(s+"objHour" + (i)+ "column", DoubleToStr(tothour[i],decimals), Lime, 25*columnwidth + lroffset - i*columnwidth, 25 + (row + 1)*14 + tboffset, corner);
      } else if (tothour[i]<0.0){
         SetLabel(s+"objHourColumn" +(i) + (row) , i , Red, 25*columnwidth + lroffset - i*columnwidth, 25 + tboffset, corner);
         SetLabel(s+"objHour" + (i)+ "column", DoubleToStr(tothour[i],decimals), Red, 25*columnwidth + lroffset - i*columnwidth, 25 + (row + 1)*14 + tboffset, corner);
      }
      else {SetLabel(s+"objHourColumn" +(i) + (row) , i , White, 25*columnwidth + lroffset - i*columnwidth, 25 + tboffset, corner);
      SetLabel(s+"objHour" + (i)+ "column", DoubleToStr(tothour[i],decimals), White, 25*columnwidth + lroffset - i*columnwidth, 25 + (row + 1)*14 + tboffset, corner);}
   }
   // Tot column header
   if(totpnl > 0.0) {
      SetLabel(s+"objHourColumn" + "24" + row, DoubleToStr(totpnl,decimals), Cyan, 25*columnwidth + lroffset - 24*columnwidth, 25 + (row + 1)*14 + tboffset, corner);
   } else {
      SetLabel(s+"objHourColumn" +"24" + row, DoubleToStr(totpnl,decimals), Magenta, 25*columnwidth + lroffset - 24*columnwidth, 25 + (row + 1)*14 + tboffset, corner);
   }
   
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+

void Output_Time(int row, string sym)
{
   
   double trades =0;
   double lots = 0.0;
   double opnl = 0.0;
   double cpnl =0.0;
   double clots = 0.0;
   double ctrades = 0;
   double symhour[24];
   double pnl =0.0;
   int pos = 1, lcolor = DimGray;
   int hour =0;
   ArrayInitialize(symhour, 0.0);
   for(int i =0; i < OrdersTotal(); i++) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if((OrderMagicNumber() == MagicNumber || MagicNumber == -1 ) && OrderSymbol() == sym) {
            if(useopentime == true) {
               hour = TimeHour(OrderOpenTime());
            } else {
               hour = TimeHour(OrderCloseTime());
            }
            pnl = OrderCommission() + OrderSwap() + OrderProfit(); 
            tothour[hour] += pnl;
            symhour[hour] += pnl;
            opnl += pnl;
         }
      }
   }
   for(i = 0; i < OrdersHistoryTotal(); i++) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) {
         if((OrderMagicNumber() == MagicNumber || MagicNumber == -1) && OrderSymbol() == sym) {
            if(useopentime == true) {
               hour = TimeHour(OrderOpenTime());
            } else {
               hour = TimeHour(OrderCloseTime());
            }
            pnl = OrderCommission() + OrderSwap() + OrderProfit();
            tothour[hour] += pnl;
            symhour[hour] += pnl;
            cpnl += pnl;
         } else { // this is the initial deposit
            //Print("Magic " + MagicNumber + " sym " + sym + " Symbol " + OrderSymbol() + " order# " + i);
            //Print("pnl " + (OrderCommission() + OrderSwap() + OrderProfit()));
         }
      } else {
         Print ("Error accessing history, order# " + i + " error: " + GetLastError());
      }
   }
   //Print("opnl: " + opnl + " cpnl: " + cpnl + " ordersHistoryTotal: " + OrdersHistoryTotal());
   for (i = 0; i < 24; i++) {
      if (symhour[i] >0.0) lcolor = Lime; else if (symhour[i] <0.0) lcolor = Red;else if (symhour[i] ==0.0)lcolor = White;
      SetLabel(s+"objPnL" + (row) + (sym) + (i), DoubleToStr(symhour[i],decimals), lcolor, 25*columnwidth + lroffset - i*columnwidth, 25 + (row + 1) * 14 + tboffset, corner);
   }
   if (opnl + cpnl >0.0) lcolor = Lime; else if (opnl + cpnl <0.0) lcolor = Red;else if (opnl + cpnl ==0.0)lcolor = White;
   SetLabel(s+"objPnL" + (row) + (sym) + (i), DoubleToStr(opnl + cpnl,decimals), lcolor, 25*columnwidth + lroffset - 24*columnwidth, 25 + (row + 1) * 14 + tboffset, corner);
   if (opnl + cpnl > 0.0) {
      // change the color of the symbol to cyan for highlighting
      SetLabel(s+"objSymbol" + (row), (sym), Cyan, 26*columnwidth + lroffset, 25 + (row + 1)*14 +tboffset, corner);
   } else {
      SetLabel(s+"objSymbol" + (row), sym, DarkGray, 26*columnwidth + lroffset, 25 + (row + 1)*14 +tboffset, corner);
   }

}

void Assign_Symbols()
{
   int i =0;
   for (i =0; i < OrdersHistoryTotal(); i++) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)==true)
      if(OrderMagicNumber() == MagicNumber || MagicNumber == -1) {
         for (int k = 0; k<=20; k++) {
            if(OrderSymbol() == symbols[k]) break;
            if(StringLen(symbols[k]) == 0) {
               symbols[k] = OrderSymbol();
               break;
            }
         }
      }
   }
   
   for (i=0; i<OrdersTotal(); i++) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)==true)
      if(OrderMagicNumber() == MagicNumber || MagicNumber == -1) {
         for (k = 0; k <=20; k++) {
            if(OrderSymbol() == symbols[k]) break;
            if(StringLen(symbols[k]) == 0) {
               symbols[k] = OrderSymbol();
               break;
            }         
         }
      }
   }
}

double CalcBeginningBalance()
{
   double pips = 0.0;
   for (int i = 0; i < 1; i++) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)==true)
      if(OrderMagicNumber() == MagicNumber || MagicNumber == -1){
         pips += OrderProfit();
      }
   }
   return(pips);
}

//+--------------------------------------------------------------------------+
//| corner - room corner bindings - (0 - upper left)                         |
//| fontsize - font size - (9 - default)                                     |
//+--------------------------------------------------------------------------+
  void SetLabel(string name, string text, color clr, int xdistance, int ydistance, int corner=1, int fontsize=9)
  {
   int window = WindowFind("Basket_Stats_Time_Sub" + (MagicNumber) + (UniqueNumber));
   
   
   //if (window == -1) return;
   if (ObjectFind(name)==-1) {
      ObjectCreate(name, OBJ_LABEL, 0, 0,0);
      ObjectSet(name, OBJPROP_XDISTANCE, xdistance);
      ObjectSet(name, OBJPROP_YDISTANCE, ydistance);
      ObjectSet(name, OBJPROP_CORNER, corner);
   }
   ObjectSetText(name, text, fontsize, "Arial", clr);
 
  }
//+--------------------------------------------------------------------------+

  void     DeleteObjects() {
  for(int i=ObjectsTotal()-1; i>-1; i--)
   if (StringFind(ObjectName(i),"obj")>=0)  ObjectDelete(ObjectName(i));  
   Comment("");
 }