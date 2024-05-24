import Mathlib.CategoryTheory.Triangulated.TStructure.TExact
import Mathlib.CategoryTheory.Triangulated.TStructure.AbelianSubcategory
import Mathlib.CategoryTheory.Triangulated.TStructure.Homology
import Mathlib.CategoryTheory.Abelian.Images
import Mathlib.Algebra.Homology.ShortComplex.Exact
import Mathlib.Algebra.Homology.Homology

namespace CategoryTheory

open Category Limits Triangulated Pretriangulated TStructure

variable {C D : Type*} [Category C] [Category D] [Preadditive C] [Preadditive D]
  [HasZeroObject C] [HasZeroObject D] [HasShift C ℤ] [HasShift D ℤ]
  [∀ (n : ℤ), (shiftFunctor C n).Additive] [∀ (n : ℤ), (shiftFunctor D n).Additive]
  [Pretriangulated C] [Pretriangulated D] [CategoryTheory.IsTriangulated C]
  [CategoryTheory.IsTriangulated D]

namespace Functor

scoped[ZeroObject] attribute [instance] CategoryTheory.Limits.HasZeroObject.zero'

open ZeroObject Limits Preadditive Pretriangulated

variable (F : C ⥤ D) [F.CommShift ℤ] (t₁ : TStructure C) (t₂ : TStructure D)
variable [F.IsTriangulated]

local instance : t₁.HasHeart := hasHeartFullSubcategory t₁
local instance : t₂.HasHeart := hasHeartFullSubcategory t₂
noncomputable local instance : t₁.HasHomology₀ := t₁.hasHomology₀
noncomputable local instance : t₂.HasHomology₀ := t₂.hasHomology₀

abbrev AcyclicObject (X : t₁.Heart) := t₂.heart (F.obj X.1)

abbrev AcyclicCategory := FullSubcategory (AcyclicObject F t₁ t₂)

abbrev FunctorFromAcyclic : (AcyclicCategory F t₁ t₂) ⥤ t₂.Heart := by
  refine FullSubcategory.lift t₂.heart
    (fullSubcategoryInclusion (AcyclicObject F t₁ t₂) ⋙ t₁.ιHeart ⋙ F) ?_
  intro ⟨_, h⟩
  simp only [comp_obj, fullSubcategoryInclusion.obj]
  exact h


abbrev FunctorFromHeart : t₁.Heart ⥤ D := t₁.ιHeart ⋙ F

instance : Functor.Additive (FunctorFromHeart F t₁) where
  map_add := by
    intro X Y f g
    simp only [comp_obj, comp_map, map_add]

noncomputable abbrev FunctorFromHeartToHeart : t₁.Heart ⥤ t₂.Heart :=
  t₁.ιHeart ⋙ F ⋙ t₂.homology₀

def AcyclicToHeart : (AcyclicCategory F t₁ t₂) ⥤ t₁.Heart := fullSubcategoryInclusion _

def FunctorFromAcyclicFactorization : FunctorFromAcyclic F t₁ t₂ ≅
    fullSubcategoryInclusion (AcyclicObject F t₁ t₂) ⋙ FunctorFromHeartToHeart F t₁ t₂ := sorry

namespace AcyclicCategory

instance closedUnderIsomorphisms : ClosedUnderIsomorphisms (AcyclicObject F t₁ t₂) := by
  refine ClosedUnderIsomorphisms.mk ?_
  intro _ _ e hX
  change t₂.heart _
  exact ClosedUnderIsomorphisms.of_iso ((FunctorFromHeart F t₁).mapIso e) hX

variable (X Y : t₁.Heart)

lemma zero {X : t₁.Heart} (hX : IsZero X) : AcyclicObject F t₁ t₂ X := by
  simp only [AcyclicObject]
  exact ClosedUnderIsomorphisms.of_iso (((FunctorFromHeart F t₁).mapIso hX.isoZero).trans
    (FunctorFromHeart F t₁).mapZeroObject).symm t₂.zero_mem_heart

