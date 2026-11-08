// Minimal Windows / Northstar ABI declarations; no CRT or SDK dependency.
using U64=unsigned long long;
using I64=long long;
using DWORD=unsigned long;
using HMODULE=void*;
extern "C" {
__declspec(dllimport) int __stdcall VirtualProtect(void*,U64,DWORD,DWORD*);
__declspec(dllimport) HMODULE __stdcall GetModuleHandleA(const char*);
__declspec(dllimport) DWORD __stdcall GetModuleFileNameA(HMODULE,char*,DWORD);
__declspec(dllimport) void* __stdcall CreateFileA(const char*,DWORD,DWORD,void*,DWORD,DWORD,void*);
__declspec(dllimport) int __stdcall WriteFile(void*,const void*,DWORD,DWORD*,void*);
__declspec(dllimport) int __stdcall CloseHandle(void*);
__declspec(dllimport) DWORD __stdcall SetFilePointer(void*,long,long*,DWORD);
void* _ReturnAddress();void* _AddressOfReturnAddress();
}
#pragma intrinsic(_ReturnAddress)
#pragma intrinsic(_AddressOfReturnAddress)
struct PluginNorthstarData { HMODULE pluginHandle; U64 size; };
using DrawBox=void(*)(void*,int,int,int,int,DWORD,float,bool,bool);
static DrawBox original=nullptr;
static void** slot=nullptr;
static unsigned char* client=nullptr;
static HMODULE selfModule=nullptr;
static bool attempted=false;
static int logged=0;
static bool Equal(const char* a,const char* b){while(*a&&*a==*b){a++;b++;}return *a==*b;}
static void Log(const char* text) {
 char path[260];DWORD n=GetModuleFileNameA(selfModule,path,260);if(n<4||n>=260)return;
 path[n-3]='l';path[n-2]='o';path[n-1]='g';
 void* f=CreateFileA(path,0x40000000,3,nullptr,4,0x80,nullptr);
 if(f==(void*)-1)return;SetFilePointer(f,0,nullptr,2);
 DWORD len=0,written;while(text[len])len++;WriteFile(f,text,len,&written,nullptr);WriteFile(f,"\r\n",2,&written,nullptr);CloseHandle(f);
}
static char* Number(char* out,int n){char temp[16];int i=0;do{temp[i++]=char('0'+n%10);n/=10;}while(n&&i<15);while(i)*out++=temp[--i];*out++=' ';return out;}
struct VisibleItem { int height,width; void* item; };
__declspec(noinline) static void FitBox(void* panel,int x,int y,int w,int h,DWORD color,float alpha,bool a,bool b) {
 // Only the verified retail CHudCloseCaption::Paint callsite uses this stack ABI.
 if(_ReturnAddress()==client+0x23e6b8) {
  unsigned char* caller=(unsigned char*)_AddressOfReturnAddress()+8;
  auto items=*(VisibleItem**)(caller+0xb8);
  int count=*(int*)(caller+0xd0);
  int* rect=(int*)(caller+0x70); // left,right,top,bottom (not Win32 RECT order)
  if(items&&count>0&&count<=128&&rect[0]==x&&rect[1]-rect[0]==w&&w>=24&&w<16384) {
   int maxWidth=0;
   for(int i=0;i<count;i++)if(items[i].width>maxWidth)maxWidth=items[i].width;
   if(maxWidth>0&&maxWidth<=w-24) {
    int fitted=maxWidth+24,shift=(w-fitted)/2;
    // Preserve native wrapping and vertical stacking; center the text with its box.
    rect[0]+=shift;x+=shift;w=fitted;
    if(logged<12){char msg[120]="fit count/width/x/y/h: ";char* end=msg+22;end=Number(end,count);end=Number(end,w);end=Number(end,x);end=Number(end,y);end=Number(end,h);*end=0;Log(msg);logged++;}
   }
  }
 }
 original(panel,x,y,w,h,color,alpha,a,b);
}
static bool Bytes(U64 at,const unsigned char* bytes,U64 n){for(U64 i=0;i<n;i++)if(client[at+i]!=bytes[i])return false;return true;}
static void TryInstall(HMODULE mod) {
 if(attempted||!mod)return;attempted=true;client=(unsigned char*)mod;
 if(*(unsigned short*)client!=0x5a4d){Log("Unsupported image.");return;}
 auto nt=client+*(DWORD*)(client+0x3c);
 if(*(DWORD*)nt!=0x4550||*(DWORD*)(nt+24+56)<0x900580){Log("Unsupported image size.");return;}
 const unsigned char callBytes[]={0x49,0x8b,0xcb,0x41,0xff,0x92,0x70,0x04,0x00,0x00,0x83,0x44,0x24,0x70,0x0c};
 const unsigned char listBytes[]={0xff,0xc7,0x49,0x8b,0xce,0x48,0xc1,0xe1,0x04,0x89,0x7d,0xd0,0x49,0x03,0xcf,0x74,0x0b,0x48,0x8b,0x45,0xe0,0x48,0x89,0x01,0x48,0x89,0x59,0x08};
 const unsigned char stackBytes[]={0x4c,0x89,0x7d,0xb8,0x4c,0x89,0x65,0xc0};
 if(!Bytes(0x23e6ae,callBytes,sizeof(callBytes))||!Bytes(0x23e28a,listBytes,sizeof(listBytes))||!Bytes(0x23e1b9,stackBytes,sizeof(stackBytes))){Log("Unsupported caption callsite; no changes made.");return;}
 slot=(void**)(client+0x9000f8+0x470);original=(DrawBox)*slot;
 if((void*)original!=client+0x7588a0){slot=nullptr;Log("Caption drawing already modified; no changes made.");return;}
 DWORD oldProtect;
 if(!VirtualProtect(slot,8,4,&oldProtect)){slot=nullptr;Log("Cannot update caption vtable.");return;}
 *slot=(void*)&FitBox;VirtualProtect(slot,8,oldProtect,&oldProtect);Log("Caption width fitting enabled.");
}

