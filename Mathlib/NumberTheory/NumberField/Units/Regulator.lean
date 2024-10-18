/-
Copyright (c) 2024 Xavier Roblot. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Xavier Roblot
-/
import Mathlib.Algebra.Module.ZLattice.Covolume
import Mathlib.LinearAlgebra.Matrix.Determinant.Misc
import Mathlib.NumberTheory.NumberField.Units.DirichletTheorem

/-!
# Regulator of a number field

We define and prove basic results about the regulator of a number field `K`.

## Main definitions and results

* `NumberField.Units.regulator`: the regulator of the number field `K`.

* `Number.Field.Units.regulator_eq_det`: For any infinite place `w'`, the regulator is equal to
the absolute value of the determinant of the matrix `(mult w * log w (fundSystem K i)))_i, w`
where `w` runs through the infinite places distinct from `w'`.

## Tags
number field, units, regulator
 -/

open scoped NumberField

noncomputable section

namespace NumberField.Units

variable (K : Type*) [Field K]

open MeasureTheory Classical BigOperators NumberField.InfinitePlace
  NumberField NumberField.Units.dirichletUnitTheorem

variable [NumberField K]

/-- The regulator of a number field `K`. -/
def regulator : ℝ := ZLattice.covolume (unitLattice K)

theorem regulator_ne_zero : regulator K ≠ 0 := ZLattice.covolume_ne_zero (unitLattice K) volume

theorem regulator_pos : 0 < regulator K := ZLattice.covolume_pos (unitLattice K) volume

#adaptation_note
/--
After https://github.com/leanprover/lean4/pull/4119
the `Module ℤ (Additive ((𝓞 K)ˣ ⧸ NumberField.Units.torsion K))` instance required below isn't found
unless we use `set_option maxSynthPendingDepth 2`, or add
explicit instances:
```
local instance : CommGroup (𝓞 K)ˣ := inferInstance
```
-/
set_option maxSynthPendingDepth 2 -- Note this is active for the remainder of the file.

theorem regulator_eq_det' (e : {w : InfinitePlace K // w ≠ w₀} ≃ Fin (rank K)) :
    regulator K = |(Matrix.of fun i ↦
      logEmbedding K (Additive.ofMul (fundSystem K (e i)))).det| := by
  simp_rw [regulator, ZLattice.covolume_eq_det _
    (((basisModTorsion K).map (logEmbeddingEquiv K)).reindex e.symm), Basis.coe_reindex,
    Function.comp_def, Basis.map_apply, ← fundSystem_mk, Equiv.symm_symm, logEmbeddingEquiv_apply]