lemma prod {X Y : t₁.Heart} (hX : AcyclicObject F t₁ t₂ X) (hY : AcyclicObject F t₁ t₂ Y) :
    AcyclicObject F t₁ t₂ (X ⨯ Y) := by
  simp only [AcyclicObject]
  have := PreservesLimitPair.iso t₁.ιHeart X Y
  exact ClosedUnderIsomorphisms.of_iso (PreservesLimitPair.iso (FunctorFromHeart F t₁) X Y).symm
      (prod_mem_heart t₂ _ _ hX hY)

instance : HasTerminal (AcyclicCategory F t₁ t₂) := by
  let Z : AcyclicCategory F t₁ t₂ := ⟨0, zero F t₁ t₂ (isZero_zero t₁.Heart)⟩
  have : ∀ X, Inhabited (X ⟶ Z) := fun X => ⟨0⟩
  have : ∀ X, Unique (X ⟶ Z) := fun X =>
    { uniq := fun f => (fullSubcategoryInclusion (AcyclicObject F t₁ t₂)).map_injective
          ((isZero_zero t₁.Heart).eq_of_tgt _ _) }
  exact hasTerminal_of_unique Z

instance : HasBinaryProducts (AcyclicCategory F t₁ t₂) := by
  apply hasLimitsOfShape_of_closedUnderLimits
  intro P c hc H
  exact mem_of_iso (AcyclicObject F t₁ t₂)
    (limit.isoLimitCone ⟨_, (IsLimit.postcomposeHomEquiv (diagramIsoPair P) _).symm hc⟩)
    (prod F t₁ t₂ (H _) (H _))

instance : HasFiniteProducts (AcyclicCategory F t₁ t₂) :=
  hasFiniteProducts_of_has_binary_and_terminal

end AcyclicCategory

instance : Functor.Additive (FunctorFromAcyclic F t₁ t₂) where
  map_add := by
    intro X Y f g
    simp only [FullSubcategory.lift_map, comp_map, fullSubcategoryInclusion.obj,
      fullSubcategoryInclusion.map, map_add]

instance : Functor.Additive (AcyclicToHeart F t₁ t₂) where
  map_add := by
    intro X Y f g
    simp only [AcyclicToHeart, fullSubcategoryInclusion.obj, fullSubcategoryInclusion.map]

lemma AcyclicExtension {S : ShortComplex t₁.Heart} (SE : S.ShortExact)
    (hS₁ : AcyclicObject F t₁ t₂ S.X₁) (hS₃ : AcyclicObject F t₁ t₂ S.X₃) :
    AcyclicObject F t₁ t₂ S.X₂ := by
  set DT' := F.map_distinguished _ (heartShortExactTriangle_distinguished t₁ S SE)
  simp only [AcyclicObject] at hS₁ hS₃ ⊢
  rw [t₂.mem_heart_iff] at hS₁ hS₃ ⊢
  constructor
  · exact t₂.isLE₂ _ DT' 0 hS₁.1 hS₃.1
  · exact t₂.isGE₂ _ DT' 0 hS₁.2 hS₃.2

