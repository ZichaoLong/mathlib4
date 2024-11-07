/-
Copyright (c) 2024 Joël Riou. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Joël Riou
-/

import Mathlib.Algebra.Module.Presentation.PiTensor
import Mathlib.LinearAlgebra.ExteriorPower.Generators

/-!
# Presentation of the exterior power

Given a presentation of a `R`-module `M`, we obtain a presentation of `⋀[R]^n M`.

-/

universe w

namespace Function

variable {ι α : Type*} [DecidableEq ι]

lemma update_comp (f : ι → α) (i : ι) (x : α) {β : Type*} (g : α → β) :
    update (g ∘ f) i (g x) = g ∘ update f i x := by
  ext j
  by_cases h : j = i
  · subst h
    simp
  · simp only [update_noteq h, comp_apply]

lemma update_update (f : ι → α) (i j : ι) (a b : α) (hij : i ≠ j) :
    update (update f i a) j b = update (update f j b) i a := by
  ext x
  by_cases h : x = i
  · subst h
    rw [update_same, update_noteq hij, update_same]
  · by_cases h' : x = j
    · subst h'
      rw [update_same, update_noteq hij.symm, update_same]
    · rw [update_noteq h, update_noteq h', update_noteq h, update_noteq h']

variable (f : ι → α) (i j : ι) (k : ι)

def swapValues (f : ι → α) (i j : ι) : ι → α :=
  update (update f i (f j)) j (f i)

lemma swapValues_eq_update_update :
    swapValues f i j = update (update f i (f j)) j (f i) :=
  rfl

@[simp] lemma swapValues_fst : swapValues f i j i = f j := by
  rw [swapValues_eq_update_update]
  by_cases h : i = j
  · subst h
    rw [update_eq_self, update_same]
  · rw [update_update _ _ _ _ _ h, update_same]

@[simp] lemma swapValues_snd : swapValues f i j j = f i := by
  rw [swapValues_eq_update_update, update_same]

lemma swapValues_apply (hi : k ≠ i) (hj : k ≠ j) :
    swapValues f i j k = f k := by
  rw [swapValues_eq_update_update]
  rw [update_noteq hj, update_noteq hi]

lemma swapValues_comp {β : Type*} (g : α → β) :
    swapValues (g.comp f) i j = g ∘ swapValues f i j := by
  simp only [swapValues_eq_update_update, comp_apply, ← update_comp]

end Function

open Function

lemma AlternatingMap.antisymmetry {R M N ι : Type*} [Ring R] [AddCommGroup M] [Module R M]
    [AddCommGroup N] [Module R N] [DecidableEq ι]
    (f : AlternatingMap R M N ι) (x : ι → M) (i j : ι) (hij : i ≠ j) :
    f (Function.swapValues x i j) = - f x := by
  have := f.map_eq_zero_of_eq
    (Function.update (Function.update x i (x i + x j)) j (x i + x j))
    (by simp [update_noteq hij]) hij
  rw [map_update_add, update_update _ _ _ _ _ hij, map_update_add,
    update_update _ _ _ _ _ hij, map_update_add] at this
  nth_rw 1 [f.map_eq_zero_of_eq (hij := hij)] at this; swap
  · rw [update_same, update_update _ _ _ _ _ hij.symm, update_same]
  nth_rw 3 [f.map_eq_zero_of_eq (hij := hij)] at this; swap
  · rw [update_same, update_update _ _ _ _ _ hij.symm, update_same]
  rw [zero_add, add_zero, ← eq_neg_iff_add_eq_zero, update_eq_self, update_eq_self] at this
  rw [swapValues_eq_update_update, update_update _ _ _ _ _ hij]
  exact this

lemma MultilinearMap.map_eq_zero_of_eq_of_generators {R M N : Type*} [Ring R] [AddCommGroup M]
    [Module R M] [AddCommGroup N] [Module R N] {ι : Type*} [DecidableEq ι]
    (f : MultilinearMap R (fun (_ : ι) ↦ M) N) {γ : Type*} {g : γ → M}
    (hg : Submodule.span R (Set.range g) = ⊤)
    {i j : ι} (hij : i ≠ j) (hf₁ : ∀ (k : ι → γ) (hk : k i = k j), f (g ∘ k) = 0)
    (hf₂ : ∀ (k : ι → γ), f (swapValues (g ∘ k) i j) = -f (g ∘ k))
    (v : ι → M) (hv : v i = v j) :
    f v = 0 := sorry

namespace Module

variable (R : Type*) [CommRing R] (M : Type*) [AddCommGroup M] [Module R M]

namespace Relations

variable {R}
variable (relation : Relations R) (n : ℕ)

namespace exteriorPower

variable (n : ℕ)
inductive Rels
  | piTensor (i₀ : Fin n) (r : relation.R) (g : ∀ (i : Fin n) (_ : i ≠ i₀), relation.G)
  | antisymmetry (g : Fin n → relation.G) (i j : Fin n) (hg : i ≠ j)
  | alternate (g : Fin n → relation.G) (i j : Fin n) (hg : g i = g j) (hij : i ≠ j)

