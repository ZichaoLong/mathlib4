/-
Copyright (c) 2015 Nathaniel Thomas. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Nathaniel Thomas, Jeremy Avigad, Johannes Hölzl, Mario Carneiro
-/
import Mathlib.Algebra.Field.Basic
import Mathlib.Algebra.Group.Indicator
import Mathlib.Algebra.Module.Basic
import Mathlib.Algebra.Order.Field.Rat
import Mathlib.GroupTheory.GroupAction.Group

/-!
# Modules over the field of rational numbers

-/

open Function Set

universe u v

variable {α R M M₂ : Type*}

theorem map_ratCast_smul [AddCommGroup M] [AddCommGroup M₂] {F : Type*} [FunLike F M M₂]
    [AddMonoidHomClass F M M₂] (f : F) (R S : Type*) [DivisionRing R] [DivisionRing S] [Module R M]
    [Module S M₂] (c : ℚ) (x : M) :
    f ((c : R) • x) = (c : S) • f x := by
  rw [Rat.cast_def, Rat.cast_def, div_eq_mul_inv, div_eq_mul_inv, mul_smul, mul_smul,
    map_intCast_smul f R S, map_inv_natCast_smul f R S]
#align map_rat_cast_smul map_ratCast_smul

@[deprecated (since := "2024-04-17")]
alias map_rat_cast_smul := map_ratCast_smul

theorem map_rat_smul [AddCommGroup M] [AddCommGroup M₂]
    [_instM : Module ℚ M] [_instM₂ : Module ℚ M₂]
    {F : Type*} [FunLike F M M₂] [AddMonoidHomClass F M M₂]
    (f : F) (c : ℚ) (x : M) : f (c • x) = c • f x :=
  map_ratCast_smul f ℚ ℚ c x
#align map_rat_smul map_rat_smul

/-- There can be at most one `Module ℚ E` structure on an additive commutative group. -/
instance subsingleton_rat_module (E : Type*) [AddCommGroup E] : Subsingleton (Module ℚ E) :=
  ⟨fun P Q => (Module.ext' P Q) fun r x =>
    map_rat_smul (_instM := P) (_instM₂ := Q) (AddMonoidHom.id E) r x⟩
#align subsingleton_rat_module subsingleton_rat_module

/-- If `E` is a vector space over two division rings `R` and `S`, then scalar multiplications
agree on rational numbers in `R` and `S`. -/
theorem ratCast_smul_eq {E : Type*} (R S : Type*) [AddCommGroup E] [DivisionRing R]
    [DivisionRing S] [Module R E] [Module S E] (r : ℚ) (x : E) : (r : R) • x = (r : S) • x :=
  map_ratCast_smul (AddMonoidHom.id E) R S r x
#align rat_cast_smul_eq ratCast_smul_eq

@[deprecated (since := "2024-04-17")]
alias rat_cast_smul_eq := ratCast_smul_eq

instance IsScalarTower.rat {R : Type u} {M : Type v} [Ring R] [AddCommGroup M] [Module R M]
    [Module ℚ R] [Module ℚ M] : IsScalarTower ℚ R M where
  smul_assoc r x y := map_rat_smul ((smulAddHom R M).flip y) r x
#align is_scalar_tower.rat IsScalarTower.rat

instance SMulCommClass.rat {R : Type u} {M : Type v} [Semiring R] [AddCommGroup M] [Module R M]
    [Module ℚ M] : SMulCommClass ℚ R M where
  smul_comm r x y := (map_rat_smul (smulAddHom R M x) r y).symm
#align smul_comm_class.rat SMulCommClass.rat

instance SMulCommClass.rat' {R : Type u} {M : Type v} [Semiring R] [AddCommGroup M] [Module R M]
    [Module ℚ M] : SMulCommClass R ℚ M :=
  SMulCommClass.symm _ _ _
#align smul_comm_class.rat' SMulCommClass.rat'

-- see note [lower instance priority]
instance (priority := 100) RatModule.noZeroSMulDivisors [AddCommGroup M] [Module ℚ M] :
    NoZeroSMulDivisors ℤ M :=
  ⟨fun {k} {x : M} h => by
    simpa only [zsmul_eq_smul_cast ℚ k x, smul_eq_zero, Rat.zero_iff_num_zero] using h⟩
  -- Porting note: old proof was:
  --⟨fun {k x} h => by simpa [zsmul_eq_smul_cast ℚ k x] using h⟩
#align rat_module.no_zero_smul_divisors RatModule.noZeroSMulDivisors
