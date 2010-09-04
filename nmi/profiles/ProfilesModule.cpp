
#include "NativeModule.h"
#include <mproengengine.h>
#include <proengfactory.h>
#include <mproengprofilenamearray.h>
#include <mproengprofilename.h>
#include <mproengprofile.h>
#include <mproengtones.h>
#include <mproengtonesettings.h>

_LIT(ID,"id");
_LIT(NAME,"name");
_LIT(RINGTYPE,"ringtype");
_LIT(RINGVOLUME,"ringvolume");
_LIT(KEYVOLUME,"keyvolume");
_LIT(VIBRA,"vibra");
_LIT(SILENT,"silent");
_LIT(RINGTONE,"ringtone");
_LIT(RINGTONE2,"ringtone2");
_LIT(MSGTONE,"msgtone");
_LIT(EMAILTONE,"emailtone");
_LIT(VIDEOTONE,"videotone");
_LIT(WARNTONES,"warntones");
_LIT(TTS,"tts");
_LIT(GROUPIDS,"groupids");

class ProfilesModule : public NativeModule {
private:
  enum {
    ActiveFunction, ListFunction, GetFunction, SetFunction
  };

  Runtime::Value GetProfileDataL(MProEngProfile* profile) {
    Runtime::Value result;
    Runtime::Array *array;
    result = runtime->NewArrayL(array, 15);

    MProEngTones& tones = profile->ProfileTones();
    MProEngToneSettings& toneSettings = profile->ToneSettings();

    array->SetL(ID, profile->ProfileName().Id());
    array->SetL(NAME, runtime->NewStringL(profile->ProfileName().Name()));

    array->SetL(RINGTYPE, toneSettings.RingingType());
    array->SetL(RINGVOLUME, toneSettings.RingingVolume());
    array->SetL(KEYVOLUME, toneSettings.KeypadVolume());
    array->SetL(VIBRA, Runtime::BooleanValue(toneSettings.VibratingAlert()));
    array->SetL(SILENT, Runtime::BooleanValue(profile->IsSilent()));
    array->SetL(RINGTONE, runtime->NewStringL(tones.RingingTone1()));
    array->SetL(RINGTONE2, runtime->NewStringL(tones.RingingTone2()));
    array->SetL(MSGTONE, runtime->NewStringL(tones.MessageAlertTone()));
    array->SetL(EMAILTONE, runtime->NewStringL(tones.EmailAlertTone()));
    array->SetL(VIDEOTONE, runtime->NewStringL(tones.VideoCallRingingTone()));
    array->SetL(WARNTONES, Runtime::BooleanValue(toneSettings.WarningAndGameTones()));
    array->SetL(TTS, Runtime::BooleanValue(toneSettings.TextToSpeech()));
    
    // doh.. is there a simpler way to get the array elements?
    TArray<TContactItemId> alertIds = profile->AlertForL();
    Runtime::Value x;
    Runtime::Array* xx;
    x = runtime->NewArrayL(xx, alertIds.Count());
    Runtime::ValueArray &xxx = xx->GetValues();
    for (TInt i = 0; i < alertIds.Count(); i++) {
      xxx.SetNumberL(i, alertIds[i]);
    }
    array->SetL(GROUPIDS, x);
    return result;
  }
  
  void SetProfileDataL(MProEngProfile* profile, Runtime::Array newData) {
    if(newData.Length() > 0) {
      if(newData.GetIndex(NAME) != -1) {
        profile->ProfileName().SetNameL(newData.GetL(NAME).GetPtrCL());
      }
      if(newData.GetIndex(RINGTYPE) != -1) {
        profile->ToneSettings().SetRingingType((TProfileRingingType)newData.GetL(RINGTYPE).GetIntL());
      }
      if(newData.GetIndex(RINGVOLUME) != -1) {
        profile->ToneSettings().SetRingingVolume((TProfileRingingVolume)newData.GetL(RINGVOLUME).GetIntL());
      }
      if(newData.GetIndex(KEYVOLUME) != -1) {
        profile->ToneSettings().SetKeypadVolume((TProfileKeypadVolume)newData.GetL(KEYVOLUME).GetIntL());
      }
      if(newData.GetIndex(VIBRA) != -1) {
        profile->ToneSettings().SetVibratingAlert(newData.GetL(VIBRA).GetBooleanL());
      }
      if(newData.GetIndex(RINGTONE) != -1) {
        profile->ProfileTones().SetRingingTone1L(newData.GetL(RINGTONE).GetPtrCL());
      }
      if(newData.GetIndex(RINGTONE2) != -1) {
        profile->ProfileTones().SetRingingTone2L(newData.GetL(RINGTONE2).GetPtrCL());
      }
      if(newData.GetIndex(MSGTONE) != -1) {
        profile->ProfileTones().SetMessageAlertToneL(newData.GetL(MSGTONE).GetPtrCL());
      }
      if(newData.GetIndex(EMAILTONE) != -1) {
        profile->ProfileTones().SetEmailAlertToneL(newData.GetL(EMAILTONE).GetPtrCL());
      }
      if(newData.GetIndex(VIDEOTONE) != -1) {
        profile->ProfileTones().SetVideoCallRingingToneL(newData.GetL(VIDEOTONE).GetPtrCL());
      }
      if(newData.GetIndex(WARNTONES) != -1) {
        profile->ToneSettings().SetWarningAndGameTones(newData.GetL(WARNTONES).GetBooleanL());
      }
      if(newData.GetIndex(TTS) != -1) {
        profile->ToneSettings().SetTextToSpeech(newData.GetL(TTS).GetBooleanL());
      }
      if(newData.GetIndex(GROUPIDS) != -1) {
        Runtime::Array inArray = newData.GetL(GROUPIDS).GetArrayL();
        
        CArrayFixFlat<TContactItemId>* array = new(ELeave)CArrayFixFlat<TContactItemId>(inArray.Length()+1);
        CleanupStack::PushL(array);
        for (TInt i = 0; i < inArray.Length(); i++) {
          array->AppendL((TContactItemId)inArray.GetL(i).GetIntL());
        }
        profile->SetAlertForL(array->Array());
        CleanupStack::PopAndDestroy(1); //array
      }
      profile->CommitChangeL();
    }
  }

protected:
  TInt ExpectedRuntimeVersion() { 
    return Runtime::VERSION; 
  }

