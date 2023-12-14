import ./bits

const mgbaCFlags = """
-DDISABLE_THREADING -DDEBUG -DHAVE_CRC32 -DHAVE_FUTIMENS -DHAVE_FUTIMES -DHAVE_LOCALE -DHAVE_LOCALTIME_R -DHAVE_NEWLOCALE -DHAVE_REALPATH -DHAVE_SETLOCALE -DHAVE_STRDUP -DHAVE_STRNDUP -DHAVE_USELOCALE -DHAVE_VASPRINTF -DM_CORE_GBA -DUSE_EGL -DUSE_EPOXY -DUSE_GLX -DUSE_LIBSWRESAMPLE -DUSE_LIBZIP -DUSE_LZMA -DUSE_PNG -DUSE_SQLITE3 -DUSE_ZLIB -D_7ZIP_PPMD_SUPPPORT -D_GNU_SOURCE -Dmgba_EXPORTS -Imgba/include -Imgba/build/include -Imgba/src -Imgba/src/third-party/lzma -Wall -Wextra -Wno-missing-field-initializers -Werror=implicit-function-declaration -Werror=implicit-int -fwrapv -Werror=incompatible-pointer-types -DNDEBUG -fPIC -MD -MT"""

{.passC:"-std=c11".}
{.compile("mgba/src/core/cache-set.c", mgbaCFlags).}
{.compile("mgba/src/core/bitmap-cache.c", mgbaCFlags).}
{.compile("mgba/src/core/map-cache.c", mgbaCFlags).}
{.compile("mgba/src/core/tile-cache.c", mgbaCFlags).}
{.compile("mgba/src/core/log.c", mgbaCFlags).}  # edited
{.compile("mgba/src/gba/video.c", mgbaCFlags).} # edited
{.compile("mgba/src/util/memory.c", mgbaCFlags).}
{.compile("mgba/src/util/geometry.c", mgbaCFlags).}
{.compile("mgba/src/util/table.c", mgbaCFlags).}
{.compile("mgba/src/util/hash.c", mgbaCFlags).}
{.compile("mgba/src/feature/video-backend.c", mgbaCFlags).}
{.compile("mgba/src/gba/renderers/cache-set.c", mgbaCFlags).}
{.compile("mgba/src/gba/renderers/common.c", mgbaCFlags).}
{.compile("mgba/src/gba/renderers/software-bg.c", mgbaCFlags).}
{.compile("mgba/src/gba/renderers/software-mode0.c", mgbaCFlags).}
{.compile("mgba/src/gba/renderers/software-obj.c", mgbaCFlags).}
{.compile("mgba/src/gba/renderers/video-software.c", mgbaCFlags).}

#[
/usr/bin/cc -DBUILD_GL -DBUILD_GLES2 -DBUILD_GLES3 -DENABLE_SCRIPTING -DHAVE_CRC32 -DHAVE_FREELOCALE -DHAVE_FUTIMENS -DHAVE_FUTIMES -DHAVE_LOCALE -DHAVE_LOCALTIME_R -DHAVE_NEWLOCALE -DHAVE_PTHREAD_CREATE -DHAVE_PTHREAD_SETNAME_NP -DHAVE_REALPATH -DHAVE_SETLOCALE -DHAVE_STRDUP -DHAVE_STRNDUP -DHAVE_USELOCALE -DHAVE_VASPRINTF '-DLUA_VERSION_ONLY="5.4"' -DMGBA_DLL -DM_CORE_GB -DM_CORE_GBA -DUSE_DEBUGGERS -DUSE_DISCORD_RPC -DUSE_EDITLINE -DUSE_EGL -DUSE_ELF -DUSE_EPOXY -DUSE_FFMPEG -DUSE_GDB_STUB -DUSE_GLX -DUSE_JSON_C -DUSE_LIBSWRESAMPLE -DUSE_LIBZIP -DUSE_LUA -DUSE_LZMA -DUSE_PNG -DUSE_PTHREADS -DUSE_SQLITE3 -DUSE_ZLIB -D_7ZIP_PPMD_SUPPPORT -D_GNU_SOURCE -Dmgba_EXPORTS -I/home/exelotl/Dev/mgba/include -I/home/exelotl/Dev/mgba/build/include -I/home/exelotl/Dev/mgba/src -I/usr/include/editline -I/home/exelotl/Dev/mgba/src/third-party/lzma -I/home/exelotl/Dev/mgba/src/third-party/discord-rpc/include -isystem /usr/include/json-c -Wall -Wextra -Wno-missing-field-initializers -Werror=implicit-function-declaration -Werror=implicit-int -fwrapv -Werror=incompatible-pointer-types -pthread -O3 -DNDEBUG -std=c11 -fPIC -MD -MT CMakeFiles/mgba.dir/src/gba/renderers/video-software.c.o -MF CMakeFiles/mgba.dir/src/gba/renderers/video-software.c.o.d -o CMakeFiles/mgba.dir/src/gba/renderers/video-software.c.o -c /home/exelotl/Dev/mgba/src/gba/renderers/video-software.c
]#

type mStateExtdataItem = object # fwd decl
type mInputMapImpl = object # fwd decl
type mCacheSet = object
type VFile = object # fwd decl
type TableList = object # fwd decl
type
  HashFunction* = proc (key: pointer; len: csize_t; seed: uint32): uint32 {.noconv.}
  TableFunctions* {.bycopy.} = object
    deinitializer*: proc (a1: pointer) {.noconv.}
    hash*: HashFunction
    equal*: proc (a1: pointer; a2: pointer): bool {.noconv.}
    `ref`*: proc (a1: pointer): pointer {.noconv.}
    deref*: proc (a1: pointer) {.noconv.}

  Table* {.bycopy.} = object
    table*: ptr TableList
    tableSize*: csize_t
    size*: csize_t
    seed*: uint32
    fn*: TableFunctions

  TableIterator* {.bycopy.} = object
    bucket*: csize_t
    entry*: csize_t


proc TableInit*(a1: ptr Table; initialSize: csize_t; deinitializer: proc (a1: pointer) {.noconv.}) {.importc: "TableInit".}
proc TableDeinit*(a1: ptr Table) {.importc: "TableDeinit".}
proc TableLookup*(a1: ptr Table; key: uint32): pointer {.importc: "TableLookup".}
proc TableInsert*(a1: ptr Table; key: uint32; value: pointer) {.importc: "TableInsert".}
proc TableRemove*(a1: ptr Table; key: uint32) {.importc: "TableRemove".}
proc TableClear*(a1: ptr Table) {.importc: "TableClear".}
proc TableEnumerate*(a1: ptr Table; handler: proc (key: uint32; value: pointer; user: pointer) {.noconv.}; user: pointer) {.importc: "TableEnumerate".}
proc TableSize*(a1: ptr Table): csize_t {.importc: "TableSize".}
proc TableIteratorStart*(a1: ptr Table; a2: ptr TableIterator): bool {.importc: "TableIteratorStart".}
proc TableIteratorNext*(a1: ptr Table; a2: ptr TableIterator): bool {.importc: "TableIteratorNext".}
proc TableIteratorGetKey*(a1: ptr Table; a2: ptr TableIterator): uint32 {.importc: "TableIteratorGetKey".}
proc TableIteratorGetValue*(a1: ptr Table; a2: ptr TableIterator): pointer {.importc: "TableIteratorGetValue".}
proc TableIteratorLookup*(a1: ptr Table; a2: ptr TableIterator; key: uint32): bool {.importc: "TableIteratorLookup".}
proc HashTableInit*(table: ptr Table; initialSize: csize_t; deinitializer: proc (a1: pointer) {.noconv.}) {.importc: "HashTableInit".}
proc HashTableInitCustom*(table: ptr Table; initialSize: csize_t; funcs: ptr TableFunctions) {.importc: "HashTableInitCustom".}
proc HashTableDeinit*(table: ptr Table) {.importc: "HashTableDeinit".}
proc HashTableLookup*(a1: ptr Table; key: cstring): pointer {.importc: "HashTableLookup".}
proc HashTableLookupBinary*(a1: ptr Table; key: pointer; keylen: csize_t): pointer {.importc: "HashTableLookupBinary".}
proc HashTableLookupCustom*(a1: ptr Table; key: pointer): pointer {.importc: "HashTableLookupCustom".}
proc HashTableInsert*(a1: ptr Table; key: cstring; value: pointer) {.importc: "HashTableInsert".}
proc HashTableInsertBinary*(a1: ptr Table; key: pointer; keylen: csize_t; value: pointer) {.importc: "HashTableInsertBinary".}
proc HashTableInsertCustom*(a1: ptr Table; key: pointer; value: pointer) {.importc: "HashTableInsertCustom".}
proc HashTableRemove*(a1: ptr Table; key: cstring) {.importc: "HashTableRemove".}
proc HashTableRemoveBinary*(a1: ptr Table; key: pointer; keylen: csize_t) {.importc: "HashTableRemoveBinary".}
proc HashTableRemoveCustom*(a1: ptr Table; key: pointer) {.importc: "HashTableRemoveCustom".}
proc HashTableClear*(a1: ptr Table) {.importc: "HashTableClear".}
proc HashTableEnumerate*(a1: ptr Table; handler: proc (key: cstring; value: pointer; user: pointer) {.noconv.}; user: pointer) {.importc: "HashTableEnumerate".}
proc HashTableEnumerateBinary*(a1: ptr Table; handler: proc (key: cstring; keylen: csize_t; value: pointer; user: pointer) {.noconv.}; user: pointer) {.importc: "HashTableEnumerateBinary".}
proc HashTableEnumerateCustom*(a1: ptr Table; handler: proc (key: pointer; value: pointer; user: pointer) {.noconv.}; user: pointer) {.importc: "HashTableEnumerateCustom".}
proc HashTableSearch*(table: ptr Table; predicate: proc (key: cstring; value: pointer; user: pointer): bool {.noconv.}; user: pointer): cstring {.importc: "HashTableSearch".}
proc HashTableSearchPointer*(table: ptr Table; value: pointer): cstring {.importc: "HashTableSearchPointer".}
proc HashTableSearchData*(table: ptr Table; value: pointer; bytes: csize_t): cstring {.importc: "HashTableSearchData".}
proc HashTableSearchString*(table: ptr Table; value: cstring): cstring {.importc: "HashTableSearchString".}
proc HashTableSize*(a1: ptr Table): csize_t {.importc: "HashTableSize".}
proc HashTableIteratorStart*(a1: ptr Table; a2: ptr TableIterator): bool {.importc: "HashTableIteratorStart".}
proc HashTableIteratorNext*(a1: ptr Table; a2: ptr TableIterator): bool {.importc: "HashTableIteratorNext".}
proc HashTableIteratorGetKey*(a1: ptr Table; a2: ptr TableIterator): cstring {.importc: "HashTableIteratorGetKey".}
proc HashTableIteratorGetBinaryKey*(a1: ptr Table; a2: ptr TableIterator): pointer {.importc: "HashTableIteratorGetBinaryKey".}
proc HashTableIteratorGetBinaryKeyLen*(a1: ptr Table; a2: ptr TableIterator): csize_t {.importc: "HashTableIteratorGetBinaryKeyLen".}
proc HashTableIteratorGetCustomKey*(a1: ptr Table; a2: ptr TableIterator): pointer {.importc: "HashTableIteratorGetCustomKey".}
proc HashTableIteratorGetValue*(a1: ptr Table; a2: ptr TableIterator): pointer {.importc: "HashTableIteratorGetValue".}
proc HashTableIteratorLookup*(a1: ptr Table; a2: ptr TableIterator; key: cstring): bool {.importc: "HashTableIteratorLookup".}
proc HashTableIteratorLookupBinary*(a1: ptr Table; a2: ptr TableIterator; key: pointer; keylen: csize_t): bool {.importc: "HashTableIteratorLookupBinary".}
proc HashTableIteratorLookupCustom*(a1: ptr Table; a2: ptr TableIterator; key: pointer): bool {.importc: "HashTableIteratorLookupCustom".}
discard "forward decl of VFile"
type
  Configuration* {.bycopy.} = object
    sections*: Table
    root*: Table


