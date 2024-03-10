/-
Copyright (c) 2024 Damiano Testa. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Damiano Testa
-/
import Lean.Elab.Command
import Std.Data.Array.Basic

/-!
#  The non-terminal `simp` linter

The non-terminal `simp` linter makes sure that `simp` is not used as a finishing tactic.
If you want to use `simp [...]` followed by other tactics, then replace `simp [...]`
by the output of `simp? [...]`, so that the final code contains `simp only [...]`.

Currently, the linter is conservative in catching non-terminal `simp`s.
It only uses syntax information.
In its current form, the linter can be fooled in at least two ways:
```lean
import Mathlib.Tactic.Basic

-- a false positive: `simp` is flagged, but it should not be
example (x : Bool) : x = x := by
  cases x <;> [simp; simp]  -- the first `simp` is considered "non-terminal"

-- a false negative: `simp` should be flagged, but is not
example (n : Nat) (h : False) : n = n - 1 := by
  cases n <;> simp  -- an actual non-terminal `simp` that is not flagged
  exact h.elim
```

TODO: fix the linter so that the cases above are classified correctly!
-/

open Lean

namespace Mathlib.Linter

/-- The non-terminal `simp` linter makes sure that `simp` is not used as a finishing tactic. -/
register_option linter.nonTerminalSimp : Bool := {
  defValue := true
  descr := "enable the 'non-terminal `simp`' linter"
}

namespace nonTerminalSimpLinter

/-- `onlyOrNotSimp stx` if `stx` is syntax for `simp` *without* `only`, then returns `false` else
returchecks whether `stx` is `simp only -/
def onlyOrNotSimp : Syntax → Bool
  | .node _info `Lean.Parser.Tactic.simp #[_, _, _, only?, _, _] => only?[0].getAtomVal == "only"
  | _ => true

variable {m : Type → Type} [Monad m] [MonadLog m] [AddMessageContext m] [MonadOptions m] in
/-- `nonTerminalSimp stx` loops inside `stx` looking for nodes corresponding to `simp` calls
that are not `simp only` calls.  Among those, it checks whether there are further tactics
after the `simp`, and, if there are, then it emits a warning. -/
partial
def nonTerminalSimp : Syntax → m Unit
  | .node _ _ args => do
    match args.findIdx? (! onlyOrNotSimp ·) with
      | none => default
      | some n =>
        for i in [n+1:args.size] do
          if "Lean.Parser.Tactic".isPrefixOf args[i]!.getKind.toString then
            logWarningAt args[n]!
              "non-terminal simp: consider replacing it with\n\
                * `suffices \"expr after simp\" by simpa`\n\
                * the output of `simp?`\n\
                [linter.nonTerminalSimp]"
    let _ ← args.mapM nonTerminalSimp
  | _ => default

/-- Gets the value of the `linter.nonTerminalSimp` option. -/
def getLinterHash (o : Options) : Bool := Linter.getLinterValue linter.nonTerminalSimp o

@[inherit_doc linter.nonTerminalSimp]
def nonTerminalSimpLinter : Linter where run := withSetOptionIn fun stx => do
  if getLinterHash (← getOptions) then
    nonTerminalSimp stx

initialize addLinter nonTerminalSimpLinter

open Elab Command
partial
def warnIfTest : Syntax → CommandElabM Unit
  | stx@(.node _ _ args) => do
--    let tot := (args.map warnIfTest).foldl (· ++ ·)
--    dbg_trace stx.getKind
--    let relevant := args.filter fun t =>
--      let tk := t.getKind
--      (tk == `Std.Tactic.seq_focus || "Lean.Parser.Tactic".isPrefixOf tk.toString)
    let relevant := args.map fun t =>
      let tk := t.getKind
      if (tk == `Std.Tactic.seq_focus || "Lean.Parser.Tactic".isPrefixOf tk.toString)
      then some t
      else none
    let ropt := relevant.reduceOption
    let mut simp_followed := #[]
    for i in [:ropt.size] do
      if i + 1 < ropt.size && ! onlyOrNotSimp ropt[i]! then
        simp_followed := simp_followed.push ropt[i]!
        logWarningAt ropt[i]! "here"
    dbg_trace "simp_followed: {simp_followed}"
    dbg_trace ropt.map (·.getKind)
--    let trueFollowedByFalse? := ropt.map (! onlyOrNotSimp ·)
--    dbg_trace "here: {trueFollowedByFalse?}: {trueFollowedByFalse trueFollowedByFalse?.toList}"
--    let filtr := ropt.filter (·.getKind == `Std.Tactic.seq_focus)
--    if filtr != #[] then
--      dbg_trace "**  found one {args.size}\n\n {filtr}"
--      return (← args.mapM warnIfTest).foldl (· ++ ·) default
--    else
--      return (← args.mapM warnIfTest).foldl (· ++ ·) default
    let (tSeq, new) := args.partition (·.getKind == `Std.Tactic.seq_focus)
    let _ ← new.mapM warnIfTest
--    let _ ← tSeq.mapM warnIfTest
    dbg_trace "tSeq: {tSeq}\nArg 3: {tSeq.map (·.getArg 3)}"
    let tSeq3 := tSeq.map (·.getArg 3)
    for ts in tSeq3 do
      for sts in ts.getArgs do warnIfTest sts
--      let tArgs := ts.getArgs
--      for i in [:tArgs.size / 2 + 1] do
--        logInfo (m!"inspect: '{tArgs[2 * i]!}'\n\n".compose (treeR tArgs[2 * i]! (sep := "|   ")))
--
--        dbg_trace "arg {i}: {tArgs[2 * i]!}"
--        warnIfTest tArgs[2 * i]!
--    return (← args.mapM warnIfTest).foldl (· ++ ·) default
  | _ => return default
