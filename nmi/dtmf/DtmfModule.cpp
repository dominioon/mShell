#include "NativeModule.h"
#include <e32base.h>
#include <Etel3rdParty.h>

class DtmfModule : public NativeModule {
private:
  enum {
    SendFunction
  };

  TBool isSendingDtmf;
  CTelephony* iTelephony;

  ~DtmfModule() {
    delete iTelephony;
  }

protected:
  TInt ExpectedRuntimeVersion() { 
    return Runtime::VERSION; 
  }

  void ConstructL() {
    runtime->AddNativeFunctionL(_L("send"), 1, 1, SendFunction);
  }
  
  Runtime::Value ExecuteL(TInt index, Runtime::Value *params,
                          TInt paramCount, TRequestStatus &status) {
    if(!iTelephony) {
      iTelephony = CTelephony::NewL();
    }

    Runtime::Value result;

    switch (index) {
      case SendFunction:
      {
        if (isSendingDtmf) {
          isSendingDtmf = EFalse;
          result.SetNull();
        }
        else {
          iTelephony->SendDTMFTones(status, params[0].GetPtrCL());
          isSendingDtmf = ETrue;
          result.SetUncomplete();
        }
        break;
      }
    }
    return result;
  }

  void Cancel() { 
    if(isSendingDtmf) {
      iTelephony->CancelAsync(CTelephony::ESendDTMFTonesCancel);
      isSendingDtmf = EFalse;
    }
  }
};

EXPORT_C NativeModule* NewDtmfModuleL() {
 return new (ELeave) DtmfModule;
}

#ifndef EKA2
GLDEF_C TInt E32Dll(TDllReason) {
 return KErrNone; 
}
#endif
