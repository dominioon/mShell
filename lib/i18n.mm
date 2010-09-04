/*
  Internationalization support for M applications and modules. This module provides 
  the following features:
  <ul>
  <li>get the list of all languages found in the device via 
   {@link getAllLanguages()},</li>
  <li>automatic detection of the device language when the module is loaded,</li>
  <li>change the language for the M application via {@link setLanguage()},</li>
  <li>get language-specific labels via {@link label()} and {@link mlabel()},</li>
  <li>automatic <a href='#quantity'>quantity resolving</a> functionality 
   (eg '1 file', but '2 file<b>s</b>'),</li>
  <li><a href='#fallback'>language fallback</a> if the label is not found in the 
  required language.</li>
  </ul>
  <h4>Files to define labels</h4>
  Language-specific labels are stored in <b>.mlf</b> files (<i>M Language File</i>). 
  Every .mlf file is just a simple Properties file (see also {@link abprops}) 
  describing label keys (internal names) and their localized values. For better
  maintenance the language files are separated into modules (module may mean a 
  .mm file, your application or any other logical unit). The name of the .mlf 
  file must follow the format <i>moduleName.languageCode.mlf</i>. For common 
  labels (eg, the language name itself) a file with name <i>languageCode.mlf</i>
  is used. Language codes are in RFC 3066 style (eg, <i>en.mlf</i> for English 
  or <i>fr-ca.mlf</i> for Canadian French labels). See {@link langIdMap} in the
  module source or 
  <a href='http://www.i18nguy.com/unicode/language-identifiers.html' target='_blank'>this</a>
  link for different language codes. The .mlf files can reside in 
  the local folder <b>or in any library folder</b>.
  <br/>
  The language files must be in UTF8 BOM encoding. The common language file 
  (en.mlf, fr.mlf etc) must contain at least the label with id <b>lang_name</b>, 
  otherwise {@link getAllLanguages()} will not find that language.
  <br/>
  <h4><a name='fallback'>Label searching rules (fallback)</a></h4>
  The functions {@link label()} and {@link mlabel()} use the following pattern 
  to find the label:
  <ol>
  <li>the label is searched from the exact language file (eg, fr-ca.mlf),</li>
  <li>if not found, search from the main language file (eg, fr.mlf in this 
  example) occurs,</li>
  <li>if still not found, search from the base language file (en.mlf) occurs,</li>
  <li>if the label is not present even in en.mlf, label id is returned.</li>
  </ol>
  The same order is used when a module-specific label is searched 
  (eg myModule.fr-ca.mlf -> myModule.fr.mlf -> myModule.en.mlf -> labelid).
  <br/>
  Also, you can overwrite some or all labels (which already exist in a label file 
  in a lib path) within a file with the same name in your local folder. Ie, if a 
  file myModule.en.mlf exists in your lib path containing <i>foo=Foo</i> and 
  <i>bar=Bar</i>, and myModule.en.mlf also exists in the local folder containing 
  only <i>foo=MyFoo</i>, then i18n.mlabel('myModule','foo') will return 'MyFoo' 
  and i18n.mlabel('myModule','bar') will return 'Bar'.
  <br/>
  <h4><a name='quantity'>Quantity resolving</a></h4>
  Resolving quantity means choosing a different label depending on the quantity
  provided (eg, 'Delete 1 file?' vs 'Delete 7 files?'). Every language may
  have different rules for choosing the right label. For example, in English
  there are only 2 label types - first for the quantity of one item and another 
  for any other quantity of items. Both (or for example 3 for Lithuanian language)
  labels need to be declared in your language file, but with different sufixes.
  The sufixes are arbitrary and for English '.1' and '.2' are chosen. The '%d' 
  placeholder in the label will be replaced with the actual quantity. So in 
  this example, labels <i>delete.1=Delete %d file?</i> and 
  <i>delete.2=Delete %d files?</i> need to be created and then calling 
  i18n.label('delete', numOfFiles) will return the correct label.
  <br/>
  NB! The quantity resolvers are created only for the following languages at 
  the moment:
  <ul>
    <li>English</li>
    <li>German</li>
    <li>Russian</li>
    <li>Estonian</li>
    <li>Latvian</li>
    <li>Lithuanian</li>
  </ul>
  Please provide rules for other languages, too!
*/

use array, io, files, system, abprops as p

/* @internal */
const EXT='.mlf';
/* @internal */
const BASE_LANG='en';
/* @internal */
const LANG_NAME_PROPERTY='lang_name';

/* @internal */
function qr_special_1(q)
  if q=1 then return 1  
  else return 2 end
end

/* @internal */
function qr_ru(q)
  r=q%10;
  if r=0 or (q>=10 and q<=20) then return 5;
  elsif r=1 then return 1;
  elsif r=2 or r=3 or r=4 then  return 2;
  else return 5;
  end
end

