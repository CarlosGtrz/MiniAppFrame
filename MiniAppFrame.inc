!ABCIncludeFile 
!!! <summary>
!!! Generated class template - SourceClass
!!! </summary>
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

MiniAppFrameClass   CLASS,MODULE('MiniAppFrame.clw'),LINK('MiniAppFrame.clw',_ABCLinkMode_),DLL(_ABCDllMode_),TYPE

InitCaller            PROCEDURE
InitChild             PROCEDURE

IsActive              PROCEDURE,BOOL

SetValue              PROCEDURE(STRING pValueName,? pValue)
GetValue              PROCEDURE(STRING pValueName),?

StoreValue            PROCEDURE(STRING pValueName,? pValue)
RetrieveValue         PROCEDURE(STRING pValueName),?
ClearValues           PROCEDURE

StoreGroupValues      PROCEDURE(*GROUP pGroup)
StoreGroup            PROCEDURE(STRING pValueName,*GROUP pGroup)
RetrieveGroup         PROCEDURE(STRING pValueName,*GROUP pGroup)
StoreQueue            PROCEDURE(STRING pValueName,*QUEUE pQueue)
RetrieveQueue         PROCEDURE(STRING pValueName,*QUEUE pQueue)

Start                 PROCEDURE(MAF_PROC procName,UNSIGNED stack=0)
Start                 PROCEDURE(MAF_PROC1 procName,UNSIGNED stack=0,STRING passedValue)
Start                 PROCEDURE(MAF_PROC2 procName,UNSIGNED stack=0,STRING passedValue1,STRING passedValue2)
Start                 PROCEDURE(MAF_PROC3 procName,UNSIGNED stack=0,STRING passedValue1,STRING passedValue2,STRING passedValue3)

GetActiveThreads      PROCEDURE(),LONG
Sleep                 PROCEDURE(LONG pHundrethsSecond)

Kill                  PROCEDURE

RaiseError            PROCEDURE(LONG pErrorNumber,STRING pErrorText),VIRTUAL                          

Notify                PROCEDURE(UNSIGNED notifyCode,LONG parameter=0)
SetNotifyDelay        PROCEDURE(LONG pHundrethsSecond)
SetMaxExecutionTime   PROCEDURE(LONG pHundrethsSecond)

VerifyAppFrame        PROCEDURE,PRIVATE
WaitForChildThread    PROCEDURE,PRIVATE
SetUpChildThread      PROCEDURE,BOOL,PRIVATE

IncrementActiveThreads    PROCEDURE,PRIVATE
DecrementActiveThreads    PROCEDURE,PRIVATE

SetupValuesQueueCS    PROCEDURE,PRIVATE

Destruct              PROCEDURE

SetShowFrame          PROCEDURE(BOOL pShowFrame)
DebugView             PROCEDURE(STRING pStr)

RaiseError            PROCEDURE(STRING pError),PRIVATE

NotifyCode            UNSIGNED,PRIVATE
NotifyParameter       UNSIGNED,PRIVATE
NotifyDelay           LONG,PRIVATE
MaxExecutionTime      LONG,PRIVATE
ShowFrame             BOOL,PRIVATE

ChildThread           SIGNED,PRIVATE
CallerInited          BOOL,PRIVATE
ChildInited           BOOL,PRIVATE
ValuesQueueCS         &ValuesQueueCSClass,PRIVATE
ValuesQueueCSAddress  POINTER_T,PRIVATE
ValuesQueueCSOwner    BOOL,PRIVATE
                    END

  MAP
    MAF_PROC(),TYPE
    MAF_PROC1(STRING),TYPE
    MAF_PROC2(STRING,STRING),TYPE
    MAF_PROC3(STRING,STRING,STRING),TYPE
  END
