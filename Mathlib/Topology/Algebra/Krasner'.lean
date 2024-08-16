import Mathlib.FieldTheory.Minpoly.Basic
import Mathlib.FieldTheory.Separable
import Mathlib.Topology.Defs.Induced
import Mathlib.FieldTheory.Adjoin
import Mathlib.RingTheory.Valuation.RankOne
import Mathlib.Topology.Algebra.Valued.NormedValued
import Mathlib.RingTheory.Henselian
import Mathlib.Topology.Algebra.Module.FiniteDimension
import Mathlib.Topology.Connected.Separation
import Mathlib.FieldTheory.Normal


import Mathlib.Topology.Algebra.KrasnerDependency

/-!
## TODO
1. uniform space eq -- no need
2. proof ‖z‖ = ‖z'‖ -- finished
3. add dictionary --
4. fill the version of valuations

5. Furthur change theorem like `Normal.minpoly_eq_iff_mem_orbit` using `IsConjRoot`
-/

open Polynomial minpoly IntermediateField

variable {R : Type*} {A : Type*} [CommRing R] [Ring A] [Algebra R A]

variable (K : Type*) {L : Type*} {ΓK ΓL : outParam Type*}
    [LinearOrderedCommGroupWithZero ΓK] [LinearOrderedCommGroupWithZero ΓL]
    [Field K] [Field L] [Algebra K L] [vK : Valued K ΓK] [vL : Valued L ΓL]


section conj

variable (R) in
def IsConjRoot (x x' : A) : Prop := (minpoly R x) = (minpoly R x')
-- Galois action

namespace IsConjRoot

theorem refl {x : A} : IsConjRoot R x x := rfl

theorem symm {x x' : A} (h : IsConjRoot R x x') : IsConjRoot R x' x := Eq.symm h

