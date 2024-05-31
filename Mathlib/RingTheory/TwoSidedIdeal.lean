/-
Copyright (c) 2024 Jujian Zhang. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jujian Zhang
-/

import Mathlib.RingTheory.Congruence
import Mathlib.RingTheory.Ideal.Basic
import Mathlib.Algebra.Module.LinearMap.Basic
import Mathlib.Algebra.Module.Opposites

/-!
# Two Sided Ideals

In this file, for any `Ring R`, we reinterpret `I : RingCon R` as a two sided ideal of a ring.

## Notes
`SetLike (RingCon R) R` makes sense for any `NonUnitalNonAssocRing R`.
But later for the `module` part, we will assume `R` is a ring.

-/

section ideal

namespace RingCon

section NonUnitalNonAssocRing

variable {R : Type*} [NonUnitalNonAssocRing R] (I : RingCon R)

instance : SetLike (RingCon R) R where
  coe t := {r | t r 0}
  coe_injective' t₁ t₂ (h : {x | _} = {x | _}) := by
    refine RingCon.ext fun a b ↦ ⟨fun H ↦ ?_, fun H ↦ ?_⟩
    · have H' : a - b ∈ {x | t₁ x 0} := sub_self b ▸  t₁.sub H (t₁.refl b)
      rw [h] at H'
      convert t₂.add H' (t₂.refl b) using 1 <;> abel
    · have H' : a - b ∈ {x | t₂ x 0} := sub_self b ▸  t₂.sub H (t₂.refl b)
      rw [← h] at H'
      convert t₁.add H' (t₁.refl b) using 1 <;> abel

lemma mem_iff (x : R) : x ∈ I ↔ I x 0 := Iff.rfl

lemma rel_iff (x y : R) : I x y ↔ (x - y) ∈ I := by
  rw [mem_iff]
  constructor
  · intro h; convert I.sub h (I.refl y); abel
  · intro h; convert I.add h (I.refl y) <;> abel

lemma le_iff (I J : RingCon R) : I ≤ J ↔ (I : Set R) ⊆ (J : Set R) := by
  constructor
  · intro h x hx
    exact h hx
  · intro h x y hxy
    have h' : J _ _ := h <| sub_self y ▸ I.sub hxy (I.refl y)
    convert J.add h' (J.refl y) <;>
    abel

lemma lt_iff (I J : RingCon R) : I < J ↔ (I : Set R) ⊂ (J : Set R) := by
  rw [lt_iff_le_and_ne, Set.ssubset_iff_subset_ne, le_iff]
  simp

lemma zero_mem : 0 ∈ I := I.refl 0

lemma add_mem {x y} (hx : x ∈ I) (hy : y ∈ I) : x + y ∈ I := by
  simpa using I.add hx hy

lemma neg_mem {x} (hx : x ∈ I) : -x ∈ I := by
  simpa using I.neg hx

lemma sub_mem {x y} (hx : x ∈ I) (hy : y ∈ I) : x - y ∈ I := by
  simpa using I.sub hx hy

lemma mul_mem_left (x y) (hy : y ∈ I) : x * y ∈ I := by
  simpa using I.mul (I.refl x) hy

lemma mul_mem_right (x y) (hx : x ∈ I) : x * y ∈ I := by
  simpa using I.mul hx (I.refl y)

instance : AddSubgroupClass (RingCon R) R where
  zero_mem := zero_mem
  add_mem := @add_mem _ _
  neg_mem := @neg_mem _ _

instance : Add I where add x y := ⟨x.1 + y.1, I.add_mem x.2 y.2⟩

instance : Zero I where zero := ⟨0, I.zero_mem⟩

instance : SMul ℕ I where
  smul n x := ⟨n • x.1, by simpa using I.nsmul _ x.2⟩

instance : Neg I where neg x := ⟨-x.1, I.neg_mem x.2⟩

instance : Sub I where sub x y := ⟨x.1 - y.1, I.sub_mem x.2 y.2⟩

instance : SMul ℤ I where
  smul n x := ⟨n • x.1, by simpa using I.zsmul n x.2⟩

instance : AddCommGroup I :=
  Function.Injective.addCommGroup _ Subtype.coe_injective
    rfl (fun _ _ ↦ rfl) (fun _ ↦ rfl) (fun _ _ ↦ rfl) (fun _ _ ↦ rfl) (fun _ _ ↦ rfl)

