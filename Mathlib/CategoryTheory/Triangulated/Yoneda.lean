/-
Copyright (c) 2024 Joël Riou. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Joël Riou
-/
import Mathlib.Algebra.Homology.ShortComplex.Ab
import Mathlib.CategoryTheory.Preadditive.Yoneda.Basic
import Mathlib.CategoryTheory.Shift.ShiftedHomOpposite
import Mathlib.CategoryTheory.Triangulated.HomologicalFunctor
import Mathlib.CategoryTheory.Triangulated.Opposite

/-!
# The Yoneda functors are homological

Let `C` be a pretriangulated category. In this file, we show that the
functors `preadditiveCoyoneda.obj A : C ⥤ AddCommGrp` for `A : Cᵒᵖ` and
`preadditiveYoneda.obj B : Cᵒᵖ ⥤ AddCommGrp` for `B : C` are homological functors.

-/

namespace CategoryTheory

open Limits Opposite Pretriangulated.Opposite

namespace Pretriangulated

variable {C : Type*} [Category C] [Preadditive C] [HasZeroObject C] [HasShift C ℤ]
  [∀ (n : ℤ), (shiftFunctor C n).Additive] [Pretriangulated C]

instance (A : Cᵒᵖ) : (preadditiveCoyoneda.obj A).IsHomological where
  exact T hT := by
    rw [ShortComplex.ab_exact_iff]
    intro (x₂ : A.unop ⟶ T.obj₂) (hx₂ : x₂ ≫ T.mor₂ = 0)
    obtain ⟨x₁, hx₁⟩ := T.coyoneda_exact₂ hT x₂ hx₂
    exact ⟨x₁, hx₁.symm⟩

instance (B : C) : (preadditiveYoneda.obj B).IsHomological where
  exact T hT := by
    rw [ShortComplex.ab_exact_iff]
    intro (x₂ : T.obj₂.unop ⟶ B) (hx₂ : T.mor₂.unop ≫ x₂ = 0)
    obtain ⟨x₃, hx₃⟩ := Triangle.yoneda_exact₂ _ (unop_distinguished T hT) x₂ hx₂
    exact ⟨x₃, hx₃.symm⟩

lemma preadditiveYoneda_map_distinguished
    (T : Triangle C) (hT : T ∈ distTriang C) (B : C) :
    ((shortComplexOfDistTriangle T hT).op.map (preadditiveYoneda.obj B)).Exact :=
  (preadditiveYoneda.obj B).map_distinguished_op_exact T hT

noncomputable instance (A : Cᵒᵖ) : (preadditiveCoyoneda.obj A).ShiftSequence ℤ :=
  Functor.ShiftSequence.tautological _ _

lemma preadditiveCoyoneda_homologySequenceδ_apply
    (T : Triangle C) (n₀ n₁ : ℤ) (h : n₀ + 1 = n₁) {A : Cᵒᵖ} (x : A.unop ⟶ T.obj₃⟦n₀⟧) :
    (preadditiveCoyoneda.obj A).homologySequenceδ T n₀ n₁ h x =
      x ≫ T.mor₃⟦n₀⟧' ≫ (shiftFunctorAdd' C 1 n₀ n₁ (by omega)).inv.app _ := by
  apply Category.assoc

noncomputable instance (B : C) : (preadditiveYoneda.obj B).ShiftSequence ℤ where
  sequence n := preadditiveYoneda.obj (B⟦n⟧)
  isoZero := preadditiveYoneda.mapIso ((shiftFunctorZero C ℤ).app B)
  shiftIso n a a' h := NatIso.ofComponents (fun A ↦ AddEquiv.toAddCommGrpIso
    { toEquiv := Quiver.Hom.opEquiv.trans (ShiftedHom.opEquiv' n a a' h).symm
      map_add' := fun _ _ ↦ ShiftedHom.opEquiv'_symm_add _ _ _ h })
        (by intros; ext; apply ShiftedHom.opEquiv'_symm_comp _ _ _ h)
  shiftIso_zero a := by ext; apply ShiftedHom.opEquiv'_zero_add_symm
  shiftIso_add n m a a' a'' ha' ha'' := by
    ext _ x
    exact ShiftedHom.opEquiv'_add_symm n m a a' a'' ha' ha'' x.op

lemma preadditiveYoneda_homologySequenceδ_apply
    (T : Triangle C) (n₀ n₁ : ℤ) (h : n₀ + 1 = n₁) {A : C} (x : T.obj₁ ⟶ A⟦n₀⟧) :
    (preadditiveYoneda.obj A).homologySequenceδ
      ((triangleOpEquivalence _).functor.obj (op T)) n₀ n₁ h x =
      T.mor₃ ≫ x⟦(1 : ℤ)⟧' ≫ (shiftFunctorAdd' C n₀ 1 n₁ h).inv.app A := by
  let a := (shiftFunctorCompIsoId C _ _ (neg_add_self (1 : ℤ))).inv.app T.obj₃
  let b := ((shiftFunctorOpIso C _ _ (add_right_neg 1)).hom.app (op T.obj₃)).unop⟦(1 : ℤ)⟧'
  let c := ((shiftFunctor Cᵒᵖ (1 : ℤ)).map T.mor₃.op).unop
  let d := (opShiftFunctorEquivalence C 1).counitIso.inv.app (op T.obj₁)
  let e := (shiftFunctorAdd' C n₀ 1 n₁ h).inv.app A
  change ((a ≫ b) ≫ ((c ≫ _) ≫ x)⟦(1 : ℤ)⟧') ≫ _ = _
  simp only [← Category.assoc, Functor.map_comp]
  congr 2
  dsimp [a, b, c]
  simp only [Category.assoc]
  sorry

end Pretriangulated

end CategoryTheory
