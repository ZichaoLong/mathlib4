/-
Copyright (c) 2024 Joël Riou. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Joël Riou, Andrew Yang
-/
import Mathlib.CategoryTheory.ComposableArrows
import Mathlib.CategoryTheory.Localization.CalculusOfFractions

/-! # Essential surjectivity of the functor induced on tuples of composable arrows

Assuming that `L : C ⥤ D` is a localization functor for a class of morphisms `W`
that has a calculus of left *or* right fractions, we show in this file
that the functor `L.mapComposableArrows n : ComposableArrows C n ⥤ ComposableArrows D n`
is essentially surjective for any `n : ℕ`.

-/

namespace CategoryTheory

open Category

open ComposableArrows
section

variable {C D : Type*} [Category C] [Category D] (F : C ⥤ D) (n : ℕ)

variable (C) in
def ComposableArrows.opEquivalence : (ComposableArrows C n)ᵒᵖ ≌ ComposableArrows Cᵒᵖ n := by
  sorry

def Functor.mapComposableArrowsOpIso :
    F.mapComposableArrows n ⋙ (opEquivalence D n).functor.rightOp ≅
      (opEquivalence C n).functor.rightOp ⋙ (F.op.mapComposableArrows n).op := by
  sorry

end

namespace Localization

variable {C D : Type*} [Category C] [Category D] (L : C ⥤ D) (W : MorphismProperty C)
  [L.IsLocalization W]

open ComposableArrows

lemma essSurj_mapComposableArrows_of_hasRightCalculusOfFractions
    [W.HasRightCalculusOfFractions] (n : ℕ) :
    (L.mapComposableArrows n).EssSurj where
  mem_essImage Y := by
    have := essSurj L W
    induction n
    · obtain ⟨Y, rfl⟩ := mk₀_surjective Y
      exact ⟨mk₀ _, ⟨isoMk₀ (L.objObjPreimageIso Y)⟩⟩
    · next n hn =>
      obtain ⟨Y, Z, f, rfl⟩ := ComposableArrows.precomp_surjective Y
      obtain ⟨Y', ⟨e⟩⟩ := hn Y
      obtain ⟨f', hf'⟩ := exists_rightFraction L W
        ((L.objObjPreimageIso Z).hom ≫ f ≫ (e.app 0).inv)
      refine ⟨Y'.precomp f'.f,
        ⟨isoMkSucc (isoOfHom L W _ f'.hs ≪≫ L.objObjPreimageIso Z) e ?_⟩⟩
      dsimp at hf' ⊢
      simp [← cancel_mono (e.inv.app 0), hf']

lemma essSurj_mapComposableArrows
    [W.HasLeftCalculusOfFractions] (n : ℕ) :
    (L.mapComposableArrows n).EssSurj := by
  have := essSurj_mapComposableArrows_of_hasRightCalculusOfFractions L.op W.op n
  have : (opEquivalence C n).functor.rightOp.EssSurj := sorry
  have : (L.op.mapComposableArrows n).op.EssSurj := sorry
  have := Functor.essSurj_of_iso (L.mapComposableArrowsOpIso n).symm
  sorry

end Localization

end CategoryTheory