theorem trans {x x' x'': A} (h₁ : IsConjRoot R x x') (h₂ : IsConjRoot R x' x'') :
    IsConjRoot R x x'' := Eq.trans h₁ h₂

theorem of_minpoly_eq {x x' : A} (h : minpoly R x = minpoly R x') : IsConjRoot R x x' := h

theorem algEquiv_apply (x : A) (s : A ≃ₐ[R] A) : IsConjRoot R x (s x) :=
  Eq.symm (minpoly.algEquiv_eq s x)

theorem algEquiv_apply₂ (x : A) (s₁ s₂ : A ≃ₐ[R] A) : IsConjRoot R (s₁ x) (s₂ x) :=
  of_minpoly_eq <| (minpoly.algEquiv_eq s₂ x) ▸ (minpoly.algEquiv_eq s₁ x)

variable {K} in
theorem exist_algEquiv [Normal K L] {x x': L} (h : IsConjRoot K x x') :
    ∃ σ : L ≃ₐ[K] L, x' = σ x := by
  obtain ⟨σ, hσ⟩ :=
    exists_algHom_of_splits_of_aeval (normal_iff.mp inferInstance) (h ▸ minpoly.aeval K x')
  exact ⟨AlgEquiv.ofBijective σ (σ.normal_bijective _ _ _), hσ.symm⟩

theorem eq_of_degree_minpoly_eq_one {x x' : A} (h : IsConjRoot R x x')
    (g : degree (minpoly R x) = 1) : x = x' := by
  sorry

theorem eq_of_natDegree_minpoly_eq_one {x x' : A} (h : IsConjRoot R x x')
    (g : natDegree (minpoly R x) = 1) : x = x' := sorry

theorem eq_of_isConjRoot_algebraMap {r : R} {x : A} (h : IsConjRoot R x (algebraMap R A r)) :
    x = algebraMap R A r := sorry

theorem neg {x x' : A} (r : R) (h : IsConjRoot R x x') :  IsConjRoot R (-x) (-x') := sorry

theorem add_algebraMap {x x' : A} (r : R) (h : IsConjRoot R x x') :
    IsConjRoot R (x + algebraMap R A r) (x' + algebraMap R A r) := sorry

theorem sub_algebraMap {x x' : A} (r : R) (h : IsConjRoot R x x') :
    IsConjRoot R (x - algebraMap R A r) (x' - algebraMap R A r) := sorry

theorem smul {x x' : A} (r : R) (h : IsConjRoot R x x') :  IsConjRoot R (r • x) (r • x') := sorry

variable (R) in
theorem of_isScalarTower {S : Type*} [CommRing S] [Algebra R S] [Algebra S A]
    [IsScalarTower R S A] {x x' : A} (h : IsConjRoot S x x') : IsConjRoot R x x' := sorry

variable {K} in
theorem not_mem_iff_exist_ne {x : L} (sep : (minpoly K x).Separable) :
    x ∉ (⊥ : Subalgebra K L) ↔ ∃ x' : L, x ≠ x' ∧ IsConjRoot K x x' := sorry

variable {K} in
theorem isIntegral {x x' : L} (hx : IsIntegral K x) (h : IsConjRoot K x x') :
    IsIntegral K x' := by sorry

theorem iff_eq_zero {x : A} : IsConjRoot R 0 x ↔ x = 0 := sorry

theorem ne_zero {x x' : A} (hx : x ≠ 0) (h : IsConjRoot R x x') : x' ≠ 0 := sorry

end IsConjRoot

end conj

section Separable
-- do we need elementwise IsSeparable (just like IsIntegral) and
-- rename old one into Field.IsSeparable
--`separable_mul`
--`Field.separable_add`
--`Field.separable_inv`
theorem Polynomial.Separable.minpoly_add {x y : A} (hx : (minpoly R x).Separable) (hy : (minpoly R y).Separable) : (minpoly R (x + y)).Separable := sorry

theorem Polynomial.Separable.minpoly_neg {x : A} (hx : (minpoly R x).Separable) : (minpoly R (-x)).Separable := sorry

theorem Polynomial.Separable.minpoly_sub {x y : A} (hx : (minpoly R x).Separable) (hy : (minpoly R y).Separable) : (minpoly R (x - y)).Separable := sorry

-- theorem Polymonial.Separable.minpoly_mul

-- smul

-- pow

variable (A : Type*) {B : Type*} [Field A] [CommRing B] [Algebra R A]
    [Algebra R B] [Algebra A B] [IsScalarTower R A B]

theorem Polynomial.minpoly_separable_of_isScalarTower {x : B} (h : (minpoly R x).Separable) :
    (minpoly A x).Separable := by
  apply Polynomial.Separable.of_dvd (Polynomial.Separable.map h)
  exact minpoly.dvd_map_of_isScalarTower R A x

end Separable

section NormValued

@[simp]
theorem Valued.toNormedField.norm_le_iff [vL.v.RankOne] {x x' : L} :
    letI := vL.toNormedField
    ‖x‖ ≤ ‖x'‖ ↔ vL.v x ≤ vL.v x' := (Valuation.RankOne.strictMono vL.v).le_iff_le

@[simp]
theorem Valued.toNormedField.norm_lt_iff [vL.v.RankOne] {x x' : L} :
    letI := vL.toNormedField
    ‖x‖ < ‖x'‖ ↔ vL.v x < vL.v x' := (Valuation.RankOne.strictMono vL.v).lt_iff_lt

@[simp]
theorem Valued.toNormedField.norm_le_one_iff [vL.v.RankOne] {x : L} :
    letI := vL.toNormedField
    ‖x‖ ≤ 1 ↔ vL.v x ≤ 1 := by
  simpa only [map_one] using (Valuation.RankOne.strictMono vL.v).le_iff_le (b := 1)

@[simp]
theorem Valued.toNormedField.norm_lt_one_iff [vL.v.RankOne] {x : L} :
    letI := vL.toNormedField
    ‖x‖ < 1 ↔ vL.v x < 1 := by
  simpa only [map_one] using (Valuation.RankOne.strictMono vL.v).lt_iff_lt (b := 1)

@[simp]
theorem Valued.toNormedField.one_le_norm_iff [vL.v.RankOne] {x : L} :
    letI := vL.toNormedField
    1 ≤ ‖x‖ ↔ 1 ≤ vL.v x := by
  simpa only [map_one] using (Valuation.RankOne.strictMono vL.v).le_iff_le (a := 1)

@[simp]
theorem Valued.toNormedField.one_lt_norm_iff [vL.v.RankOne] {x : L} :
    letI := vL.toNormedField
    1 < ‖x‖ ↔ 1 < vL.v x := by
  simpa only [map_one] using (Valuation.RankOne.strictMono vL.v).lt_iff_lt (a := 1)

def Valued.toNontriviallyNormedField [vL.v.RankOne] : NontriviallyNormedField L := {
  vL.toNormedField with
  non_trivial := by
    obtain ⟨x, hx⟩ := Valuation.RankOne.nontrivial vL.v
    have : x ≠ 0 := vL.v.ne_zero_iff.mp hx.1
    rcases Valuation.val_le_one_or_val_inv_le_one vL.v x with h | h
    · use x⁻¹
      simp only [toNormedField.one_lt_norm_iff, map_inv₀, one_lt_inv₀ hx.1, lt_of_le_of_ne h hx.2]
    · use x
      simp only [map_inv₀, inv_le_one₀ hx.1] at h
      simp only [toNormedField.one_lt_norm_iff, lt_of_le_of_ne h hx.2.symm]
}

end NormValued

section ContinuousSMul

instance ContinuousSMul.instBotIntermediateField {K L : Type*} [Field K] [Field L] [Algebra K L]
    [TopologicalSpace L] [TopologicalRing L] (M : IntermediateField K L) :
    ContinuousSMul (⊥ : IntermediateField K L) M :=
  Inducing.continuousSMul (N := (⊥ : IntermediateField K L)) (Y := M)
    (M := (⊥ : IntermediateField K L)) (X := L) inducing_subtype_val continuous_id rfl

end ContinuousSMul

section NormedField

instance instNormedSubfield {L : Type*} [NL : NormedField L] {M : Subfield L} : NormedField M := {
  M.toField with
  dist_eq := fun _ _ ↦ NL.dist_eq _ _
  norm_mul' := fun _ _ ↦ NL.norm_mul' _ _
}

instance instNormedIntermediateField {K L : Type*} [Field K] [NormedField L] [Algebra K L]
    {M : IntermediateField K L} : NormedField M :=
  inferInstanceAs (NormedField M.toSubfield)

end NormedField

section FunctionExtends

theorem functionExtends_of_functionExtends_of_functionExtends {A} [CommRing A] [Algebra R A]
    {B : Type*} [Ring B] [Algebra R B] [Algebra A B] [IsScalarTower R A B] {fR : R → ℝ}
    {fA : A → ℝ} {fB : B → ℝ} (h1 : FunctionExtends fR fA) (h2 : FunctionExtends fA fB) :
    FunctionExtends fR fB := by
  intro x
  calc
    fB ((algebraMap R B) x) = fA (algebraMap R A x) :=
      h2 _ ▸ IsScalarTower.algebraMap_apply R A B x ▸ rfl
    _ = fR x := h1 x

end FunctionExtends

-- section AlgEquiv
-- -- a missing lemma
-- variable (R) in
-- @[simp]
-- theorem AlgEquiv.refl_apply (x : A) : (AlgEquiv.refl : A ≃ₐ[R] A) x = x := rfl

-- end AlgEquiv


open Algebra
open IntermediateField

variable (L) in
class IsKrasner : Prop where
  krasner' : ∀ {x y : L}, (minpoly K x).Separable → IsIntegral K y →
    (∀ x' : L, IsConjRoot K x x' →  x ≠ x' → vL.v (x - y) < vL.v (x - x')) →
      x ∈ K⟮y⟯

class IsKrasnerNorm (K L : Type*) [Field K] [NormedField L] [Algebra K L] : Prop where
  krasner_norm' : ∀ {x y : L}, (minpoly K x).Separable → IsIntegral K y →
    (∀ x' : L, IsConjRoot K x x' →  x ≠ x' → ‖x - y‖ < ‖x - x'‖) →
      x ∈ K⟮y⟯

variable [IsKrasner K L]

theorem IsKrasner.krasner {x y : L} (hx : (minpoly K x).Separable) (hy : IsIntegral K y)
    (h : (∀ x' : L, IsConjRoot K x x' → x ≠ x' → vL.v (x - y) < vL.v (x - x'))) : x ∈ K⟮y⟯ :=
  IsKrasner.krasner' hx hy h
-- Algebra.adjoin R {x} ≤ Algebra.adjoin R {y}

theorem IsKrasnerNorm.krasner_norm {K L : Type*} [Field K] [NormedField L] [Algebra K L]
    [IsKrasnerNorm K L] {x y : L} (hx : (minpoly K x).Separable) (hy : IsIntegral K y)
    (h : (∀ x' : L, IsConjRoot K x x' → x ≠ x' → ‖x - y‖ < ‖x - x'‖)) : x ∈ K⟮y⟯ :=
  IsKrasnerNorm.krasner_norm' hx hy h

namespace IsKrasnerNorm

variable {K L : Type*} [NK : NontriviallyNormedField K] (is_na : IsNonarchimedean (norm : K → ℝ))
    [NL : NormedField L] [Algebra K L] (extd : FunctionExtends (norm : K → ℝ) (norm : L → ℝ))


variable (M : IntermediateField K L)

#synth Algebra K M
#synth NormedField M
#synth Algebra M L
#synth Algebra (⊥ : IntermediateField K L) M
-- #synth IsScalarTower K (⊥ : IntermediateField K L) M

#check spectralNorm_aut_isom
#check spectralNorm_unique_field_norm_ext
theorem of_completeSpace [CompleteSpace K] : IsKrasnerNorm K L := by
  constructor
  intro x y xsep hyK hxy
  let z := x - y
  let M := K⟮y⟯
  let FDM := IntermediateField.adjoin.finiteDimensional hyK
  let BotEquiv : NormedAddGroupHom K (⊥ : IntermediateField K L) := -- put this outside
    {
      (IntermediateField.botEquiv K L).symm with
      bound' := by
        use 1
        intro x
        erw [extd x]
        simp only [one_mul, le_refl]
    }
  have : ContinuousSMul K M := by
    -- decompose as `ContinuousSMul K L`
    -- and `ContinuousSMul K L implies ContinuousSMul K M`
    apply Inducing.continuousSMul (N := K) (M := (⊥ : IntermediateField K L)) (X := M) (Y := M)
      (f := (IntermediateField.botEquiv K L).symm) inducing_id
    · exact BotEquiv.continuous
    · intros c x
      rw [Algebra.smul_def, @Algebra.smul_def (⊥ : IntermediateField K L) M _ _ _]
      rfl
  letI : CompleteSpace M := FiniteDimensional.complete K M
  have hy : y ∈ K⟮y⟯ := IntermediateField.subset_adjoin K {y} rfl
  have zsep : (minpoly M z).Separable := by
    apply Polynomial.Separable.minpoly_sub (Polynomial.minpoly_separable_of_isScalarTower M xsep)
    exact
      minpoly.eq_X_sub_C_of_algebraMap_inj (⟨y, hy⟩ : M)
          (NoZeroSMulDivisors.algebraMap_injective (↥M) L) ▸
        Polynomial.separable_X_sub_C (x := (⟨y, hy⟩ : M))
  suffices z ∈ K⟮y⟯ by simpa [z] using add_mem this hy
  by_contra hnin
  have : z ∈ K⟮y⟯ ↔ z ∈ (⊥ : Subalgebra M L) := by simp [Algebra.mem_bot]
  rw [this.not] at hnin
  obtain ⟨z', hne, h1⟩ := (IsConjRoot.not_mem_iff_exist_ne zsep).mp hnin
  -- this is where the separablity is used.
  simp only [ne_eq, Subtype.mk.injEq] at hne
  have eq_spnM : (norm : M → ℝ) = spectralNorm K M :=
    funext <| spectralNorm_unique_field_norm_ext
      (f := instNormedIntermediateField.toMulRingNorm) extd is_na
  have eq_spnL : (norm : L → ℝ) = spectralNorm K L :=
    funext <| spectralNorm_unique_field_norm_ext (f := NL.toMulRingNorm) extd is_na
  have is_naM : IsNonarchimedean (norm : M → ℝ) := eq_spnM ▸ spectralNorm_isNonarchimedean K M is_na
  have is_naL : IsNonarchimedean (norm : L → ℝ) := eq_spnL ▸ spectralNorm_isNonarchimedean K L is_na
  letI : NontriviallyNormedField M := {
    instNormedIntermediateField with
    non_trivial := by
      obtain ⟨k, hk⟩ :=  @NontriviallyNormedField.non_trivial K _
      use algebraMap K M k
      change 1 < ‖(algebraMap K L) k‖
      simp [extd k, hk]-- a lemma for extends nontrivial implies nontrivial
  }
  have eq_spnML: (norm : L → ℝ) = spectralNorm M L := by
    apply Eq.trans eq_spnL
    apply (_root_.funext <| spectralNorm_unique_field_norm_ext (K := K)
      (f := (spectralMulAlgNorm is_naM).toMulRingNorm) _ is_na).symm
    apply functionExtends_of_functionExtends_of_functionExtends (fA := (norm : M → ℝ))
    · intro m
      exact extd m
    · exact spectralNorm_extends M L -- a lemma for extends extends
  have norm_eq: ‖z‖ = ‖z'‖ := by -- a lemma
    simp only [eq_spnML, spectralNorm]
    congr 1
    -- spectralNorm K L = spectralnorm M L
  -- IsConjRoot.val_eq M hM (Polynomial.Separable.isIntegral zsep) h1
  -- need rank one -- exist_algEquiv
  have : ‖z - z'‖ < ‖z - z'‖ := by
    calc
      _ ≤ max ‖z‖ ‖z'‖ := by
        simpa only [norm_neg, sub_eq_add_neg] using (is_naL z (- z'))
      _ ≤ ‖x - y‖ := by
        simp only [← norm_eq, max_self, le_refl]
      _ < ‖x - (z' + y)‖ := by
        apply hxy (z' + y)
        · apply IsConjRoot.of_isScalarTower (S := M) K
          simpa only [IntermediateField.algebraMap_apply, sub_add_cancel, z] using
            IsConjRoot.add_algebraMap ⟨y, hy⟩ h1
        · simpa [z, sub_eq_iff_eq_add] using hne
      _ = ‖z - z'‖ := by congr 1; ring
  simp only [lt_self_iff_false] at this

end IsKrasnerNorm

section Valued

variable {Γ Γ' : Type*} [LinearOrderedCommGroupWithZero Γ] [LinearOrderedCommGroupWithZero Γ']
    {vK : Valued K Γ} {vK' : Valued K Γ'}
/-- Equivalent valuations induces the same topology -/
theorem Valued.toUniformSpace_eq_of_isEquiv (h : vK.v.IsEquiv vK'.v) :
  vK.toUniformSpace = vK'.toUniformSpace := by
  sorry -- must use new definition of is_topological_valuation

end Valued

namespace IsKrasner

-- TODO: it is possible to remove the condition `vL.v.RankOne`, since
-- any algebraic extension of rank one valued field K is rank one valued.
-- Just extract the maximal algebraic extension of K in L
-- it should be an instance after h is a type class
theorem of_completeSpace [rk1L : vL.v.RankOne] {ΓK : outParam Type*}
    [LinearOrderedCommGroupWithZero ΓK] [vK : Valued K ΓK] [rk1K : vK.v.RankOne] [CompleteSpace K]
    (h : vK.v.IsEquiv <| vL.v.comap (algebraMap K L)): IsKrasner K L := by
  constructor
  intro x y xsep hyK hxy
  -- translate between vL.v.comap (algebraMap K L) and vL
  letI := vL.toNormedField
  letI vK' : Valued K ΓL := {
    vK.toUniformSpace with
    v := (vL.v.comap (algebraMap K L))
    is_topological_valuation := sorry
  }
  letI : (vL.v.comap (algebraMap K L)).RankOne := {
    hom := rk1L.hom
    strictMono' := rk1L.strictMono'
    nontrivial' := by
      obtain ⟨x, ⟨hx0, hx1⟩⟩ := rk1K.nontrivial'
      use x
      exact ⟨h.ne_zero.mp hx0 , ((Valuation.isEquiv_iff_val_eq_one _ _).mp h).not.mp hx1⟩
  }
  letI := vK'.toNontriviallyNormedField
  refine (IsKrasnerNorm.of_completeSpace (K := K) (L := L) ?_ ?_).krasner_norm xsep hyK ?_
  · sorry -- isNonArch
  · sorry -- FunctionExtends
  · sorry -- translation
  -- let z := x - y
  -- let M := K⟮y⟯
  -- let FDM := IntermediateField.adjoin.finiteDimensional hyK
  -- let I'' : UniformAddGroup M := inferInstanceAs (UniformAddGroup M.toSubfield.toSubring)
  -- let NNFK : NontriviallyNormedField K := vK.toNontriviallyNormedField
  -- have : ContinuousSMul K M := by -- decompose as `ContinuousSMul K L implies ContinuousSMul K M`
  --   apply Inducing.continuousSMul (N := K) (M := (⊥ : IntermediateField K L)) (X := M)
  --    (Y := M) (f := (IntermediateField.botEquiv K L).symm) inducing_id
  --   · simpa only [bot_toSubalgebra] using
  --     (continuous_induced_rng (f := (Subtype.val : (⊥ : IntermediateField K L) → L)) (g :=
  --           (IntermediateField.botEquiv K L).symm)).mpr <|
  --       h.toUniformInducing.inducing.continuous
  --   · intro r m
  --     ext
  --     simp
  -- -- have : u = NNFK.toUniformSpace := by
  -- --   rw [Valued.toNormedField.toUniformSpace_eq]
  -- --   rw [Valued.toUniformSpace_eq_of_isEquiv_comap (vK := vK) (Valuation.IsEquiv.refl)]
  -- --   ext
  --   -- rw [← h.comap_uniformity]
  --   -- rfl
  -- -- subst this
  -- let hM : Embedding (algebraMap M L) := Function.Injective.embedding_induced
  --    Subtype.val_injective
  -- -- M with UniformSpace already, as subspace of L
  -- letI : CompleteSpace M := FiniteDimensional.complete K M
  -- -- @FiniteDimensional.complete K M sorry sorry _ _ _ sorry _ _ _
  -- -- this need all topology on M is the same and complete?
  -- have hy : y ∈ K⟮y⟯ := IntermediateField.subset_adjoin K {y} rfl
  -- have zsep : (minpoly M z).Separable := by
  --   apply Polynomial.Separable.minpoly_sub (Polynomial.minpoly_separable_of_isScalarTower M xsep)
  --   simpa only using
  --     minpoly.eq_X_sub_C_of_algebraMap_inj (⟨y, hy⟩ : M)
  --         (NoZeroSMulDivisors.algebraMap_injective (↥M) L) ▸
  --       Polynomial.separable_X_sub_C (x := (⟨y, hy⟩ : M))
  -- suffices z ∈ K⟮y⟯ by simpa [z] using add_mem this hy
  -- by_contra hnin
  -- have : z ∈ K⟮y⟯ ↔ z ∈ (⊥ : Subalgebra M L) := by simp [Algebra.mem_bot]
  -- rw [this.not] at hnin
  -- obtain ⟨z', hne, h1⟩ := (IsConjRoot.not_mem_iff_exist_ne zsep).mp hnin
  -- -- this is where the separablity is used.
  -- -- rw [not_mem_iff_nontrvial zsep] at hnin
  -- -- obtain ⟨⟨z', h1⟩, hne⟩ := exists_ne (⟨z, conjRootSet.self_mem z⟩ :
  --    { x // x ∈ conjRootSet M z })
  -- simp only [ne_eq, Subtype.mk.injEq] at hne
  -- -- simp only [conjRootSet, Set.coe_setOf, Set.mem_toFinset, Set.mem_setOf_eq] at h1
  -- -- let vM : Valued M NNReal := sorry
  -- have : vL.v z = vL.v z' := IsConjRoot.val_eq M hM (Polynomial.Separable.isIntegral zsep) h1
  -- -- need rank one
  -- have : vL.v (z - z') < vL.v (z - z') := by
  --   calc
  --     _ ≤ vL.v (x - y) := by simpa only [max_self, ← this] using Valuation.map_sub vL.v z z'
  --     _ < vL.v (x - (z' + y)) := by
  --       apply hxy (z' + y)
  --       · apply IsConjRoot.of_isScalarTower (S := M) K
  --         simpa only [IntermediateField.algebraMap_apply, sub_add_cancel, z] using
  --           IsConjRoot.add_algebraMap ⟨y, hy⟩ h1
  --       · simpa [z, sub_eq_iff_eq_add] using hne
  --     _ = vL.v (z - z') := by congr 1; ring
  -- simp only [lt_self_iff_false] at this

end IsKrasner