/-- Let `u : Fin (rank K) → (𝓞 K)ˣ` be a family of units and let `w₁` and `w₂` be two infinite
places. Then, the two square matrices with entries `(mult w * log w (u i))_i, {w ≠ w_i}`, `i = 1,2`,
have the same determinant in absolute value. -/
theorem abs_det_eq_abs_det (u : Fin (rank K) → (𝓞 K)ˣ)
    {w₁ w₂ : InfinitePlace K} (e₁ : {w // w ≠ w₁} ≃ Fin (rank K))
    (e₂ : {w // w ≠ w₂} ≃ Fin (rank K)) :
    |(Matrix.of fun i w : {w // w ≠ w₁} ↦ (mult w.val : ℝ) * (w.val (u (e₁ i) : K)).log).det| =
    |(Matrix.of fun i w : {w // w ≠ w₂} ↦ (mult w.val : ℝ) * (w.val (u (e₂ i) : K)).log).det| := by
  -- We construct an equiv `Fin (rank K + 1) ≃ InfinitePlace K` from `e₂.symm`
  let f : Fin (rank K + 1) ≃ InfinitePlace K :=
    (finSuccEquiv _).trans ((Equiv.optionSubtype _).symm e₁.symm).val
  -- And `g` corresponds to the restriction of `f⁻¹` to `{w // w ≠ w₂}`
  let g : {w // w ≠ w₂} ≃ Fin (rank K) :=
    (Equiv.subtypeEquiv f.symm (fun _ ↦ by simp [f])).trans
      (finSuccAboveEquiv (f.symm w₂)).symm
  have h_col := congr_arg abs <| Matrix.det_permute (g.trans e₂.symm)
    (Matrix.of fun i w : {w // w ≠ w₂} ↦ (mult w.val : ℝ) * (w.val (u (e₂ i) : K)).log)
  rw [abs_mul, ← Int.cast_abs, Equiv.Perm.sign_abs, Int.cast_one, one_mul] at h_col
  rw [← h_col]
  have h := congr_arg abs <| Matrix.submatrix_succAbove_det_eq_negOnePow_submatrix_succAbove_det'
    (Matrix.of fun i w ↦ (mult (f w) : ℝ) * ((f w) (u i)).log) ?_ 0 (f.symm w₂)
  · rw [← Matrix.det_reindex_self e₁, ← Matrix.det_reindex_self g]
    · rw [Units.smul_def, abs_zsmul, Int.abs_negOnePow, one_smul] at h
      convert h
      · ext; simp only [ne_eq, Matrix.reindex_apply, Matrix.submatrix_apply, Matrix.of_apply,
          Equiv.apply_symm_apply, Equiv.trans_apply, Fin.succAbove_zero, id_eq, finSuccEquiv_succ,
          Equiv.optionSubtype_symm_apply_apply_coe, f]
      · ext; simp only [ne_eq, Equiv.coe_trans, Matrix.reindex_apply, Matrix.submatrix_apply,
          Function.comp_apply, Equiv.apply_symm_apply, id_eq, Matrix.of_apply]; rfl
  · intro _
    simp_rw [Matrix.of_apply, ← Real.log_pow]
    rw [← Real.log_prod, Equiv.prod_comp f (fun w ↦ (w (u _) ^ (mult w))), prod_eq_abs_norm,
      Units.norm, Rat.cast_one, Real.log_one]
    exact fun _ _ ↦ pow_ne_zero _ <| (map_ne_zero _).mpr (coe_ne_zero _)

/-- For any infinite place `w'`, the regulator is equal to the absolute value of the determinant
of the matrix `(mult w * log w (fundSystem K i)))_i, {w ≠ w'}`. -/
theorem regulator_eq_det (w' : InfinitePlace K) (e : {w // w ≠ w'} ≃ Fin (rank K)) :
    regulator K =
      |(Matrix.of fun i w : {w // w ≠ w'} ↦ (mult w.val : ℝ) *
        Real.log (w.val (fundSystem K (e i) : K))).det| := by
  let e' : {w : InfinitePlace K // w ≠ w₀} ≃ Fin (rank K) := Fintype.equivOfCardEq (by
    rw [Fintype.card_subtype_compl, Fintype.card_ofSubsingleton, Fintype.card_fin, rank])
  simp_rw [regulator_eq_det' K e', logEmbedding, AddMonoidHom.coe_mk, ZeroHom.coe_mk]
  exact abs_det_eq_abs_det K (fun i ↦ fundSystem K i) e' e

open Module in
theorem finrank_mul_regulator_eq_det (w' : InfinitePlace K) (e : {w // w ≠ w'} ≃ Fin (rank K)) :
    finrank ℚ K * regulator K =
      |(Matrix.of (fun i w : InfinitePlace K ↦
        if h : i = w' then (w.mult : ℝ) else w.mult * (w (fundSystem K (e ⟨i, h⟩))).log)).det| := by
  rw [show |Matrix.det _| = |(1 : ℝ) • Matrix.det _| by rw [one_smul],
    ← Matrix.det_updateColumn_sum _ w' (fun _ ↦ 1)]
  let M := Matrix.of fun i w : InfinitePlace K ↦ if w = w' then
      (if i = w' then (finrank ℚ K : ℝ) else 0) else
      (if h : i = w' then w.mult else w.mult * (w (fundSystem K (e ⟨i, h⟩))).log)
  have : |M.det| = finrank ℚ K * regulator K := by
    simp only [M]
    let e' : Fin (rank K + 1) ≃ InfinitePlace K :=
      (finSuccEquiv _).trans ((Equiv.optionSubtype _).symm e.symm).val
    have h₁ : ∀ j, e' ((e'.symm w').succAbove j) = e.symm j := by
      intro _
      have : e'.symm w' = 0 := by
        rw [Equiv.symm_apply_eq, Equiv.trans_apply, finSuccEquiv_zero,
          Equiv.optionSubtype_symm_apply_apply_none]
      rw [this]
      simp [ne_eq, Fin.zero_succAbove, Equiv.trans_apply, finSuccEquiv_succ,
        Equiv.optionSubtype_symm_apply_apply_coe, e']
    have h₂ : ∀ j, e' ((e'.symm w').succAbove j) ≠ w' := by
      intro _
      rw [ne_eq, Equiv.apply_eq_iff_eq_symm_apply]
      exact Fin.succAbove_ne (e'.symm w') _
    rw [← Matrix.det_reindex_self e'.symm, Matrix.det_succ_column _ (e'.symm w')]
    simp [Function.comp_def]
    simp_rw [Equiv.apply_eq_iff_eq_symm_apply]
    rw [Fintype.sum_ite_eq', abs_mul, abs_mul, Nat.abs_cast, abs_pow, abs_neg, abs_one, one_pow,
      one_mul, regulator_eq_det K w' e, ← Matrix.det_reindex_self e]
    rw [Matrix.reindex_apply]
    congr
    ext
    simp_rw [Matrix.submatrix_apply, Matrix.of_apply]
    simp_rw [Equiv.apply_symm_apply]
    simp_rw [if_neg (h₂ _), dif_neg (h₂ _), h₁]
    simp only [Subtype.coe_eta, Equiv.apply_symm_apply]
  rw [← this]
  congr
  ext
  have : ∀ (w : InfinitePlace K) i, w ((algebraMap (𝓞 K) K) (fundSystem K (e i))) ^ w.mult ≠ 0 := by
    intro _ _
    refine pow_ne_zero _ ((map_ne_zero _).mpr (coe_ne_zero _))
  simp_rw [M, Matrix.of_apply, smul_eq_mul, one_mul, Finset.sum_dite_irrel,
    Matrix.updateColumn_apply, ← Real.log_pow, ← Real.log_prod _ _ (fun _ _ ↦ this _ _),
    prod_eq_abs_norm,
    Units.norm, Rat.cast_one, Real.log_one, ← Nat.cast_sum, sum_mult_eq, dite_eq_ite,
    Matrix.of_apply]

end Units

end NumberField
