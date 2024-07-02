#include "tonc_types.h"
#include "tonc_bios.h"
#include <limits.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>

void natuPanic(char *a, char *b);
uintptr_t natuGetRegBase(void);
void natuReqSoftReset(void);

void SoftReset(void) {
  natuReqSoftReset();
}
void RegisterRamReset(u32 flags) {
  // swiRegisterRamReset(flags);
}
void Halt(void) {
  natuPanic("Halt()", "");
}
void Stop(void) {
  natuPanic("Stop()", "");
}
void IntrWait(u32 flagClear, u32 irq) {
  uintptr_t base = natuGetRegBase();
  u16 *ime = (u16*)(base + 0x208);
  *ime = 1;
}
void VBlankIntrWait(void) {
  uintptr_t base = natuGetRegBase();
  u16 *ime = (u16*)(base + 0x208);
  *ime = 1;
  // TODO: actually jump back to app here?
}
s32 Div(s32 num, s32 den) {
  return num / den;
}
s32 DivArm(s32 den, s32 num) {
  return num / den;
}
u32 Sqrt(u32 num) {
  return (u32) sqrtf((float) num);
}

#define Rad2gba ((float)0x10000 / (M_PI * 2))

s16 ArcTan(s16 dydx) {
  return (s16)(atanf((float)dydx / (1 << 14)) * Rad2gba);
}
s16 ArcTan2(s16 x, s16 y) {
  return (s16)(atan2f((float) y, (float) x) * Rad2gba);
}
void CpuSet(const void *src, void *dst, u32 mode) {
  if (mode & (1 << 26)) {
    // words
      int count = (((mode & 0x1fffff) + 7) >> 3) << 3;
      const u32 *s = (const u32 *) src;
      u32 *d = (u32 *) dst;
      int i, j = 0;
      for (i = 0; i < count; i++) {
        d[i] = s[j];
        if (mode & (1 << 24)) j++;
      }
  } else {
    // halfwords
    int count = (((mode & 0x1fffff) + 7) >> 3) << 3;
    const u16 *s = (const u16 *) src;
    u16 *d = (u16 *) dst;
    int i, j = 0;
    for (i = 0; i < count; i++) {
      d[i] = s[j];
      if (mode & (1 << 24)) j++;
    }
  }
}
void CpuFastSet(const void *src, void *dst, u32 mode) {
  int count = (((mode & 0x1fffff) + 7) >> 3) << 3;
  const u32 *s = (const u32 *) src;
  u32 *d = (u32 *) dst;
  int i, j = 0;
  for (i = 0; i < count; i++) {
    d[i] = s[j];
    if (mode & (1 << 24)) j++;
  }
}
u32 BiosCheckSum(void) {
  return 0x12345678;
}
void ObjAffineSet(const ObjAffineSource *src, void *dst, s32 num, s32 offset) {
  // swiObjAffineSet((const ObjAffineSource *)src, dst, num, offset);
}
void BgAffineSet(const BgAffineSource *src, BgAffineDest *dst, s32 num) {
  // swiBgAffineSet((const BgAffineSource *)src, dst, num);
}
void BitUnPack(const void *src, void *dst, const BUP *bup) {
  // swiBitUnPack(const void *src, dst, (const BUP *)bup);
}
void LZ77UnCompWram(const void *src, void *dst) {
  // swiLZ77UnCompWram((const void *)src, dst);
}
void LZ77UnCompVram(const void *src, void *dst) {
  // swiLZ77UnCompVram((const void *)src, dst);
}
void HuffUnComp(const void *src, void *dst) {
  // swiHuffUnComp((const void *)src, dst);
}

void RLUnComp_Impl(void *src, void *dst);

void RLUnCompWram(const void *src, void *dst) {
  RLUnComp_Impl((void *)src, dst);
}
void RLUnCompVram(const void *src, void *dst) {
  RLUnComp_Impl((void *)src, dst);
}
void Diff8bitUnFilterWram(const void *src, void *dst) {
  // swiDiff8bitUnFilterWram((const void *)src, dst);
}
void Diff8bitUnFilterVram(const void *src, void *dst) {
  // swiDiff8bitUnFilterVram((const void *)src, dst);
}
void Diff16bitUnFilter(const void *src, void *dst) {
  // swiDiff16bitUnFilter((const void *)src, dst);
}
// void SoundBias(u32 bias) {
// }
// void SoundDriverInit(void *src) {
// }
// void SoundDriverMode(u32 mode) {
// }
// void SoundDriverMain(void) {
// }
// void SoundDriverVSync(void) {
// }
// void SoundChannelClear(void) {
// }
// u32 MidiKey2Freq(void *wa, u8 mk, u8 fp) {
// }
// void SoundDriverVSyncOff(void) {
// }
// void SoundDriverVSyncOn(void) {
// }
// int MultiBoot(MultiBootParam* mb, u32 mode) {
// }
void VBlankIntrDelay(u32 count) {
  for (u32 i = 0; i < count; i++) {
    VBlankIntrWait();
  }
}
int DivSafe(int num, int den) {
  if (den == 0) {
    return num >= 0 ? INT_MAX : INT_MIN;
  } else {
    return num / den;
  }
}
int Mod(int num, int den) {
  return num % den;
}
// u32 DivAbs(int num, int den) {
// }
// int DivArmMod(int den, int num) {
// }
// u32 DivArmAbs(int den, int num) {
// }
void CpuFastFill(u32 wd, void *dst, u32 count) {
  u32 *d = (u32 *) dst;
  for (int i = 0; i < count; i++) {
    d[i] = wd;
  }
}