/* @internal */
function qr_lt(q)
  r=q%10;
  if r=0 or (q>=10 and q<=20) then return 0;
  elsif r=1 then return 1;
  else return 2;
  end;
end

/* 
  Quantity resolvers for all languages (partial)
*/
quantityResolvers=[
  BASE_LANG:&qr_special_1,  // sufixes .1 and .2
  'de':&qr_special_1,       // sufixes .1 and .2
  'ru':&qr_ru,              // sufixes .1, .2 and .5
  'et':&qr_special_1,       // sufixes .1 and .2
  'lv':&qr_special_1,       // sufixes .1 and .2
  'lt':&qr_lt,              // sufixes .0, .1, and .2
];

/* 
  Finds all library paths.
  @return array of library paths and the local path at the end.
*/
function findLibPaths()
  libPaths=[];
  try
    mprops:p.Properties=p.Properties(system.appdir+'mShell.prp');
    paths=split(mprops.get('libpath'), ',');
    for p in paths do
      if files.exists(p) then
        append(libPaths, p);
      end
    end
  catch ex by
  end;

  append(libPaths, '.\\');
  return libPaths;
end

/* @internal */
libPaths=findLibPaths();

/* 
  Mapping from S60 Locale IDs to corresponding RFC 3066 codes.
*/
langIdMap=[
 '1':'en-gb', // UK English
 '2':'fr',    // French
 '3':'de',    // German
 '4':'es',    // Spanish
 '5':'it',    // Italian
 '6':'sv',    // Swedish
 '7':'da',    // Danish
 '8':'no',    // Norwegian
 '9':'fi',    // Finnish
'10':'en-us', // American English
'11':'fr-ch', // Swiss French
'12':'de-ch', // Swiss German
'13':'pt',    // Portuguese
'14':'tr',    // Turkish
'15':'is',    // Icelandic
'16':'ru',    // Russian
'17':'hu',    // Hungarian
'18':'nl',    // Dutch
'19':'nl-be', // Belgian Flemish
'20':'en-au', // Australian
'21':'fr-be', // Belgian French
'22':'de-at', // Austrian
'23':'en-nz', // New Zealand
'24':'fr',    // International French *
'25':'cs',    // Czech
'26':'sk',    // Slovak
'27':'pl',    // Polish
'28':'hu-si', // Slovenian
'29':'zh-tw', // Chinese (Taiwan)
'30':'zh-hk', // Chinese (Hong Kong)
'31':'zh',    // Chinese (PRC)
'32':'ja',    // Japanese
'33':'th',    // Thai
'34':'af',    // Afrikaans
'35':'sq',    // Albanian
'36':'am',    // Amharic
'37':'ar',    // Arabic
'38':'hy',    // Armenian
'39':'tl',    // Tagalog
'40':'be',    // Belarussian
'41':'bn',    // Bengali
'42':'bg',    // Bulgarian
'43':'my',    // Burmese
'44':'ca',    // Catalan
'45':'hr',    // Croatian
'46':'en-ca', // Canadian English
'47':'en',    // International English
'48':'en-za', // South African English
'49':'et',    // Estonian
'50':'fa',    // Farsi
'51':'fr-ca', // Canadian French
'52':'gd',    // Scots Gaelic
'53':'ka',    // Georgian
'54':'el',    // Greek
'55':'el-cy', // Cyprus Greek
'56':'gu',    // Gujarati
'57':'he',    // Hebrew
'58':'hi',    // Hindi
'59':'id',    // Indonesian
'60':'ga',    // Irish
'61':'it-ch', // Swiss Italian
'62':'kn',    // Kannada
'63':'kk',    // Kazakh
'64':'km',    // Khmer
'65':'ko',    // Korean
'66':'lo',    // Lao
'67':'lv',    // Latvian
'68':'lt',    // Lithuanian
'69':'mk',    // Macedonian
'70':'ms',    // Malay
'71':'ml',    // Malayalam
'72':'mr',    // Marathi
'73':'mo',    // Moldavian
'74':'mn',    // Mongolian
'75':'nn',    // Norwegian Nynorsk
'76':'pt-br', // Brazilian Portuguese
'77':'pa',    // Punjabi
'78':'ro',    // Romanian
'79':'sr',    // Serbian
'80':'si',    // Sinhalese
'81':'so',    // Somali
'82':'es',    // International Spanish *
'83':'es',    // Latin American Spanish *
'84':'sw',    // Swahili
'85':'sv-fi', // Finland Swedish
'86':'tg',    // Tajik
'87':'ta',    // Tamil
'88':'te',    // Telugu
'89':'bo',    // Tibetan
'90':'ti',    // Tigrinya
'91':'tr-cy', // Cyprus Turkish
'92':'tk',    // Turkmen
'93':'uk',    // Ukrainian
'94':'ur',    // Urdu
'95':'uz',    // Uzbek
'96':'vi',    // Vietnamese
'97':'cy',    // Welsh
'98':'zu',    // Zulu
];

