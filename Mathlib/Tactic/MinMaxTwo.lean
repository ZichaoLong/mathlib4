/-
Copyright (c) 2024 Damiano Testa. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Damiano Testa
-/

import Lean.Elab.Command
/-!
#  `to_ama` a command to convert from `MonoidAlgebra` to `AddMonoidAlgebra`

If `thm` is a theorem about `MonoidAlgebra`, then `to_ama thm` tries to add to the
environment the analogous result about `AddMonoidAlgebra`.
-/

open Lean Elab Command

namespace Mathlib.MA

/-- `toAddWords` performs a subset of what `to_additive` would do. -/
abbrev toAddWords : HashMap String String := HashMap.empty
  |>.insert "Mul"       "Add"
  |>.insert "Semigroup" "AddSemigroup"
  |>.insert "CommMonoid" "AddCommMonoid"
  |>.insert "Monoid" "AddMonoid"
  |>.insert "CommSemigroup" "AddCommSemigroup"
  |>.insert "MulOneClass" "AddZeroClass"
  |>.insert "MonoidAlgebra" "AddMonoidAlgebra"
  |>.insert "monoid" "add_monoid"

/-- splits a string into maximal substrings consisting of either `[alpha]*` or `[non-alpha]*`. -/
def splitAlpha (s : String) : List String :=
  s.toList.groupBy (fun a b => (a.isAlpha && b.isAlpha)) |>.map (⟨·⟩)

/-- replaces "words" in a string using `convs`.  It breaks the string into "words"
grouping together maximal consecutive substrings consisting of
either `[uppercase]*[lowercase]*` or a single `non-alpha`. -/
def stringReplacements (convs : HashMap String String) (str : String) : String :=
  String.join <| (splitAlpha str).map fun s => (convs.find? s).getD s

variable (convs : HashMap String String) in
/-- converts a name involving `WithBot` to a name involving `WithTop`. -/
def nameToTop : Name → Name
  | .str a b => .str (nameToTop a) (stringReplacements convs b)
  | _ => default

variable (convs : HashMap String String) (toMultArrow : Name) (toMult : Name) (toPlus : Name) in
/-- converts `WithBot _` to `ℕ∞` and `⊥` to `⊤`.
Useful when converting a `degree` with values in `WithBot ℕ` to a `trailingDegree` with values
in `ℕ∞`. -/
def MaxToMin (stx : Syntax) : CommandElabM Syntax := do
  let stx ← stx.replaceM fun s => do
    match s.getId with
      | .anonymous => return none
      | v => return some (mkIdent (nameToTop convs v))

  stx.replaceM fun s => do
    match s with
      | .node _ `«term_*_» #[a, _, b] =>
        if (a.getId != .anonymous) && a.getId == toPlus then
          return some <| ← `($(⟨a⟩) + $(⟨b⟩))
        else return none
      | .node _ ``Lean.Parser.Term.app
          #[.ident _ _ `single _, .node _ _ #[one, c]] =>
        match one with
          | `(1)           => return some <| ← `($(mkIdent `single) 0 $(⟨c⟩))
          | `((1 : $type)) => return some <| ← `($(mkIdent `single) (0 : $(⟨type⟩)) $(⟨c⟩))
          | _ => return none
      | .node _ ``Lean.Parser.Term.app #[.ident _ _ na _, .node _ _ #[b]] =>
        match na with
          | _ => if na != toMultArrow then return none else
                    return some <| ← `($(mkIdent na) ($(mkIdent `Multiplicative.ofAdd) $(⟨b⟩)))
      | .ident _ _ x _ => if x != toMult then return none else
                return some <| ← `($(mkIdent `Multiplicative) $(mkIdent x))
      | .node _ ``Lean.Parser.Command.docComment #[init, .atom _ docs] =>
        let newDocs := stringReplacements convs docs
        let newDocs :=
          if newDocs == docs
          then "[recycled by `to_top`] " ++ docs
          else "[autogenerated by `to_top`] " ++ newDocs
        let nd := mkNode ``Lean.Parser.Command.docComment #[init, mkAtom newDocs]
        return some nd
      | .node _ ``Lean.Parser.Term.explicitBinder
        #[_, -- `(`
          .node _ _ #[.ident _ _ `g _],
          .node _ _ #[
            _, -- `:`
            .node _ ``Lean.Parser.Term.arrow
            #[.ident _ _ `G _,
              .atom _ _,
              .ident _ _ `R _]],
          _, _] => -- `)`
            let MultGtoR ← `($(mkIdent `Multiplicative) $(mkIdent `G) → $(mkIdent `R))
            return some <| Term.mkExplicitBinder (mkIdent `g) MultGtoR
      | _ => return none

/--
If `thm` is a theorem about `MonoidAlgebra`, then `to_ama thm` tries to add to the
environment the analogous result about `AddMonoidAlgebra`.

Writing `to_ama?` also prints the extra declaration added by `to_ama`.
-/
elab (name := to_amaCmd) "to_ama " tk:("?")? "[" id:(ident)? "]" id2:(ident)? "plus"? id3:(ident)? "noplus"? cmd:command :
    command => do
  let g := match id with | some id => id.getId | _ => default
  let h := match id2 with | some id => id.getId | _ => default
  let i := match id3 with | some id => id.getId | _ => default
  let newCmd ← MaxToMin toAddWords g h i cmd
  if tk.isSome then logInfo m!"-- adding\n{newCmd}"
  elabCommand cmd
  if (← get).messages.hasErrors then return
  let currNS ← getCurrNamespace
  withScope (fun s => { s with currNamespace := nameToTop toAddWords currNS }) <| elabCommand newCmd

@[inherit_doc to_amaCmd]
macro "to_ama? " "[" id:(ident)? "]" cmd:command : command =>
  let rid := mkIdent `hi
  return (← `(to_ama ? [$(id.getD default)] $rid noplus $cmd))

@[inherit_doc to_amaCmd]
macro "to_ama? " cmd:command : command =>
  let rid := mkIdent `hi
  return (← `(to_ama ? [] $rid noplus $cmd))

@[inherit_doc to_amaCmd]
macro "to_ama " id:ident cmd:command : command =>
  return (← `(to_ama [] $id noplus $cmd))

@[inherit_doc to_amaCmd]
macro "to_ama " "plus" id:ident cmd:command : command =>
  return (← `(to_ama [] $id plus $id noplus $cmd))

@[inherit_doc to_amaCmd]
macro "to_ama " cmd:command : command =>
  let rid := mkIdent `hi
  return (← `(to_ama [] $rid noplus $cmd))