/-- The coercion into the ring as a `AddMonoidHom` -/
@[simp]
def coeAddMonoidHom : I →+ R where
  toFun := (↑)
  map_zero' := rfl
  map_add' _ _ := rfl

end NonUnitalNonAssocRing

section ring

variable {R : Type*} [Ring R] (I : RingCon R)

instance : SMul R I where smul r x := ⟨r • x.1, I.mul_mem_left _ _ x.2⟩

instance : SMul Rᵐᵒᵖ I where smul r x := ⟨r • x.1, I.mul_mem_right _ _ x.2⟩

instance : Module R I :=
  Function.Injective.module _ (coeAddMonoidHom I) Subtype.coe_injective fun _ _ => rfl

instance : Module Rᵐᵒᵖ I :=
  Function.Injective.module _ (coeAddMonoidHom I) Subtype.coe_injective fun _ _ => rfl

instance : SMulCommClass R Rᵐᵒᵖ I where
  smul_comm r s x := Subtype.ext <| smul_comm r s x.1

/--
For any `I : RingCon R`, when we view it as an ideal, `I.subtype` is the injective `R`-linear map
`I → R`.
-/
@[simps]
def subtype : I →ₗ[R] R where
  toFun x := x.1
  map_add' _ _ := rfl
  map_smul' _ _ := rfl

/--
For any `RingCon R`, when we view it as an ideal in `Rᵒᵖ`, `subtype` is the injective `Rᵐᵒᵖ`-linear
map `I → Rᵐᵒᵖ`.
-/
@[simps]
def subtypeMop : I →ₗ[Rᵐᵒᵖ] Rᵐᵒᵖ where
  toFun x := MulOpposite.op x.1
  map_add' _ _ := rfl
  map_smul' _ _ := rfl

end ring

section operations

variable {R : Type*} [Ring R] (I : RingCon R)

/--
Every two-sided ideal is also a left ideal.
-/
def toIdeal : Ideal R := LinearMap.range I.subtype

lemma mem_toIdeal {x} : x ∈ I.toIdeal ↔ x ∈ I := by simp [toIdeal]

/--
Every two-sided ideal is also a right ideal.
-/
def toIdealMop : Ideal Rᵐᵒᵖ := LinearMap.range I.subtypeMop

lemma mem_toIdealMop {x} : x ∈ I.toIdealMop ↔ x.unop ∈ I := by
  simp only [toIdealMop, LinearMap.mem_range, subtypeMop_apply, Subtype.exists, exists_prop]
  constructor
  · rintro ⟨a, ha, rfl⟩; simpa
  · intro h; exact ⟨x.unop, h, rfl⟩

lemma mem_toIdealMop' {x} : (MulOpposite.op x) ∈ I.toIdealMop ↔ x ∈ I := by
  rw [mem_toIdealMop]; rfl

/--
The smallest two-sided-ideal contain a set.
-/
def span (s : Set R) : RingCon R := ringConGen (fun a b ↦ a - b ∈ s)

lemma subset_span {s : Set R} : s ⊆ (span s : Set R) := by
  intro x hx
  rw [SetLike.mem_coe, mem_iff]
  exact RingConGen.Rel.of _ _ (by simpa using hx)

lemma mem_span_iff {s : Set R} {x} :
    x ∈ span s ↔ ∀ (I : RingCon R), s ⊆ I → x ∈ I := by
  refine ⟨?_, fun h => h _ subset_span⟩
  delta span
  rw [ringConGen_eq]
  intro h I hI
  refine sInf_le (α := RingCon R) ?_ h
  intro x y hxy
  specialize hI hxy
  rwa [SetLike.mem_coe, ← rel_iff] at hI

/--
Every left ideal generates a two sided ideal.
-/
def fromIdeal (I : Ideal R) : RingCon R := span I

lemma fromIdeal_toIdeal : fromIdeal I.toIdeal = I := by
  refine SetLike.ext fun x ↦ ?_
  simp only [fromIdeal, toIdeal, mem_span_iff]
  constructor
  · intro H
    refine H I ?_
    rintro _ ⟨x, rfl⟩
    exact x.2
  · intro hx J hJ
    exact hJ ⟨⟨x, hx⟩, rfl⟩

lemma le_toIdeal_fromIdeal (J : Ideal R) : J ≤ (fromIdeal J).toIdeal  := by
  intro x hx
  simp only [toIdeal, fromIdeal, LinearMap.mem_range, subtype_apply, Subtype.exists, exists_prop,
    exists_eq_right] at hx ⊢
  exact subset_span hx

end operations

end RingCon

end ideal