using CopyText=int(*)(char*,U64,const char*);
static CopyText originalCopy=nullptr;
static void** copySlot=nullptr;
static unsigned char* vrModule=nullptr;
static bool ziplineAttempted=false;
static U64 promptReturn=0,promptString=0;
__declspec(noinline) static int CopyPrompt(char* dst,U64 size,const char* src) {
 if(_ReturnAddress()==vrModule+promptReturn && src==(const char*)(vrModule+promptString))
  return originalCopy(dst,size,"\xec\x98\xa4\xeb\xa5\xb8\xec\xaa\xbd\x20\xed\x8a\xb8\xeb\xa6\xac\xea\xb1\xb0\xeb\xa5\xbc\x20\xeb\x88\x8c\xeb\x9f\xac\x20\xec\xa7\x91\xeb\x9d\xbc\xec\x9d\xb8\xec\x9d\x84\x20\xed\x83\x80\xec\x84\xb8\xec\x9a\x94");
 return originalCopy(dst,size,src);
}
#include "zipline_locator.h"
static void TryZipline(HMODULE mod) {
 if(ziplineAttempted||!mod)return;ziplineAttempted=true;
 auto b=(unsigned char*)mod;
 if(*(unsigned short*)b!=0x5a4d)return;
 DWORD nt=*(DWORD*)(b+0x3c);if(nt>4096)return;
 if(*(DWORD*)(b+nt)!=0x4550)return;
 U64 size=*(DWORD*)(b+nt+24+56);ZiplineSite site={};
 if(!FindZipline(b,size,&site)){Log("Unrecognized or ambiguous VR zipline pattern; no changes made.");return;}
 promptReturn=site.call+21;promptString=site.text;
 vrModule=b;copySlot=(void**)(b+site.slot);originalCopy=(CopyText)*copySlot;
 DWORD old;if(!VirtualProtect(copySlot,8,4,&old)){copySlot=nullptr;return;}
 *copySlot=(void*)&CopyPrompt;VirtualProtect(copySlot,8,old,&old);Log("Zipline prompt localization enabled (validated pattern).");
}

static const char* GetString(void*,int p){return p==0?"Korean Caption Layout":p==1?"KO_CAPTION":"KoreanCaptionLayout";}
static I64 GetField(void*,int p){return p==0?2:0x80d0ff;}
static void Init(void*,HMODULE,const PluginNorthstarData* d,bool){selfModule=d->pluginHandle;TryInstall(GetModuleHandleA("client.dll"));TryZipline(GetModuleHandleA("Titanfall2VR.dll"));}
static void Finalize(void*){}
static bool Unload(void*){if(copySlot&&*copySlot==(void*)&CopyPrompt){DWORD old;if(!VirtualProtect(copySlot,8,4,&old))return false;*copySlot=(void*)originalCopy;VirtualProtect(copySlot,8,old,&old);}if(slot&&*slot==(void*)&FitBox){DWORD old;if(!VirtualProtect(slot,8,4,&old))return false;*slot=(void*)original;VirtualProtect(slot,8,old,&old);}return true;}
static void OnSqvm(void*,void*){}
static void OnLibrary(void*,HMODULE m,const char* name){if(name&&Equal(name,"client.dll"))TryInstall(m);if(name&&Equal(name,"Titanfall2VR.dll"))TryZipline(m);}
static void Frame(void*){}
static void* idTable[]={(void*)&GetString,(void*)&GetField};
static void* callbackTable[]={(void*)&Init,(void*)&Finalize,(void*)&Unload,(void*)&OnSqvm,(void*)&OnSqvm,(void*)&OnLibrary,(void*)&Frame};
static void** id=idTable;static void** callbacks=callbackTable;
extern "C" __declspec(dllexport) void* CreateInterface(const char* name,int* result){
 void* p=Equal(name,"PluginId001")?(void*)&id:Equal(name,"PluginCallbacks001")?(void*)&callbacks:nullptr;if(result)*result=p?0:1;return p;
}
extern "C" int _fltused=0;
