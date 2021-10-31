

   MEMBER('TestApp.clw')                                   ! This is a MEMBER module

                     MAP
                       INCLUDE('TESTS.INC'),ONCE        !Local module procedure declarations
                       INCLUDE('TESTAPP001.INC'),ONCE        !Req'd for module callout resolution
                       INCLUDE('TESTAPP002.INC'),ONCE        !Req'd for module callout resolution
                       INCLUDE('TESTAPP003.INC'),ONCE        !Req'd for module callout resolution
                       INCLUDE('TESTAPP004.INC'),ONCE        !Req'd for module callout resolution
                       INCLUDE('TESTAPP005.INC'),ONCE        !Req'd for module callout resolution
                       INCLUDE('TESTAPP006.INC'),ONCE        !Req'd for module callout resolution
                       INCLUDE('TESTAPP008.INC'),ONCE        !Req'd for module callout resolution
                     END


!!! <summary>
!!! Generated from procedure template - Source
!!! </summary>
Tests                PROCEDURE                             ! Declare Procedure
  MAP
AssertEqual PROCEDURE(? pExpected,? pActual,STRING pInfo),LONG,PROC
  END  

TestsResult             ANY

  CODE
  
  TestsResult = FORMAT(TODAY(),@D10)&' '&FORMAT(CLOCK(),@T04)
  
  DO TestStart
  DO TestStart1Parm
  DO TestStart2Parm
  DO TestStart3Parm
  DO TestStart3ParmSetupThreadSetValue
  DO TestStructures
  
  !DO TestStart3ParmSetupThreadNotify
  
  !StringToFile(TestsResult,'TestsResult.txt')
  !RUN('TestsResult.txt')

TestStart           ROUTINE
  
  !Arrange
  MiniAppFrame.InitCaller
  !MiniAppFrame.SetShowFrame(TRUE)
  
  !Act
  MiniAppFrame.Start(MdiProcess,30000) 
  
  !Assert
  AssertEqual('152',MiniAppFrame.GetValue('sum'),'0 Parm')

TestStart1Parm             ROUTINE
   
  !Arrange
  MiniAppFrame.InitCaller
  !Act  
  MiniAppFrame.Start(MdiProcess1Parm,30000,'123') 
  !Assert
  AssertEqual('2366',MiniAppFrame.GetValue('sum'),'1 Parm')
  
TestStart2Parm      ROUTINE
   
  !Arrange
  MiniAppFrame.InitCaller
  !Act
  MiniAppFrame.Start(MdiProcess2Parm,30000,'123','456')   
  !Assert
  AssertEqual('10574',MiniAppFrame.GetValue('sum'),'2 Parm')

TestStart3Parm      ROUTINE

  !Arrange
  MiniAppFrame.InitCaller
  !Act
  MiniAppFrame.Start(MdiProcess3Parm,30000,'123','456','789')     
  !Assert
  AssertEqual('24776',MiniAppFrame.GetValue('sum'),'3 Parm')
  
TestStart3ParmSetupThreadSetvalue    ROUTINE

  LOOP 10 TIMES    
    !Arrange
    MiniAppFrame.InitCaller
    MiniAppFrame.SetValue('VAL',987)    
    !Act
    MiniAppFrame.Start(MdiProcess3ParmSetupThreadSetVariable,30000,'123','456','789') 
    !Assert
    AssertEqual('42542',MiniAppFrame.GetValue('sum'),'3 Parm Setup Thread SetValue')
  .
  
TestStructures      ROUTINE  
  DATA
