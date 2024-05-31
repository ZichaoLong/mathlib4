import Mathlib.Tactic.Linter.Style
import Mathlib.Tactic.Common

/-! Tests for all the style linters. -/

/-! Tests for the `setOption` linter -/
section setOption

-- The warning generated by `linter.setOption` is not suppressed by `#guard_msgs`,
-- because the linter is run on `#guard_msgs` itself. This is a known issue, see e.g.
-- https://leanprover.zulipchat.com/#narrow/stream/348111-batteries/topic/unreachableTactic.20linter.20not.20suppressed.20by.20.60.23guard_msgs.60
-- We jump through an extra hoop here to silence the warning.

-- All types of options are supported: boolean, numeric and string-valued.
-- On the top level, i.e. as commands.

set_option linter.setOption false in
/--
warning: Forbidden set_option `pp.all`; please remove
note: this linter can be disabled with `set_option linter.setOption false`
-/
#guard_msgs in
set_option linter.setOption true in
set_option pp.all true

set_option linter.setOption false in
/--
warning: Forbidden set_option `pp.all`; please remove
note: this linter can be disabled with `set_option linter.setOption false`
-/
#guard_msgs in
set_option linter.setOption true in
set_option pp.all false

set_option linter.setOption false in
/--
warning: Forbidden set_option `pp.raw.maxDepth`; please remove
note: this linter can be disabled with `set_option linter.setOption false`
-/
#guard_msgs in
set_option linter.setOption true in
set_option pp.raw.maxDepth 32

set_option linter.setOption false in
/--
warning: Forbidden set_option `trace.profiler.output`; please remove
note: this linter can be disabled with `set_option linter.setOption false`
-/
#guard_msgs in
set_option linter.setOption true in
set_option trace.profiler.output "foo"

-- The lint does not fire on arbitrary options.
set_option autoImplicit false

-- We also cover set_option tactics.

set_option linter.setOption false in
/--
warning: Forbidden set_option `pp.all`; please remove
note: this linter can be disabled with `set_option linter.setOption false`
-/
#guard_msgs in
set_option linter.setOption true in
lemma tactic : True := by
  set_option pp.all true in
  trivial

set_option linter.setOption false in
/--
warning: Forbidden set_option `pp.raw.maxDepth`; please remove
note: this linter can be disabled with `set_option linter.setOption false`
-/
#guard_msgs in
set_option linter.setOption true in
lemma tactic2 : True := by
  set_option pp.raw.maxDepth 32 in
  trivial

set_option linter.setOption false in
/--
warning: Forbidden set_option `pp.all`; please remove
note: this linter can be disabled with `set_option linter.setOption false`
-/
#guard_msgs in
set_option linter.setOption true in
lemma tactic3 : True := by
  set_option pp.all false in
  trivial

set_option linter.setOption false in
/--
warning: Forbidden set_option `trace.profiler.output`; please remove
note: this linter can be disabled with `set_option linter.setOption false`
-/
#guard_msgs in
set_option linter.setOption true in
lemma tactic4 : True := by
  set_option trace.profiler.output "foo" in
  trivial

-- This option is not affected, hence does not throw an error.
set_option autoImplicit true in
lemma foo' : True := trivial

-- TODO: add terms for the term form

end setOption

-- Tests for the linter on anonymous lambda syntax.
section lambdaSyntax

set_option linter.lambdaFunction true

set_option linter.lambdaFunction false

def foo : ℕ → ℕ := λ _n ↦ 2

def bar : ℕ → ℕ := fun _n ↦ 2

end lambdaSyntax
