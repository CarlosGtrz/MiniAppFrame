# Mini App Frame
A class for calling MDI processes from programs without an `APPLICATION` frame, for example, from [Nettalk Web Services](https://www.capesoft.com/docs/NetTalk10/NetTalkWebServices.htm).

## *Introduction*

This class was created to call processes that run as MDI windows from Nettalk Web Services. It starts the MDI processes in a new thread, and waits for the tread to end. It also creates a background app frame.

Clarion structures and single values can be exchanged between the calling thread and the child thread using a value storage object. This object is shared only by the caller and child threads, and use a critical section to be thread safe.

Example:
```
!In the web service
!Data
WebServiceRequestGroup GROUP
ClientNumber   LONG
StartDate      DATE
EndDate        DATE
             END

ServiceMethod  routine
  MiniAppFrame.InitCaller
  MiniAppFrame.StoreGroupValues(WebServiceRequestGroup)
  MiniAppFrame.Start(SomeMdiProcess) !Calls SomeMdiProcess in a new thread and waits for it to finish
  MiniAppFrame.RetrieveQueue('Result',WebServiceResultQueue)  
  
!In the called MDI Proccess
!  OF EVENT:OpenWindow (or where appropriate)
  IF MiniAppFrame.IsActive()
    MiniAppFrame.InitChild
    LOC:ClientNumber = MiniAppFrame.GetValue('ClientNumber')
    LOC:StartDate    = MiniAppFrame.GetValue('StartDate')
    LOC:EndDate      = MiniAppFrame.GetValue('EndDate')
    POST(EVENT:Accepted,?StartButton)
  END

!ThisWindow.Kill (or where appropriate)
  IF MiniAppFrame.IsActive()
    MiniAppFrame.SetValue('Total',LOC:Total)
    MiniAppFrame.StoreQueue('Result',SomeQueue)
  END
```

## *Install*
Copy `MiniAppFrame.inc` and `MiniAppFrame.clw` to a folder where Clarion looks for ABC complaint classes, like `Accessory\libsrc\win`.

Files `FlatSerializer.inc` and `FlatSerializer.clw` (available [here](https://github.com/CarlosGtrz/FlatSerializer)) should also be in a folder visible to the .red file, also like `Accessory\libsrc\win`.

## *Use*

In your `data.dll`, declare and export the global threaded object in an embed like `After Global Includes`:

```
INCLUDE('MiniAppFrame.inc'),ONCE
MiniAppFrame        MiniAppFrameClass,THREAD,EXPORT 
```

In all APPs using it, and the Nettalk EXE, import the global threaded object in an embed like `After Global Includes`:
```
INCLUDE('MiniAppFrame.inc'),ONCE
MiniAppFrame        MiniAppFrameClass,THREAD,EXTERNAL,DLL(DLL_MODE)
```

In the Nettalk EXE, in the WebServer procedure, close the  background app frame in an embed like `ThisWindow.Kill`:

```
  MiniAppFrame.Kill 
```

## *Methods*

## Initialization

```
InitCaller
```
Must be called once from the caller thread to setup the value storage object.

```
InitChild
```
Must be called once from the child thread to wait for the value storage object to be available.

```
IsActive,BOOL
```
Returns TRUE when `InitCaller` or `Start` has been called. Child thread should do the Web Service specific work when this flag is true.


## Value Exchange

```
StoreValue(STRING pValueName,? pValue)
```
Stores a value in the value storage object.  

*Parameters*
* pValueName: String to use as name to retrieve the value later
* pValue: Variable with the value to store

```
RetrieveValue(STRING pValueName),?
```
Retrieves a value from the value storage object.  

*Parameter*
* pValueName: String to use as name to retrieve the value

```
SetValue(STRING pValueName,? pValue)
GetValue(STRING pValueName),?
```
Short names for `StoreValue` and `RetrieveValue`.


```
ClearValues
```
Deletes all values in the value storage object.

```
StoreGroupValues(*GROUP pGroup)
```
Stores each field of the group in the value storage object.  

*Parameter*
* pGroup: Group with fields to store

```
StoreGroup(STRING pValueName,*GROUP pGroup)
StoreQueue(STRING pValueName,*QUEUE pQueue)
RetrieveGroup(STRING pValueName,*GROUP pGroup)
RetrieveQueue(STRING pValueName,*QUEUE pQueue)
```
Store and retrieve a Clarion group or queue structure as a single value in the value storage object. The structure is stored as a TSV (Tab Separated Value) string using [FlatSerializer](https://github.com/CarlosGtrz/FlatSerializer).

## Start MDI processes

```
Start(MAF_PROC procName,UNSIGNED stack=0)
Start(MAF_PROC1 procName,UNSIGNED stack=0,STRING passedValue)
Start(MAF_PROC2 procName,UNSIGNED stack=0,STRING passedValue1,STRING passedValue2)
Start(MAF_PROC3 procName,UNSIGNED stack=0,STRING passedValue1,STRING passedValue2,STRING passedValue3)
```
Starts a procedure as a new MDI thread and, unlike `START`, waits for it to finish.  

*Parameters*
* procName: Name of the procedure to start
* stack: stack parameter for `START`
* passedValue: Strings to be passed to the procedure, same usage as `START`

## Thread monitoring

```
GetActiveThreads(),LONG
```
Can be used to monitor if there are still threads running.

```
Kill
```
Posts `EVENT:CloseDown` to the thread running the background app frame.

Example:
```
  !Before ending EXE
  LOOP
    IF NOT MiniAppFrame.GetActiveThreads() THEN BREAK.
    MiniAppFrame.Sleep(100) !1 second
  .
  MiniAppFrame.Kill
```

## Error Handling

```
RaiseError(LONG pErrorNumber,STRING pErrorText),VIRTUAL
```
Called when there is an error. By default calls `STOP` to show the error, but can be derived to change this behavior.

Posible errors:

|#|Label|Text|
|-|:-|:-|
|1|maf:ErrorNotInited|InitCaller or InitChild must be called before accesing values|
|2|maf:ErrorInitedAsCaller|Instance was initialized as Caller, cannot be initialized as Child|
|3|maf:ErrorInitedAsChild|Instance was initialized as Child, cannot be initialized as Caller or call Start()|

## Utility
```
Sleep(LONG pHundrethsSecond)
```
Suspends de execution of the current thread for the specified time.

```
DebugView (STRING pStr)
```
Writes a string to the debug output. The debug output will contain the prefix `maf` and the thread number.

## Notify

These methods are not recommended. The notification is lost if posted before the child thread's `ACCEPT` loop is ready.

```
Notify(UNSIGNED notifyCode,LONG parameter=0)
```
Sets the notification to be sent when the child thread is started. Same parameters as `NOTIFY`.

```
SetNotifyDelay(LONG pHundrethsSecond)
```
Sets how long to wait for the child thread to be ready before sending the notification.

```
SetMaxExecutionTime(LONG pHundrethsSecond)
```
Sets how long to wait for the child thread to finish processing, in case the notification is lost.