end exteriorPower

@[simps]
noncomputable def exteriorPower : Relations R where
  G := Fin n → relation.G
  R := exteriorPower.Rels relation n
  relation x := match x with
    | .piTensor i₀ r g => (piTensor (fun _ ↦ relation)).relation
          (⟨i₀, r, fun ⟨a, ha⟩ ↦ g a ha⟩)
    | .antisymmetry g i j _ => Finsupp.single (swapValues g i j) 1 + Finsupp.single g 1
    | .alternate g _ _ _ _ => Finsupp.single g 1

namespace Solution

variable {M}
variable {relation} (s : relation.Solution M)

@[simps var]
def exteriorPower (n : ℕ) : (relation.exteriorPower n).Solution
    (ExteriorAlgebra.exteriorPower R n M) where
  var g := exteriorPower.ιMulti _ _ (s.var ∘ g)
  linearCombination_var_relation := by
    rintro (⟨i₀, r, g⟩ | ⟨g, i, j, hij⟩ | ⟨g, i, j, hg, hij⟩)
    · have := ((Relations.Solution.piTensor (fun (i : Fin n) ↦ s)).postcomp
        (exteriorPower.fromTensorPower R M n)).linearCombination_var_relation
        ⟨i₀, r, fun ⟨i, hi⟩ ↦ g i hi⟩
      dsimp at this ⊢
      simp only [Finsupp.linearCombination_embDomain] at this ⊢
      convert this
      aesop
    · dsimp
      simp only [map_add, Finsupp.linearCombination_single, one_smul,
        ← swapValues_comp, AlternatingMap.antisymmetry _ _ _ _ hij, neg_add_cancel]
    · dsimp
      simp only [Finsupp.linearCombination_single, one_smul]
      exact AlternatingMap.map_eq_zero_of_eq _ _ (by simp [hg]) hij

variable {s}

namespace isPresentationCore

variable {N : Type*} [AddCommGroup N] [Module R N]
  (h : s.IsPresentation) {n : ℕ} (t : (relation.exteriorPower n).Solution N)

noncomputable def descAsMultilinearMap :
    MultilinearMap R (fun (_ : Fin n) ↦ M) N :=
      LinearMap.compMultilinearMap (
        (IsPresentation.piTensor (fun (_ : Fin n) ↦ h)).desc
          { var := t.var
            linearCombination_var_relation := by
              rintro ⟨i₀, r, g⟩
              exact t.π_relation (.piTensor i₀ r (fun i hi ↦ g ⟨i, hi⟩)) })
        (PiTensorProduct.tprod (R := R) )

@[simp]
lemma descAsMultilinearMap_apply (g : Fin n → relation.G) :
    descAsMultilinearMap h t (s.var ∘ g) = t.var g :=
  IsPresentation.desc_var _ _ _

lemma map_eq_zero_of_eq (v : Fin n → M) (i j : Fin n) (hv : v i = v j) (hij : i ≠ j) :
    descAsMultilinearMap h t v = 0 := by
  apply MultilinearMap.map_eq_zero_of_eq_of_generators (hg := h.span_var_eq_top)
    (hij := hij) (v := v) (hv := hv)
  · intro k hk
    have := t.π_relation (.alternate k i j hk hij)
    dsimp at this
    erw [π_single] at this
    simpa only [descAsMultilinearMap_apply] using this
  · intro k
    have := t.π_relation (.antisymmetry k i j hij)
    dsimp at this
    rw [map_add] at this
    erw [π_single, π_single] at this
    simpa only [swapValues_comp, descAsMultilinearMap_apply, eq_neg_iff_add_eq_zero] using this

end isPresentationCore

open isPresentationCore in
noncomputable def isPresentationCore (h : s.IsPresentation) (n : ℕ) :
    IsPresentationCore.{w} (s.exteriorPower n) where
  desc t := exteriorPower.alternatingMapLinearEquiv
    { toMultilinearMap := descAsMultilinearMap h t
      map_eq_zero_of_eq' := map_eq_zero_of_eq h t }
  postcomp_desc t := by aesop
  postcomp_injective {N _ _ f f'} hff' := by
    rw [Submodule.linearMap_eq_iff_of_span_eq_top
      (hM := exteriorPower.span_ιMulti_of_span_eq_top (hg := h.span_var_eq_top) n)]
    rintro ⟨_, ⟨g, rfl⟩⟩
    simpa using congr_var hff' g

lemma IsPresentation.exteriorPower (h : s.IsPresentation) (n : ℕ) :
    (s.exteriorPower n).IsPresentation :=
  (isPresentationCore h n).isPresentation

end Solution

end Relations

namespace Presentation

variable {R M} (pres : Presentation R M) (n : ℕ)

@[simps! R G relation var]
noncomputable def exteriorPower : Presentation R (ExteriorAlgebra.exteriorPower R n M) where
  toSolution := pres.toSolution.exteriorPower n
  toIsPresentation := pres.toIsPresentation.exteriorPower n

end Presentation

end Module