proc ConfigurationInit*(a1: ptr Configuration) {.importc: "ConfigurationInit".}
proc ConfigurationDeinit*(a1: ptr Configuration) {.importc: "ConfigurationDeinit".}
proc ConfigurationSetValue*(a1: ptr Configuration; section: cstring; key: cstring; value: cstring) {.importc: "ConfigurationSetValue".}
proc ConfigurationSetIntValue*(a1: ptr Configuration; section: cstring; key: cstring; value: cint) {.importc: "ConfigurationSetIntValue".}
proc ConfigurationSetUIntValue*(a1: ptr Configuration; section: cstring; key: cstring; value: cuint) {.importc: "ConfigurationSetUIntValue".}
proc ConfigurationSetFloatValue*(a1: ptr Configuration; section: cstring; key: cstring; value: cfloat) {.importc: "ConfigurationSetFloatValue".}
proc ConfigurationHasSection*(a1: ptr Configuration; section: cstring): bool {.importc: "ConfigurationHasSection".}
proc ConfigurationDeleteSection*(a1: ptr Configuration; section: cstring) {.importc: "ConfigurationDeleteSection".}
proc ConfigurationGetValue*(a1: ptr Configuration; section: cstring; key: cstring): cstring {.importc: "ConfigurationGetValue".}
proc ConfigurationClearValue*(a1: ptr Configuration; section: cstring; key: cstring) {.importc: "ConfigurationClearValue".}
proc ConfigurationRead*(a1: ptr Configuration; path: cstring): bool {.importc: "ConfigurationRead".}
proc ConfigurationReadVFile*(a1: ptr Configuration; vf: ptr VFile): bool {.importc: "ConfigurationReadVFile".}
proc ConfigurationWrite*(a1: ptr Configuration; path: cstring): bool {.importc: "ConfigurationWrite".}
proc ConfigurationWriteSection*(a1: ptr Configuration; path: cstring; section: cstring): bool {.importc: "ConfigurationWriteSection".}
proc ConfigurationWriteVFile*(a1: ptr Configuration; vf: ptr VFile): bool {.importc: "ConfigurationWriteVFile".}
proc ConfigurationEnumerateSections*(configuration: ptr Configuration; handler: proc (sectionName: cstring; user: pointer) {.noconv.}; user: pointer) {.importc: "ConfigurationEnumerateSections".}
proc ConfigurationEnumerate*(configuration: ptr Configuration; section: cstring; handler: proc (key: cstring; value: cstring; user: pointer) {.noconv.}; user: pointer) {.importc: "ConfigurationEnumerate".}

type
  mCoreConfig* {.bycopy.} = object
    configTable*: Configuration
    defaultsTable*: Configuration
    overridesTable*: Configuration
    port*: cstring

  mCoreConfigLevel* {.size: 4.} = enum
    mCONFIG_LEVEL_DEFAULT = 0, mCONFIG_LEVEL_CUSTOM, mCONFIG_LEVEL_OVERRIDE


type
  mCoreOptions* {.bycopy.} = object
    bios*: cstring
    skipBios*: bool
    useBios*: bool
    logLevel*: cint
    frameskip*: cint
    rewindEnable*: bool
    rewindBufferCapacity*: cint
    rewindBufferInterval*: cint
    fpsTarget*: cfloat
    audioBuffers*: csize_t
    sampleRate*: cuint
    fullscreen*: cint
    width*: cint
    height*: cint
    lockAspectRatio*: bool
    lockIntegerScaling*: bool
    interframeBlending*: bool
    resampleVideo*: bool
    suspendScreensaver*: bool
    shader*: cstring
    savegamePath*: cstring
    savestatePath*: cstring
    screenshotPath*: cstring
    patchPath*: cstring
    cheatsPath*: cstring
    volume*: cint
    mute*: bool
    videoSync*: bool
    audioSync*: bool


proc mCoreConfigInit*(a1: ptr mCoreConfig; port: cstring) {.importc: "mCoreConfigInit".}
proc mCoreConfigDeinit*(a1: ptr mCoreConfig) {.importc: "mCoreConfigDeinit".}
proc mCoreConfigLoad*(a1: ptr mCoreConfig): bool {.importc: "mCoreConfigLoad".}
proc mCoreConfigSave*(a1: ptr mCoreConfig): bool {.importc: "mCoreConfigSave".}
proc mCoreConfigLoadPath*(a1: ptr mCoreConfig; path: cstring): bool {.importc: "mCoreConfigLoadPath".}
proc mCoreConfigSavePath*(a1: ptr mCoreConfig; path: cstring): bool {.importc: "mCoreConfigSavePath".}
proc mCoreConfigLoadVFile*(a1: ptr mCoreConfig; vf: ptr VFile): bool {.importc: "mCoreConfigLoadVFile".}
proc mCoreConfigSaveVFile*(a1: ptr mCoreConfig; vf: ptr VFile): bool {.importc: "mCoreConfigSaveVFile".}
proc mCoreConfigMakePortable*(a1: ptr mCoreConfig) {.importc: "mCoreConfigMakePortable".}
proc mCoreConfigDirectory*(`out`: cstring; outLength: csize_t) {.importc: "mCoreConfigDirectory".}
proc mCoreConfigPortablePath*(`out`: cstring; outLength: csize_t) {.importc: "mCoreConfigPortablePath".}
proc mCoreConfigIsPortable*(): bool {.importc: "mCoreConfigIsPortable".}
proc mCoreConfigGetValue*(a1: ptr mCoreConfig; key: cstring): cstring {.importc: "mCoreConfigGetValue".}
proc mCoreConfigGetBoolValue*(a1: ptr mCoreConfig; key: cstring; value: ptr bool): bool {.importc: "mCoreConfigGetBoolValue".}
proc mCoreConfigGetIntValue*(a1: ptr mCoreConfig; key: cstring; value: ptr cint): bool {.importc: "mCoreConfigGetIntValue".}
proc mCoreConfigGetUIntValue*(a1: ptr mCoreConfig; key: cstring; value: ptr cuint): bool {.importc: "mCoreConfigGetUIntValue".}
proc mCoreConfigGetFloatValue*(a1: ptr mCoreConfig; key: cstring; value: ptr cfloat): bool {.importc: "mCoreConfigGetFloatValue".}
proc mCoreConfigSetValue*(a1: ptr mCoreConfig; key: cstring; value: cstring) {.importc: "mCoreConfigSetValue".}
proc mCoreConfigSetIntValue*(a1: ptr mCoreConfig; key: cstring; value: cint) {.importc: "mCoreConfigSetIntValue".}
proc mCoreConfigSetUIntValue*(a1: ptr mCoreConfig; key: cstring; value: cuint) {.importc: "mCoreConfigSetUIntValue".}
proc mCoreConfigSetFloatValue*(a1: ptr mCoreConfig; key: cstring; value: cfloat) {.importc: "mCoreConfigSetFloatValue".}
proc mCoreConfigSetDefaultValue*(a1: ptr mCoreConfig; key: cstring; value: cstring) {.importc: "mCoreConfigSetDefaultValue".}
proc mCoreConfigSetDefaultIntValue*(a1: ptr mCoreConfig; key: cstring; value: cint) {.importc: "mCoreConfigSetDefaultIntValue".}
proc mCoreConfigSetDefaultUIntValue*(a1: ptr mCoreConfig; key: cstring; value: cuint) {.importc: "mCoreConfigSetDefaultUIntValue".}
proc mCoreConfigSetDefaultFloatValue*(a1: ptr mCoreConfig; key: cstring; value: cfloat) {.importc: "mCoreConfigSetDefaultFloatValue".}
proc mCoreConfigSetOverrideValue*(a1: ptr mCoreConfig; key: cstring; value: cstring) {.importc: "mCoreConfigSetOverrideValue".}
proc mCoreConfigSetOverrideIntValue*(a1: ptr mCoreConfig; key: cstring; value: cint) {.importc: "mCoreConfigSetOverrideIntValue".}
proc mCoreConfigSetOverrideUIntValue*(a1: ptr mCoreConfig; key: cstring; value: cuint) {.importc: "mCoreConfigSetOverrideUIntValue".}
proc mCoreConfigSetOverrideFloatValue*(a1: ptr mCoreConfig; key: cstring; value: cfloat) {.importc: "mCoreConfigSetOverrideFloatValue".}
proc mCoreConfigCopyValue*(config: ptr mCoreConfig; src: ptr mCoreConfig; key: cstring) {.importc: "mCoreConfigCopyValue".}
proc mCoreConfigMap*(config: ptr mCoreConfig; opts: ptr mCoreOptions) {.importc: "mCoreConfigMap".}
proc mCoreConfigLoadDefaults*(config: ptr mCoreConfig; opts: ptr mCoreOptions) {.importc: "mCoreConfigLoadDefaults".}
proc mCoreConfigEnumerate*(config: ptr mCoreConfig; prefix: cstring; handler: proc (key: cstring; value: cstring; `type`: mCoreConfigLevel; user: pointer) {.noconv.}; user: pointer) {.importc: "mCoreConfigEnumerate".}
proc mCoreConfigGetInput*(a1: ptr mCoreConfig): ptr Configuration {.importc: "mCoreConfigGetInput".}
proc mCoreConfigGetOverrides*(a1: ptr mCoreConfig): ptr Configuration {.importc: "mCoreConfigGetOverrides".}
proc mCoreConfigGetOverridesConst*(a1: ptr mCoreConfig): ptr Configuration {.importc: "mCoreConfigGetOverridesConst".}
proc mCoreConfigFreeOpts*(opts: ptr mCoreOptions) {.importc: "mCoreConfigFreeOpts".}
type VDir = object # fwd decl
type
  mDirectorySet* {.bycopy.} = object
    baseName*: array[4096, char]
    base*: ptr VDir
    archive*: ptr VDir
    save*: ptr VDir
    patch*: ptr VDir
    state*: ptr VDir
    screenshot*: ptr VDir
    cheats*: ptr VDir