lemma AcyclicShortExact {S : ShortComplex (AcyclicCategory F t₁ t₂)}
    (SE : ((AcyclicToHeart F t₁ t₂).mapShortComplex.obj S).ShortExact) :
    ((FunctorFromAcyclic F t₁ t₂).mapShortComplex.obj S).ShortExact := by sorry
  /-
  set T := heartShortExactTriangle t₁ _ SE with hTdef
  set DT := heartShortExactTriangle_distinguished t₁ _ SE
  set T' := F.mapTriangle.obj T with hT'def
  set DT' := F.map_distinguished _ DT
  set X := T'.obj₁ with hXdef
  set Y := T'.obj₂ with hYdef
  set Z := T'.obj₃ with hZdef
  set hX : t₂.heart X := by
    simp only [hXdef, hT'def, hTdef, AcyclicToHeart, FullSubcategory.map, mapShortComplex_obj,
      mapTriangle_obj, id_eq, heartShortExactTriangle_obj₁, ιHeart, ShortComplex.map_X₁,
      heartShortExactTriangle_obj₂, ShortComplex.map_X₂, heartShortExactTriangle_obj₃,
      ShortComplex.map_X₃, heartShortExactTriangle_mor₁, ShortComplex.map_f,
      heartShortExactTriangle_mor₂, ShortComplex.map_g, heartShortExactTriangle_mor₃,
      Triangle.mk_obj₁]
    exact hS₁.2
  set hY : t₂.heart Y := by sorry
  set hZ : t₂.heart Z := by sorry
  set f : (⟨X, hX⟩ : t₂.Heart) ⟶ ⟨Y, hY⟩ := T'.mor₁ with hfdef
  set g : (⟨Y, hY⟩ : t₂.Heart) ⟶ ⟨Z, hZ⟩ := T'.mor₂ with hgdef
  set δ : t₂.ιHeart.obj (⟨Z, hZ⟩ : t₂.Heart) ⟶ (t₂.ιHeart.obj ⟨X, hX⟩)⟦1⟧ := T'.mor₃
  set h : Triangle.mk (t₂.ιHeart.map f) (t₂.ιHeart.map g) δ ∈ distinguishedTriangles := by
    refine isomorphic_distinguished T' DT' _ ?_
    refine Triangle.isoMk _ _ ?_ ?_ ?_ ?_ ?_ ?_
    · simp only [Triangle.mk_obj₁, hXdef, hT'def, hTdef, AcyclicToHeart, mapShortComplex_obj,
      mapTriangle_obj, id_eq, heartShortExactTriangle_obj₁, ShortComplex.map_X₁,
      heartShortExactTriangle_obj₂, ShortComplex.map_X₂, heartShortExactTriangle_obj₃,
      ShortComplex.map_X₃, heartShortExactTriangle_mor₁, ShortComplex.map_f,
      FullSubcategory.map_map, heartShortExactTriangle_mor₂, ShortComplex.map_g,
      heartShortExactTriangle_mor₃]
      exact Iso.refl (F.obj S.X₁.1)
    · simp only [Triangle.mk_obj₂, hYdef, hT'def, hTdef, AcyclicToHeart, mapShortComplex_obj,
      mapTriangle_obj, id_eq, heartShortExactTriangle_obj₁, ShortComplex.map_X₁,
      heartShortExactTriangle_obj₂, ShortComplex.map_X₂, heartShortExactTriangle_obj₃,
      ShortComplex.map_X₃, heartShortExactTriangle_mor₁, ShortComplex.map_f,
      FullSubcategory.map_map, heartShortExactTriangle_mor₂, ShortComplex.map_g,
      heartShortExactTriangle_mor₃]
      exact Iso.refl (F.obj S.X₂.1)
    · simp only [Triangle.mk_obj₃, hZdef, hT'def, hTdef, AcyclicToHeart, mapShortComplex_obj,
      mapTriangle_obj, id_eq, heartShortExactTriangle_obj₁, ShortComplex.map_X₁,
      heartShortExactTriangle_obj₂, ShortComplex.map_X₂, heartShortExactTriangle_obj₃,
      ShortComplex.map_X₃, heartShortExactTriangle_mor₁, ShortComplex.map_f,
      FullSubcategory.map_map, heartShortExactTriangle_mor₂, ShortComplex.map_g,
      heartShortExactTriangle_mor₃]
      exact Iso.refl (F.obj S.X₃.1)
    · simp only [Triangle.mk_obj₁, Triangle.mk_obj₂, Triangle.mk_mor₁, mapShortComplex_obj,
      mapTriangle_obj, heartShortExactTriangle_obj₁, ShortComplex.map_X₁,
      heartShortExactTriangle_obj₂, ShortComplex.map_X₂, heartShortExactTriangle_obj₃,
      ShortComplex.map_X₃, heartShortExactTriangle_mor₁, ShortComplex.map_f,
      heartShortExactTriangle_mor₂, ShortComplex.map_g, heartShortExactTriangle_mor₃,
      eq_mpr_eq_cast, cast_eq, Iso.refl_hom]
      erw [comp_id, id_comp]
      simp only [hfdef]; rfl
    · sorry -- same proof as first point, but with g
    · sorry -- same proof as first point, but with δ
  set e : (ShortComplex.mk f g (t₂.ιHeart.map_injective
    (by
      rw [Functor.map_comp, Functor.map_zero]
      exact comp_distTriang_mor_zero₁₂ _ h))) ≅
   ((mapShortComplex (FunctorFromAcyclic F t₁ t₂)).obj S) := by
    refine ShortComplex.isoMk ?_ ?_ ?_ ?_ ?_
    · refine (isoEquivOfFullyFaithful t₂.ιHeart).invFun ?_
      simp only [ιHeart, hXdef, hT'def, hTdef, AcyclicToHeart, FullSubcategory.map,
        mapShortComplex_obj, mapTriangle_obj, id_eq, heartShortExactTriangle_obj₁,
        ShortComplex.map_X₁, heartShortExactTriangle_obj₂, ShortComplex.map_X₂,
        heartShortExactTriangle_obj₃, ShortComplex.map_X₃, heartShortExactTriangle_mor₁,
        ShortComplex.map_f, heartShortExactTriangle_mor₂, ShortComplex.map_g,
        heartShortExactTriangle_mor₃, Triangle.mk_obj₁, FunctorFromAcyclic]
      exact Iso.refl (F.obj S.X₁.1)
    · refine (isoEquivOfFullyFaithful t₂.ιHeart).invFun ?_
      simp only [ιHeart, hYdef, hT'def, hTdef, AcyclicToHeart, FullSubcategory.map,
        mapShortComplex_obj, mapTriangle_obj, id_eq, heartShortExactTriangle_obj₁,
        ShortComplex.map_X₁, heartShortExactTriangle_obj₂, ShortComplex.map_X₂,
        heartShortExactTriangle_obj₃, ShortComplex.map_X₃, heartShortExactTriangle_mor₁,
        ShortComplex.map_f, heartShortExactTriangle_mor₂, ShortComplex.map_g,
        heartShortExactTriangle_mor₃, Triangle.mk_obj₁, FunctorFromAcyclic]
      exact Iso.refl (F.obj S.X₂.1)
    · refine (isoEquivOfFullyFaithful t₂.ιHeart).invFun ?_
      simp only [ιHeart, hZdef, hT'def, hTdef, AcyclicToHeart, FullSubcategory.map,
        mapShortComplex_obj, mapTriangle_obj, id_eq, heartShortExactTriangle_obj₁,
        ShortComplex.map_X₁, heartShortExactTriangle_obj₂, ShortComplex.map_X₂,
        heartShortExactTriangle_obj₃, ShortComplex.map_X₃, heartShortExactTriangle_mor₁,
        ShortComplex.map_f, heartShortExactTriangle_mor₂, ShortComplex.map_g,
        heartShortExactTriangle_mor₃, Triangle.mk_obj₁, FunctorFromAcyclic]
      exact Iso.refl (F.obj S.X₃.1)
    · simp only [id_eq, eq_mpr_eq_cast, cast_eq, FunctorFromAcyclic, mapShortComplex_obj,
      ShortComplex.map_X₂, ShortComplex.map_X₁, isoEquivOfFullyFaithful, mapTriangle_obj,
      heartShortExactTriangle_obj₁, heartShortExactTriangle_obj₂, heartShortExactTriangle_obj₃,
      ShortComplex.map_X₃, heartShortExactTriangle_mor₁, ShortComplex.map_f,
      heartShortExactTriangle_mor₂, ShortComplex.map_g, heartShortExactTriangle_mor₃,
      Triangle.mk_obj₁, Equiv.invFun_as_coe, Equiv.coe_fn_symm_mk, preimageIso_hom, Iso.refl_hom,
      FullSubcategory.lift_map, comp_map, fullSubcategoryInclusion.obj,
      fullSubcategoryInclusion.map, Triangle.mk_obj₂]
      refine t₂.ιHeart.map_injective ?_
      simp only [map_comp, image_preimage, hfdef]
      erw [comp_id, id_comp]
      congr 1
    · simp only [id_eq, eq_mpr_eq_cast, cast_eq, FunctorFromAcyclic, mapShortComplex_obj,
      ShortComplex.map_X₂, ShortComplex.map_X₁, isoEquivOfFullyFaithful, mapTriangle_obj,
      heartShortExactTriangle_obj₁, heartShortExactTriangle_obj₂, heartShortExactTriangle_obj₃,
      ShortComplex.map_X₃, heartShortExactTriangle_mor₁, ShortComplex.map_f,
      heartShortExactTriangle_mor₂, ShortComplex.map_g, heartShortExactTriangle_mor₃,
      Triangle.mk_obj₁, Equiv.invFun_as_coe, Equiv.coe_fn_symm_mk, preimageIso_hom, Iso.refl_hom,
      FullSubcategory.lift_map, comp_map, fullSubcategoryInclusion.obj,
      fullSubcategoryInclusion.map, Triangle.mk_obj₂]
      refine t₂.ιHeart.map_injective ?_
      simp only [map_comp, image_preimage, hgdef]
      erw [comp_id, id_comp]
      congr 1
  exact ShortComplex.shortExact_of_iso e (shortExact_of_distTriang t₂ δ h)
