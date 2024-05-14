import ./applib

export GamepadAxis, GamepadButton, GamepadKind, Gamepad

template keyinput*: KeyInput = cast[ptr KeyInput](addr natuMem.regs[0x130 shr 1])[]
template keycnt*: KeyCnt = cast[ptr KeyCnt](addr natuMem.regs[0x132 shr 1])[]

# Gamepad API (SDL platform only)
# -------------------------------

const allButtons* = {btnNone.succ .. GamepadButton.high}

{.push inline.}

proc numGamepads*: int =
  natuMem.numGamepads().int

proc anyGamepadConnected*: bool =
  natuMem.numGamepads() > 0

proc getGamepadUid*(i = 0): string =
  let g = natuMem.getGamepad(i)
  if g == nil: ""
  else: g.uid

proc getGamepadKind*(i = 0): GamepadKind =
  let g = natuMem.getGamepad(i)
  if g == nil: GamepadUnknown
  else: g.kind

proc buttonsDown*(i = 0): set[GamepadButton] =
  let g = natuMem.getGamepad(i)
  if g == nil: {}
  else: g.currBtnStates

proc buttonsUp*(i = 0): set[GamepadButton] =
  let g = natuMem.getGamepad(i)
  if g == nil: {}
  else: allButtons - g.currBtnStates

proc buttonsHit*(i = 0): set[GamepadButton] =
  let g = natuMem.getGamepad(i)
  if g == nil: {}
  else: g.currBtnStates - g.prevBtnStates

proc buttonsReleased*(i = 0): set[GamepadButton] =
  let g = natuMem.getGamepad(i)
  if g == nil: {}
  else: g.prevBtnStates - g.currBtnStates

proc buttonIsDown*(btn: GamepadButton; i = 0): bool =
  let g = natuMem.getGamepad(i)
  (g != nil) and (btn in g.currBtnStates)

proc buttonIsUp*(btn: GamepadButton; i = 0): bool =
  let g = natuMem.getGamepad(i)
  (g != nil) and (btn notin g.currBtnStates)

proc buttonWasDown*(btn: GamepadButton; i = 0): bool =
  let g = natuMem.getGamepad(i)
  (g != nil) and (btn in g.prevBtnStates)

proc buttonWasUp*(btn: GamepadButton; i = 0): bool =
  let g = natuMem.getGamepad(i)
  (g != nil) and (btn notin g.prevBtnStates)

proc buttonHit*(btn: GamepadButton; i = 0): bool =
  let g = natuMem.getGamepad(i)
  (g != nil) and btn in (g.currBtnStates - g.prevBtnStates)

proc buttonReleased*(btn: GamepadButton; i = 0): bool =
  let g = natuMem.getGamepad(i)
  (g != nil) and btn in (g.prevBtnStates - g.currBtnStates)

proc anyButtonHit*(s: set[GamepadButton]; i = 0): bool =
  let g = natuMem.getGamepad(i)
  (g != nil) and s * (g.currBtnStates - g.prevBtnStates) != {}


# Stick / Trigger axes:

proc getAxis*(i: int; axis: GamepadAxis): float32 =
  let g = natuMem.getGamepad(i)
  if g == nil: 0f
  else: g.currAxisStates[axis]

proc getPrevAxis*(i: int; axis: GamepadAxis): float32 =
  let g = natuMem.getGamepad(i)
  if g == nil: 0f
  else: g.prevAxisStates[axis]

{.pop.}


# Keyboard Input (SDL platform only)
# ----------------------------------

type
  Keycode* = distinct int32

proc `==`*(a, b: Keycode): bool {.borrow.}

{.push inline.}

proc kbIsDown*(k: Keycode): bool =
  natuMem.keyIsDown(k.int32)

proc kbIsUp*(k: Keycode): bool =
  not natuMem.keyIsDown(k.int32)

proc kbWasDown*(k: Keycode): bool =
  natuMem.keyWasDown(k.int32)

proc kbWasUp*(k: Keycode): bool =
  not natuMem.keyWasDown(k.int32)

proc kbHit*(k: Keycode): bool =
  natuMem.keyIsDown(k.int32) and not natuMem.keyWasDown(k.int32)

proc kbReleased*(k: Keycode): bool =
  natuMem.keyWasDown(k.int32) and not natuMem.keyIsDown(k.int32)

{.pop.}

# Key constants (matching SDL)
# ----------------------------

proc key(c: char): Keycode = ord(c).Keycode
proc scan(n: int32): Keycode = (n or (1 shl 30)).Keycode

