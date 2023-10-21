#property copyright "Ajchi"
#property link "No Link"
#property indicator_chart_window
#property indicator_buffers 6
#property indicator_color1 Green
#property indicator_color2 Red
#property indicator_color3 MediumVioletRed
#property indicator_color4 DodgerBlue
#property indicator_color5 Bisque
#property indicator_color6 DeepPink
//extern int takenBars,difference,matching;
//----vyrovnávací pamìti
double buyPB[];
double sellPB[];
double insideBar[];
double arrayGaps[];
double outsideBars[];
double smallSR[];
int startDay=2000;
static int prevTime;
double dayRange = 0.0;
int outsideBarsCount=0;
string period="";
//stats variables

input bool ShowBuyPinBars = true;
input bool ShowSellPinBars = true;
string scriptIdentifier = "PinBarsWithDeleteFunctionality"

//+------------------------------------------------------------------+
//| Custom indicator – inicializaèní funkce |
//+------------------------------------------------------------------+
int init()
{
   //----indikátory
   SetIndexStyle(0,DRAW_ARROW);
   SetIndexArrow(0,233); //242 for down arrow
   SetIndexBuffer(0,buyPB);
   SetIndexLabel(0, scriptIdentifier + "PB UP");
   
   SetIndexStyle(1,DRAW_ARROW);
   SetIndexArrow(1,234); //244 for up&down arrow
   SetIndexBuffer(1,sellPB);
   SetIndexLabel(1, scriptIdentifier + "PB DOWN");
   
   SetIndexStyle(2,DRAW_ARROW);
   SetIndexArrow(2,235); //242 for down arrow
   SetIndexBuffer(2,insideBar);
   SetIndexLabel(2, scriptIdentifier + "Inside Bar");

/*   SetIndexStyle(3,DRAW_ARROW);
   SetIndexArrow(3,242); //244 for up&down arrow
   SetIndexBuffer(3,arrayGaps);
   SetIndexLabel(3,"PB DOWN");
*/
   SetIndexStyle(3,DRAW_ARROW);
   SetIndexArrow(3,120); //242 for down arrow
   SetIndexBuffer(3,arrayGaps);
   SetIndexLabel(3, scriptIdentifier + "GAP");
   
   
   SetIndexStyle(4,DRAW_ARROW);
   SetIndexArrow(4,163); //242 for down arrow
   SetIndexBuffer(4,outsideBars); 
   SetIndexLabel(4, scriptIdentifier + "Outside Bar");
   
   
   SetIndexStyle(5,DRAW_ARROW);
   SetIndexArrow(5,163); //242 for down arrow
   SetIndexBuffer(5,smallSR); 
   SetIndexLabel(5, scriptIdentifier + "Sup-Res");


   switch (Period())
   {
      case 60:
         period="H1";
         break;
      case 240:
         period="H4";
         break;
      case 1440:
         period="D1";
         break;
      case 30:
         period="30m";
         break;
      case 15:
         period="15m";
         break;
      case 5:
         period="5m";
         break;    
   }
   
   ObjectsDeleteAll(0, scriptIdentifier);
   //edit from wen: should be able to stop the deleting of objects
   
   return(0);
}
//+------------------------------------------------------------------+
//| Custom indicator – deinicializaèní funkce |
//+------------------------------------------------------------------+
int deinit()
{
//-----
   
//----
return(0);
}
//+------------------------------------------------------------------+
//| Custom indicator – funkce opakování |
//+------------------------------------------------------------------+
int start()
{  
   string info="";
   string time="";
   bool addInfo=false;
   int outsideBarDirection;
   int hours, min, sec;
   double gapSize;
   bool alertOn;
   int smallSRcount=0;
	
   if(prevTime==Time[0]) return(0);      // Always start at the new bar
      prevTime=Time[0]; 
   int counted_bars=IndicatorCounted();
   if (counted_bars<0) return(-1);
   if (counted_bars>0) counted_bars--;
   int pos=Bars-counted_bars;
   if(pos>20000) pos=20000;
   alertOn=true;
   //Comment("counted_bars="+counted_bars+", pos="+pos);
   //pos=0;
   int counter=0;
   //double poslGap=0.0;
   while(pos>=0 )//&& TimeYear(Time[pos])>startDay
   {
      
      //addInfo=false;
      if (ShowBuyPinBars && IsBuyPinbar(dayRange,pos))
      {
         buyPB[pos+1]=Low[pos+1]-dayRange/4.0;   
         if(alertOn&&pos<1)
         {
            
            Alert ("Symbol: ",Symbol(),"   TimeFrame: ",period,"   Operace: PinBar BUY   Rozsah: ",(High[1]-Low[1])/Point,"  Cas:",TimeToStr(Time[pos],TIME_DATE|TIME_MINUTES));
            PlaySound("alert2.wav"); 
            addInfo=true;
         }
      }

      
      if (ShowSellPinBars && IsSellPinbar(dayRange,pos))
      {
          sellPB[pos+1]=High[pos+1]+dayRange/4.0;
          if(alertOn&&pos<1)
          {
               Alert ("Symbol: ",Symbol(),"   TimeFrame: ",period,"   Operace: PinBar SELL   Rozsah: ",(High[1]-Low[1])/Point,"  Cas:",TimeToStr(Time[pos],TIME_DATE|TIME_MINUTES));
               PlaySound("alert2.wav");
               addInfo=true;
          }
      } 
      
      pos--;
      

   }
   return(0);
}

