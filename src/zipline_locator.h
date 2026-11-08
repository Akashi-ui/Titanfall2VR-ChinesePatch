// Locate the prompt by verified x64 instructions, string, and named CRT import.
// No version offsets: ambiguous or structurally changed images are left untouched.
struct ZiplineSite { U64 call, text, slot; };
static bool Range(U64 at,U64 n,U64 size){return at<=size && n<=size-at;}
static bool TextAt(const unsigned char* b,U64 size,U64 at,const char* text){
 for(U64 i=0;;i++){if(!Range(at+i,1,size)||b[at+i]!=(unsigned char)text[i])return false;if(!text[i])return true;}
}
static bool FindZipline(const unsigned char* b,U64 size,ZiplineSite* result){
 if(size<4096||size>64*1024*1024||*(const unsigned short*)b!=0x5a4d)return false;
 U64 nt=*(const DWORD*)(b+60);if(!Range(nt,24+120,size)||*(const DWORD*)(b+nt)!=0x4550||*(const unsigned short*)(b+nt+4)!=0x8664)return false;
 U64 opt=nt+24,os=*(const unsigned short*)(b+nt+20),count=*(const unsigned short*)(b+nt+6);
 if(os<128||!Range(opt,os,size)||*(const unsigned short*)(b+opt)!=0x20b||*(const DWORD*)(b+opt+56)!=size||count==0||count>96)return false;
 U64 sections=opt+os;if(!Range(sections,count*40,size))return false;
 int found=0;ZiplineSite candidate={};
 for(U64 s=0;s<count;s++){
  U64 sh=sections+s*40,va=*(const DWORD*)(b+sh+12),len=*(const DWORD*)(b+sh+8);DWORD flags=*(const DWORD*)(b+sh+36);
  if(!(flags&0x20000000)||!Range(va,len,size)||len<21)continue;
  for(U64 at=va;at<=va+len-21;at++){
   const unsigned char* c=b+at;
   if(c[0]!=0x4c||c[1]!=0x8d||c[2]!=5||c[7]!=0xba||c[8]!=0||c[9]!=1||c[10]!=0||c[11]!=0||c[12]!=0x48||c[13]!=0x8b||(c[14]!=0xcd&&c[14]!=0xc8)||c[15]!=0xff||c[16]!=0x15)continue;
   I64 text=(I64)at+7+*(const int*)(c+3),slotAt=(I64)at+21+*(const int*)(c+17);
   if(text<0||slotAt<0||!Range((U64)slotAt,8,size)||!TextAt(b,size,(U64)text,"Press %use% to ride zipline"))continue;
   bool readonlyText=false;
   for(U64 t=0;t<count;t++){U64 q=sections+t*40,v=*(const DWORD*)(b+q+12),n=*(const DWORD*)(b+q+8);DWORD f=*(const DWORD*)(b+q+36);if((U64)text>=v&&Range((U64)text-v,26,n)&&(f&0x40000000)&&!(f&0xa0000000))readonlyText=true;}
   if(!readonlyText)continue;
   // Resolve this exact IAT slot through the PE import name table.
   U64 dir=*(const DWORD*)(b+opt+120),dirSize=*(const DWORD*)(b+opt+124);bool named=false;
   if(!dir||!Range(dir,dirSize,size))continue;
   for(U64 d=dir;Range(d,20,dir+dirSize);d+=20){
    U64 names=*(const DWORD*)(b+d),iat=*(const DWORD*)(b+d+16);if(!names&&!iat)break;
    if(!names||!iat||(U64)slotAt<iat||((U64)slotAt-iat)%8)continue;
    U64 nameAt=names+((U64)slotAt-iat);if(!Range(nameAt,8,size))continue;
    U64 name=*(const U64*)(b+nameAt);if(name&0x8000000000000000ULL)continue;
    if(Range(name,2,size)&&TextAt(b,size,name+2,"strcpy_s"))named=true;
   }
   if(!named)continue;
   candidate.call=at;candidate.text=(U64)text;candidate.slot=(U64)slotAt;if(++found>1)return false;
  }
 }
 if(found!=1)return false;*result=candidate;return true;
}
