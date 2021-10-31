  MEMBER()
  MAP
  END
  INCLUDE('Equates.CLW'),ONCE
  INCLUDE('MINIAPPFRAME.INC'),ONCE
!Carlos Gutierrez   carlosg@sca.mx    https://github.com/CarlosGtrz
!
!MIT License
!
!Copyright (c) 2021 Carlos Gutierrez Fragosa
!
!Permission is hereby granted, free of charge, to any person obtaining a copy
!of this software and associated documentation files (the "Software"), to deal
!in the Software without restriction, including without limitation the rights
!to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
!copies of the Software, and to permit persons to whom the Software is
!furnished to do so, subject to the following conditions:
!
!The above copyright notice and this permission notice shall be included in all
!copies or substantial portions of the Software.
!
!THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
!IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
!FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
!AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
!LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
!OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
!SOFTWARE.

  MAP 
    MODULE('Win32')
      maf_EnableWindow(UNSIGNED,BOOL),BOOL,PASCAL,PROC,NAME('EnableWindow')
      maf_OutputDebugString(*CSTRING cstr),PASCAL,RAW,NAME('OutputDebugStringA')      
      maf_Sleep(LONG milliseconds),PASCAL,NAME('sleep')
    END
MiniAppFrameProc    PROCEDURE(STRING pShowFrame)
  END

  INCLUDE('cwsynchc.inc'),ONCE
  INCLUDE('FlatSerializer.inc'),ONCE

!Private global data
MiniAppFrame:cs     CriticalSection
MiniAppFrame:ThreadedVariable   LONG,THREAD
MiniAppFrame:MaxThreads EQUATE(500)

MiniAppFrameGlobal  GROUP
IsActive              BOOL
AppFrameStarted       LONG
AppFrameThread        LONG
ActiveThreads         LONG
Caller                UNSIGNED,DIM(MiniAppFrame:MaxThreads)
                    END

NOTIFY:maf_Destruct EQUATE(2001)

!Types
ValuesQueueType     QUEUE,TYPE
ValueNameUpper        STRING(60)
Value                 ANY
                    END

ValuesQueueCSClass  CLASS,TYPE
Store                 PROCEDURE(STRING pValueName,? pValue)
Retrieve              PROCEDURE(STRING pValueName),?
ClearQueue            PROCEDURE
Construct             PROCEDURE
Destruct              PROCEDURE
ValuesQueue           &ValuesQueueType,PRIVATE
cs                    &CriticalSection,PRIVATE
                    END


maf:ErrorNotInited  STRING('001InitCaller or InitChild must be called before accesing values')
maf:ErrorInitedAsCaller STRING('002Instance was initialized as Caller, cannot be initialized as Child')
maf:ErrorInitedAsChild  STRING('003Instance was initialized as Child, cannot be initialized as Caller or call Start()')
                      
MiniAppFrameClass.InitCaller    PROCEDURE
  CODE
  
  IF SELF.ChildInited THEN 
    SELF.RaiseError(maf:ErrorInitedAsChild)
    RETURN
  .
  SELF.CallerInited = TRUE  
  
  MiniAppFrameGlobal.IsActive = TRUE  
  CLEAR(SELF.NotifyCode)
  CLEAR(SELF.NotifyParameter)
  CLEAR(SELF.NotifyDelay)
  CLEAR(SELF.MaxExecutionTime)
  CLEAR(SELF.ShowFrame)
  CLEAR(SELF.ChildThread)
  SELF.SetupValuesQueueCS
  SELF.ClearValues
  
MiniAppFrameClass.InitChild PROCEDURE
ptr                           &POINTER_T
  CODE
  
  IF SELF.CallerInited THEN
    SELF.RaiseError(maf:ErrorInitedAsCaller)
    RETURN
  .
  
  IF INRANGE(THREAD(),1,MiniAppFrame:MaxThreads) AND |
      INSTANCE(SELF.ValuesQueueCSAddress, MiniAppFrameGlobal.Caller[THREAD()] )
    ptr &= INSTANCE(SELF.ValuesQueueCSAddress,MiniAppFrameGlobal.Caller[THREAD()])
    IF ptr
      SELF.ValuesQueueCSAddress = ptr
      SELF.ValuesQueueCS &= SELF.ValuesQueueCSAddress+0
      SELF.ChildInited = TRUE
      RETURN
    .
  .
  
  !Fallback strategy: wait for the caller to set the address variable
  LOOP
    IF SELF.ValuesQueueCSAddress
      SELF.ValuesQueueCS &= SELF.ValuesQueueCSAddress+0
      BREAK
    .
    SELF.Sleep(1) ! .01 Seconds
  .
  SELF.ChildInited = TRUE
  