Group1  LIKE(TestGroup)
Group2  LIKE(TestGroup)
Queue1  QUEUE(TestQueue)
        END
  CODE
  !Arrange
  Group1.TestString = 'abcdef'
  Group1.TestNumber = 123456.78  
  Group1.TestDate = DATE(10,30,2021)
  Group1.TestTime = 13*60*60*100 + 32*60*100 + 25*100 + 1    
  CLEAR(Queue1)
  Queue1.TestNumber = 1
  Queue1.TestString = 'ONE'
  ADD(Queue1)
  CLEAR(Queue1)
  Queue1.TestNumber = 2
  Queue1.TestString = 'TWO'
  ADD(Queue1)
  
  MiniAppFrame.InitCaller
  MiniAppFrame.StoreGroupValues(Group1)  
  MiniAppFrame.StoreGroup('TestGroup1',Group1)  
  MiniAppFrame.StoreQueue('TestQ1',Queue1)
  !Act
  MiniAppFrame.Start(MdiProcessStructures,30000) 
  !Assert
  AssertEqual('abcdefGHI',MiniAppFrame.GetValue('TestString'),'Structure, group value teststring')
  AssertEqual(123456.789012,MiniAppFrame.GetValue('TestNumber'),'Structure, group value testnumber')
  AssertEqual(DATE(10,30,2021)+7,MiniAppFrame.GetValue('TestDate'),'Structure, group value testdate')
  AssertEqual(13*60*60*100 + 32*60*100 + 25*100 + 1 + 500,MiniAppFrame.GetValue('TestTime'),'Structure, group value testtime')

  MiniAppFrame.RetrieveGroup('TestGroup1',Group2)
  AssertEqual('abcdefJKL',Group2.TestString,'Structure, store retrieve group')
  AssertEqual(123456.789024,Group2.TestNumber,'Structure, store retrieve group')
  AssertEqual(DATE(10,30,2021)+14,Group2.TestDate,'Structure, store retrieve group')
  AssertEqual(13*60*60*100 + 32*60*100 + 25*100 + 1 + 1000,Group2.TestTime,'Structure, store retrieve group')
  CLEAR(Group2)
  MiniAppFrame.RetrieveGroup('TestGroup2',Group2)
  AssertEqual('abcdefJKL',Group2.TestString,'Structure, store retrieve group 2')
  AssertEqual(123456.789024,Group2.TestNumber,'Structure, store retrieve group 2')
  AssertEqual(DATE(10,30,2021)+14,Group2.TestDate,'Structure, store retrieve group 2')
  AssertEqual(13*60*60*100 + 32*60*100 + 25*100 + 1 + 1000,Group2.TestTime,'Structure, store retrieve group 2')
  
  FREE(Queue1)
  CLEAR(Queue1)
  MiniAppFrame.RetrieveQueue('TestQ1',Queue1)
  GET(Queue1,2)
  AssertEqual(1002,Queue1.TestNumber,'Structure, store retrieve queue')
  AssertEqual('TWOxyz',Queue1.TestString,'Structure, store queue')

TestStart3ParmSetupThreadNotify    ROUTINE
   
  LOOP 3 TIMES
    !Arrange
    MiniAppFrame.InitCaller
    MiniAppFrame.Notify(1001,654)
    MiniAppFrame.SetNotifyDelay(50) ! 0.50 seconds
    MiniAppFrame.SetMaxExecutiontime(1000) !10.00 seconds
    !Act
    MiniAppFrame.Start(MdiProcess3ParmSetupThreadNotify,30000,'123','456','789') 
    !Assert
    AssertEqual('36548',MiniAppFrame.GetValue('sum'),'3 Parm Setup Thread Notify')
  .  
  

AssertEqual         PROCEDURE(? pExpected,? pActual,STRING pInfo)!,LONG,PROC
TestResult ANY
  CODE 
  
  TestResult = 'Thread: '&THREAD()&'<13,10>' & |
      CHOOSE(pExpected = pActual,'ok','--')&'<9>'& |
      pInfo&'<13,10>' & |
      'Exp: <'&pExpected&'>'&'<13,10>'& |
      'Act: <'&pActual&'>' & |          
      '<13,10>'
  
  DebugView(TestResult)
  
  TestsResult =  CHOOSE(TestsResult = '','',TestsResult&'<13,10>')& |         
      TestResult  
  
  IF pExpected <> pActual
    SETCLIPBOARD(TestResult)
    STOP(TestResult)
  .
  
  RETURN CHOOSE(pExpected = pActual)
    
