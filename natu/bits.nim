import macros

type
  FieldFlag* = enum
    ReadOnly
    WriteOnly
    Private

macro defineBitsImpl(
  bitfieldType: typedesc;
  fromBit, toBit: static[int];
  fieldIdent: untyped;
  fieldType: typedesc;
  flags: static set[FieldFlag]
) =
  ## Define a getter/setter template for a range of bits on a distinct type.
  ## 
  ## Implementation for `defineBits` and `defineBit`.
  ##
  ## Note: ``fromBit..toBit`` range is inclusive.  
  
  let bitfieldTypeDef = getImpl(bitfieldType)
  if bitfieldTypeDef[2].kind != nnkDistinctTy:
    error("bitfield type not distinct (`defineBits` can only be applied to distinct unsigned integer types)", bitfieldType)
  
  let distinctType = bitfieldTypeDef[2][0]
  if distinctType.strVal notin ["byte", "uint", "uint8", "uint16", "uint32", "uint64"]:
    error("bitfield type not an unsigned integer (`defineBits` can only be applied to distinct unsigned integer types)", bitfieldType)
  
  if fieldIdent.kind != nnkIdent:
    error("Expect identifier to be used as the name of the getter/setter", fieldIdent)
  
  let fieldBits = (toBit+1) - fromBit
  if fieldBits <= 0:
    error("Supplied range " & $fromBit & ".." & $toBit & " has 0 or fewer bits")
  
  # generate getter / setter for field
  var getterName = fieldIdent
  var setterName = nnkAccQuoted.newTree(fieldIdent, ident("="))
  if Private notin flags:
    getterName = postfix(getterName, "*")
    setterName = postfix(setterName, "*")
  
  var mask = 0'u
  for i in fromBit..toBit:
    mask = mask or (1'u shl i)
  
  let maskLit = newLit(mask)
  let shiftLit = newLit(fromBit)
  
  result = newStmtList()
  
  if WriteOnly notin flags:
    result.add quote do:
      proc `getterName`(b: `bitfieldType`): `fieldType` {.inline.} =
        ((b.`distinctType` and `maskLit`.`distinctType`) shr `shiftLit`).`fieldType`
  
  if ReadOnly notin flags:
    result.add quote do:
      proc `setterName`(b: var `bitfieldType`, v: `fieldType`) {.inline.} =
        ## NOTE: this may not work with -O0 if b is unaligned.
        ## But using `template` makes the compiler unhappy.
        b = (
          (v.`distinctType` shl `shiftLit` and `maskLit`.`distinctType`) or
          (b.`distinctType` and not `maskLit`.`distinctType`)
        ).`bitfieldType`
    
  # echo repr(result)


template defineBits*(
    bitfieldType: typedesc,
    bits: Slice[SomeInteger],
    fieldIdent: untyped,
    fieldType: typedesc = int,
    flags: static set[FieldFlag] = {}
  ) =
    defineBitsImpl(bitfieldType, bits.a, bits.b, fieldIdent, fieldType, flags)

template defineBit*(
    bitfieldType: typedesc,
    bit: SomeInteger,
    fieldIdent: untyped,
    fieldType: typedesc = bool,
    flags: static set[FieldFlag] = {}
  ) =
    defineBitsImpl(bitfieldType, bit, bit, fieldIdent, fieldType, flags)


when isMainModule:
  
  type Foo* = distinct uint16
  
  Foo.defineBits(0..0, hflip, bool)
  Foo.defineBit(1, vflip)
  Foo.defineBits(2..3, doorStyle)
  