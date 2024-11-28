/-
Copyright (c) 2024 Jireh Loreaux. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jireh Loreaux
-/
import Mathlib.Analysis.CStarAlgebra.ContinuousFunctionalCalculus.Order
import Mathlib.Analysis.CStarAlgebra.ContinuousFunctionalCalculus.Isometric
import Mathlib.Analysis.CStarAlgebra.SpecialFunctions.PosPart
import Mathlib.Analysis.SpecialFunctions.ContinuousFunctionalCalculus.Rpow
import Mathlib.Topology.ApproximateUnit

/-! # Nonnegative contractions in a C⋆-algebra form an approximate unit

This file shows that the collection of positive contractions (of norm strictly less than one)
in a possibly non-unital C⋆-algebra form a directed set. The key step uses the continuous functional
calculus applied with the functions `fun x : ℝ≥0, 1 - (1 + x)⁻¹` and `fun x : ℝ≥0, x * (1 - x)⁻¹`,
which are inverses on the interval `{x : ℝ≥0 | x < 1}`.

In addition, this file defines `IsIncreasingApproximateUnit` to be a filter `l` that is an
approximate unit contained in the closed unit ball of nonnegative elements. Every C⋆-algebra has
a filter generated by the sections `{x | a ≤ x} ∩ closedBall 0 1` for `0 ≤ a` and `‖a‖ < 1`, and
moreover, this filter is an increasing approximate unit.

## Main declarations

+ `CFC.monotoneOn_one_sub_one_add_inv`: the function `f := fun x : ℝ≥0, 1 - (1 + x)⁻¹` is
  *operator monotone* on `Set.Ici (0 : A)` (i.e., `cfcₙ f` is monotone on `{x : A | 0 ≤ x}`).
+ `Set.InvOn.one_sub_one_add_inv`: the functions `f := fun x : ℝ≥0, 1 - (1 + x)⁻¹` and
  `g := fun x : ℝ≥0, x * (1 - x)⁻¹` are inverses on `{x : ℝ≥0 | x < 1}`.
+ `CStarAlgebra.directedOn_nonneg_ball`: the set `{x : A | 0 ≤ x} ∩ Metric.ball 0 1` is directed.
+ `Filter.IsIncreasingApproximateUnit`: a filter `l` is an *increasing approximate unit* if it is an
  approximate unit contained in the closed unit ball of nonnegative elements.
+ `CStarAlgebra.approximateUnit`: the filter generated by the sections
  `{x | a ≤ x} ∩ closedBall 0 1` for `0 ≤ a` with `‖a‖ < 1`.
+ `CStarAlgebra.increasingApproximateUnit`: the filter `CStarAlgebra.approximateUnit` is an
  increasing approximate unit.

-/

variable {A : Type*} [NonUnitalCStarAlgebra A]

local notation "σₙ" => quasispectrum
local notation "σ" => spectrum

open Unitization NNReal CStarAlgebra

variable [PartialOrder A] [StarOrderedRing A]