/* 
  The system language code in RFC 3066 format. 
*/
systemLanguageCode=null;

/* @internal */
function initSystemLanguageCode()
  ..systemLanguageCode=..langIdMap[str(system.hal(0x44))];
  ..langIdMap=null; // free up some memory
end

/* @internal */
function getOrCreateLang(code) forward

/* @internal */
class Language
  name;
  code;
  modules;
  qr;
  fallback:Language;

  function loadLabels()
    this.modules=[];
    for p in ..libPaths do
      langFiles=files.scan(p+'*'+code+..EXT);
      for f in langFiles do
        fileName=files.parse(f)[2];
        lbls:p.Properties=p.Properties();
        lbls.read(p+f, io.bom);
        i=rindex(fileName,'.');
        if i=-1 then
          module='';
          langName=lbls.get(..LANG_NAME_PROPERTY);
          if langName#null then
            this.name=langName;
          end;
        else
          module=substr(fileName,0,i);
        end;
        if modules[module]#null then
          for newLabelKey in keys(lbls.entries) do
            modules[module].(p.Properties)set(newLabelKey,lbls.entries[newLabelKey]);
          end;
        else
          modules[module]=lbls;
        end
      end
    end
  end

  function getOrCreateFallback():Language
    if fallback#null then
      return fallback;
    elsif code=..BASE_LANG then
      throw 'langNotFound';
    elsif index(code,'-')#-1 then
      fallback=getOrCreateLang(substr(code,0,index(code,'-')));
    else
      fallback=getOrCreateLang(..BASE_LANG);
    end;
    return fallback;
  end

  function getQR()
    if qr=null then
      qr=getOrCreateFallback().getQR();
    end;
    return qr;
  end

  function getLabelsInModule(module):p.Properties
    if modules[module]=null then
      modules[module]=getOrCreateFallback().getLabelsInModule(module);
    end;
    return modules[module];
  end

  function getLabelText(module, id)
    try
      labels:p.Properties=getLabelsInModule(module);
      lblText=labels.get(id);
      if lblText=null then
        lblText=getOrCreateFallback().getLabelText(module, id);
      end;
      return lblText;
    catch ex by
      return id;
    end;
  end

  function label(module, id, q=null)
    if q#null then
      id=id+'.'+getQR()(q);
      text=getLabelText(module, id);
      if index(text,'%d')#-1 then
        text=io.format(text, q);
      end
    else
      text=getLabelText(module, id)
    end;
    return text
  end

  function init(code)
    this.code=code;
    this.qr=..quantityResolvers[code];
    loadLabels();
  end
end


/* @internal */
languagesCache=[];
/* @internal */
currentLanguage:Language=null;
/* @internal */
allLanguagesNames=null;

/* @internal */
function initAllLanguages()
  ..allLanguagesNames=[];
  for p in ..libPaths do
    langFiles=files.scan(p+'*'+..EXT);
    for f in langFiles do
      fileName=files.parse(f)[2];
      if index(fileName,'.')=-1 then
        lbls:p.Properties=p.Properties();
        lbls.read(p+f, io.bom);
        name=lbls.get(..LANG_NAME_PROPERTY);
        if name#null then
          ..allLanguagesNames[lower(fileName)]=name;
        end
      end
    end
  end;
  array.sort(..allLanguagesNames, false, array.fold);
end

/* @internal */
function getOrCreateLang(code)
  if ..languagesCache[code]=null then
    ..languagesCache[code]=Language(code);
  end;
  return ..languagesCache[code];
end

/* 
  Sets the application language to the specified one.
  @param code language code.
*/
function setLanguage(code)
  ..currentLanguage=getOrCreateLang(lower(code));
end

/* @internal */
function setInitialLanguage()
  initSystemLanguageCode();
  if ..systemLanguageCode#null then
    setLanguage(..systemLanguageCode)
  else
    setLanguage(..BASE_LANG)
  end
end

/* 
  Gets the current language or null if the name of the language name is unknown.
  @return current language name and code in format [code:name], or null if the 
  language name is unknown (only fallback is available).
*/
function getLanguage()
  if ..currentLanguage.name#null then
    return [..currentLanguage.code:..currentLanguage.name];
  else
    return null
  end
end

/* 
  Gets the list of all languages which name is known.
  @return list of all known languages in format [code:name, code:name...]
*/
function getAllLanguages()
  if ..allLanguagesNames=null then
    initAllLanguages();
  end;
  return ..allLanguagesNames
end

/*
  Gets the label text in the specified module for the id and (optional)
  quantity.
  @param module module name.
  @param id label id.
  @param quantity of items the label is describing.
*/
function mlabel(module, id, quantity=null)
  return ..currentLanguage.label(module,id,quantity)
end

/*
  Gets the label text in the common module for the specified id and (optional)
  quantity.
  @param id label id.
  @param quantity of items the label is describing.
*/
function label(id, quantity=null)
  return mlabel('',id,quantity)
end

setInitialLanguage();