MiniAppFrameClass.IsActive  PROCEDURE!,BOOL
  CODE
  
  RETURN MiniAppFrameGlobal.IsActive

MiniAppFrameClass.StoreValue    PROCEDURE(STRING pValueName,? pValue)
  CODE  
  
  IF NOT (SELF.CallerInited OR SELF.ChildInited)
    SELF.RaiseError(maf:ErrorNotInited)
    RETURN
  .
  IF SELF.ValuesQueueCS &= NULL THEN RETURN.
  SELF.ValuesQueueCS.Store(pValueName,pValue)
      
MiniAppFrameClass.RetrieveValue PROCEDURE(STRING pValueName)!,?
  CODE

  IF NOT (SELF.CallerInited OR SELF.ChildInited)
    SELF.RaiseError(maf:ErrorNotInited)
    RETURN ''
  .
  IF SELF.ValuesQueueCS &= NULL
    RETURN ''
  .
  RETURN SELF.ValuesQueueCS.Retrieve(pValueName)

MiniAppFrameClass.SetValue  PROCEDURE(STRING pValueName,? pValue)
  CODE  
  
  SELF.StoreValue(pValueName,pValue)
        
MiniAppFrameClass.GetValue  PROCEDURE(STRING pValueName)!,?
  CODE
  
  RETURN SELF.RetrieveValue(pValueName)

MiniAppFrameClass.ClearValues   PROCEDURE
idx                               LONG
  CODE  
  
  IF NOT (SELF.CallerInited OR SELF.ChildInited)
    SELF.RaiseError(maf:ErrorNotInited)
    RETURN
  .
  IF SELF.ValuesQueueCS &= NULL THEN RETURN.
  SELF.ValuesQueueCS.ClearQueue
  
MiniAppFrameClass.StoreGroupValues  PROCEDURE(*GROUP pGroup)
fs                                    FlatSerializer
idx                                   LONG
  CODE
  fs.InitTSV
  fs.SetAlwaysQuoteStrings(FALSE)  
  fs.LoadString(fs.SerializeGroup(pGroup))  
  LOOP idx = 1 TO fs.GetColumnsCount()
    SELF.StoreValue( |
        fs.GetColumnName(idx), |
        fs.GetValueByName(fs.GetColumnName(idx)) |
        )
  .

MiniAppFrameClass.StoreGroup    PROCEDURE(STRING pValueName,*GROUP pGroup)
fs                                FlatSerializer
  CODE
  fs.InitTSV
  fs.SetAlwaysQuoteStrings(FALSE)  
  SELF.StoreValue(pValueName,fs.SerializeGroup(pGroup))
  
MiniAppFrameClass.RetrieveGroup PROCEDURE(STRING pValueName,*GROUP pGroup)
fs                                FlatSerializer
  CODE
  fs.InitTSV
  fs.LoadString(SELF.RetrieveValue(pValueName))
  fs.DeSerializeToGroup(pGroup)

MiniAppFrameClass.StoreQueue    PROCEDURE(STRING pValueName,*QUEUE pQueue)
fs                                FlatSerializer
  CODE
  fs.InitTSV
  fs.SetAlwaysQuoteStrings(FALSE)  
  SELF.StoreValue(pValueName,fs.SerializeQueue(pQueue))
  
MiniAppFrameClass.RetrieveQueue PROCEDURE(STRING pValueName,*QUEUE pQueue)
fs                                FlatSerializer
  CODE    
  fs.InitTSV
  fs.LoadString(SELF.RetrieveValue(pValueName))
  fs.DeSerializeToQueue(pQueue)
  
MiniAppFrameClass.Start PROCEDURE(MAF_PROC procName,UNSIGNED stack=0)
  CODE
  
  IF SELF.ChildInited THEN 
    SELF.RaiseError(maf:ErrorInitedAsChild)
    RETURN
  .
  MiniAppFrameGlobal.IsActive = TRUE  
  SELF.SetupValuesQueueCS
  SELF.VerifyAppFrame
  SELF.IncrementActiveThreads
  SELF.ChildThread = START(procName,stack)
  SELF.WaitForChildThread
  SELF.DecrementActiveThreads
  