  void ConstructL() {
    runtime->AddNativeFunctionL(_L("list"), 0, 0, ListFunction);
    runtime->AddNativeFunctionL(_L("active"), 0, 1, ActiveFunction);
    runtime->AddNativeFunctionL(_L("get"), 0, 1, GetFunction);
    runtime->AddNativeFunctionL(_L("set"), 1, 2, SetFunction);
    
    runtime->AddConstantL(_L("default"), EProfileGeneralId);
    runtime->AddConstantL(_L("silent"), EProfileSilentId);
    runtime->AddConstantL(_L("meeting"), EProfileMeetingId);
    runtime->AddConstantL(_L("outdoor"), EProfileOutdoorId);
    runtime->AddConstantL(_L("pager"), EProfilePagerId);
    runtime->AddConstantL(_L("offline"), EProfileOffLineId);
    runtime->AddConstantL(_L("drive"), EProfileDriveId);

    runtime->AddConstantL(_L("ringNormal"), EProfileRingingTypeRinging);
    runtime->AddConstantL(_L("ringAscending"), EProfileRingingTypeAscending);
    runtime->AddConstantL(_L("ringOnce"), EProfileRingingTypeRingingOnce);
    runtime->AddConstantL(_L("ringBeep"), EProfileRingingTypeBeepOnce);
    runtime->AddConstantL(_L("ringSilent"), EProfileRingingTypeSilent);
  }

  Runtime::Value ExecuteL(TInt index, Runtime::Value *params,
                          TInt paramCount, TRequestStatus &status) {
    runtime->CheckPermissionL(ReadAppPermission);
    
    MProEngEngine* engine = ProEngFactory::NewEngineLC();
    
    Runtime::Value result;
    MProEngProfile* profile;

    switch (index) {
      case ListFunction:
      {
        MProEngProfileNameArray* profileNames(engine->ProfileNameArrayLC());

        Runtime::Array *array;
        result = runtime->NewArrayL(array, profileNames->MdcaCount());
        for (TInt i = 0; i < profileNames->MdcaCount(); i++) {
          array->SetL(runtime->NewStringL(profileNames->MdcaPoint(i)), profileNames->ProfileId(i));
        }
        
        CleanupStack::PopAndDestroy(1); //profileNames
        break;
      }
      case ActiveFunction:
        result.SetNumber(engine->ActiveProfileId());
        
        if (paramCount > 0 && !params[0].IsNull()) {
          runtime->CheckPermissionL(WriteAppPermission);
          engine->SetActiveProfileL(params[0].GetIntL());
        }
        break;
        
      case GetFunction:
        if (paramCount > 0 && !params[0].IsNull()) {  
          profile=engine->ProfileLC(params[0].GetIntL());
        }
        else {
          profile=engine->ActiveProfileLC();
        }
        result = GetProfileDataL(profile);      
        CleanupStack::PopAndDestroy(1); //profile
      break;
    
      case SetFunction:
        runtime->CheckPermissionL(WriteAppPermission);
        if (paramCount > 1 && !params[1].IsNull()) {  
          profile=engine->ProfileLC(params[1].GetIntL());
        }
        else {
          profile=engine->ActiveProfileLC();
        }
        SetProfileDataL(profile, params[0].GetArrayL());
        
        result.SetNull();
        CleanupStack::PopAndDestroy(1); //profile
      break;
    }
    CleanupStack::PopAndDestroy(1); // engine
    return result;
  }
};

EXPORT_C NativeModule* NewProfilesModuleL() {
 return new (ELeave) ProfilesModule;
}

#ifndef EKA2
GLDEF_C TInt E32Dll(TDllReason) {
 return KErrNone; 
}
#endif