proc mDirectorySetInit*(dirs: ptr mDirectorySet) {.importc: "mDirectorySetInit".}
proc mDirectorySetDeinit*(dirs: ptr mDirectorySet) {.importc: "mDirectorySetDeinit".}
proc mDirectorySetAttachBase*(dirs: ptr mDirectorySet; base: ptr VDir) {.importc: "mDirectorySetAttachBase".}
proc mDirectorySetDetachBase*(dirs: ptr mDirectorySet) {.importc: "mDirectorySetDetachBase".}
proc mDirectorySetOpenPath*(dirs: ptr mDirectorySet; path: cstring; filter: proc (a1: ptr VFile): bool {.noconv.}): ptr VFile {.importc: "mDirectorySetOpenPath".}
proc mDirectorySetOpenSuffix*(dirs: ptr mDirectorySet; dir: ptr VDir; suffix: cstring; mode: cint): ptr VFile {.importc: "mDirectorySetOpenSuffix".}
discard "forward decl of mCoreOptions"
proc mDirectorySetMapOptions*(dirs: ptr mDirectorySet; opts: ptr mCoreOptions) {.importc: "mDirectorySetMapOptions".}
discard "forward decl of Configuration"

type
  mInputHat* = int32

const
  M_INPUT_HAT_NEUTRAL = 0
  M_INPUT_HAT_UP = 1
  M_INPUT_HAT_RIGHT = 2
  M_INPUT_HAT_DOWN = 4
  M_INPUT_HAT_LEFT = 8

type
  mInputHatBindings* {.bycopy.} = object
    up*: cint
    right*: cint
    down*: cint
    left*: cint

  mInputPlatformInfo* {.bycopy.} = object
    platformName*: cstring
    keyId*: cstringArray
    nKeys*: csize_t
    hat*: mInputHatBindings

  mInputMap* {.bycopy.} = object
    maps*: ptr mInputMapImpl
    numMaps*: csize_t
    info*: ptr mInputPlatformInfo

  mInputAxis* {.bycopy.} = object
    highDirection*: cint
    lowDirection*: cint
    deadHigh*: int32
    deadLow*: int32

type
  color_t* = uint32
  mColorFormat* = int32

const
  mCOLOR_ANY* = -1
  mCOLOR_XBGR8* = 0x00001
  mCOLOR_XRGB8* = 0x00002
  mCOLOR_BGRX8* = 0x00004
  mCOLOR_RGBX8* = 0x00008
  mCOLOR_ABGR8* = 0x00010
  mCOLOR_ARGB8* = 0x00020
  mCOLOR_BGRA8* = 0x00040
  mCOLOR_RGBA8* = 0x00080
  mCOLOR_RGB5* = 0x00100
  mCOLOR_BGR5* = 0x00200
  mCOLOR_RGB565* = 0x00400
  mCOLOR_BGR565* = 0x00800
  mCOLOR_ARGB5* = 0x01000
  mCOLOR_ABGR5* = 0x02000
  mCOLOR_RGBA5* = 0x04000
  mCOLOR_BGRA5* = 0x08000
  mCOLOR_RGB8* = 0x10000
  mCOLOR_BGR8* = 0x20000
  mCOLOR_L8* = 0x40000
  mCOLOR_PAL8* = 0x80000

type ssize_t = int
type intptr_t = int
type time_t = int
type uintptr_t = uint
type blip_t = object

discard "forward decl of mCore"
discard "forward decl of mStateExtdataItem"
discard "forward decl of blip_t"
type
  mCoreFeature* {.size:4.} = enum
    mCORE_FEATURE_OPENGL = 1


type
  mCoreCallbacks* {.bycopy.} = object
    context*: pointer
    videoFrameStarted*: proc (context: pointer) {.noconv.}
    videoFrameEnded*: proc (context: pointer) {.noconv.}
    coreCrashed*: proc (context: pointer) {.noconv.}
    sleep*: proc (context: pointer) {.noconv.}
    shutdown*: proc (context: pointer) {.noconv.}
    keysRead*: proc (context: pointer) {.noconv.}
    savedataUpdated*: proc (context: pointer) {.noconv.}
    alarm*: proc (context: pointer) {.noconv.}

  mCoreCallbacksList* {.bycopy.} = object
    vector*: ptr mCoreCallbacks
    size*: csize_t
    capacity*: csize_t


proc mCoreCallbacksListInit*(vector: ptr mCoreCallbacksList; capacity: csize_t) {.importc: "mCoreCallbacksListInit".}
proc mCoreCallbacksListDeinit*(vector: ptr mCoreCallbacksList) {.importc: "mCoreCallbacksListDeinit".}
proc mCoreCallbacksListGetPointer*(vector: ptr mCoreCallbacksList; location: csize_t): ptr mCoreCallbacks {.importc: "mCoreCallbacksListGetPointer".}
proc mCoreCallbacksListGetConstPointer*(vector: ptr mCoreCallbacksList; location: csize_t): ptr mCoreCallbacks {.importc: "mCoreCallbacksListGetConstPointer".}
proc mCoreCallbacksListAppend*(vector: ptr mCoreCallbacksList): ptr mCoreCallbacks {.importc: "mCoreCallbacksListAppend".}
proc mCoreCallbacksListClear*(vector: ptr mCoreCallbacksList) {.importc: "mCoreCallbacksListClear".}
proc mCoreCallbacksListResize*(vector: ptr mCoreCallbacksList; change: ssize_t) {.importc: "mCoreCallbacksListResize".}
proc mCoreCallbacksListShift*(vector: ptr mCoreCallbacksList; location: csize_t; difference: csize_t) {.importc: "mCoreCallbacksListShift".}
proc mCoreCallbacksListUnshift*(vector: ptr mCoreCallbacksList; location: csize_t; difference: csize_t) {.importc: "mCoreCallbacksListUnshift".}
proc mCoreCallbacksListEnsureCapacity*(vector: ptr mCoreCallbacksList; capacity: csize_t) {.importc: "mCoreCallbacksListEnsureCapacity".}
proc mCoreCallbacksListSize*(vector: ptr mCoreCallbacksList): csize_t {.importc: "mCoreCallbacksListSize".}
proc mCoreCallbacksListIndex*(vector: ptr mCoreCallbacksList; member: ptr mCoreCallbacks): csize_t {.importc: "mCoreCallbacksListIndex".}
proc mCoreCallbacksListCopy*(dest: ptr mCoreCallbacksList; src: ptr mCoreCallbacksList) {.importc: "mCoreCallbacksListCopy".}
## ignored statement

