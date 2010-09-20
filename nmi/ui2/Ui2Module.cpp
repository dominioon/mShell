
#include "NativeModule.h"
#include <aknnotewrappers.h>
#include <aknnotedialog.h>


class Ui2Module : public NativeModule {
private:
  enum {
    MsgFunction, InfoFunction, WarningFunction, ErrorFunction
  };

protected:
  const char *ModuleVersion() { 
    return "2.0"; 
  }

  TInt ExpectedRuntimeVersion() { 
    return Runtime::VERSION; 
  }

  void ConstructL() {
    runtime->AddNativeFunctionL(_L("msg"), 1, 2, MsgFunction);
    runtime->AddNativeFunctionL(_L("info"), 1, 2, InfoFunction);
    runtime->AddNativeFunctionL(_L("warning"), 1, 2, WarningFunction);
    runtime->AddNativeFunctionL(_L("error"), 1, 2, ErrorFunction);
    
#ifdef EKA2
    runtime->AddConstantL(_L("shortesttimeout"), CAknNoteDialog::EShortestTimeout);
#else
    runtime->AddConstantL(_L("shortesttimeout"), 500000); // no const CAknNoteDialog::EShortestTimeout in S60v2
#endif
    runtime->AddConstantL(_L("shorttimeout"), CAknNoteDialog::EShortTimeout);
    runtime->AddConstantL(_L("longtimeout"), CAknNoteDialog::ELongTimeout);
    runtime->AddConstantL(_L("forever"), CAknNoteDialog::ENoTimeout);
  }

  Runtime::Value ExecuteL(TInt index, Runtime::Value *params,
                          TInt paramCount, TRequestStatus &status) {

    CAknResourceNoteDialog *dialog;
    switch (index) {
      case MsgFunction:
        dialog = new (ELeave) CAknConfirmationNote(ETrue);
        break;
      case InfoFunction:
        dialog = new (ELeave) CAknInformationNote(ETrue);
        break;
      case WarningFunction:
        dialog = new (ELeave) CAknWarningNote(ETrue);
        break;
      case ErrorFunction:
        dialog = new (ELeave) CAknErrorNote(ETrue);
        break;
    }
    TPtrC message(params[0].GetPtrCL());
    if (paramCount > 1 && !params[1].IsNull()) {
      dialog->SetTimeout((CAknNoteDialog::TTimeout)params[1].GetIntL());
    }
    dialog->ExecuteLD(message);
    
    return Runtime::NullValue();
  }
};

EXPORT_C NativeModule* NewUi2ModuleL() {
 return new (ELeave) Ui2Module;
}

#ifndef EKA2
GLDEF_C TInt E32Dll(TDllReason) {
 return KErrNone; 
}
#endif
