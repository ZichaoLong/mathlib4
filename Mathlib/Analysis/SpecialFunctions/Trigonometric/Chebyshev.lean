/-
Copyright (c) 2020 Johan Commelin. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johan Commelin
-/
import Mathlib.Data.Complex.Exponential
import Mathlib.Data.Complex.Module
import Mathlib.RingTheory.Polynomial.Chebyshev

/-!
# Multiple angle formulas in terms of Chebyshev polynomials

This file gives the trigonometric characterizations of Chebyshev polynomials, for both the real
(`Real.cos`) and complex (`Complex.cos`) cosine.
-/


namespace Polynomial.Chebyshev

open Polynomial

variable {R A : Type*} [CommRing R] [CommRing A] [Algebra R A]

-- Porting note: added type ascriptions to the statement
@[simp, norm_cast]
theorem complex_ofReal_eval_T : ∀ (x : ℝ) n, (((T ℝ n).eval x : ℝ) : ℂ) = (T ℂ n).eval (x : ℂ) :=
  @algebraMap_eval_T ℝ ℂ _ _ _

-- Porting note: added type ascriptions to the statement
@[simp, norm_cast]
theorem complex_ofReal_eval_U : ∀ (x : ℝ) n, (((U ℝ n).eval x : ℝ) : ℂ) = (U ℂ n).eval (x : ℂ) :=
  @algebraMap_eval_U ℝ ℂ _ _ _

@[simp, norm_cast]
theorem complex_ofReal_eval_C : ∀ (x : ℝ) n, (((C ℝ n).eval x : ℝ) : ℂ) = (C ℂ n).eval (x : ℂ) :=
  @algebraMap_eval_C ℝ ℂ _ _ _

@[simp, norm_cast]
theorem complex_ofReal_eval_S : ∀ (x : ℝ) n, (((S ℝ n).eval x : ℝ) : ℂ) = (S ℂ n).eval (x : ℂ) :=
  @algebraMap_eval_S ℝ ℂ _ _ _

/-! ### Complex versions -/

section Complex

open Complex

variable (θ : ℂ)

/-- The `n`-th Chebyshev polynomial of the first kind evaluates on `cos θ` to the
value `cos (n * θ)`. -/
@[simp]
theorem T_complex_cos (n : ℤ) : (T ℂ n).eval (cos θ) = cos (n * θ) := by
  induction n using Polynomial.Chebyshev.induct with
  | zero => simp
  | one => simp
  | add_two n ih1 ih2 =>
    simp only [T_add_two, eval_sub, eval_mul, eval_X, eval_ofNat, ih1, ih2, sub_eq_iff_eq_add,
      cos_add_cos]
    push_cast
    ring_nf
  | neg_add_one n ih1 ih2 =>
    simp only [T_sub_one, eval_sub, eval_mul, eval_X, eval_ofNat, ih1, ih2, sub_eq_iff_eq_add',
      cos_add_cos]
    push_cast
    ring_nf

/-- The `n`-th Chebyshev polynomial of the second kind evaluates on `cos θ` to the
value `sin ((n + 1) * θ) / sin θ`. -/
@[simp]
theorem U_complex_cos (n : ℤ) : (U ℂ n).eval (cos θ) * sin θ = sin ((n + 1) * θ) := by
  induction n using Polynomial.Chebyshev.induct with
  | zero => simp
  | one => simp [one_add_one_eq_two, sin_two_mul]; ring
  | add_two n ih1 ih2 =>
    simp only [U_add_two, add_sub_cancel_right, eval_sub, eval_mul, eval_X, eval_ofNat, sub_mul,
      mul_assoc, ih1, ih2, sub_eq_iff_eq_add, sin_add_sin]
    push_cast
    ring_nf
  | neg_add_one n ih1 ih2 =>
    simp only [U_sub_one, add_sub_cancel_right, eval_sub, eval_mul, eval_X, eval_ofNat, sub_mul,
      mul_assoc, ih1, ih2, sub_eq_iff_eq_add', sin_add_sin]
    push_cast
    ring_nf

/-- The `n`-th rescaled Chebyshev polynomial of the first kind (Vieta–Lucas polynomial) evaluates on
`2 * cos θ` to the value `2 * cos (n * θ)`. -/
@[simp]
theorem C_two_mul_complex_cos (n : ℤ) : (C ℂ n).eval (2 * cos θ) = 2 * cos (n * θ) := by
  simp [C_eq_two_mul_T_comp_half_mul_X]

/-- The `n`-th rescaled Chebyshev polynomial of the second kind (Vieta–Fibonacci polynomial)
evaluates on `2 * cos θ` to the value `sin ((n + 1) * θ) / sin θ`. -/
@[simp]
theorem S_two_mul_complex_cos (n : ℤ) : (S ℂ n).eval (2 * cos θ) * sin θ = sin ((n + 1) * θ) := by
  simp [S_eq_U_comp_half_mul_X]

end Complex

/-! ### Real versions -/

section Real

open Real

variable (θ : ℝ) (n : ℤ)

/-- The `n`-th Chebyshev polynomial of the first kind evaluates on `cos θ` to the
value `cos (n * θ)`. -/
@[simp]
theorem T_real_cos : (T ℝ n).eval (cos θ) = cos (n * θ) := mod_cast T_complex_cos θ n

/-- The `n`-th Chebyshev polynomial of the second kind evaluates on `cos θ` to the
value `sin ((n + 1) * θ) / sin θ`. -/
@[simp]
theorem U_real_cos : (U ℝ n).eval (cos θ) * sin θ = sin ((n + 1) * θ) :=
  mod_cast U_complex_cos θ n

/-- The `n`-th rescaled Chebyshev polynomial of the first kind (Vieta–Lucas polynomial) evaluates on
`2 * cos θ` to the value `2 * cos (n * θ)`. -/
@[simp]
theorem C_two_mul_real_cos : (C ℝ n).eval (2 * cos θ) = 2 * cos (n * θ) :=
  mod_cast C_two_mul_complex_cos θ n

/-- The `n`-th rescaled Chebyshev polynomial of the second kind (Vieta–Fibonacci polynomial)
evaluates on `2 * cos θ` to the value `sin ((n + 1) * θ) / sin θ`. -/
@[simp]
theorem S_two_mul_real_cos : (S ℝ n).eval (2 * cos θ) * sin θ = sin ((n + 1) * θ) :=
  mod_cast S_two_mul_complex_cos θ n

end Real

end Polynomial.Chebyshev