type
  mAVStream* {.bycopy.} = object
    videoDimensionsChanged*: proc (a1: ptr mAVStream; width: cuint; height: cuint) {.noconv.}
    audioRateChanged*: proc (a1: ptr mAVStream; rate: cuint) {.noconv.}
    postVideoFrame*: proc (a1: ptr mAVStream; buffer: ptr color_t; stride: csize_t) {.noconv.}
    postAudioFrame*: proc (a1: ptr mAVStream; left: int16; right: int16) {.noconv.}
    postAudioBuffer*: proc (a1: ptr mAVStream; left: ptr blip_t; right: ptr blip_t) {.noconv.}

  mStereoSample* {.bycopy.} = object
    left*: int16
    right*: int16

  mKeyCallback* {.bycopy.} = object
    readKeys*: proc (a1: ptr mKeyCallback): uint16 {.noconv.}
    requireOpposingDirections*: bool

  mPeripheral* = int32
  
const
  mPERIPH_ROTATION = 1
  mPERIPH_RUMBLE = 2
  mPERIPH_IMAGE_SOURCE =3
  mPERIPH_CUSTOM = 0x1000


type
  mRotationSource* {.bycopy.} = object
    sample*: proc (a1: ptr mRotationSource) {.noconv.}
    readTiltX*: proc (a1: ptr mRotationSource): int32 {.noconv.}
    readTiltY*: proc (a1: ptr mRotationSource): int32 {.noconv.}
    readGyroZ*: proc (a1: ptr mRotationSource): int32 {.noconv.}

  mRTCSource* {.bycopy.} = object
    sample*: proc (a1: ptr mRTCSource) {.noconv.}
    unixTime*: proc (a1: ptr mRTCSource): time_t {.noconv.}
    serialize*: proc (a1: ptr mRTCSource; a2: ptr mStateExtdataItem) {.noconv.}
    deserialize*: proc (a1: ptr mRTCSource; a2: ptr mStateExtdataItem): bool {.noconv.}

  mImageSource* {.bycopy.} = object
    startRequestImage*: proc (a1: ptr mImageSource; w: cuint; h: cuint; colorFormats: cint) {.noconv.}
    stopRequestImage*: proc (a1: ptr mImageSource) {.noconv.}
    requestImage*: proc (a1: ptr mImageSource; buffer: ptr pointer; stride: ptr csize_t; colorFormat: ptr mColorFormat) {.noconv.}

  mRTCGenericType* = int32

const
  RTC_NO_OVERRIDE = 0
  RTC_FIXED = 1
  RTC_FAKE_EPOCH = 2
  RTC_WALLCLOCK_OFFSET = 3
  RTC_CUSTOM_START = 0x1000


type
  mRTCGenericSource* {.bycopy.} = object
    d*: mRTCSource
    p*: ptr mCore
    override*: mRTCGenericType
    value*: int64
    custom*: ptr mRTCSource

  mRTCGenericState* {.bycopy.} = object
    `type`*: int32
    padding*: int32
    value*: int64
  
  mRumble* {.bycopy.} = object
    setRumble*: proc (a1: ptr mRumble; enable: cint) {.noconv.}

  mCoreChannelInfo* {.bycopy.} = object
    id*: csize_t
    internalName*: cstring
    visibleName*: cstring
    visibleType*: cstring

  mCoreMemoryBlockFlags* {.size:4.} = enum
    mCORE_MEMORY_READ = 0x01, mCORE_MEMORY_WRITE = 0x02, mCORE_MEMORY_RW = 0x03,
    mCORE_MEMORY_WORM = 0x04, mCORE_MEMORY_MAPPED = 0x10, mCORE_MEMORY_VIRTUAL = 0x20
  
  mCoreMemoryBlock* {.bycopy.} = object
    id*: csize_t
    internalName*: cstring
    shortName*: cstring
    longName*: cstring
    start*: uint32
    `end`*: uint32
    size*: uint32
    flags*: uint32
    maxSegment*: uint16
    segmentStart*: uint32

  mCoreScreenRegion* {.bycopy.} = object
    id*: csize_t
    description*: cstring
    x*: int16
    y*: int16
    w*: int16
    h*: int16

  mCoreRegisterType* {.size:4.} = enum
    mCORE_REGISTER_GPR = 0, mCORE_REGISTER_FPR, mCORE_REGISTER_FLAGS,
    mCORE_REGISTER_SIMD
  
  mCoreRegisterInfo* {.bycopy.} = object
    name*: cstring
    aliases*: cstringArray
    width*: cuint
    mask*: uint32
    `type`*: mCoreRegisterType

  mPlatform* {.size:4.} = enum
    mPLATFORM_NONE = -1, mPLATFORM_GBA = 0, mPLATFORM_GB = 1
  
  mCoreChecksumType* {.size:4.} = enum
    mCHECKSUM_CRC32
  
  mTimingEvent* {.bycopy.} = object
    context*: pointer
    callback*: proc (a1: ptr mTiming; context: pointer; a3: uint32) {.noconv.}
    name*: cstring
    `when`*: uint32
    priority*: cuint
    next*: ptr mTimingEvent
  
  mTiming* {.bycopy.} = object
    root*: ptr mTimingEvent
    reroot*: ptr mTimingEvent
    globalCycles*: uint64
    masterCycles*: uint32
    relativeCycles*: ptr int32
    nextEvent*: ptr int32
  
  mDebugger* {.bycopy.} = object
  mDebuggerSymbols* {.bycopy.} = object
  mVideoLogger* {.bycopy.} = object
  mVideoLogContext* {.bycopy.} = object
  mCoreSync* {.bycopy.} = object
  mCheatDevice* {.bycopy.} = object

  mCore* {.bycopy.} = object
    cpu*: pointer
    board*: pointer
    timing*: ptr mTiming
    debugger*: ptr mDebugger
    symbolTable*: ptr mDebuggerSymbols
    videoLogger*: ptr mVideoLogger
    dirs*: mDirectorySet
    inputMap*: mInputMap
    config*: mCoreConfig
    opts*: mCoreOptions
    rtc*: mRTCGenericSource
    init*: proc (a1: ptr mCore): bool {.noconv.}
    deinit*: proc (a1: ptr mCore) {.noconv.}
    platform*: proc (a1: ptr mCore): mPlatform {.noconv.}
    supportsFeature*: proc (a1: ptr mCore; a2: mCoreFeature): bool {.noconv.}
    setSync*: proc (a1: ptr mCore; a2: ptr mCoreSync) {.noconv.}
    loadConfig*: proc (a1: ptr mCore; a2: ptr mCoreConfig) {.noconv.}
    reloadConfigOption*: proc (a1: ptr mCore; option: cstring; a3: ptr mCoreConfig) {.noconv.}
    setOverride*: proc (a1: ptr mCore; override: pointer) {.noconv.}
    baseVideoSize*: proc (a1: ptr mCore; width: ptr cuint; height: ptr cuint) {.noconv.}
    currentVideoSize*: proc (a1: ptr mCore; width: ptr cuint; height: ptr cuint) {.noconv.}
    videoScale*: proc (a1: ptr mCore): cuint {.noconv.}
    screenRegions*: proc (a1: ptr mCore; a2: ptr ptr mCoreScreenRegion): csize_t {.noconv.}
    setVideoBuffer*: proc (a1: ptr mCore; buffer: ptr color_t; stride: csize_t) {.noconv.}
    setVideoGLTex*: proc (a1: ptr mCore; texid: cuint) {.noconv.}
    getPixels*: proc (a1: ptr mCore; buffer: ptr pointer; stride: ptr csize_t) {.noconv.}
    putPixels*: proc (a1: ptr mCore; buffer: pointer; stride: csize_t) {.noconv.}
    getAudioChannel*: proc (a1: ptr mCore; ch: cint): ptr blip_t {.noconv.}
    setAudioBufferSize*: proc (a1: ptr mCore; samples: csize_t) {.noconv.}
    getAudioBufferSize*: proc (a1: ptr mCore): csize_t {.noconv.}
    addCoreCallbacks*: proc (a1: ptr mCore; a2: ptr mCoreCallbacks) {.noconv.}
    clearCoreCallbacks*: proc (a1: ptr mCore) {.noconv.}
    setAVStream*: proc (a1: ptr mCore; a2: ptr mAVStream) {.noconv.}
    isROM*: proc (vf: ptr VFile): bool {.noconv.}
    loadROM*: proc (a1: ptr mCore; vf: ptr VFile): bool {.noconv.}
    loadSave*: proc (a1: ptr mCore; vf: ptr VFile): bool {.noconv.}
    loadTemporarySave*: proc (a1: ptr mCore; vf: ptr VFile): bool {.noconv.}
    unloadROM*: proc (a1: ptr mCore) {.noconv.}
    romSize*: proc (a1: ptr mCore): csize_t {.noconv.}
    checksum*: proc (a1: ptr mCore; data: pointer; `type`: mCoreChecksumType) {.noconv.}
    loadBIOS*: proc (a1: ptr mCore; vf: ptr VFile; biosID: cint): bool {.noconv.}
    selectBIOS*: proc (a1: ptr mCore; biosID: cint): bool {.noconv.}
    loadPatch*: proc (a1: ptr mCore; vf: ptr VFile): bool {.noconv.}
    reset*: proc (a1: ptr mCore) {.noconv.}
    runFrame*: proc (a1: ptr mCore) {.noconv.}
    runLoop*: proc (a1: ptr mCore) {.noconv.}
    step*: proc (a1: ptr mCore) {.noconv.}
    stateSize*: proc (a1: ptr mCore): csize_t {.noconv.}
    loadState*: proc (a1: ptr mCore; state: pointer): bool {.noconv.}
    saveState*: proc (a1: ptr mCore; state: pointer): bool {.noconv.}
    setKeys*: proc (a1: ptr mCore; keys: uint32) {.noconv.}
    addKeys*: proc (a1: ptr mCore; keys: uint32) {.noconv.}
    clearKeys*: proc (a1: ptr mCore; keys: uint32) {.noconv.}
    getKeys*: proc (a1: ptr mCore): uint32 {.noconv.}
    frameCounter*: proc (a1: ptr mCore): uint32 {.noconv.}
    frameCycles*: proc (a1: ptr mCore): int32 {.noconv.}
    frequency*: proc (a1: ptr mCore): int32 {.noconv.}
    getGameTitle*: proc (a1: ptr mCore; title: cstring) {.noconv.}
    getGameCode*: proc (a1: ptr mCore; title: cstring) {.noconv.}
    setPeripheral*: proc (a1: ptr mCore; `type`: cint; a3: pointer) {.noconv.}
    getPeripheral*: proc (a1: ptr mCore; `type`: cint): pointer {.noconv.}
    busRead8*: proc (a1: ptr mCore; address: uint32): uint32 {.noconv.}
    busRead16*: proc (a1: ptr mCore; address: uint32): uint32 {.noconv.}
    busRead32*: proc (a1: ptr mCore; address: uint32): uint32 {.noconv.}
    busWrite8*: proc (a1: ptr mCore; address: uint32; a3: uint8) {.noconv.}
    busWrite16*: proc (a1: ptr mCore; address: uint32; a3: uint16) {.noconv.}
    busWrite32*: proc (a1: ptr mCore; address: uint32; a3: uint32) {.noconv.}
    rawRead8*: proc (a1: ptr mCore; address: uint32; segment: cint): uint32 {.noconv.}
    rawRead16*: proc (a1: ptr mCore; address: uint32; segment: cint): uint32 {.noconv.}
    rawRead32*: proc (a1: ptr mCore; address: uint32; segment: cint): uint32 {.noconv.}
    rawWrite8*: proc (a1: ptr mCore; address: uint32; segment: cint; a4: uint8) {.noconv.}
    rawWrite16*: proc (a1: ptr mCore; address: uint32; segment: cint; a4: uint16) {.noconv.}
    rawWrite32*: proc (a1: ptr mCore; address: uint32; segment: cint; a4: uint32) {.noconv.}
    listMemoryBlocks*: proc (a1: ptr mCore; a2: ptr ptr mCoreMemoryBlock): csize_t {.noconv.}
    getMemoryBlock*: proc (a1: ptr mCore; id: csize_t; sizeOut: ptr csize_t): pointer {.noconv.}
    listRegisters*: proc (a1: ptr mCore; a2: ptr ptr mCoreRegisterInfo): csize_t {.noconv.}
    readRegister*: proc (a1: ptr mCore; name: cstring; `out`: pointer): bool {.noconv.}
    writeRegister*: proc (a1: ptr mCore; name: cstring; `in`: pointer): bool {.noconv.}
    cheatDevice*: proc (a1: ptr mCore): ptr mCheatDevice {.noconv.}
    savedataClone*: proc (a1: ptr mCore; sram: ptr pointer): csize_t {.noconv.}
    savedataRestore*: proc (a1: ptr mCore; sram: pointer; size: csize_t; writeback: bool): bool {.noconv.}
    listVideoLayers*: proc (a1: ptr mCore; a2: ptr ptr mCoreChannelInfo): csize_t {.noconv.}
    listAudioChannels*: proc (a1: ptr mCore; a2: ptr ptr mCoreChannelInfo): csize_t {.noconv.}
    enableVideoLayer*: proc (a1: ptr mCore; id: csize_t; enable: bool) {.noconv.}
    enableAudioChannel*: proc (a1: ptr mCore; id: csize_t; enable: bool) {.noconv.}
    adjustVideoLayer*: proc (a1: ptr mCore; id: csize_t; x: int32; y: int32) {.noconv.}
    startVideoLog*: proc (a1: ptr mCore; a2: ptr mVideoLogContext) {.noconv.}
    endVideoLog*: proc (a1: ptr mCore) {.noconv.}


