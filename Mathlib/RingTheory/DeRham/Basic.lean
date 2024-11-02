/-
Copyright (c) 2024 Joël Riou. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Joël Riou
-/
import Mathlib.Algebra.Module.Presentation.Differentials
import Mathlib.Algebra.Module.Presentation.ExteriorPower
import Mathlib.Algebra.Module.Presentation.RestrictScalars
import Mathlib.Algebra.Homology.HomologicalComplex
import Mathlib.Algebra.Category.ModuleCat.Basic
import Mathlib.RingTheory.Kaehler.Basic

/-!
# The algebraic De Rham complex

-/

variable (A B : Type*) [CommRing A] [CommRing B] [Algebra A B]

namespace Algebra.Presentation

inductive tautological.Rels
  | add (b b' : B)
  | mul (b b' : B)
  | algebraMap (a : A)

@[simps]
noncomputable def tautological : Algebra.Presentation A B where
  vars := B
  val := _root_.id
  σ' := MvPolynomial.X
  aeval_val_σ' := by simp
  rels := tautological.Rels A B
  relation r := match r with
    | .add b b' => .X b + .X b' - .X (b + b')
    | .mul b b' => .X b * .X b' - .X (b * b')
    | .algebraMap a => a • 1 - .X (algebraMap A B a)
  span_range_relation_eq_ker := sorry

end Algebra.Presentation

open ExteriorAlgebra

@[simps! G R]
noncomputable abbrev KaehlerDifferential.presentation :
    Module.Presentation B (KaehlerDifferential A B) :=
  Algebra.Presentation.differentials (Algebra.Presentation.tautological A B)

namespace DeRhamComplex

variable {n : ℕ}

section

variable {α : Type*} (x : α) (f : Fin n → α)

def finInsert : Fin (n + 1) → α
  | ⟨0, _⟩ => x
  | ⟨n + 1, _⟩ => f ⟨n, by omega⟩

@[simp]
lemma finInsert_zero : finInsert x f 0 = x := rfl

@[simp]
lemma finInsert_succ (i : Fin n) : finInsert x f i.succ = f i := rfl

lemma comp_finInsert {β : Type*} (g : α → β) :
    g.comp (finInsert x f) = finInsert (g x) (g.comp f) := by
  ext ⟨(_ | _), _⟩ <;> rfl

lemma finInsert_eq_update_finInsert_zero [Zero α]:
    finInsert x f = Function.update (finInsert 0 f) 0 x := by
  ext ⟨(_ | _), _⟩ <;> rfl

end


variable (n)

@[simps!]
noncomputable def presentationDifferentialsUp :
    Module.Presentation B (exteriorPower B n (KaehlerDifferential A B)) :=
  (KaehlerDifferential.presentation A B).exteriorPower n

lemma presentationDifferentialsUp_relation_alternate
    (g : Fin n → B) (i j : Fin n) (hg : g i = g j) (hij : i ≠ j):
    (presentationDifferentialsUp A B n).relation
    (Module.Relations.exteriorPower.Rels.alternate g i j hg hij) =
      Finsupp.single g 1 := by
  dsimp

open Classical in
@[simps!]
noncomputable def differentialsRestrictScalarsData :
    (presentationDifferentialsUp A B n).RestrictScalarsData
      (Module.Presentation.tautological A B) where
  lift r := match r with
    | ⟨b₀, .piTensor i₀ (.add b₁ b₂) g⟩ => by
        dsimp at g ⊢
        sorry
    | ⟨b₀, .piTensor i₀ (.mul _ _) g⟩ => by
        sorry
    | ⟨b₀, .piTensor i₀ (.algebraMap a) g⟩ => by
        sorry
    | ⟨b₀, .alternate g i j hg hij⟩ => Finsupp.single ⟨g, b₀⟩ 1
    | ⟨b₀, .antisymmetry g i j hg⟩ => sorry
  π_lift r := match r with
    | ⟨b₀, .piTensor i₀ (.add b₁ b₂) g⟩ => by
        dsimp [presentationDifferentialsUp]
        simp
        sorry
    | ⟨b₀, .piTensor i₀ (.mul b₁ b₂) g⟩ => by
        sorry
    | ⟨b₀, .piTensor i₀ (.algebraMap a) g⟩ => by
        sorry
    | ⟨b₀, .alternate g i j hg hij⟩ => by
        dsimp
        rw [map_smul]
        erw [Module.Presentation.finsupp_π, Module.Relations.map_single]
        dsimp
        rw [Finsupp.smul_single, smul_eq_mul, mul_one]
    | ⟨b₀, .antisymmetry g i j hg⟩ => sorry

open Classical in
@[simps! G R relation]
noncomputable def presentationDifferentialsDown :
    Module.Presentation A (exteriorPower B n (KaehlerDifferential A B)) :=
  (presentationDifferentialsUp A B n).restrictScalars
    (Module.Presentation.tautological A B) (differentialsRestrictScalarsData A B n)

lemma presentationDifferentialsDown_var (b₀ : B) {n : ℕ} (g : Fin n → B) :
    ((presentationDifferentialsDown A B n).var ⟨g, b₀⟩) =
      b₀ • exteriorProduct _ _ _ (KaehlerDifferential.D A B ∘ g) := by
  sorry

lemma smul_def (M : Type*) [AddCommGroup M] [Module A M] [Module B M]
    [IsScalarTower A B M] (m : M) (a : A) : a • m = (algebraMap A B a) • m := by
  exact algebra_compatible_smul B a m

noncomputable def d (n : ℕ) : exteriorPower B n (KaehlerDifferential A B) →ₗ[A]
    exteriorPower B (n + 1) (KaehlerDifferential A B) :=
  (presentationDifferentialsDown A B n).desc
    { var := fun ⟨g, b₀⟩ ↦
        ((presentationDifferentialsDown A B (n + 1)).var ⟨finInsert b₀ g, (1 : B)⟩)
      linearCombination_var_relation := by
        rintro (⟨g, r⟩ | ⟨b₀, r⟩)
        · induction r with
          | add b₁ b₂ =>
              dsimp
              simp only [presentationDifferentialsDown_relation,
                Finsupp.linearCombination_embDomain, map_sub, map_add,
                Finsupp.linearCombination_single, Function.comp_apply,
                Function.Embedding.sigmaMk_apply, one_smul]
              rw [presentationDifferentialsDown_var,
                presentationDifferentialsDown_var,
                presentationDifferentialsDown_var]
              simp only [comp_finInsert, one_smul, map_add, sub_eq_zero]
              rw [finInsert_eq_update_finInsert_zero]
              nth_rw 2 [finInsert_eq_update_finInsert_zero]
              nth_rw 3 [finInsert_eq_update_finInsert_zero]
              rw [AlternatingMap.map_add]
          | smul a b =>
              dsimp
              simp only [presentationDifferentialsDown_relation,
                Finsupp.linearCombination_embDomain, map_sub, Finsupp.linearCombination_single,
                Function.comp_apply, Function.Embedding.sigmaMk_apply, one_smul]
              rw [presentationDifferentialsDown_var,
                presentationDifferentialsDown_var]
              simp only [one_smul, comp_finInsert, Derivation.map_smul, sub_eq_zero]
              rw [finInsert_eq_update_finInsert_zero]
              nth_rw 2 [finInsert_eq_update_finInsert_zero]
              rw [algebra_compatible_smul B a, algebra_compatible_smul B a,
                AlternatingMap.map_smul]
        · dsimp at b₀
          induction r with
          | piTensor i r g =>
              induction r with
              | add b₁ b₂ =>
                  dsimp
                  sorry
              | mul b₁ b₂ =>
                  dsimp
                  sorry
              | algebraMap a =>
                  dsimp
                  sorry
          | antisymmetry g i j hij => sorry
          | alternate g i j hg hij => sorry
        }


@[simp]
lemma d_apply (b₀ : B) {n : ℕ} (g : Fin n → B) :
    d A B n ((presentationDifferentialsDown A B n).var ⟨g, b₀⟩) =
      ((presentationDifferentialsDown A B (n + 1)).var ⟨finInsert b₀ g, (1 : B)⟩) := by
  apply (presentationDifferentialsDown A B n).desc_var

@[simp]
lemma d_d (n : ℕ) : d A B (n + 1) ∘ₗ d A B n = 0 := by
  apply (presentationDifferentialsDown A B n).postcomp_injective
  ext ⟨g, b₀⟩
  dsimp
  rw [d_apply, d_apply, presentationDifferentialsDown_var, one_smul]
  exact MultilinearMap.map_of_eq_zero _ _ 0 (by simp)

@[simp]
lemma d_d_apply {n : ℕ} (x) : d A B (n + 1) (d A B n x) = 0 := DFunLike.congr_fun (d_d A B n) x

end DeRhamComplex

noncomputable def deRhamComplex : CochainComplex (ModuleCat A) ℕ :=
  CochainComplex.of (fun n ↦ ModuleCat.of A (exteriorPower B n (KaehlerDifferential A B)))
    (DeRhamComplex.d A B) (by intro; ext; apply DeRhamComplex.d_d_apply)