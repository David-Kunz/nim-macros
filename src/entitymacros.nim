import macros
import sugar
import sequtils
import fusion/matching

template readonly {.pragma.}
template mandatory {.pragma.}

type
  Entity = ref object of RootObj
  Book = ref object of Entity
    id: int
    name {.readonly.}: string
    important {.readonly, mandatory.}: string

func getTableName(e: typedesc[Entity]): string =
  $e

type Col = object
  name: string
  ty: string

func getColumns(e: typedesc[Entity]): seq[Col] =
  var x = new e
  for field, val in x[].fieldPairs:
    result.add(Col(name: field, ty: $typeof(val)))


type Pragma = object
  name: string
  field: string

macro getPragmas(t: typedesc[Entity]): untyped =
  let myTreeImpl = t.getTypeInst[1].getImpl
  var pragmas: seq[Pragma] = @[]
  if myTreeImpl.matches(TypeDef[_, _, RefTy[ObjectTy[_, _, RecList[all @identDefs]]]]):
    for identDef in identDefs:
      if identDef.matches(IdentDefs[PragmaExpr[all @prags], _, _]):
        if prags[0].matches(@ident is Ident()) and prags[1].matches(Pragma[all @sym is Sym()]):
          for singleSym in sym:
            var pragma = Pragma(name: singleSym.strVal, field: ident.strVal)
            pragmas.add(pragma)

  return quote do:
    `pragmas`


proc hasPragma(e: typedesc[Entity], field: string, pragma: string): bool =
  const pragmas = e.getPragmas()
  return pragmas.any(x => x.field == field and x.name == pragma)

proc isReadonly(e: typedesc[Entity], field: string): bool =
  return e.hasPragma(field, "readonly")

proc isMandatory(e: typedesc[Entity], field: string): bool =
  return e.hasPragma(field, "mandatory")

echo Book.getTableName()
for col in Book.getColumns:
  echo "  " & col.name & " (" & col.ty & ")"
assert Book.isReadonly("name")
assert Book.isMandatory("important")
assert Book.isReadonly("important")