discard "forward decl of mCoreConfig"
discard "forward decl of mCoreSync"
discard "forward decl of mDebuggerSymbols"
discard "forward decl of mStateExtdata"
discard "forward decl of mVideoLogContext"

proc mCoreFind*(path: cstring): ptr mCore {.importc: "mCoreFind".}
proc mCoreLoadFile*(core: ptr mCore; path: cstring): bool {.importc: "mCoreLoadFile".}
proc mCorePreloadVF*(core: ptr mCore; vf: ptr VFile): bool {.importc: "mCorePreloadVF".}
proc mCorePreloadFile*(core: ptr mCore; path: cstring): bool {.importc: "mCorePreloadFile".}
proc mCorePreloadVFCB*(core: ptr mCore; vf: ptr VFile; cb: proc (a1: csize_t; a2: csize_t; a3: pointer) {.noconv.}; context: pointer): bool {.importc: "mCorePreloadVFCB".}
proc mCorePreloadFileCB*(core: ptr mCore; path: cstring; cb: proc (a1: csize_t; a2: csize_t; a3: pointer) {.noconv.}; context: pointer): bool {.importc: "mCorePreloadFileCB".}
proc mCoreAutoloadSave*(core: ptr mCore): bool {.importc: "mCoreAutoloadSave".}
proc mCoreAutoloadPatch*(core: ptr mCore): bool {.importc: "mCoreAutoloadPatch".}
proc mCoreAutoloadCheats*(core: ptr mCore): bool {.importc: "mCoreAutoloadCheats".}
proc mCoreLoadSaveFile*(core: ptr mCore; path: cstring; temporary: bool): bool {.importc: "mCoreLoadSaveFile".}
proc mCoreSaveState*(core: ptr mCore; slot: cint; flags: cint): bool {.importc: "mCoreSaveState".}
proc mCoreLoadState*(core: ptr mCore; slot: cint; flags: cint): bool {.importc: "mCoreLoadState".}
proc mCoreGetState*(core: ptr mCore; slot: cint; write: bool): ptr VFile {.importc: "mCoreGetState".}
proc mCoreDeleteState*(core: ptr mCore; slot: cint) {.importc: "mCoreDeleteState".}
proc mCoreTakeScreenshot*(core: ptr mCore) {.importc: "mCoreTakeScreenshot".}
proc mCoreTakeScreenshotVF*(core: ptr mCore; vf: ptr VFile): bool {.importc: "mCoreTakeScreenshotVF".}
proc mCoreFindVF*(vf: ptr VFile): ptr mCore {.importc: "mCoreFindVF".}
proc mCoreIsCompatible*(vf: ptr VFile): mPlatform {.importc: "mCoreIsCompatible".}
proc mCoreCreate*(a1: mPlatform): ptr mCore {.importc: "mCoreCreate".}
proc mCoreSaveStateNamed*(core: ptr mCore; vf: ptr VFile; flags: cint): bool {.importc: "mCoreSaveStateNamed".}
proc mCoreLoadStateNamed*(core: ptr mCore; vf: ptr VFile; flags: cint): bool {.importc: "mCoreLoadStateNamed".}
proc mCoreInitConfig*(core: ptr mCore; port: cstring) {.importc: "mCoreInitConfig".}
proc mCoreLoadConfig*(core: ptr mCore) {.importc: "mCoreLoadConfig".}
proc mCoreLoadForeignConfig*(core: ptr mCore; config: ptr mCoreConfig) {.importc: "mCoreLoadForeignConfig".}
proc mCoreSetRTC*(core: ptr mCore; rtc: ptr mRTCSource) {.importc: "mCoreSetRTC".}
proc mCoreGetMemoryBlock*(core: ptr mCore; start: uint32; size: ptr csize_t): pointer {.importc: "mCoreGetMemoryBlock".}
proc mCoreGetMemoryBlockMasked*(core: ptr mCore; start: uint32; size: ptr csize_t; mask: uint32): pointer {.importc: "mCoreGetMemoryBlockMasked".}
proc mCoreGetMemoryBlockInfo*(core: ptr mCore; address: uint32): ptr mCoreMemoryBlock {.importc: "mCoreGetMemoryBlockInfo".}

proc mTimingInit*(timing: ptr mTiming; relativeCycles: ptr int32; nextEvent: ptr int32) {.importc: "mTimingInit".}
proc mTimingDeinit*(timing: ptr mTiming) {.importc: "mTimingDeinit".}
proc mTimingClear*(timing: ptr mTiming) {.importc: "mTimingClear".}
proc mTimingInterrupt*(timing: ptr mTiming) {.importc: "mTimingInterrupt".}
proc mTimingSchedule*(timing: ptr mTiming; a2: ptr mTimingEvent; `when`: int32) {.importc: "mTimingSchedule".}
proc mTimingScheduleAbsolute*(timing: ptr mTiming; a2: ptr mTimingEvent; `when`: int32) {.importc: "mTimingScheduleAbsolute".}
proc mTimingDeschedule*(timing: ptr mTiming; a2: ptr mTimingEvent) {.importc: "mTimingDeschedule".}
proc mTimingIsScheduled*(timing: ptr mTiming; a2: ptr mTimingEvent): bool {.importc: "mTimingIsScheduled".}
proc mTimingTick*(timing: ptr mTiming; cycles: int32): int32 {.importc: "mTimingTick".}
proc mTimingCurrentTime*(timing: ptr mTiming): int32 {.importc: "mTimingCurrentTime".}
proc mTimingGlobalTime*(timing: ptr mTiming): uint64 {.importc: "mTimingGlobalTime".}
proc mTimingNextEvent*(timing: ptr mTiming): int32 {.importc: "mTimingNextEvent".}
proc mTimingUntil*(timing: ptr mTiming; a2: ptr mTimingEvent): int32 {.importc: "mTimingUntil".}

const
  GBA_VIDEO_HORIZONTAL_PIXELS* = 240
  GBA_VIDEO_VERTICAL_PIXELS* = 160