MiniAppFrameClass.Start PROCEDURE(MAF_PROC1 procName,UNSIGNED stack=0,STRING passedValue)
  CODE  
  
  IF SELF.ChildInited THEN 
    SELF.RaiseError(maf:ErrorInitedAsChild)
    RETURN
  .
  MiniAppFrameGlobal.IsActive = TRUE  
  SELF.SetupValuesQueueCS
  SELF.VerifyAppFrame
  SELF.IncrementActiveThreads
  SELF.ChildThread = START(procName,stack,passedValue)
  SELF.WaitForChildThread
  SELF.DecrementActiveThreads
  
MiniAppFrameClass.Start PROCEDURE(MAF_PROC2 procName,UNSIGNED stack=0,STRING passedValue1,STRING passedValue2)
  CODE
  
  IF SELF.ChildInited THEN 
    SELF.RaiseError(maf:ErrorInitedAsChild)
    RETURN
  .
  MiniAppFrameGlobal.IsActive = TRUE  
  SELF.SetupValuesQueueCS
  SELF.VerifyAppFrame
  SELF.IncrementActiveThreads
  SELF.ChildThread = START(procName,stack,passedValue1,passedValue2)
  SELF.WaitForChildThread
  SELF.DecrementActiveThreads

MiniAppFrameClass.Start PROCEDURE(MAF_PROC3 procName,UNSIGNED stack=0,STRING passedValue1,STRING passedValue2,STRING passedValue3)
  CODE
  
  IF SELF.ChildInited THEN 
    SELF.RaiseError(maf:ErrorInitedAsChild)
    RETURN
  .
  MiniAppFrameGlobal.IsActive = TRUE  
  SELF.SetupValuesQueueCS
  SELF.VerifyAppFrame  
  SELF.IncrementActiveThreads
  SELF.ChildThread = START(procName,stack,passedValue1,passedValue2,passedValue3)
  SELF.WaitForChildThread
  SELF.DecrementActiveThreads
  
MiniAppFrameClass.GetActiveThreads  PROCEDURE()!,LONG
  CODE
  
  RETURN MiniAppFrameGlobal.ActiveThreads
  
MiniAppFrameClass.Sleep PROCEDURE(LONG pHundrethsSecond)
  CODE
  
  maf_Sleep(pHundrethsSecond*10) !Convert to milliseconds
  
MiniAppFrameClass.Kill  PROCEDURE
  CODE
  
  IF MiniAppFrameGlobal.AppFrameThread
    NOTIFY(NOTIFY:maf_Destruct,MiniAppFrameGlobal.AppFrameThread)
  .    

MiniAppFrameClass.RaiseError    PROCEDURE(LONG pErrorNumber,STRING pErrorText)!,VIRTUAL                          
  CODE
  
  STOP(pErrorText&' ('&pErrorNumber&')')  

MiniAppFrameClass.Notify    PROCEDURE(UNSIGNED notifyCode,LONG parameter=0)  
  CODE
  
  SELF.NotifyCode = notifyCode
  SELF.NotifyParameter = parameter

MiniAppFrameClass.SetNotifyDelay    PROCEDURE(LONG pHundrethsSecond)
  CODE
  
  SELF.NotifyDelay = pHundrethsSecond
  
MiniAppFrameClass.SetMaxExecutionTime   PROCEDURE(LONG pHundrethsSecond)
  CODE
  
  SELF.MaxExecutionTime = pHundrethsSecond
  
MiniAppFrameClass.VerifyAppFrame    PROCEDURE!,PRIVATE
  CODE
  
  IF MiniAppFrameGlobal.AppFrameThread THEN RETURN.
  MiniAppFrame:cs.Wait
  IF NOT MiniAppFrameGlobal.AppFrameStarted
    MiniAppFrameGlobal.AppFrameStarted = 1
    MiniAppFrame:cs.Release    

    RESUME(START(MiniAppFrameProc,,SELF.ShowFrame))  

  ELSE
    MiniAppFrame:cs.Release    
  .  
  LOOP
    IF MiniAppFrameGlobal.AppFrameThread THEN BREAK.
    SELF.Sleep(1) ! .01 seconds
  .

MiniAppFrameClass.WaitForChildThread    PROCEDURE!,PRIVATE
MiniAppFrameWindow                        WINDOW,AT(,,180,15),SYSTEM,MDI,TIMER(10)
                                          END