import std/[macros, tables, strutils]

macro defineKeycodes(body: typed) =
  assert body.kind == nnkStmtList
  assert body.len == 1
  assert body[0].kind == nnkConstSection
  let table1 = nnkTableConstr.newTree()
  let table2 = nnkTableConstr.newTree()
  for n in body[0]:
    let sym = n[0]
    let name = sym.strVal.toLowerAscii()
    table1.add newColonExpr(newStrLitNode(name), sym)
    table2.add newColonExpr(sym, newStrLitNode(sym.strVal))
  
  result = quote do:
    `body`
    const keycodeByName = toTable[string, Keycode](`table1`)
    const nameByKeycode = toTable[Keycode, string](`table2`)
    
    proc getKeycodeByName*(name: string): Keycode =
      let s = name.toLowerAscii
      if s in keycodeByName:
        keycodeByName[s]
      else:
        kUnknown
    
    proc getNameByKeycode*(keycode: Keycode): string =
      if keycode in nameByKeycode:
        nameByKeycode[keycode]
      else:
        "kUnknown" # should never happen.
  
  # echo treeRepr(result)

defineKeycodes:
 const
  kUnknown* = Keycode(0)
  kBackspace* = key '\x08'
  kTab* = key '\x09'
  kReturn* = key '\x0D'
  kEscape* = key '\x1B'
  kSpace* = key ' '
  kExclaim* = key '!'
  kQuoteDbl* = key '\"'
  kHash* = key '#'
  kDollar* = key '$'
  kPercent* = key '%'
  kAmpersand* = key '&'
  kQuote* = key '\''
  kLeftParen* = key '('
  kRightParen* = key ')'
  kAsterisk* = key '*'
  kPlus* = key '+'
  kComma* = key ','
  kMinus* = key '-'
  kPeriod* = key '.'
  kSlash* = key '/'
  k0* = key '0'
  k1* = key '1'
  k2* = key '2'
  k3* = key '3'
  k4* = key '4'
  k5* = key '5'
  k6* = key '6'
  k7* = key '7'
  k8* = key '8'
  k9* = key '9'
  kColon* = key ':'
  kSemicolon* = key ';'
  kLess* = key '<'
  kEquals* = key '='
  kGreater* = key '>'
  kQuestion* = key '?'
  kAt* = key '@'
  kLeftBracket* = key '['
  kBackslash* = key '\\'
  kRightBracket* = key ']'
  kCaret* = key '^'
  kUnderscore* = key '_'
  kBackquote* = key '`'
  kA* = key 'a'
  kB* = key 'b'
  kC* = key 'c'
  kD* = key 'd'
  kE* = key 'e'
  kF* = key 'f'
  kG* = key 'g'
  kH* = key 'h'
  kI* = key 'i'
  kJ* = key 'j'
  kK* = key 'k'
  kL* = key 'l'
  kM* = key 'm'
  kN* = key 'n'
  kO* = key 'o'
  kP* = key 'p'
  kQ* = key 'q'
  kR* = key 'r'
  kS* = key 's'
  kT* = key 't'
  kU* = key 'u'
  kV* = key 'v'
  kW* = key 'w'
  kX* = key 'x'
  kY* = key 'y'
  kZ* = key 'z'
  kDelete* = Keycode(127)
  kCapsLock* = scan 57
  kF1* = scan 58
  kF2* = scan 59
  kF3* = scan 60
  kF4* = scan 61
  kF5* = scan 62
  kF6* = scan 63
  kF7* = scan 64
  kF8* = scan 65
  kF9* = scan 66
  kF10* = scan 67
  kF11* = scan 68
  kF12* = scan 69
  kPrintScreen* = scan 70
  kScrollLock* = scan 71
  kPause* = scan 72
  kInsert* = scan 73
  kHome* = scan 74
  kPageup* = scan 75
  kEnd* = scan 77
  kPagedown* = scan 78
  kRight* = scan 79
  kLeft* = scan 80
  kDown* = scan 81
  kUp* = scan 82
  kNumlockClear* = scan 83
  kKpDivide* = scan 84
  kKpMultiply* = scan 85
  kKpMinus* = scan 86
  kKpPlus* = scan 87
  kKpEnter* = scan 88
  kKp1* = scan 89
  kKp2* = scan 90
  kKp3* = scan 91
  kKp4* = scan 92
  kKp5* = scan 93
  kKp6* = scan 94
  kKp7* = scan 95
  kKp8* = scan 96
  kKp9* = scan 97
  kKp0* = scan 98
  kKpPeriod* = scan 99
  kApplication* = scan 101
  kPower* = scan 102
  kKpEquals* = scan 103
  kF13* = scan 104
  kF14* = scan 105
  kF15* = scan 106
  kF16* = scan 107
  kF17* = scan 108
  kF18* = scan 109
  kF19* = scan 110
  kF20* = scan 111
  kF21* = scan 112
  kF22* = scan 113
  kF23* = scan 114
  kF24* = scan 115
  kExecute* = scan 116
  kHelp* = scan 117
  kMenu* = scan 118
  kSelect* = scan 119
  kStop* = scan 120
  kAgain* = scan 121
  kUndo* = scan 122
  kCut* = scan 123
  kCopy* = scan 124
  kPaste* = scan 125
  kFind* = scan 126
  kMute* = scan 127
  kVolumeUp* = scan 128
  kVolumeDown* = scan 129
  kKpComma* = scan 133
  kKpEqualsAs400* = scan 134
  kAltErase* = scan 135
  kSysreq* = scan 154
  kCancel* = scan 155
  kClear* = scan 156
  kPrior* = scan 157
  kReturn2* = scan 158
  kSeparator* = scan 159
  kOut* = scan 160
  kOper* = scan 161
  kClearAgain* = scan 162
  kCrSel* = scan 163
  kExSel* = scan 164
  kKp00* = scan 176
  kKp000* = scan 177
  kThousandsSeparator* = scan 178
  kDecimalSeparator* = scan 179
  kCurrencyUnit* = scan 180
  kCurrencysUbUnit* = scan 181
  kKpLeftParen* = scan 182
  kKpRightParen* = scan 183
  kKpLeftBrace* = scan 184
  kKpRightBrace* = scan 185
  kKpTab* = scan 186
  kKpBackspace* = scan 187
  kKpA* = scan 188
  kKpB* = scan 189
  kKpC* = scan 190
  kKpD* = scan 191
  kKpE* = scan 192
  kKpF* = scan 193
  kKpXor* = scan 194
  kKpPower* = scan 195
  kKpPercent* = scan 196
  kKpLess* = scan 197
  kKpGreater* = scan 198
  kKpAmpersand* = scan 199
  kKpDblAmpersand* = scan 200
  kKpVerticalBar* = scan 201
  kKpDblverticalBar* = scan 202
  kKpColon* = scan 203
  kKpHash* = scan 204
  kKpSpace* = scan 205
  kKpAt* = scan 206
  kKpExclam* = scan 207
  kKpMemStore* = scan 208
  kKpMemRecall* = scan 209
  kKpMemClear* = scan 210
  kKpMemAdd* = scan 211
  kKpMemSubtract* = scan 212
  kKpMemMultiply* = scan 213
  kKpMemDivide* = scan 214
  kKpPlusMinus* = scan 215
  kKpClear* = scan 216
  kKpClearEntry* = scan 217
  kKpBinary* = scan 218
  kKpOctal* = scan 219
  kKpDecimal* = scan 220
  kKpHexadecimal* = scan 221
  kLCtrl* = scan 224
  kLShift* = scan 225
  kLAlt* = scan 226
  kLGui* = scan 227
  kRCtrl* = scan 228
  kRShift* = scan 229
  kRAlt* = scan 230
  kRGui* = scan 231
  kMode* = scan 257
  kAudioNext* = scan 258
  kAudioPrev* = scan 259
  kAudioStop* = scan 260
  kAudioPlay* = scan 261
  kAudioMute* = scan 262
  kMediaSelect* = scan 263
  kWww* = scan 264
  kMail* = scan 265
  kCalculator* = scan 266
  kComputer* = scan 267
  kAcSearch* = scan 268
  kAcHome* = scan 269
  kAcBack* = scan 270
  kAcForward* = scan 271
  kAcStop* = scan 272
  kAcRefresh* = scan 273
  kAcBookmarks* = scan 274
  kBrightnessDown* = scan 275
  kBrightnessUp* = scan 276
  kDisplaySwitch* = scan 277
  kKbdIllumToggle* = scan 278
  kKbdIllumDown* = scan 279
  kKbdIllumUp* = scan 280
  kEject* = scan 281
  kSleep* = scan 282
  kApp1* = scan 283
  kApp2* = scan 284
  kAudioRewind* = scan 285
  kAudioFastforward* = scan 286


proc `$`*(keycode: Keycode): string =
  getNameByKeycode(keycode)