type
  GBASIOMode* {.size:4.} = enum
    SIO_NORMAL_8 = 0, SIO_NORMAL_32 = 1, SIO_MULTI = 2, SIO_UART = 3, SIO_GPIO = 8,
    SIO_JOYBUS = 12


type
  GBASIOJOYCommand* {.size:4.} = enum
    JOY_POLL = 0x00, JOY_TRANS = 0x14, JOY_RECV = 0x15, JOY_RESET = 0xFF


type
  GBAVideoLayer* {.size:4.} = enum
    GBA_LAYER_BG0 = 0, GBA_LAYER_BG1, GBA_LAYER_BG2, GBA_LAYER_BG3, GBA_LAYER_OBJ,
    GBA_LAYER_WIN0, GBA_LAYER_WIN1, GBA_LAYER_OBJWIN


discard "forward decl of GBA"
discard "forward decl of GBAAudio"
discard "forward decl of GBASIO"
discard "forward decl of GBAVideoRenderer"
discard "forward decl of VFile"

let GBA_LUX_LEVELS* {.importc.}: array[10, cint]

const
  mPERIPH_GBA_LUMINANCE* = 0x1000
  mPERIPH_GBA_BATTLECHIP_GATE* = 4097

proc GBAIsROM*(vf: ptr VFile): bool {.importc: "GBAIsROM".}
proc GBAIsMB*(vf: ptr VFile): bool {.importc: "GBAIsMB".}
proc GBAIsBIOS*(vf: ptr VFile): bool {.importc: "GBAIsBIOS".}
type
  GBALuminanceSource* {.bycopy.} = object
    sample*: proc (a1: ptr GBALuminanceSource) {.noconv.}
    readLuminance*: proc (a1: ptr GBALuminanceSource): uint8 {.noconv.}
  
  GBASIO = object
  
  GBASIODriver* {.bycopy.} = object
    p*: ptr GBASIO
    init*: proc (driver: ptr GBASIODriver): bool {.noconv.}
    deinit*: proc (driver: ptr GBASIODriver) {.noconv.}
    load*: proc (driver: ptr GBASIODriver): bool {.noconv.}
    unload*: proc (driver: ptr GBASIODriver): bool {.noconv.}
    writeRegister*: proc (driver: ptr GBASIODriver; address: uint32; value: uint16): uint16 {.noconv.}


proc GBASIOJOYCreate*(sio: ptr GBASIODriver) {.importc: "GBASIOJOYCreate".}
type
  GBASIOBattleChipGateFlavor* {.size:4.} = enum
    GBA_FLAVOR_BATTLECHIP_GATE = 4, GBA_FLAVOR_PROGRESS_GATE = 5,
    GBA_FLAVOR_BEAST_LINK_GATE = 6, GBA_FLAVOR_BEAST_LINK_GATE_US = 7

type
  mLogLevel* {.size:4.} = enum
    mLOG_FATAL = 0x01, mLOG_ERROR = 0x02, mLOG_WARN = 0x04, mLOG_INFO = 0x08,
    mLOG_DEBUG = 0x10, mLOG_STUB = 0x20, mLOG_GAME_ERROR = 0x40, mLOG_ALL = 0x7F

discard "forward decl of Table"
type
  mLogFilter* {.bycopy.} = object
    defaultLevels*: cint
    categories*: Table
    levels*: Table

  mLogger* {.bycopy.} = object
    # log*: proc (a1: ptr mLogger; category: cint; level: mLogLevel; format: cstring; args: va_list) {.noconv.}
    log*: pointer
    filter*: ptr mLogFilter

  mStandardLogger* {.bycopy.} = object
    d*: mLogger
    logToStdout*: bool
    logFile*: ptr VFile


proc mLogGetContext*(): ptr mLogger {.importc: "mLogGetContext".}
proc mLogSetDefaultLogger*(a1: ptr mLogger) {.importc: "mLogSetDefaultLogger".}
proc mLogGenerateCategory*(a1: cstring; a2: cstring): cint {.importc: "mLogGenerateCategory".}
proc mLogCategoryName*(a1: cint): cstring {.importc: "mLogCategoryName".}
proc mLogCategoryId*(a1: cint): cstring {.importc: "mLogCategoryId".}
proc mLogCategoryById*(a1: cstring): cint {.importc: "mLogCategoryById".}
discard "forward decl of mCoreConfig"
proc mStandardLoggerInit*(a1: ptr mStandardLogger) {.importc: "mStandardLoggerInit".}
proc mStandardLoggerDeinit*(a1: ptr mStandardLogger) {.importc: "mStandardLoggerDeinit".}
proc mStandardLoggerConfig*(a1: ptr mStandardLogger; config: ptr mCoreConfig) {.importc: "mStandardLoggerConfig".}
proc mLogFilterInit*(a1: ptr mLogFilter) {.importc: "mLogFilterInit".}
proc mLogFilterDeinit*(a1: ptr mLogFilter) {.importc: "mLogFilterDeinit".}
proc mLogFilterLoad*(a1: ptr mLogFilter; a2: ptr mCoreConfig) {.importc: "mLogFilterLoad".}
proc mLogFilterSave*(a1: ptr mLogFilter; a2: ptr mCoreConfig) {.importc: "mLogFilterSave".}
proc mLogFilterSet*(a1: ptr mLogFilter; category: cstring; levels: cint) {.importc: "mLogFilterSet".}
proc mLogFilterReset*(a1: ptr mLogFilter; category: cstring) {.importc: "mLogFilterReset".}
proc mLogFilterTest*(a1: ptr mLogFilter; category: cint; level: mLogLevel): bool {.importc: "mLogFilterTest".}
proc mLogFilterLevels*(a1: ptr mLogFilter; category: cint): cint {.importc: "mLogFilterLevels".}
## !!!Ignored construct:  ) void mLog ( int category , enum mLogLevel level , const char * format , ... ) ;
## Error: did not expect )!!!

## !!!Ignored construct:  ) void mLogExplicit ( struct mLogger * , int category , enum mLogLevel level , const char * format , ... ) ;
## Error: did not expect )!!!


type
  GBAIORegisters* = uint32

