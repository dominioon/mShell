
#include "NativeModule.h"
#include <aknnotewrappers.h>
#include <aknnotedialog.h>

#include <AknQueryDialog.h>


class Ui2Module : public NativeModule {
private:
  enum {
    MsgFunction, InfoFunction, WarningFunction, ErrorFunction, 
    PhoneFunction, TimeFunction, DateFunction, DurationFunction
  };

  void ShowMessage(TInt index, Runtime::Value *params, TInt paramCount) {
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
  }
  
    Runtime::Value ShowDialog(TInt index, Runtime::Value *params, TInt paramCount) {
      Runtime::Value result = Runtime::NullValue();
      CAknQueryDialog *dialog;
      if (index == PhoneFunction) {
        TBuf<256> value1(paramCount > 1 ? params[1].GetPtrCL() : _L(""));
        dialog = CAknTextQueryDialog::NewL((TDes&)value1);
        dialog->SetPromptL(params[0].GetPtrCL());
        if (dialog->ExecuteLD(R_AVKON_DIALOG_QUERY_VALUE_PHONE)) result = runtime->NewStringL(value1);
      }
      else if(index == DateFunction) {
        TTime value2(paramCount > 1 ? params[1].GetTimeL() : 0);
        dialog = CAknTimeQueryDialog::NewL(value2);
        dialog->SetPromptL(params[0].GetPtrCL());
        if (dialog->ExecuteLD(R_AVKON_DIALOG_QUERY_VALUE_DATE)) result.SetTime(value2);
      }
      else if(index == TimeFunction) {
        TTime value3(paramCount > 1 ? params[1].GetTimeL() : 0);
        dialog = CAknTimeQueryDialog::NewL(value3);
        dialog->SetPromptL(params[0].GetPtrCL());
        if (dialog->ExecuteLD(R_AVKON_DIALOG_QUERY_VALUE_TIME)) result.SetTime(value3);
      }
      else if(index == DurationFunction) {
        TTimeIntervalSeconds value4(paramCount > 1 ? params[1].GetIntL()/1000 : 0);
        dialog = CAknDurationQueryDialog::NewL(value4);
        dialog->SetPromptL(params[0].GetPtrCL());
        if (dialog->ExecuteLD(R_AVKON_DIALOG_QUERY_VALUE_DURATION)) result.SetNumber(value4.Int()*1000);
      }
      return result;
    }

protected:
  const char *ModuleVersion() { 
    return "3.0"; 
  }

  TInt ExpectedRuntimeVersion() { 
    return Runtime::VERSION; 
  }

  void ConstructL() {
    runtime->AddNativeFunctionL(_L("msg"), 1, 2, MsgFunction);
    runtime->AddNativeFunctionL(_L("info"), 1, 2, InfoFunction);
    runtime->AddNativeFunctionL(_L("warning"), 1, 2, WarningFunction);
    runtime->AddNativeFunctionL(_L("error"), 1, 2, ErrorFunction);
    
    runtime->AddNativeFunctionL(_L("phone"), 1, 2, PhoneFunction);
    runtime->AddNativeFunctionL(_L("time"), 1, 2, TimeFunction);
    runtime->AddNativeFunctionL(_L("date"), 1, 2, DateFunction);
    runtime->AddNativeFunctionL(_L("duration"), 1, 2, DurationFunction);
    
#ifdef EKA2
    runtime->AddConstantL(_L("tiny"), CAknNoteDialog::EShortestTimeout);
#else
    runtime->AddConstantL(_L("tiny"), 500000); // no const CAknNoteDialog::EShortestTimeout in S60v2
#endif
    runtime->AddConstantL(_L("short"), CAknNoteDialog::EShortTimeout);
    runtime->AddConstantL(_L("long"), CAknNoteDialog::ELongTimeout);
    runtime->AddConstantL(_L("forever"), CAknNoteDialog::ENoTimeout);
  }

  Runtime::Value ExecuteL(TInt index, Runtime::Value *params,
                          TInt paramCount, TRequestStatus &status) {
    Runtime::Value result;

    switch (index) {
      case MsgFunction:
      case InfoFunction:
      case WarningFunction:
      case ErrorFunction:
        ShowMessage(index, params, paramCount);
        result.SetNull();
        break;
      
      case PhoneFunction:
      case TimeFunction:
      case DateFunction:
      case DurationFunction:
        result = ShowDialog(index, params, paramCount);
        break;
    }
    return result;
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
