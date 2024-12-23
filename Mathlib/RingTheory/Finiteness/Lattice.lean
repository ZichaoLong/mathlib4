/-
Copyright (c) 2020 Johan Commelin. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johan Commelin
-/
import Mathlib.Data.Fintype.Lattice
import Mathlib.RingTheory.Finiteness.Basic

/-!
# Finite suprema of finite modules

-/

namespace Submodule

open Module

variable {R V} [Ring R] [AddCommGroup V] [Module R V]

/-- The submodule generated by a supremum of finite dimensional submodules, indexed by a finite
sort is finite-dimensional. -/
instance finite_iSup {ι : Sort*} [Finite ι] (S : ι → Submodule R V)
    [∀ i, Module.Finite R (S i)] : Module.Finite R ↑(⨆ i, S i) := by
  cases nonempty_fintype (PLift ι)
  rw [← iSup_plift_down, ← Finset.sup_univ_eq_iSup]
  exact Submodule.finite_finset_sup _ _

end Submodule