const
  GBA_REG_DISPCNT* = 0x000
  GBA_REG_GREENSWP* = 0x002
  GBA_REG_DISPSTAT* = 0x004
  GBA_REG_VCOUNT* = 0x006
  GBA_REG_BG0CNT* = 0x008
  GBA_REG_BG1CNT* = 0x00A
  GBA_REG_BG2CNT* = 0x00C
  GBA_REG_BG3CNT* = 0x00E
  GBA_REG_BG0HOFS* = 0x010
  GBA_REG_BG0VOFS* = 0x012
  GBA_REG_BG1HOFS* = 0x014
  GBA_REG_BG1VOFS* = 0x016
  GBA_REG_BG2HOFS* = 0x018
  GBA_REG_BG2VOFS* = 0x01A
  GBA_REG_BG3HOFS* = 0x01C
  GBA_REG_BG3VOFS* = 0x01E
  GBA_REG_BG2PA* = 0x020
  GBA_REG_BG2PB* = 0x022
  GBA_REG_BG2PC* = 0x024
  GBA_REG_BG2PD* = 0x026
  GBA_REG_BG2X_LO* = 0x028
  GBA_REG_BG2X_HI* = 0x02A
  GBA_REG_BG2Y_LO* = 0x02C
  GBA_REG_BG2Y_HI* = 0x02E
  GBA_REG_BG3PA* = 0x030
  GBA_REG_BG3PB* = 0x032
  GBA_REG_BG3PC* = 0x034
  GBA_REG_BG3PD* = 0x036
  GBA_REG_BG3X_LO* = 0x038
  GBA_REG_BG3X_HI* = 0x03A
  GBA_REG_BG3Y_LO* = 0x03C
  GBA_REG_BG3Y_HI* = 0x03E
  GBA_REG_WIN0H* = 0x040
  GBA_REG_WIN1H* = 0x042
  GBA_REG_WIN0V* = 0x044
  GBA_REG_WIN1V* = 0x046
  GBA_REG_WININ* = 0x048
  GBA_REG_WINOUT* = 0x04A
  GBA_REG_MOSAIC* = 0x04C
  GBA_REG_BLDCNT* = 0x050
  GBA_REG_BLDALPHA* = 0x052
  GBA_REG_BLDY* = 0x054
  GBA_REG_SOUND1CNT_LO* = 0x060
  GBA_REG_SOUND1CNT_HI* = 0x062
  GBA_REG_SOUND1CNT_X* = 0x064
  GBA_REG_SOUND2CNT_LO* = 0x068
  GBA_REG_SOUND2CNT_HI* = 0x06C
  GBA_REG_SOUND3CNT_LO* = 0x070
  GBA_REG_SOUND3CNT_HI* = 0x072
  GBA_REG_SOUND3CNT_X* = 0x074
  GBA_REG_SOUND4CNT_LO* = 0x078
  GBA_REG_SOUND4CNT_HI* = 0x07C
  GBA_REG_SOUNDCNT_LO* = 0x080
  GBA_REG_SOUNDCNT_HI* = 0x082
  GBA_REG_SOUNDCNT_X* = 0x084
  GBA_REG_SOUNDBIAS* = 0x088
  GBA_REG_WAVE_RAM0_LO* = 0x090
  GBA_REG_WAVE_RAM0_HI* = 0x092
  GBA_REG_WAVE_RAM1_LO* = 0x094
  GBA_REG_WAVE_RAM1_HI* = 0x096
  GBA_REG_WAVE_RAM2_LO* = 0x098
  GBA_REG_WAVE_RAM2_HI* = 0x09A
  GBA_REG_WAVE_RAM3_LO* = 0x09C
  GBA_REG_WAVE_RAM3_HI* = 0x09E
  GBA_REG_FIFO_A_LO* = 0x0A0
  GBA_REG_FIFO_A_HI* = 0x0A2
  GBA_REG_FIFO_B_LO* = 0x0A4
  GBA_REG_FIFO_B_HI* = 0x0A6
  GBA_REG_DMA0SAD_LO* = 0x0B0
  GBA_REG_DMA0SAD_HI* = 0x0B2
  GBA_REG_DMA0DAD_LO* = 0x0B4
  GBA_REG_DMA0DAD_HI* = 0x0B6
  GBA_REG_DMA0CNT_LO* = 0x0B8
  GBA_REG_DMA0CNT_HI* = 0x0BA
  GBA_REG_DMA1SAD_LO* = 0x0BC
  GBA_REG_DMA1SAD_HI* = 0x0BE
  GBA_REG_DMA1DAD_LO* = 0x0C0
  GBA_REG_DMA1DAD_HI* = 0x0C2
  GBA_REG_DMA1CNT_LO* = 0x0C4
  GBA_REG_DMA1CNT_HI* = 0x0C6
  GBA_REG_DMA2SAD_LO* = 0x0C8
  GBA_REG_DMA2SAD_HI* = 0x0CA
  GBA_REG_DMA2DAD_LO* = 0x0CC
  GBA_REG_DMA2DAD_HI* = 0x0CE
  GBA_REG_DMA2CNT_LO* = 0x0D0
  GBA_REG_DMA2CNT_HI* = 0x0D2
  GBA_REG_DMA3SAD_LO* = 0x0D4
  GBA_REG_DMA3SAD_HI* = 0x0D6
  GBA_REG_DMA3DAD_LO* = 0x0D8
  GBA_REG_DMA3DAD_HI* = 0x0DA
  GBA_REG_DMA3CNT_LO* = 0x0DC
  GBA_REG_DMA3CNT_HI* = 0x0DE
  GBA_REG_TM0CNT_LO* = 0x100
  GBA_REG_TM0CNT_HI* = 0x102
  GBA_REG_TM1CNT_LO* = 0x104
  GBA_REG_TM1CNT_HI* = 0x106
  GBA_REG_TM2CNT_LO* = 0x108
  GBA_REG_TM2CNT_HI* = 0x10A
  GBA_REG_TM3CNT_LO* = 0x10C
  GBA_REG_TM3CNT_HI* = 0x10E
  GBA_REG_SIODATA32_LO* = 0x120
  GBA_REG_SIODATA32_HI* = 0x122
  GBA_REG_SIOMULTI2* = 0x124
  GBA_REG_SIOMULTI3* = 0x126
  GBA_REG_SIOCNT* = 0x128
  GBA_REG_SIOMLT_SEND* = 0x12A
  GBA_REG_KEYINPUT* = 0x130
  GBA_REG_KEYCNT* = 0x132
  GBA_REG_RCNT* = 0x134
  GBA_REG_JOYCNT* = 0x140
  GBA_REG_JOY_RECV_LO* = 0x150
  GBA_REG_JOY_RECV_HI* = 0x152
  GBA_REG_JOY_TRANS_LO* = 0x154
  GBA_REG_JOY_TRANS_HI* = 0x156
  GBA_REG_JOYSTAT* = 0x158
  GBA_REG_IE* = 0x200
  GBA_REG_IF* = 0x202
  GBA_REG_WAITCNT* = 0x204
  GBA_REG_IME* = 0x208
  GBA_REG_MAX* = 0x20A
  GBA_REG_INTERNAL_EXWAITCNT_LO* = 0x210
  GBA_REG_INTERNAL_EXWAITCNT_HI* = 0x212
  GBA_REG_INTERNAL_MAX* = 0x214
  GBA_REG_POSTFLG* = 0x300
  GBA_REG_HALTCNT* = 0x301
  GBA_REG_EXWAITCNT_LO* = 0x800
  GBA_REG_EXWAITCNT_HI* = 0x802
  GBA_REG_DEBUG_STRING* = 0xFFF600
  GBA_REG_DEBUG_FLAGS* = 0xFFF700
  GBA_REG_DEBUG_ENABLE* = 0xFFF780
  
  GBA_REG_SIOMULTI0* = GBA_REG_SIODATA32_LO
  GBA_REG_SIOMULTI1* = GBA_REG_SIODATA32_HI
  GBA_REG_SIODATA8* = GBA_REG_SIOMLT_SEND


## ignored statement

# let GBAIORegisterNames* {.importc.}: UncheckedArray[cstring]

type GBA = object

const
  VIDEO_HBLANK_PIXELS* = 68
  VIDEO_HDRAW_LENGTH* = 1008
  VIDEO_HBLANK_LENGTH* = 224
  VIDEO_HORIZONTAL_LENGTH* = 1232
  VIDEO_VBLANK_PIXELS* = 68
  VIDEO_VERTICAL_TOTAL_PIXELS* = 228
  VIDEO_TOTAL_LENGTH* = 280896
  OBJ_HBLANK_FREE_LENGTH* = 954
  OBJ_LENGTH* = 1210
  BASE_TILE* = 0x00010000

type
  GBAVideoObjMode* = uint32
  GBAVideoObjShape* = uint32
  GBAVideoBlendEffect* = uint32

const 
  OBJ_MODE_NORMAL = 0
  OBJ_MODE_SEMITRANSPARENT = 1
  OBJ_MODE_OBJWIN = 2

  OBJ_SHAPE_SQUARE = 0
  OBJ_SHAPE_HORIZONTAL = 1
  OBJ_SHAPE_VERTICAL = 2

  BLEND_NONE = 0
  BLEND_ALPHA = 1
  BLEND_BRIGHTEN = 2
  BLEND_DARKEN = 3


type
  GBAObjAttributesA* = uint16
  GBAObjAttributesB* = uint16
  GBAObjAttributesC* = uint16

proc GBAObjAttributesAIsY*(src: GBAObjAttributesA): GBAObjAttributesA {.inline,
    importc: "GBAObjAttributesAIsY".} =
  return (src) and (((1 shl (((0) + (8)) - ((0)))) - 1) shl ((0)))


type
  GBAObj* {.bycopy.} = object
    a*: GBAObjAttributesA
    b*: GBAObjAttributesB
    c*: GBAObjAttributesC
    d*: uint16

  GBAOAMMatrix* {.bycopy.} = object
    padding0*: array[3, int16]
    a*: int16
    padding1*: array[3, int16]
    b*: int16
    padding2*: array[3, int16]
    c*: int16
    padding3*: array[3, int16]
    d*: int16

  GBAOAM* {.bycopy, union.} = object
    obj*: array[128, GBAObj]
    mat*: array[32, GBAOAMMatrix]
    raw*: array[512, uint16]

  GBAVideoWindowRegion* {.bycopy.} = object
    `end`*: uint8
    start*: uint8

type GBARegisterDISPCNT* = distinct uint16

defineBits GBARegisterDISPCNT, 0..3, mode, uint16
defineBit GBARegisterDISPCNT, 3, cgb
defineBit GBARegisterDISPCNT, 4, frameSelect
defineBit GBARegisterDISPCNT, 5, hblankIntervalFree
defineBit GBARegisterDISPCNT, 6, objCharacterMapping
defineBit GBARegisterDISPCNT, 7, forcedBlank
defineBit GBARegisterDISPCNT, 8, bg0Enable
defineBit GBARegisterDISPCNT, 9, bg1Enable
defineBit GBARegisterDISPCNT, 10, bg2Enable
defineBit GBARegisterDISPCNT, 11, bg3Enable
defineBit GBARegisterDISPCNT, 12, objEnable
defineBit GBARegisterDISPCNT, 13, win0Enable
defineBit GBARegisterDISPCNT, 14, win1Enable
defineBit GBARegisterDISPCNT, 15, objwinEnable

type GBARegisterDISPSTAT* = distinct uint16

defineBit GBARegisterDISPSTAT, 0, inVblank
defineBit GBARegisterDISPSTAT, 1, inHblank
defineBit GBARegisterDISPSTAT, 2, vcounter
defineBit GBARegisterDISPSTAT, 3, vblankIRQ
defineBit GBARegisterDISPSTAT, 4, hblankIRQ
defineBit GBARegisterDISPSTAT, 5, vcounterIRQ
defineBits GBARegisterDISPSTAT, 8..15, vcountSetting, uint16

type GBARegisterBGCNT* = distinct uint16

defineBits GBARegisterBGCNT, 0..1, priority, uint16
defineBits GBARegisterBGCNT, 2..3, charBase, uint16
defineBit GBARegisterBGCNT, 6, mosaic
defineBit GBARegisterBGCNT, 7, is8bpp
defineBits GBARegisterBGCNT, 8..12, screenBase, uint16
defineBit GBARegisterBGCNT, 13, overflow
defineBits GBARegisterBGCNT, 14..15, size, uint16

type GBARegisterBLDCNT* = distinct uint16

defineBit GBARegisterBLDCNT, 0, target1Bg0
defineBit GBARegisterBLDCNT, 1, target1Bg1
defineBit GBARegisterBLDCNT, 2, target1Bg2
defineBit GBARegisterBLDCNT, 3, target1Bg3
defineBit GBARegisterBLDCNT, 4, target1Obj
defineBit GBARegisterBLDCNT, 5, target1Bd
defineBits GBARegisterBLDCNT, 6..7, effect, uint16
defineBit GBARegisterBLDCNT, 8, target2Bg0
defineBit GBARegisterBLDCNT, 9, target2Bg1
defineBit GBARegisterBLDCNT, 10, target2Bg2
defineBit GBARegisterBLDCNT, 11, target2Bg3
defineBit GBARegisterBLDCNT, 12, target2Obj
defineBit GBARegisterBLDCNT, 13, target2Bd