//+------------------------------------------------------------------+
//| User function AveRange4                                          |
//+------------------------------------------------------------------+
double AveRange4(int pos)
{
   double sum;
   double rangeSerie[4];
   
   int i=0;
   int ind=1;
   int startYear=1995;
   int den;
   
   if(pos<=0)den=1;
   else den = pos;
   if (TimeYear(Time[den-1])>=startYear)
   {
      while (i<4)
      {
         //datetime pok=Time[pos+ind];
         if(TimeDayOfWeek(Time[pos+ind])!=0)
         {
            sum+=High[pos+ind]-Low[pos+ind];//make summation
            i++;
         }
         ind++;   
         //i++;
      }
      //Comment(sum/4.0);
      return (sum/4.0);//make average, don't count min and max, this is why I divide by 4 and not by 6
   } 
      return (50*Point);
   
}//------------END FUNCTION-------------



//+------------------------------------------------------------------+
//| User function IsPinbar                                           |
//+------------------------------------------------------------------+
bool IsBuyPinbar(double& dayRange, int pos)
{
   //start of declarations
   double actOp,actCl,actHi,actLo,preHi,preLo,preCl,preOp,actRange,preRange,actHigherPart,actHigherPart1;
   actOp=Open[pos+1];
   actCl=Close[pos+1];
   actHi=High[pos+1];
   actLo=Low[pos+1];
   preOp=Open[pos+2];
   preCl=Close[pos+2];
   preHi=High[pos+2];
   preLo=Low[pos+2];
   //SetProxy(preHi,preLo,preOp,preCl);//Check proxy
   actRange=actHi-actLo;
   preRange=preHi-preLo;
   actHigherPart=actHi-actRange*0.4;//helping variable to not have too much counting in IF part
   actHigherPart1=actHi-actRange*0.4;//helping variable to not have too much counting in IF part
   //end of declaratins
   //start function body
   dayRange=AveRange4(pos);
   if((actCl>actHigherPart1&&actOp>actHigherPart)&&  //Close&Open of PB is in higher 1/3 of PB
      (actRange>dayRange*0.5)&& //PB is not too small
      //(actHi<(preHi-preRange*0.3))&& //High of PB is NOT higher than 1/2 of previous Bar
      (actLo+actRange*0.25<preLo)) //Nose of the PB is at least 1/3 lower than previous bar
   {
    
      if(Low[ArrayMinimum(Low,3,pos+3)]>Low[pos+1])
         return (true);
   }
   return(false);
   
}//------------END FUNCTION-------------


