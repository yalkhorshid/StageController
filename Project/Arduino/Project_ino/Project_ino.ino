
#define SyncOne          85  //0x55
#define SyncTwo          170 //0xAA

#define CMDConnection    20
#define CMDMove          21

#define ArgSync          30
#define ArgAck           31
#define ArgNack          32
#define ArgFin           33

#define ArgLeft          40
#define ArgRight         41
#define ArgUp            42
#define ArgDown          43
#define ArgForward       44
#define ArgBackward      45
#define ArgStop          46
#define ArgCalHigh       47
#define ArgCalLow        48

#define LEDGreen         9
#define LEDRed           12


#define Y_BIT0           6
#define Y_BIT1           7

#define X_BIT0           4        
#define X_BIT1           5

#define Z_BIT0           10
#define Z_BIT1           11

#define CAL_BIT          8

//Inline Function===========================================================================
#define TimerStart()     TCCR1B = 0x05
#define TimerStop()      TCCR1B = 0x00
//Function Definition=======================================================================
boolean UnpackFrame(char* pFrame , char* Command , char* Argument);
boolean UnpackFrame(char* pFrame , char* Command , char* Argument);
void Movement(char Argument);

//==========================================================================================
void setup() {
  
  //Configure RS232 Baud Rate
  Serial.begin(9600);
  
  //Configure LED PIN as Output
  pinMode(LEDRed   , OUTPUT);
  pinMode(LEDGreen , OUTPUT);
  
  pinMode(X_BIT0 , OUTPUT);
  pinMode(X_BIT1 , OUTPUT);
  
  pinMode(Y_BIT0 , OUTPUT);
  pinMode(Y_BIT1 , OUTPUT);
  
  pinMode(Z_BIT0 , OUTPUT);
  pinMode(Z_BIT1 , OUTPUT);
  
  pinMode(CAL_BIT , INPUT);
  
  digitalWrite(X_BIT0  , HIGH);
  digitalWrite(X_BIT1  , LOW);
  
  digitalWrite(Y_BIT0  , HIGH);
  digitalWrite(Y_BIT1  , LOW);
  
  digitalWrite(Z_BIT0  , HIGH);
  digitalWrite(Z_BIT1  , LOW);
  
  digitalWrite(CAL_BIT , LOW);

  
  //Turn OFF LEDs
  digitalWrite(LEDRed  , HIGH);
  digitalWrite(LEDGreen, HIGH);
  
  //Configure Timer1
  TCCR1A = 0x00; //Configure Timer to Workk in Normal Mode
  TCCR1B = 0x00; //If 0x05 Timer Starts at 15.625 KHz (Prescaler = 1024)
  OCR1AH = 0x2F; //Timer Interrupt Time (High Byte)
  OCR1AL = 0xFF; //Timer Interrupt Time (Low Byte)
  TIMSK1 = 0x02; //Enable Timer1 Compare Match Interrupt
  
  
  //LEDs Play, Showing Startup
  digitalWrite(LEDRed  , LOW);
  delay(100);
  digitalWrite(LEDGreen, LOW);
  delay(100);
  digitalWrite(LEDRed  , HIGH);
  delay(100);
  digitalWrite(LEDGreen, HIGH);

  
}
//==========================================================================================
void loop() {
  
  char RFrame[6] = {0};
  char TFrame[6] = {0};
  
  char Command;
  char Argument;
  

   
  //Check Receiver Buffer
  if( Serial.available() > 0 )
  {
    
    
    if( Serial.readBytes( RFrame , 5 ) == 5 )
    {
      
        if(UnpackFrame( RFrame , &Command , &Argument ))
        {
            
          switch( Command )
          {
            
            
            
            case CMDConnection:
              
              if(Argument == ArgSync)
              {
                TimerStart();

                Command  = CMDConnection;
                Argument = ArgAck;
              }
              else if(Argument == ArgFin)
              {
                TimerStop();

                Command  = CMDConnection;
                Argument = ArgAck;
              }
              else           
              {
                TimerStop();

                Command  = CMDConnection;
                Argument = ArgNack;
              }
              
            break;
            
            
 
            
            case CMDMove:
                   
              Movement( Argument );
              
              Command  = CMDMove;
              Argument = ArgAck;
            break;
            
            

            
            default:
              PackFrame( TFrame , Command , ArgNack );
            break;

          }//End Switch
            
            PackFrame( TFrame , Command , Argument );
            Serial.write( TFrame );
        }
      
    }
    
  }
  
}
//==========================================================================================
//==========================================================================================
void PackFrame(char* pFrame , char Command , char Argument) {
  
  pFrame[0] = SyncOne;
  pFrame[1] = SyncTwo;
  pFrame[2] = Command;
  pFrame[3] = Argument;
  pFrame[4] = SyncOne ^ SyncTwo ^ Command ^ Argument;
  
  if(pFrame[4] == 0)
    pFrame[4] = 255;
}
//==========================================================================================
boolean UnpackFrame(char* pFrame , char* Command , char* Argument) {

  char Checksum;
  
  *Command  = 0;
  *Argument = 0;
  
  if( (pFrame[0] != SyncOne) && (pFrame[1] != SyncTwo) )
    return false;
  
  Checksum = pFrame[0] ^ pFrame[1] ^ pFrame[2] ^ pFrame[3];
  if(Checksum == 0)
    Checksum = 255;
    
  if(Checksum != pFrame[4])
    return false;
    
  *Command  = pFrame[2];
  *Argument = pFrame[3];    
    
  return true;
} 
//==========================================================================================
void Movement(char Argument) {
  
  
  switch(Argument)
  {
    case ArgLeft:
      
      digitalWrite(Y_BIT0  , HIGH);
      digitalWrite(Y_BIT1  , HIGH);
      
      digitalWrite(LEDGreen, LOW);
      
    break;
    
    case ArgRight:
    
      digitalWrite(Y_BIT0  , LOW);
      digitalWrite(Y_BIT1  , LOW);
      
      digitalWrite(LEDGreen, LOW);
    
    break;
    
    case ArgUp:
    
      digitalWrite(Z_BIT0  , LOW);
      digitalWrite(Z_BIT1  , LOW);
      
      digitalWrite(LEDGreen, LOW);
    
    break;
    
    case ArgDown:
    
      digitalWrite(Z_BIT0  , HIGH);
      digitalWrite(Z_BIT1  , HIGH);
      
      digitalWrite(LEDGreen, LOW);
    
    break;
    
    case ArgForward:
      
      digitalWrite(X_BIT0  , LOW);
      digitalWrite(X_BIT1  , LOW);
      
      digitalWrite(LEDGreen, LOW);
      
    break;
    
    case ArgBackward:
    
      digitalWrite(X_BIT0  , HIGH);
      digitalWrite(X_BIT1  , HIGH);
      
      digitalWrite(LEDGreen, LOW);
    
    break;
    
    case ArgCalLow:
      pinMode(CAL_BIT , OUTPUT);
    break;
    
    case ArgCalHigh:
      pinMode(CAL_BIT , INPUT);
    break;
    
    case ArgStop:
    
      digitalWrite(X_BIT0  , HIGH);
      digitalWrite(X_BIT1  , LOW);
      
      digitalWrite(Y_BIT0  , HIGH);
      digitalWrite(Y_BIT1  , LOW);
      
      digitalWrite(Z_BIT0  , HIGH);
      digitalWrite(Z_BIT1  , LOW);
      
      digitalWrite(LEDGreen,HIGH);
    break;
  }


}
//==========================================================================================
ISR(TIMER1_COMPA_vect)
{
  TCNT1H=0x00;
  TCNT1L=0x00;
  
  digitalWrite(LEDRed, !digitalRead(LEDRed));
}
//==========================================================================================
//==========================================================================================
//==========================================================================================