type GBAWindowControl* = distinct uint8

defineBit GBAWindowControl, 0, bg0Enable
defineBit GBAWindowControl, 1, bg1Enable
defineBit GBAWindowControl, 2, bg2Enable
defineBit GBAWindowControl, 3, bg3Enable
defineBit GBAWindowControl, 4, objEnable
defineBit GBAWindowControl, 5, blendEnable

type GBAMosaicControl* = distinct uint16

defineBits GBAMosaicControl, 0..3, bgH, uint16
defineBits GBAMosaicControl, 4..7, bgV, uint16
defineBits GBAMosaicControl, 8..11, objH, uint16
defineBits GBAMosaicControl, 12..15, objV, uint16

type
  GBAVideoRenderer* {.bycopy.} = object
    init*: proc (renderer: ptr GBAVideoRenderer) {.noconv.}
    reset*: proc (renderer: ptr GBAVideoRenderer) {.noconv.}
    deinit*: proc (renderer: ptr GBAVideoRenderer) {.noconv.}
    writeVideoRegister*: proc (renderer: ptr GBAVideoRenderer; address: uint32; value: uint16): uint16 {.noconv.}
    writeVRAM*: proc (renderer: ptr GBAVideoRenderer; address: uint32) {.noconv.}
    writePalette*: proc (renderer: ptr GBAVideoRenderer; address: uint32; value: uint16) {.noconv.}
    writeOAM*: proc (renderer: ptr GBAVideoRenderer; oam: uint32) {.noconv.}
    drawScanline*: proc (renderer: ptr GBAVideoRenderer; y: cint) {.noconv.}
    finishFrame*: proc (renderer: ptr GBAVideoRenderer) {.noconv.}
    getPixels*: proc (renderer: ptr GBAVideoRenderer; stride: var csize_t; pixels: var pointer) {.noconv.}
    putPixels*: proc (renderer: ptr GBAVideoRenderer; stride: csize_t; pixels: pointer) {.noconv.}
    palette*: ptr array[512, uint16]
    vram*: ptr array[0xC000, uint16]
    oam*: ptr GBAOAM
    cache*: ptr mCacheSet
    disableBG*: array[4, bool]
    disableOBJ*: bool
    disableWIN*: array[2, bool]
    disableOBJWIN*: bool
    highlightBG*: array[4, bool]
    highlightOBJ*: array[128, bool]
    highlightColor*: color_t
    highlightAmount*: uint8

  GBAVideo* {.bycopy.} = object
    p*: ptr GBA
    renderer*: ptr GBAVideoRenderer
    event*: mTimingEvent
    vcount*: cint
    shouldStall*: cint
    palette*: array[512, uint16]
    vram*: ptr array[0xC000, uint16]
    oam*: GBAOAM
    frameCounter*: uint32
    frameskip*: cint
    frameskipCounter*: cint


proc GBAVideoInit*(video: ptr GBAVideo) {.importc: "GBAVideoInit".}
proc GBAVideoReset*(video: ptr GBAVideo) {.importc: "GBAVideoReset".}
proc GBAVideoDeinit*(video: ptr GBAVideo) {.importc: "GBAVideoDeinit".}
proc GBAVideoDummyRendererCreate*(a1: ptr GBAVideoRenderer) {.importc: "GBAVideoDummyRendererCreate".}
proc GBAVideoAssociateRenderer*(video: ptr GBAVideo; renderer: ptr GBAVideoRenderer) {.importc: "GBAVideoAssociateRenderer".}
proc GBAVideoWriteDISPSTAT*(video: ptr GBAVideo; value: uint16) {.importc: "GBAVideoWriteDISPSTAT".}
# discard "forward decl of GBASerializedState"
# proc GBAVideoSerialize*(video: ptr GBAVideo; state: ptr GBASerializedState) {.importc: "GBAVideoSerialize".}
# proc GBAVideoDeserialize*(video: ptr GBAVideo; state: ptr GBASerializedState) {.importc: "GBAVideoDeserialize".}
let GBAVideoObjSizes* {.importc.}: array[16, array[2, cint]]

type
  GBAVideoRendererSprite* {.bycopy.} = object
    obj*: GBAObj
    y*: int16
    endY*: int16
    cycles*: int16
    index*: int8


proc GBAVideoRendererCleanOAM*(oam: ptr GBAObj; sprites: ptr GBAVideoRendererSprite; offsetY: cint): cint {.importc: "GBAVideoRendererCleanOAM".}
type
  GBAVideoSoftwareBackground* {.bycopy.} = object
    index*: cuint
    enabled*: cint
    priority*: cuint
    charBase*: uint32
    mosaic*: cint
    multipalette*: cint
    screenBase*: uint32
    overflow*: cint
    size*: cint
    target1*: cint
    target2*: cint
    x*: uint16
    y*: uint16
    refx*: int32
    refy*: int32
    dx*: int16
    dmx*: int16
    dy*: int16
    dmy*: int16
    sx*: int32
    sy*: int32
    yCache*: cint
    mapCache*: array[64, uint16]
    flags*: uint32
    objwinFlags*: uint32
    variant*: bool
    offsetX*: int32
    offsetY*: int32
    highlight*: bool

const
  OFFSET_PRIORITY* = 30
  OFFSET_INDEX* = 28

const iolen = GBA_REG_SOUND1CNT_LO shr 1

type
  WindowControl* {.bycopy.} = object
    packed*: GBAWindowControl
    priority*: int8
  
  Window* {.bycopy.} = object
    endX*: uint8
    control*: WindowControl
  
  WindowN* {.bycopy.} = object
    h*: GBAVideoWindowRegion
    v*: GBAVideoWindowRegion
    control*: WindowControl
    offsetX*: int16
    offsetY*: int16
  
  ScanlineCache* {.bycopy.} = object
    io*: array[iolen, uint16]
    scale*: array[2, array[2, int32]]
  
  GBAVideoSoftwareRenderer* {.bycopy.} = object
    d*: GBAVideoRenderer
    outputBuffer*: ptr color_t
    outputBufferStride*: cint
    temporaryBuffer*: ptr uint32
    dispcnt*: GBARegisterDISPCNT
    row*: array[GBA_VIDEO_HORIZONTAL_PIXELS, uint32]
    spriteLayer*: array[GBA_VIDEO_HORIZONTAL_PIXELS, uint32]
    spriteCyclesRemaining*: int32
    target1Obj*: cuint
    target1Bd*: cuint
    target2Obj*: cuint
    target2Bd*: cuint
    blendDirty*: bool
    blendEffect*: GBAVideoBlendEffect
    normalPalette*: array[512, color_t]
    variantPalette*: array[512, color_t]
    highlightPalette*: array[512, color_t]
    highlightVariantPalette*: array[512, color_t]
    blda*: uint16
    bldb*: uint16
    bldy*: uint16
    mosaic*: GBAMosaicControl
    greenswap*: bool
    winN*: array[2, WindowN]
    winout*: WindowControl
    objwin*: WindowControl
    currentWindow*: WindowControl
    nWindows*: cint
    windows*: array[5, Window]
    bg*: array[4, GBAVideoSoftwareBackground]
    forceTarget1*: bool
    oamDirty*: bool
    oamMax*: cint
    sprites*: array[128, GBAVideoRendererSprite]
    objOffsetX*: int16
    objOffsetY*: int16
    scanlineDirty*: array[5, uint32]            # muffin
    nextIo*: array[iolen, uint16]
    cache*: array[GBA_VIDEO_VERTICAL_PIXELS, ScanlineCache]
    nextY*: cint
    start*: cint
    `end`*: cint
    lastHighlightAmount*: uint8


proc GBAVideoSoftwareRendererCreate*(renderer: ptr GBAVideoSoftwareRenderer) {.importc: "GBAVideoSoftwareRendererCreate".}

proc init*(r: var GBAVideoSoftwareRenderer) {.inline.} = (r.d.init)(addr r.d)
proc reset*(r: var GBAVideoSoftwareRenderer) {.inline.} = (r.d.reset)(addr r.d)
proc deinit*(r: var GBAVideoSoftwareRenderer) {.inline.} = (r.d.deinit)(addr r.d)
proc writeVideoRegister*(r: var GBAVideoSoftwareRenderer; address: uint32; value: uint16): uint16 {.inline.} = (r.d.writeVideoRegister)(addr r.d, address, value)
proc writeVRAM*(r: var GBAVideoSoftwareRenderer; address: uint32) {.inline.} = (r.d.writeVRAM)(addr r.d, address)
proc writePalette*(r: var GBAVideoSoftwareRenderer; address: uint32; value: uint16) {.inline.} = (r.d.writePalette)(addr r.d, address, value)
proc writeOAM*(r: var GBAVideoSoftwareRenderer; oam: uint32) {.inline.} = (r.d.writeOAM)(addr r.d, oam)
proc drawScanline*(r: var GBAVideoSoftwareRenderer; y: cint) {.inline.} = (r.d.drawScanline)(addr r.d, y)
proc finishFrame*(r: var GBAVideoSoftwareRenderer) {.inline.} = (r.d.finishFrame)(addr r.d)
proc getPixels*(r: var GBAVideoSoftwareRenderer; stride: var csize_t; pixels: var pointer) {.inline.} = (r.d.getPixels)(addr r.d, stride, pixels)
proc putPixels*(r: var GBAVideoSoftwareRenderer; stride: csize_t; pixels: pointer) {.inline.} = (r.d.putPixels)(addr r.d, stride, pixels)