-/

noncomputable local instance : t₂.homology₀.ShiftSequence ℤ :=
  Functor.ShiftSequence.tautological _ _

noncomputable def ShortComplexHomologyFunctor {S : ShortComplex t₁.Heart}
    (hS₁ : AcyclicObject F t₁ t₂ S.X₁) (hS : S.Exact) {n : ℤ} (hn : n ≠ -1 ∧ n ≠ 0) :
    (t₂.homology n).obj (F.obj (Limits.kernel S.g).1) ≅ (t₂.homology (n + 1)).obj
    (F.obj (Limits.kernel S.f).1) := by
  set S' : ShortComplex t₁.Heart := ShortComplex.mk (X₁ := Limits.kernel S.f) (X₂ := S.X₁)
    (X₃ := Limits.kernel S.g) (Limits.kernel.ι S.f) (Limits.kernel.lift S.g S.f S.zero)
    (by refine Mono.right_cancellation (f := Limits.kernel.ι S.g) _ _ ?_
        simp only [assoc, kernel.lift_ι, kernel.condition, zero_comp])
    with hS'def
  set S'' : ShortComplex t₁.Heart := ShortComplex.mk (Limits.kernel.ι S.f)
    (Abelian.factorThruImage S.f) (by
    refine Mono.right_cancellation (f := Abelian.image.ι S.f) _ _ ?_
    simp only [equalizer_as_kernel, assoc, kernel.lift_ι, kernel.condition, zero_comp])
    with hS''def
  rw [← exact_iff_shortComplex_exact] at hS
  set e : S' ≅ S'' := by
    refine ShortComplex.isoMk (Iso.refl (Limits.kernel S.f)) (Iso.refl S.X₁)
      (Limits.IsLimit.conePointUniqueUpToIso (Limits.kernelIsKernel S.g)
      (Abelian.isLimitImage S.f S.g hS)) (by simp only [Iso.refl_hom, id_comp, comp_id]) ?_
    refine Mono.right_cancellation (f := Abelian.image.ι S.f) _ _ ?_
    simp only [Iso.refl_hom, id_comp, equalizer_as_kernel, kernel.lift_ι, coequalizer_as_cokernel,
        eq_mp_eq_cast, IsLimit.lift_comp_conePointUniqueUpToIso_hom]
    have := (Abelian.isLimitImage S.f S.g hS).fac (KernelFork.ofι S.f S.zero)
        Limits.WalkingParallelPair.zero
    simp only [Fork.ofι_pt, parallelPair_obj_zero, equalizer_as_kernel, coequalizer_as_cokernel,
        Fork.ofι_π_app] at this
    exact this.symm
  have hS' : S'.ShortExact := by
    refine ShortComplex.shortExact_of_iso e.symm (ShortComplex.ShortExact.mk' ?_ ?_ ?_)
    · rw [← exact_iff_shortComplex_exact, ← exact_comp_mono_iff (h := Abelian.image.ι S.f)]
      simp only [equalizer_as_kernel, kernel.lift_ι]
      rw [Abelian.exact_iff]
      aesop_cat
    · exact inferInstance
    · exact inferInstance
  set T := t₁.heartShortExactTriangle S' hS'
  have hT := t₁.heartShortExactTriangle_distinguished S' hS'
  have hT' := F.map_distinguished T hT
  set f := t₂.homologyδ (F.mapTriangle.obj T) n (n + 1) rfl
  have h1 : Mono f := by
    refine (ShortComplex.exact_iff_mono _ (Limits.zero_of_source_iso_zero _ ?_)).mp
      (t₂.homology_exact₃ _ hT' n (n + 1) rfl)
    change (t₂.homology n).obj (F.obj S.X₁.1) ≅ 0
    refine Limits.IsZero.isoZero ?_
    by_cases hn' : 0 ≤ n
    · letI : t₂.IsLE (F.obj S.X₁.1) 0 := {le := hS₁.1}
      exact t₂.isZero_homology_of_isLE _ n 0 (lt_iff_le_and_ne.mpr ⟨hn', Ne.symm hn.2⟩)
    · letI : t₂.IsGE (F.obj S.X₁.1) 0 := {ge := hS₁.2}
      exact t₂.isZero_homology_of_isGE _ n 0 (lt_iff_not_le.mpr hn')
  have h2 : Epi f := by
    refine (ShortComplex.exact_iff_epi _ (Limits.zero_of_target_iso_zero _ ?_)).mp
      (t₂.homology_exact₁ _ hT' n (n + 1) rfl)
    change (t₂.homology (n + 1)).obj (F.obj S.X₁.1) ≅ 0
    refine Limits.IsZero.isoZero ?_
    by_cases hn' : 0 ≤ n
    · letI : t₂.IsLE (F.obj S.X₁.1) 0 := {le := hS₁.1}
      exact t₂.isZero_homology_of_isLE _ (n + 1) 0 (Int.lt_add_one_iff.mpr hn')
    · letI : t₂.IsGE (F.obj S.X₁.1) 0 := {ge := hS₁.2}
      refine t₂.isZero_homology_of_isGE _ (n + 1) 0 ?_
      rw [lt_iff_le_and_ne, Int.add_one_le_iff, and_iff_right (lt_iff_not_le.mpr hn'), ne_eq,
          ← eq_neg_iff_add_eq_zero]
      exact hn.1
  exact @asIso _ _ _ _ f ((isIso_iff_mono_and_epi f).mpr ⟨h1, h2⟩)

noncomputable def KernelMapEpiAcyclic {X Y : t₁.Heart} (hX : AcyclicObject F t₁ t₂ X)
    (hY : AcyclicObject F t₁ t₂ Y) (f : X ⟶ Y)
    (hf1 : AcyclicObject F t₁ t₂ (Limits.kernel f)) (hf2 : Epi f) :
    IsLimit (Limits.KernelFork.ofι (f := (F.FunctorFromHeartToHeart t₁ t₂).map f)
    ((F.FunctorFromHeartToHeart t₁ t₂).map (kernel.ι f))
    (by rw [← map_comp, kernel.condition, Functor.map_zero])) := by
  set Z : AcyclicCategory F t₁ t₂ := ⟨(Limits.kernel f), hf1⟩
  set g : Z ⟶ ⟨X, hX⟩ := Limits.kernel.ι f with hgdef
  set f' : (⟨X, hX⟩ : AcyclicCategory F t₁ t₂) ⟶ ⟨Y, hY⟩ := f with hf'def
  set S := ShortComplex.mk (C := AcyclicCategory F t₁ t₂) g f'
    (by refine Functor.Faithful.map_injective (F := fullSubcategoryInclusion _) ?_
        simp only [fullSubcategoryInclusion.obj, hgdef, hf'def, fullSubcategoryInclusion.map]
        exact kernel.condition f (C := t₁.Heart))
  have SE : ((AcyclicToHeart F t₁ t₂).mapShortComplex.obj S).ShortExact := by
    refine ShortComplex.ShortExact.mk' ?_ ?_ ?_
    · refine ShortComplex.exact_of_f_is_kernel _ ?_
      simp only [AcyclicToHeart, fullSubcategoryInclusion.obj, fullSubcategoryInclusion.map, id_eq,
        eq_mpr_eq_cast, cast_eq, mapShortComplex_obj, ShortComplex.map_X₂, ShortComplex.map_X₃,
        ShortComplex.map_g, ShortComplex.map_X₁, ShortComplex.map_f, S, g]
      exact kernelIsKernel _
    · simp only [fullSubcategoryInclusion.obj, fullSubcategoryInclusion.map, id_eq, eq_mpr_eq_cast,
      cast_eq, mapShortComplex_obj, ShortComplex.map_X₁, ShortComplex.map_X₂, ShortComplex.map_f, S]
      change Mono (Limits.kernel.ι (C := t₁.Heart) f)
      exact inferInstance
    · simp only [fullSubcategoryInclusion.obj, fullSubcategoryInclusion.map, id_eq, eq_mpr_eq_cast,
      cast_eq, mapShortComplex_obj, ShortComplex.map_X₂, ShortComplex.map_X₃, ShortComplex.map_g, S]
      simp only [f', AcyclicToHeart]; change Epi (C := t₁.Heart) f
      exact hf2
  have FSE : ((FunctorFromAcyclic F t₁ t₂).mapShortComplex.obj S).ShortExact :=
    AcyclicShortExact F t₁ t₂ SE
  set S' := (FunctorFromHeartToHeart F t₁ t₂).mapShortComplex.obj
    (ShortComplex.mk (kernel.ι (C := t₁.Heart) f) f (kernel.condition (C := t₁.Heart) f)) with hS'
  have S'E : S'.ShortExact := by
    refine ShortComplex.shortExact_of_iso ((ShortComplex.mapNatIso _
      (FunctorFromAcyclicFactorization F t₁ t₂)).trans ?_ ) FSE
    simp only [hS', mapShortComplex_obj]
    refine ShortComplex.isoMk ?_ ?_ ?_ ?_ ?_
    · simp only [ShortComplex.map_X₁, comp_obj, fullSubcategoryInclusion.obj]
      exact Iso.refl _
    · simp only [ShortComplex.map_X₂, comp_obj, fullSubcategoryInclusion.obj]
      exact Iso.refl _
    · simp only [ShortComplex.map_X₃, comp_obj, fullSubcategoryInclusion.obj]
      exact Iso.refl _
    · simp only [ShortComplex.map_X₁, comp_obj, fullSubcategoryInclusion.obj, ShortComplex.map_X₂,
      id_eq, Iso.refl_hom, ShortComplex.map_f, comp_map, id_comp, fullSubcategoryInclusion.map,
      comp_id]
    · simp only [ShortComplex.map_X₂, comp_obj, fullSubcategoryInclusion.obj, ShortComplex.map_X₃,
      id_eq, Iso.refl_hom, ShortComplex.map_g, comp_map, id_comp, fullSubcategoryInclusion.map,
      comp_id]
  exact ShortComplex.ShortExact.fIsKernel S'E

lemma KernelComparisonEpiAcyclic {X Y : t₁.Heart} (hX : AcyclicObject F t₁ t₂ X)
    (hY : AcyclicObject F t₁ t₂ Y) (f : X ⟶ Y)
    (hf1 : AcyclicObject F t₁ t₂ (Limits.kernel f)) (hf2 : Epi f) :
    IsIso (Limits.kernelComparison f (FunctorFromHeartToHeart F t₁ t₂)) := by
  set e := IsLimit.conePointUniqueUpToIso (KernelMapEpiAcyclic F t₁ t₂ hX hY f hf1 hf2)
    (limit.isLimit (parallelPair ((F.FunctorFromHeartToHeart t₁ t₂).map f) 0)) with hedef
  have heq : (kernelComparison f (C := t₁.Heart) (F.FunctorFromHeartToHeart t₁ t₂)) = e.hom := by
    refine Mono.right_cancellation (f := kernel.ι ((FunctorFromHeartToHeart F t₁ t₂).map f)) _ _ ?_
    rw [kernelComparison_comp_ι, hedef]
    change _ = _ ≫ CategoryTheory.Limits.limit.π (CategoryTheory.Limits.parallelPair
      ((F.FunctorFromHeartToHeart t₁ t₂).map f) 0) CategoryTheory.Limits.WalkingParallelPair.zero
    erw [IsLimit.conePointUniqueUpToIso_hom_comp]
    simp only [comp_obj, comp_map, parallelPair_obj_zero, Fork.ofι_pt, Fork.ofι_π_app]
  rw [heq]
  exact inferInstance

noncomputable def KernelMapAcyclic {X Y : t₁.Heart} (hX : AcyclicObject F t₁ t₂ X)
    (f : X ⟶ Y) (hf0 : AcyclicObject F t₁ t₂ (Abelian.image f))
    (hf1 : AcyclicObject F t₁ t₂ (Limits.kernel f))
    (hf2 : AcyclicObject F t₁ t₂ (Limits.cokernel f)) :
    IsLimit (Limits.KernelFork.ofι (f := (F.FunctorFromHeartToHeart t₁ t₂).map f)
    ((F.FunctorFromHeartToHeart t₁ t₂).map (kernel.ι f))
    (by rw [← map_comp, kernel.condition, Functor.map_zero])) := by
  set g := Abelian.factorThruImage f
  have hg := isKernelCompMono (kernelIsKernel g) (Abelian.image.ι f)
    (Abelian.image.fac f).symm
  have hg1 : AcyclicObject F t₁ t₂ (kernel g) := by
    set e := IsLimit.conePointUniqueUpToIso (kernelIsKernel f) hg
    exact ClosedUnderIsomorphisms.of_iso e hf1
  set hgK := KernelMapEpiAcyclic F t₁ t₂ hX hf0 g hg1 inferInstance
  have heq : (F.FunctorFromHeartToHeart t₁ t₂).map f =
      (F.FunctorFromHeartToHeart t₁ t₂).map g ≫ (F.FunctorFromHeartToHeart t₁ t₂).map
      (Abelian.image.ι f) := by rw [← map_comp, Abelian.image.fac]
  have hmon : Mono ((F.FunctorFromHeartToHeart t₁ t₂).map (Abelian.image.ι f)) := sorry
  letI := hmon
  have := isKernelCompMono hgK ((F.FunctorFromHeartToHeart t₁ t₂).map (Abelian.image.ι f)) heq
  set e := (Cones.functoriality _ (F.FunctorFromHeartToHeart t₁ t₂)).mapIso (IsLimit.uniqueUpToIso hg (kernelIsKernel f))
  simp? at e
--  exact IsLimit.ofIsoLimit this e

abbrev IsCohomologicalBound (a b : ℤ) := ∀ (X : t₁.Heart) (r : ℤ),
    r < a ∨ b < r → (t₂.homology r).obj (F.obj X.1) = 0

lemma ExactOfExactComplex {a b : ℤ} (hb : IsCohomologicalBound F t₁ t₂ a b)
    {S : CochainComplex t₁.Heart ℤ} (Sexact : ∀ (n : ℤ), S.homology' n = 0) :
    0 = 0 := sorry