bool IsSellPinbar(double& dayRange, int pos)
{
   //start of declarations
   double actOp,actCl,actHi,actLo,preHi,preLo,preCl,preOp,actRange,preRange,actLowerPart, actLowerPart1;
   actOp=Open[pos+1];
   actCl=Close[pos+1];
   actHi=High[pos+1];
   actLo=Low[pos+1];
   preOp=Open[pos+2];
   preCl=Close[pos+2];
   preHi=High[pos+2];
   preLo=Low[pos+2];
   //SetProxy(preHi,preLo,preOp,preCl);//Check proxy
   actRange=actHi-actLo;
   preRange=preHi-preLo;
   actLowerPart=actLo+actRange*0.4;//helping variable to not have too much counting in IF part
   actLowerPart1=actLo+actRange*0.4;//helping variable to not have too much counting in IF part
   //end of declaratins
   
   //start function body

   dayRange=AveRange4(pos);
   if((actCl<actLowerPart1&&actOp<actLowerPart)&&  //Close&Open of PB is in higher 1/3 of PB
      (actRange>dayRange*0.5)&& //PB is not too small
      //(actLo>(preLo+preRange/3.0))&& //Low of PB is NOT lower than 1/2 of previous Bar
      (actHi-actRange*0.25>preHi)) //Nose of the PB is at least 1/3 lower than previous bar
      
   {
      if(High[ArrayMaximum(High,3,pos+3)]<High[pos+1])
         return (true);
   }
}//------------END FUNCTION-------------


//+------------------------------------------------------------------+
//| User function LotSize             vcetne spreadu                 |
//+------------------------------------------------------------------+
double LotSize(double pbDay)
{
   pbDay=pbDay+MarketInfo(Symbol(),MODE_SPREAD)*Point;
   double actBalance=AccountBalance();
   double tickValue=MarketInfo(Symbol(),MODE_TICKVALUE);
   double myBet=0;
   double lot=0;
   double minLot = MarketInfo(Symbol(),MODE_MINLOT);
   myBet=actBalance*0.02; //2 percent of account
   lot=myBet/(pbDay/Point*tickValue);
   lot=MathRound(lot*10.0)/10.0;
   if(lot<minLot) 
      lot = minLot;
   return (lot);
}
//------------END FUNCTION-------------


//+------------------------------------------------------------------+
//| User function IsInsideBar                                          |
//+------------------------------------------------------------------+
bool IsInsideBar(int pos)
{
   int i = 0;
   int x = 0;
   
   //bool naplneno=false;
   int takenDays[3];
   if(Period()==1440) 
   //"In the daily chart, we will exclude Sundays by recording the indexes of individual days except for Sundays, and then process it. - translated. Period()==1440 means if it's a daily chart
   {
      while(i<3)
      {
         if(TimeDayOfWeek(Time[pos+1+x])!=0) 
         {
            takenDays[i]=pos+1+x;
            i++;
         }
         x++;
      }
      if(Low[takenDays[0]]>=Low[takenDays[1]]&&Low[takenDays[1]]>=Low[takenDays[2]])
         if (High[takenDays[0]]<=High[takenDays[1]]&&High[takenDays[1]]<=High[takenDays[2]])
            return (true);
   
   }
   else 
   {
      if(Low[pos+1]>=Low[pos+2]&&Low[pos+2]>=Low[pos+3])
         if (High[pos+1]<=High[pos+2]&&High[pos+2]<=High[pos+3])
            return (true);
   
   
   }
   return (false);
}


//+------------------------------------------------------------------+
//| User function IsOutsideBar - average gap size                            |
//+------------------------------------------------------------------+
int IsOutsideBar(int pos)
{
   int i = 0;
  // int x = 0;
  // int diff = 1;
   if(TimeDayOfWeek(Time[pos+2])!=0) 
     // return (0);
   if(Low[pos+2]>=Low[pos+1]&&High[pos+2]<=High[pos+1])
   {
      if(Open[pos+1]<Close[pos+1]&&Close[pos+1]>High[pos+2])
         return (1);
      else if(Open[pos+1]>Close[pos+1]&&Close[pos+1]<Low[pos+2])    
         return (-1);
   }
   return (0);
}
//------------END FUNCTION-------------



