/-
Copyright (c) 2024 Damiano Testa. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Damiano Testa
-/

import Mathlib.Util.CountHeartbeats

/-!
A linter that flags tactic `rfl`s that take over `10 ^ 5` heartbeats to elaborate.
-/

open Lean Elab Command

/-!
#  The "heavyRfl" linter

For "each" tactic `rfl`, the "heavyRfl" linter prints the number of heartbeats that it takes
to elaborate it, assuming that it exceeds the linter's value (set to `10 ^5` by default).
-/

open Lean Elab

namespace Mathlib.Linter

/-- The "heavyRfl" linter prints the number of heartbeat that a tactic `rfl` uses, if they exceed
the value of the linter option. -/
register_option linter.heavyRfl : Nat := {
  defValue := 10 ^ 5
  descr := "enable the heavyRfl linter"
}

namespace HeavyRfl

@[inherit_doc Mathlib.Linter.linter.heavyRfl]
def heavyRflLinter : Linter where run := withSetOptionIn fun stx ↦ do
  let hbBd ← getNatOption `linter.heavyRfl linter.heavyRfl.defValue
  unless hbBd != 0 do
    return
  if (← get).messages.hasErrors then
    return
  unless (stx.isOfKind ``Lean.Parser.Command.declaration) do return
  unless (stx.find? (·.isOfKind ``Lean.Parser.Tactic.tacticRfl)).isSome do return
  if (stx.find? (·.isOfKind `to_additive)).isSome then return
  if (stx.find? (·.isOfKind ``Lean.Parser.Term.namedArgument)).isSome then return
  let hbStx := Syntax.mkNumLit s!"{hbBd}"
  let declId :=
    (stx.find? (·.isOfKind ``Lean.Parser.Command.declId)).getD (mkNode `null #[mkIdent `ohHi])
  let declName    := declId[0].getId
  let newDeclName := ((← getScope).currNamespace ++ declName ++ `_hb)
  let newId       := mkIdentFrom declId[0] newDeclName
  let newDeclId   := mkNode ``Lean.Parser.Command.declId #[newId, declId.getArgs.back]
  let repl ← stx.replaceM fun s => do
    match s with
      | .node _ ``Lean.Parser.Tactic.tacticRfl _ =>
        return some (← `(tactic| count_heartbeats_over $hbStx ($(⟨s⟩); done)))
      | .node _ ``Lean.Parser.Command.declId _ =>
        return some newDeclId
      | .ident _ _ dName _ =>
        if dName == declName then return some newId else return none
      | _ => return none
--  withScope (fun sc => {sc with currNamespace := `X ++ sc.currNamespace}) do
  --logInfo repl
  let s ← get
  dbg_trace "Declaration '{(← getScope).currNamespace ++ declName}'"
  elabCommand repl
  set s

initialize addLinter heavyRflLinter

end HeavyRfl

end Mathlib.Linter