setupDone                                 LONG
startTime                                 LONG
elapsedTime                               LONG
notifCode                                 LONG
notifThread                               LONG
  CODE

  IF INRANGE(SELF.ChildThread,1,MiniAppFrame:MaxThreads)
    MiniAppFrameGlobal.Caller[SELF.ChildThread] = THREAD()
  .    

  OPEN(MiniAppFrameWindow)
  IF SELF.ShowFrame
    MiniAppFrameWindow{PROP:Text} = 'Thr:'&THREAD()&' MxT:'&SELF.MaxExecutionTime&' NotC:'&SELF.NotifyCode&' NotP:'&SELF.NotifyParameter&' NotD:'&SELF.NotifyDelay
    DISPLAY
  ELSE
    MiniAppFrameWindow{PROP:Hide} = TRUE
    maf_EnableWindow(MiniAppFrameWindow{PROP:Handle},0)
  .
  
  startTime = CLOCK()
  ACCEPT
    IF NOT setupDone
      IF SELF.ChildThread AND INSTANCE(MiniAppFrame:ThreadedVariable,SELF.ChildThread)
        IF SELF.SetupChildThread()
          setupDone = 1
        .        
      .      
    .
    CASE EVENT()
      OF EVENT:CloseWindow
        CYCLE
      OF EVENT:Timer
        elapsedTime = CLOCK() - startTime
        IF elapsedTime < 0
          elapsedTime += 24*60*60*100
        .        
        IF SELF.MaxExecutionTime AND elapsedTime > SELF.MaxExecutionTime
          POST(EVENT:CloseDown,SELF.ChildThread)
          SELF.MaxExecutionTime = 0
        .        
        IF SELF.NotifyCode AND elapsedTime > SELF.NotifyDelay
          IF INSTANCE(MiniAppFrame:ThreadedVariable,SELF.ChildThread)
            NOTIFY(SELF.NotifyCode,SELF.ChildThread,SELF.NotifyParameter)
            SELF.NotifyCode = 0
            SELF.NotifyParameter = 0
          .          
        .          
        IF setupDone AND NOT INSTANCE(MiniAppFrame:ThreadedVariable,SELF.ChildThread)
          !Fallback strategy: if there is no instance of the variable, the tread no longer exists
          BREAK
        .
      OF EVENT:Notify
        IF NOTIFICATION(notifCode,notifThread)
          IF notifCode = NOTIFY:maf_Destruct AND notifThread = SELF.ChildThread
            BREAK
          .
        .        
    .
  END
  CLOSE(MiniAppFrameWindow)
  SELF.ChildThread = 0
  
MiniAppFrameClass.SetUpChildThread  PROCEDURE
ptr                                   &POINTER_T
  CODE
  
  IF SELF.ValuesQueueCSOwner AND SELF.ChildThread
    IF INSTANCE(SELF.ValuesQueueCSAddress,SELF.ChildThread) !Check if child thread is running
      !Fallback strategy: set the address variable in case the child can't get its parent instance
      ptr &= INSTANCE(SELF.ValuesQueueCSAddress,SELF.ChildThread) !Get child thread's address of ValuesQueueCSAddress 
      IF ptr !Child alread got address
        RETURN TRUE 
      .      
      ptr =  INSTANCE(SELF.ValuesQueueCS,THREAD())                !Set child thread's ValuesQueueCSAddress value to address of this thread's ValuesQueueCS
      RETURN TRUE !The child thread is ready and running
    .
  .    
  RETURN FALSE
  
MiniAppFrameClass.IncrementActiveThreads    PROCEDURE!,PRIVATE
  CODE
  
  MiniAppFrame:cs.Wait
  MiniAppFrameGlobal.ActiveThreads += 1
  MiniAppFrame:cs.Release
  
MiniAppFrameClass.DecrementActiveThreads    PROCEDURE!,PRIVATE
  CODE
  
  MiniAppFrame:cs.Wait
  MiniAppFrameGlobal.ActiveThreads -= 1
  MiniAppFrame:cs.Release
 
MiniAppFrameClass.SetupValuesQueueCS    PROCEDURE!,PRIVATE
  CODE
  
  IF NOT SELF.ValuesQueueCS &= NULL THEN RETURN.
  SELF.ValuesQueueCS &= NEW ValuesQueueCsClass
  SELF.ValuesQueueCSAddress = INSTANCE(SELF.ValuesQueueCS,THREAD())  
  SELF.ValuesQueueCSOwner = TRUE
  