lemma CFC.monotoneOn_one_sub_one_add_inv :
    MonotoneOn (cfcₙ (fun x : ℝ≥0 ↦ 1 - (1 + x)⁻¹)) (Set.Ici (0 : A)) := by
  intro a ha b hb hab
  simp only [Set.mem_Ici] at ha hb
  rw [← inr_le_iff .., nnreal_cfcₙ_eq_cfc_inr a _, nnreal_cfcₙ_eq_cfc_inr b _]
  rw [← inr_le_iff a b (.of_nonneg ha) (.of_nonneg hb)] at hab
  rw [← inr_nonneg_iff] at ha hb
  have h_cfc_one_sub (c : A⁺¹) (hc : 0 ≤ c := by cfc_tac) :
      cfc (fun x : ℝ≥0 ↦ 1 - (1 + x)⁻¹) c = 1 - cfc (·⁻¹ : ℝ≥0 → ℝ≥0) (1 + c) := by
    rw [cfc_tsub _ _ _ (fun x _ ↦ by simp) (hg := by fun_prop (disch := intro _ _; positivity)),
      cfc_const_one ℝ≥0 c, cfc_comp' (·⁻¹) (1 + ·) c ?_, cfc_add .., cfc_const_one ℝ≥0 c,
      cfc_id' ℝ≥0 c]
    exact continuousOn_id.inv₀ (Set.forall_mem_image.mpr fun x _ ↦ by dsimp only [id]; positivity)
  rw [h_cfc_one_sub (a : A⁺¹), h_cfc_one_sub (b : A⁺¹)]
  gcongr
  rw [← CFC.rpow_neg_one_eq_cfc_inv, ← CFC.rpow_neg_one_eq_cfc_inv]
  exact rpow_neg_one_le_rpow_neg_one (add_nonneg zero_le_one ha) (by gcongr) <|
    isUnit_of_le isUnit_one zero_le_one <| le_add_of_nonneg_right ha

lemma Set.InvOn.one_sub_one_add_inv : Set.InvOn (fun x ↦ 1 - (1 + x)⁻¹) (fun x ↦ x * (1 - x)⁻¹)
    {x : ℝ≥0 | x < 1} {x : ℝ≥0 | x < 1} := by
  have : (fun x : ℝ≥0 ↦ x * (1 + x)⁻¹) = fun x ↦ 1 - (1 + x)⁻¹ := by
    ext x : 1
    field_simp
    simp [tsub_mul, inv_mul_cancel₀]
  rw [← this]
  constructor <;> intro x (hx : x < 1)
  · have : 0 < 1 - x := tsub_pos_of_lt hx
    field_simp [tsub_add_cancel_of_le hx.le, tsub_tsub_cancel_of_le hx.le]
  · field_simp [mul_tsub]

lemma norm_cfcₙ_one_sub_one_add_inv_lt_one (a : A) :
    ‖cfcₙ (fun x : ℝ≥0 ↦ 1 - (1 + x)⁻¹) a‖ < 1 :=
  nnnorm_cfcₙ_nnreal_lt fun x _ ↦ tsub_lt_self zero_lt_one (by positivity)

-- the calls to `fun_prop` with a discharger set off the linter
set_option linter.style.multiGoal false in
lemma CStarAlgebra.directedOn_nonneg_ball :
    DirectedOn (· ≤ ·) ({x : A | 0 ≤ x} ∩ Metric.ball 0 1) := by
  let f : ℝ≥0 → ℝ≥0 := fun x => 1 - (1 + x)⁻¹
  let g : ℝ≥0 → ℝ≥0 := fun x => x * (1 - x)⁻¹
  suffices ∀ a b : A, 0 ≤ a → 0 ≤ b → ‖a‖ < 1 → ‖b‖ < 1 →
      a ≤ cfcₙ f (cfcₙ g a + cfcₙ g b) by
    rintro a ⟨(ha₁ : 0 ≤ a), ha₂⟩ b ⟨(hb₁ : 0 ≤ b), hb₂⟩
    simp only [Metric.mem_ball, dist_zero_right] at ha₂ hb₂
    refine ⟨cfcₙ f (cfcₙ g a + cfcₙ g b), ⟨by simp, ?_⟩, ?_, ?_⟩
    · simpa only [Metric.mem_ball, dist_zero_right] using norm_cfcₙ_one_sub_one_add_inv_lt_one _
    · exact this a b ha₁ hb₁ ha₂ hb₂
    · exact add_comm (cfcₙ g a) (cfcₙ g b) ▸ this b a hb₁ ha₁ hb₂ ha₂
  rintro a b ha₁ - ha₂ -
  calc
    a = cfcₙ (f ∘ g) a := by
      conv_lhs => rw [← cfcₙ_id ℝ≥0 a]
      refine cfcₙ_congr (Set.InvOn.one_sub_one_add_inv.1.eqOn.symm.mono fun x hx ↦ ?_)
      exact lt_of_le_of_lt (le_nnnorm_of_mem_quasispectrum hx) ha₂
    _ = cfcₙ f (cfcₙ g a) := by
      rw [cfcₙ_comp f g a ?_ (by simp [f, tsub_self]) ?_ (by simp [g]) ha₁]
      · fun_prop (disch := intro _ _; positivity)
      · have (x) (hx : x ∈ σₙ ℝ≥0 a) :  1 - x ≠ 0 := by
          refine tsub_pos_of_lt ?_ |>.ne'
          exact lt_of_le_of_lt (le_nnnorm_of_mem_quasispectrum hx) ha₂
        fun_prop (disch := assumption)
    _ ≤ cfcₙ f (cfcₙ g a + cfcₙ g b) := by
      have hab' : cfcₙ g a ≤ cfcₙ g a + cfcₙ g b := le_add_of_nonneg_right cfcₙ_nonneg_of_predicate
      exact CFC.monotoneOn_one_sub_one_add_inv cfcₙ_nonneg_of_predicate
        (cfcₙ_nonneg_of_predicate.trans hab') hab'

section ApproximateUnit

open Metric Filter Topology

/-- An *increasing approximate unit* in a C⋆-algebra is an approximate unit contained in the
closed unit ball of nonnegative elements. -/
structure Filter.IsIncreasingApproximateUnit (l : Filter A) extends l.IsApproximateUnit : Prop where
  eventually_nonneg : ∀ᶠ x in l, 0 ≤ x
  eventually_norm : ∀ᶠ x in l, ‖x‖ ≤ 1

namespace Filter.IsIncreasingApproximateUnit

omit [StarOrderedRing A] in
lemma eventually_nnnorm {l : Filter A} (hl : l.IsIncreasingApproximateUnit) :
    ∀ᶠ x in l, ‖x‖₊ ≤ 1 :=
  hl.eventually_norm

lemma eventually_isSelfAdjoint {l : Filter A} (hl : l.IsIncreasingApproximateUnit) :
    ∀ᶠ x in l, IsSelfAdjoint x :=
  hl.eventually_nonneg.mp <| .of_forall fun _ ↦ IsSelfAdjoint.of_nonneg

lemma eventually_star_eq {l : Filter A} (hl : l.IsIncreasingApproximateUnit) :
    ∀ᶠ x in l, star x = x :=
  hl.eventually_isSelfAdjoint.mp <| .of_forall fun _ ↦ IsSelfAdjoint.star_eq

end Filter.IsIncreasingApproximateUnit

namespace CStarAlgebra

open Submodule in
/-- To show that `l` is a one-sided approximate unit for `A`, it suffices to verify it only for
`m : A` with `0 ≤ m` and `‖m‖ < 1`. -/
lemma tendsto_mul_right_of_forall_nonneg_tendsto {l : Filter A}
    (h : ∀ m, 0 ≤ m → ‖m‖ < 1 → Tendsto (· * m) l (𝓝 m)) (m : A) :
    Tendsto (· * m) l (𝓝 m) := by
  obtain ⟨n, c, x, rfl⟩ := mem_span_set'.mp <| by
    show m ∈ span ℂ ({x | 0 ≤ x} ∩ ball 0 1)
    simp [span_nonneg_inter_unitBall]
  simp_rw [Finset.mul_sum]
  refine tendsto_finset_sum _ fun i _ ↦ ?_
  simp_rw [mul_smul_comm]
  exact tendsto_const_nhds.smul <| h (x i) (x i).2.1 <| by simpa using (x i).2.2

omit [PartialOrder A] in
/-- Multiplication on the left by `m` tends to `𝓝 m` if and only if multiplication on the right
does, provided the elements are eventually selfadjoint along the filter `l`. -/
lemma tendsto_mul_left_iff_tendsto_mul_right {l : Filter A} (hl : ∀ᶠ x in l, IsSelfAdjoint x) :
    (∀ m, Tendsto (m * ·) l (𝓝 m)) ↔ (∀ m, Tendsto (· * m) l (𝓝 m)) := by
  refine ⟨fun h m ↦ ?_, fun h m ↦ ?_⟩
  all_goals
    apply (star_star m ▸ (continuous_star.tendsto _ |>.comp <| h (star m))).congr'
    filter_upwards [hl] with x hx
    simp [hx.star_eq]

variable (A)

/-- The sections of positive strict contractions form a filter basis. -/
lemma isBasis_nonneg_sections :
    IsBasis (fun x : A ↦ 0 ≤ x ∧ ‖x‖ < 1) ({x | · ≤ x}) where
  nonempty := ⟨0, by simp⟩
  inter {x y} hx hy := by
    peel directedOn_nonneg_ball x (by simpa) y (by simpa) with z hz
    exact ⟨by simpa using hz.1, fun a ha ↦ ⟨hz.2.1.trans ha, hz.2.2.trans ha⟩⟩

/-- The canonical approximate unit in a C⋆-algebra generated by the basis of sets
`{x | a ≤ x} ∩ closedBall 0 1` for `0 ≤ a`. See also `CStarAlgebra.hasBasis_approximateUnit`. -/
def approximateUnit : Filter A :=
  (isBasis_nonneg_sections A).filter ⊓ 𝓟 (closedBall 0 1)

/-- The canonical approximate unit in a C⋆-algebra has a basis of sets
`{x | a ≤ x} ∩ closedBall 0 1` for `0 ≤ a`. -/
lemma hasBasis_approximateUnit :
    (approximateUnit A).HasBasis (fun x : A ↦ 0 ≤ x ∧ ‖x‖ < 1) ({x | · ≤ x} ∩ closedBall 0 1) :=
  isBasis_nonneg_sections A |>.hasBasis.inf_principal (closedBall 0 1)

/-- This is a common reasoning sequence in C⋆-algebra theory. If `0 ≤ x ≤ y ≤ 1`, then the norm
of `z - y * z` is controled by the norm of `star z * (1 - x) * z`, which is advantageous because the
latter is nonnegative. This is a key step in establishing the existence of an increasing approximate
unit in general C⋆-algebras. -/
lemma nnnorm_sub_mul_self_le {A : Type*} [CStarAlgebra A] [PartialOrder A] [StarOrderedRing A]
    {x y : A} (z : A) (hx₀ : 0 ≤ x) (hy : y ∈ Set.Icc x 1) {c : ℝ≥0}
    (h : ‖star z * (1 - x) * z‖₊ ≤ c ^ 2) :
    ‖z - y * z‖₊ ≤ c := by
  nth_rw 1 [← one_mul z]
  rw [← sqrt_sq c, le_sqrt_iff_sq_le, ← sub_mul, sq, ← CStarRing.nnnorm_star_mul_self]
  simp only [star_mul, star_sub, star_one]
  have hy₀ : y ∈ Set.Icc 0 1 := ⟨hx₀.trans hy.1, hy.2⟩
  have hy' : 1 - y ∈ Set.Icc 0 1 := Set.sub_mem_Icc_zero_iff_right.mpr hy₀
  rw [hy₀.1.star_eq, ← mul_assoc, mul_assoc (star _), ← sq]
  refine nnnorm_le_nnnorm_of_nonneg_of_le (conjugate_nonneg (pow_nonneg hy'.1 2) _) ?_ |>.trans h
  refine conjugate_le_conjugate ?_ _
  trans (1 - y)
  · simpa using pow_antitone hy'.1 hy'.2 one_le_two
  · gcongr
    exact hy.1

/-- A variant of `nnnorm_sub_mul_self_le` which uses `‖·‖` instead of `‖·‖₊`. -/
lemma norm_sub_mul_self_le {A : Type*} [CStarAlgebra A] [PartialOrder A] [StarOrderedRing A]
    {x y : A} (z : A) (hx₀ : 0 ≤ x) (hy : y ∈ Set.Icc x 1)
    {c : ℝ} (hc : 0 ≤ c) (h : ‖star z * (1 - x) * z‖ ≤ c ^ 2) :
    ‖z - y * z‖ ≤ c :=
  nnnorm_sub_mul_self_le z hx₀ hy h (c := ⟨c, hc⟩)

variable {A} in
/-- A variant of `norm_sub_mul_self_le` for non-unital algebras that passes to the unitization. -/
lemma norm_sub_mul_self_le_of_inr {x y : A} (z : A) (hx₀ : 0 ≤ x) (hxy : x ≤ y) (hy₁ : ‖y‖ ≤ 1)
    {c : ℝ} (hc : 0 ≤ c) (h : ‖star (z : A⁺¹) * (1 - x) * z‖ ≤ c ^ 2) :
    ‖z - y * z‖ ≤ c := by
  rw [← norm_inr (𝕜 := ℂ), inr_sub, inr_mul]
  refine norm_sub_mul_self_le _ ?_ ?_ hc h
  · rwa [inr_nonneg_iff]
  · have hy := hx₀.trans hxy
    rw [Set.mem_Icc, inr_le_iff _ _ hx₀.isSelfAdjoint hy.isSelfAdjoint,
      ← norm_le_one_iff_of_nonneg _, norm_inr]
    exact ⟨hxy, hy₁⟩

variable {A} in
/-- This shows `CStarAlgebra.approximateUnit` is a one-sided approximate unit, but this is marked
`private` because it is only used to prove `CStarAlgebra.increasingApproximateUnit`. -/
private lemma tendsto_mul_right_approximateUnit (m : A) :
    Tendsto (· * m) (approximateUnit A) (𝓝 m) := by
  refine tendsto_mul_right_of_forall_nonneg_tendsto (fun m hm₁ hm₂ ↦ ?_) m
  rw [(hasBasis_approximateUnit A).tendsto_iff nhds_basis_closedBall]
  intro ε hε
  lift ε to ℝ≥0 using hε.le
  rw [coe_pos] at hε
  refine ⟨cfcₙ (fun y : ℝ≥0 ↦ 1 - (1 + y)⁻¹) (ε⁻¹ ^ 2 • m),
    ⟨cfcₙ_nonneg_of_predicate, norm_cfcₙ_one_sub_one_add_inv_lt_one (ε⁻¹ ^ 2 • m)⟩, ?_⟩
  rintro x ⟨(hx₁ : _ ≤ x), hx₂⟩
  simp only [mem_closedBall, dist_eq_norm', zero_sub, norm_neg] at hx₂ ⊢
  rw [← coe_nnnorm, coe_le_coe]
  have hx₀ : 0 ≤ x := cfcₙ_nonneg_of_predicate.trans hx₁
  rw [← inr_le_iff _ _ (.of_nonneg cfcₙ_nonneg_of_predicate) (.of_nonneg hx₀),
    nnreal_cfcₙ_eq_cfc_inr _ _ (by simp [tsub_self]), inr_smul] at hx₁
  rw [← norm_inr (𝕜 := ℂ)] at hm₂ hx₂
  rw [← inr_nonneg_iff] at hx₀ hm₁
  rw [← nnnorm_inr (𝕜 := ℂ), inr_sub, inr_mul]
  generalize (x : A⁺¹) = x, (m : A⁺¹) = m at *
  set g : ℝ≥0 → ℝ≥0 := fun y ↦ 1 - (1 + y)⁻¹
  have hg : Continuous g := by
    rw [continuous_iff_continuousOn_univ]
    fun_prop (disch := intro _ _; positivity)
  have hg' : ContinuousOn (fun y ↦ (1 + ε⁻¹ ^ 2 • y)⁻¹) (spectrum ℝ≥0 m) :=
    ContinuousOn.inv₀ (by fun_prop) fun _ _ ↦ by positivity
  have hx : x ∈ Set.Icc 0 1 := mem_Icc_iff_norm_le_one.mpr ⟨hx₀, hx₂⟩
  have hx' : x ∈ Set.Icc _ 1 := ⟨hx₁, hx.2⟩
  refine nnnorm_sub_mul_self_le m cfc_nonneg_of_predicate hx' ?_
  suffices star m * (1 - cfc g (ε⁻¹ ^ 2 • m)) * m =
      cfc (fun y : ℝ≥0 ↦ y * (1 + ε⁻¹ ^ 2 • y)⁻¹ * y) m by
    rw [this]
    refine nnnorm_cfc_nnreal_le fun y hy ↦ ?_
    field_simp
    calc
      y * ε ^ 2 * y / (ε ^ 2 + y) ≤ ε ^ 2 * 1 := by
        rw [mul_div_assoc]
        gcongr
        · refine mul_le_of_le_one_left (zero_le _) ?_
          have hm' := hm₂.le
          rw [norm_le_one_iff_of_nonneg m hm₁, ← cfc_id' ℝ≥0 m, ← cfc_one (R := ℝ≥0) m,
            cfc_nnreal_le_iff _ _ _ (QuasispectrumRestricts.nnreal_of_nonneg hm₁)] at hm'
          exact hm' y hy
        · exact div_le_one (by positivity) |>.mpr le_add_self
      _ = ε ^ 2 := mul_one _
  rw [cfc_mul _ _ m (continuousOn_id' _ |>.mul hg') (continuousOn_id' _),
    cfc_mul _ _ m (continuousOn_id' _) hg', cfc_id' .., hm₁.star_eq]
  congr
  rw [← cfc_one (R := ℝ≥0) m, ← cfc_comp_smul _ _ _ hg.continuousOn hm₁,
    ← cfc_tsub _ _ m (by simp [g]) hm₁ (by fun_prop) (Continuous.continuousOn <| by fun_prop)]
  refine cfc_congr (fun y _ ↦ ?_)
  simp [g, tsub_tsub_cancel_of_le]

/-- The filter `CStarAlgebra.approximateUnit` generated by the sections
`{x | a ≤ x} ∩ closedBall 0 1` for `0 ≤ a` forms an increasing approximate unit. -/
lemma increasingApproximateUnit :
    IsIncreasingApproximateUnit (approximateUnit A) where
  tendsto_mul_left := by
    rw [tendsto_mul_left_iff_tendsto_mul_right]
    · exact tendsto_mul_right_approximateUnit
    · rw [(hasBasis_approximateUnit A).eventually_iff]
      peel (hasBasis_approximateUnit A).ex_mem with x hx
      exact ⟨hx, fun y hy ↦ (hx.1.trans hy.1).isSelfAdjoint⟩
  tendsto_mul_right := tendsto_mul_right_approximateUnit
  eventually_nonneg := .filter_mono inf_le_left <|
    (isBasis_nonneg_sections A).hasBasis.eventually_iff.mpr ⟨0, by simp⟩
  eventually_norm := .filter_mono inf_le_right <| by simp
  neBot := hasBasis_approximateUnit A |>.neBot_iff.mpr
    fun hx ↦ ⟨_, ⟨le_rfl, by simpa using hx.2.le⟩⟩

end CStarAlgebra

end ApproximateUnit
