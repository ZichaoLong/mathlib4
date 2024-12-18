/-
Copyright (c) 2023 Xavier Roblot. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Xavier Roblot
-/
import Mathlib.Analysis.SpecialFunctions.PolarCoord
import Mathlib.MeasureTheory.Constructions.Pi
import Mathlib.MeasureTheory.Integral.Prod

/-!
# Integration with respect to a finite product of measures

## Fubini theorem

On a finite product of measure spaces, we show that a product of integrable functions each
depending on a single coordinate is integrable, in `MeasureTheory.integrable_fintype_prod`, and
that its integral is the product of the individual integrals,
in `MeasureTheory.integral_fintype_prod_eq_prod`.

## Polar coordinates change of variables

The polar coordinates change of variables formula for the Lebesgue integral for a function
defined on the product space `ι → ℂ`, see `integral_comp_pi_polarCoord_symm`.

-/

open Fintype MeasureTheory MeasureTheory.Measure

namespace MeasureTheory

section Fubini

variable {𝕜 : Type*} [RCLike 𝕜]

/-- On a finite product space in `n` variables, for a natural number `n`, a product of integrable
functions depending on each coordinate is integrable. -/
theorem Integrable.fin_nat_prod {n : ℕ} {E : Fin n → Type*}
    [∀ i, MeasureSpace (E i)] [∀ i, SigmaFinite (volume : Measure (E i))]
    {f : (i : Fin n) → E i → 𝕜} (hf : ∀ i, Integrable (f i)) :
    Integrable (fun (x : (i : Fin n) → E i) ↦ ∏ i, f i (x i)) := by
  induction n with
  | zero => simp only [Finset.univ_eq_empty, Finset.prod_empty, volume_pi,
      integrable_const_iff, one_ne_zero, pi_empty_univ, ENNReal.one_lt_top, or_true]
  | succ n n_ih =>
      have := ((measurePreserving_piFinSuccAbove (fun i => (volume : Measure (E i))) 0).symm)
      rw [volume_pi, ← this.integrable_comp_emb (MeasurableEquiv.measurableEmbedding _)]
      simp_rw [MeasurableEquiv.piFinSuccAbove_symm_apply, Fin.insertNthEquiv,
        Fin.prod_univ_succ, Fin.insertNth_zero]
      simp only [Fin.zero_succAbove, cast_eq, Function.comp_def, Fin.cons_zero, Fin.cons_succ]
      have : Integrable (fun (x : (j : Fin n) → E (Fin.succ j)) ↦ ∏ j, f (Fin.succ j) (x j)) :=
        n_ih (fun i ↦ hf _)
      exact Integrable.prod_mul (hf 0) this

/-- On a finite product space, a product of integrable functions depending on each coordinate is
integrable. Version with dependent target. -/
theorem Integrable.fintype_prod_dep {ι : Type*} [Fintype ι] {E : ι → Type*}
    {f : (i : ι) → E i → 𝕜} [∀ i, MeasureSpace (E i)] [∀ i, SigmaFinite (volume : Measure (E i))]
    (hf : ∀ i, Integrable (f i)) :
    Integrable (fun (x : (i : ι) → E i) ↦ ∏ i, f i (x i)) := by
  let e := (equivFin ι).symm
  simp_rw [← (volume_measurePreserving_piCongrLeft _ e).integrable_comp_emb
    (MeasurableEquiv.measurableEmbedding _),
    ← e.prod_comp, MeasurableEquiv.coe_piCongrLeft, Function.comp_def,
    Equiv.piCongrLeft_apply_apply]
  exact .fin_nat_prod (fun i ↦ hf _)

/-- On a finite product space, a product of integrable functions depending on each coordinate is
integrable. -/
theorem Integrable.fintype_prod {ι : Type*} [Fintype ι] {E : Type*}
    {f : ι → E → 𝕜} [MeasureSpace E] [SigmaFinite (volume : Measure E)]
    (hf : ∀ i, Integrable (f i)) :
    Integrable (fun (x : ι → E) ↦ ∏ i, f i (x i)) :=
  Integrable.fintype_prod_dep hf