MiniAppFrameClass.Destruct  PROCEDURE
  CODE
  
  IF SELF.ValuesQueueCSOwner
    DISPOSE(SELF.ValuesQueueCS)
  . 
  IF INRANGE(THREAD(),1,MiniAppFrame:MaxThreads)
    NOTIFY(NOTIFY:maf_Destruct,MiniAppFrameGlobal.Caller[THREAD()])
  .  

MiniAppFrameClass.SetShowFrame  PROCEDURE(BOOL pShowFrame)
  CODE
  
  SELF.ShowFrame = pShowFrame

MiniAppFrameClass.DebugView PROCEDURE(STRING pStr)
pre                           STRING('maf')
lcstr                         CSTRING(SIZE(pre)+SIZE(pStr)+21)
  CODE
  
  lcstr = pre&'|Thread:'&THREAD()&'|'&pStr&'|'
  maf_OutputDebugString(lcstr)  
  
MiniAppFrameClass.RaiseError    PROCEDURE(STRING pError)!,PRIVATE
  CODE
  SELF.RaiseError( pError[1 : 3] , pError[4 : SIZE(pError) ] )
  
ValuesQueueCsClass.Store    PROCEDURE(STRING pValueName,? pValue)
  CODE
  
  IF SELF.ValuesQueue &= NULL THEN RETURN.
  SELF.cs.Wait
  CLEAR(SELF.ValuesQueue)
  SELF.ValuesQueue.ValueNameUpper = UPPER(pValueName)
  GET(SELF.ValuesQueue,SELF.ValuesQueue.ValueNameUpper)
  IF ERRORCODE() THEN ADD(SELF.ValuesQueue).
  SELF.ValuesQueue.Value &= NULL !Reset ANY type
  SELF.ValuesQueue.Value = pValue 
  PUT(SELF.ValuesQueue)
  SELF.cs.Release

ValuesQueueCsClass.Retrieve PROCEDURE(STRING pValueName)!,?
value                         ANY
  CODE
  
  IF SELF.ValuesQueue &= NULL THEN RETURN ''.
  SELF.cs.Wait
  CLEAR(SELF.ValuesQueue)
  SELF.ValuesQueue.ValueNameUpper = UPPER(pValueName)
  GET(SELF.ValuesQueue,SELF.ValuesQueue.ValueNameUpper)
  IF ERRORCODE() THEN
    SELF.cs.Release
    RETURN ''
  .
  value = SELF.ValuesQueue.Value
  SELF.cs.Release
  RETURN value
  
ValuesQueueCsClass.ClearQueue   PROCEDURE
idx                               LONG
  CODE
  
  IF SELF.ValuesQueue &= NULL THEN RETURN.
  SELF.cs.Wait
  LOOP idx = RECORDS(SELF.ValuesQueue) TO 1 BY -1
    GET(SELF.ValuesQueue,idx)
    SELF.ValuesQueue.Value &= NULL
    DELETE(SELF.ValuesQueue)
  .
  SELF.cs.Release

ValuesQueueCsClass.Construct    PROCEDURE
  CODE
  
  SELF.ValuesQueue &= NEW ValuesQueueType
  SELF.cs &= NEW CriticalSection  
    
ValuesQueueCsClass.Destruct PROCEDURE
  CODE

  SELF.ClearQueue
  DISPOSE(SELF.ValuesQueue)
  DISPOSE(SELF.cs)

MiniAppFrameProc    PROCEDURE(STRING pShowFrame)
MiniAppFrameFrame     APPLICATION,AT(,,400,200),SYSTEM,TIMER(10)
                      END
notifCode             LONG
  CODE  
  
  OPEN(MiniAppFrameFrame)
  IF pShowFrame = TRUE 
    MiniAppFrameFrame{PROP:Text} = 'Thr:'&THREAD()
    DISPLAY
  ELSE    
    MiniAppFrameFrame{PROP:Hide} = TRUE
    maf_EnableWindow(MiniAppFrameFrame{PROP:Handle},0)
  .
  ACCEPT
    CASE EVENT()
      OF EVENT:OpenWindow
        MiniAppFrameGlobal.AppFrameThread = THREAD()
      OF EVENT:CloseWindow
        CYCLE
      OF EVENT:Notify
        IF NOTIFICATION(notifCode) AND notifCode = NOTIFY:maf_Destruct
          BREAK
        .        
    .    
  END    
  