/-- A version of **Fubini's theorem** in `n` variables, for a natural number `n`. -/
theorem integral_fin_nat_prod_eq_prod {n : ℕ} {E : Fin n → Type*}
    [∀ i, MeasureSpace (E i)] [∀ i, SigmaFinite (volume : Measure (E i))]
    (f : (i : Fin n) → E i → 𝕜) :
    ∫ x : (i : Fin n) → E i, ∏ i, f i (x i) = ∏ i, ∫ x, f i x := by
  induction n with
  | zero =>
      simp only [volume_pi, Finset.univ_eq_empty, Finset.prod_empty, integral_const,
        pi_empty_univ, ENNReal.one_toReal, smul_eq_mul, mul_one, pow_zero, one_smul]
  | succ n n_ih =>
      calc
        _ = ∫ x : E 0 × ((i : Fin n) → E (Fin.succ i)),
            f 0 x.1 * ∏ i : Fin n, f (Fin.succ i) (x.2 i) := by
          rw [volume_pi, ← ((measurePreserving_piFinSuccAbove
            (fun i => (volume : Measure (E i))) 0).symm).integral_comp']
          simp_rw [MeasurableEquiv.piFinSuccAbove_symm_apply, Fin.insertNthEquiv,
            Fin.prod_univ_succ, Fin.insertNth_zero, Equiv.coe_fn_mk, Fin.cons_succ, volume_eq_prod,
            volume_pi, Fin.zero_succAbove, cast_eq, Fin.cons_zero]
        _ = (∫ x, f 0 x) * ∏ i : Fin n, ∫ (x : E (Fin.succ i)), f (Fin.succ i) x := by
          rw [← n_ih, ← integral_prod_mul, volume_eq_prod]
        _ = ∏ i, ∫ x, f i x := by rw [Fin.prod_univ_succ]

/-- A version of **Fubini's theorem** with the variables indexed by a general finite type. -/
theorem integral_fintype_prod_eq_prod (ι : Type*) [Fintype ι] {E : ι → Type*}
    (f : (i : ι) → E i → 𝕜) [∀ i, MeasureSpace (E i)] [∀ i, SigmaFinite (volume : Measure (E i))] :
    ∫ x : (i : ι) → E i, ∏ i, f i (x i) = ∏ i, ∫ x, f i x := by
  let e := (equivFin ι).symm
  rw [← (volume_measurePreserving_piCongrLeft _ e).integral_comp']
  simp_rw [← e.prod_comp, MeasurableEquiv.coe_piCongrLeft, Equiv.piCongrLeft_apply_apply,
    MeasureTheory.integral_fin_nat_prod_eq_prod]

theorem integral_fintype_prod_eq_pow {E : Type*} (ι : Type*) [Fintype ι] (f : E → 𝕜)
    [MeasureSpace E] [SigmaFinite (volume : Measure E)] :
    ∫ x : ι → E, ∏ i, f (x i) = (∫ x, f x) ^ (card ι) := by
  rw [integral_fintype_prod_eq_prod, Finset.prod_const, card]

end Fubini

end MeasureTheory

section polarCoord

open ENNReal

variable {ι : Type*} [DecidableEq ι] (f : (ι → ℂ) → ℝ≥0∞)

private theorem Complex.lintegral_comp_pi_polarCoord_symm_aux (hf : Measurable f) (s : Finset ι)
    (a : ι → ℝ × ℝ) :
    (∫⋯∫⁻_s, f ∂fun _ ↦ (volume : Measure ℂ)) (fun i ↦ Complex.polarCoord.symm (a i)) =
      (∫⋯∫⁻_s, fun p ↦
          ((∏ i ∈ s, .ofReal (p i).1) * f (fun i ↦ Complex.polarCoord.symm (p i)))
            ∂fun _ ↦ ((volume : Measure (ℝ × ℝ)).restrict polarCoord.target)) a := by
  induction s using Finset.induction generalizing f a with
  | empty => simp
  | @insert i₀ s hi₀ h_ind =>
      have h : ∀ t : Finset ι, Measurable fun p : ι → ℝ × ℝ ↦
          (∏ i ∈ t, .ofReal (p i).1) * f fun i ↦ Complex.polarCoord.symm (p i) := by
        intro _
        refine Measurable.mul ?_ ?_
        · exact Finset.measurable_prod _ (fun _ _ ↦ by fun_prop)
        · exact hf.comp <| measurable_pi_lambda _ fun _ ↦
            Complex.continuous_polarCoord_symm.measurable.comp (measurable_pi_apply _)
      calc
        _ = ∫⁻ x in polarCoord.target, ENNReal.ofReal x.1 •
              (∫⋯∫⁻_s, f ∂fun _ ↦ volume)
                fun j ↦ Complex.polarCoord.symm (Function.update a i₀ x j) := ?_
        _ = ∫⁻ (x : ℝ × ℝ) in polarCoord.target,
              (∫⋯∫⁻_s,
                (fun p ↦ ↑(∏ i ∈ insert i₀ s, .ofReal (p i).1) *
                  (f fun i ↦ Complex.polarCoord.symm (p i))) ∘ fun p ↦ Function.update p i₀ x
              ∂fun _ ↦ volume.restrict polarCoord.target) a := ?_
        _ = (∫⋯∫⁻_insert i₀ s, fun p ↦ (∏ i ∈ insert i₀ s, .ofReal (p i).1) *
              f (fun i ↦ Complex.polarCoord.symm (p i))
                ∂fun _ ↦ volume.restrict polarCoord.target) a := ?_
      · simp_rw [lmarginal_insert _ hf hi₀, ← Complex.lintegral_comp_polarCoord_symm,
          Function.apply_update (f := fun _ ↦ Complex.polarCoord.symm)]
      · simp_rw [h_ind _ hf, lmarginal_update_of_not_mem (h s) hi₀, Function.comp_def,
          Finset.prod_insert hi₀, Function.update_same, smul_eq_mul, mul_assoc,
          ← lmarginal_const_smul' _ ofReal_ne_top, Pi.smul_def, smul_eq_mul]
      · simp_rw [← lmarginal_update_of_not_mem (h _) hi₀, lmarginal_insert _ (h _) hi₀]

theorem Complex.lintegral_comp_pi_polarCoord_symm [Fintype ι] (hf : Measurable f) :
    ∫⁻ p in (Set.univ.pi fun _ : ι ↦ polarCoord.target),
      (∏ i, .ofReal (p i).1) * f (fun i ↦ Complex.polarCoord.symm (p i)) = ∫⁻ p, f p := by
  rw [volume_pi, volume_pi, lintegral_eq_lmarginal_univ (fun _ ↦ Complex.polarCoord.symm 0),
    Complex.lintegral_comp_pi_polarCoord_symm_aux _ hf, lmarginal_univ, ← restrict_pi_pi]

end polarCoord
