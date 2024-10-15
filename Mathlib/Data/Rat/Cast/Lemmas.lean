/-
Copyright (c) 2019 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johannes Hölzl, Mario Carneiro
-/
import Mathlib.Algebra.Field.Basic
import Mathlib.Data.Rat.Cast.Defs
import Mathlib.Tactic.Positivity.Basic

/-!
# Some exiled lemmas about casting

These lemmas have been removed from `Mathlib.Data.Rat.Cast.Defs`
to avoiding needing to import `Mathlib.Algebra.Field.Basic` there.

In fact, these lemmas don't appear to be used anywhere in Mathlib,
so perhaps this file can simply be deleted.
-/

namespace Rat

variable {α : Type*} [DivisionRing α]

@[simp, norm_cast]
lemma cast_pow (p : ℚ) (n : ℕ) : ↑(p ^ n) = (p ^ n : α) := by
  rw [cast_def, cast_def, den_pow, num_pow, Nat.cast_pow, Int.cast_pow, div_eq_mul_inv, ← inv_pow,
    ← (Int.cast_commute _ _).mul_pow, ← div_eq_mul_inv]

-- Porting note: rewrote proof
@[simp]
theorem cast_inv_nat (n : ℕ) : ((n⁻¹ : ℚ) : α) = (n : α)⁻¹ := by
  cases' n with n
  · simp
  rw [cast_def, inv_natCast_num, inv_natCast_den, if_neg n.succ_ne_zero,
    Int.sign_eq_one_of_pos (Int.ofNat_succ_pos n), Int.cast_one, one_div]

-- Porting note: proof got a lot easier - is this still the intended statement?
@[simp]
theorem cast_inv_int (n : ℤ) : ((n⁻¹ : ℚ) : α) = (n : α)⁻¹ := by
  cases' n with n n
  · simp [ofInt_eq_cast, cast_inv_nat]
  · simp only [ofInt_eq_cast, Int.cast_negSucc, ← Nat.cast_succ, cast_neg, inv_neg, cast_inv_nat]

@[simp, norm_cast]
theorem cast_nnratCast {K} [DivisionRing K] (q : ℚ≥0) :
    ((q : ℚ) : K) = (q : K) := by
  rw [Rat.cast_def, NNRat.cast_def, NNRat.cast_def]
  have hn := @num_div_eq_of_coprime q.num q.den ?hdp q.coprime_num_den
  on_goal 1 => have hd := @den_div_eq_of_coprime q.num q.den ?hdp q.coprime_num_den
  case hdp => simpa only [Int.ofNat_pos] using q.den_pos
  simp only [Int.cast_natCast, Nat.cast_inj] at hn hd
  rw [hn, hd, Int.cast_natCast]

/-- Casting a scientific literal via `ℚ` is the same as casting directly. -/
@[simp, norm_cast]
theorem cast_ofScientific {K} [DivisionRing K] (m : ℕ) (s : Bool) (e : ℕ) :
    (OfScientific.ofScientific m s e : ℚ) = (OfScientific.ofScientific m s e : K) := by
  rw [← NNRat.cast_ofScientific (K := K), ← NNRat.cast_ofScientific, cast_nnratCast]

end Rat

namespace NNRat

@[simp, norm_cast]
theorem cast_pow {K} [DivisionSemiring K] (q : ℚ≥0) (n : ℕ) :
    NNRat.cast (q ^ n) = (NNRat.cast q : K) ^ n := by
  rw [cast_def, cast_def, den_pow, num_pow, Nat.cast_pow, Nat.cast_pow, div_eq_mul_inv, ← inv_pow,
    ← (Nat.cast_commute _ _).mul_pow, ← div_eq_mul_inv]

theorem cast_zpow_of_ne_zero {K} [DivisionSemiring K] (q : ℚ≥0) (z : ℤ) (hq : (q.num : K) ≠ 0) :
    NNRat.cast (q ^ z) = (NNRat.cast q : K) ^ z := by
  obtain ⟨n, rfl | rfl⟩ := z.eq_nat_or_neg
  · simp
  · simp_rw [zpow_neg, zpow_natCast, ← inv_pow, NNRat.cast_pow]
    congr
    rw [cast_inv_of_ne_zero hq]

namespace NNRat

@[simp, norm_cast]
theorem cast_pow {K} [DivisionSemiring K] (q : ℚ≥0) (n : ℕ) :
    NNRat.cast (q ^ n) = (NNRat.cast q : K) ^ n := by
  rw [cast_def, cast_def, den_pow, num_pow, Nat.cast_pow, Nat.cast_pow, div_eq_mul_inv, ← inv_pow,
    ← (Nat.cast_commute _ _).mul_pow, ← div_eq_mul_inv]

theorem cast_zpow_of_ne_zero {K} [DivisionSemiring K] (q : ℚ≥0) (z : ℤ) (hq : (q.num : K) ≠ 0) :
    NNRat.cast (q ^ z) = (NNRat.cast q : K) ^ z := by
  obtain ⟨n, rfl | rfl⟩ := z.eq_nat_or_neg
  · simp
  · simp_rw [zpow_neg, zpow_natCast, ← inv_pow, NNRat.cast_pow]
    congr
    rw [cast_inv_of_ne_zero hq]

open OfNat in
theorem _root_.ofScientific_def {K} [DivisionSemiring K] (m : ℕ) (s : Bool) (e : ℕ) :
    (OfScientific.ofScientific m s e : K)
      = (ofNat m : ℕ) * (10 : K) ^ (cond s (-(ofNat e)) (ofNat e) : ℤ) := by
  rw [← NNRat.cast_ofScientific, ← NNRat.cast_natCast]
  change NNRat.cast ⟨Rat.ofScientific (ofNat m) s (ofNat e), _⟩ = _
  generalize_proofs h _
  revert h
  generalize hq : Rat.ofScientific (ofNat m) s (ofNat e) = q
  intro hq'
  lift q to ℚ≥0 using hq' with q''
  cases s
  · rw [Rat.ofScientific_false_def] at hq
  by_cases h : (10 : K) = 0
  · obtain rfl | he := eq_or_ne (ofNat e) 0
    · simp only [neg_zero, Bool.cond_self, zpow_zero, mul_one]
      congr
      cases s
      · rw [Rat.ofScientific_false_def, pow_zero, mul_one]
      · rw [Rat.ofScientific_true_def, pow_zero, Rat.mkRat_one, Int.cast_natCast]
    · rw [h]
      congr
      cases s
      · rw [cond_false, zpow_ofNat, zero_pow_eq, if_neg he, mul_zero]
      · rw [Rat.ofScientific_true_def, pow_zero, Rat.mkRat_one, Int.cast_natCast]
        rfl

    simp [h]
  rw [←NNRat.cast_ofNat 10, ← NNRat.cast_zpow_of_ne_zero, ← NNRat.cast_mul_of_ne_zero]
  · congr
    cases s
    · rw [Rat.ofScientific_false_def]
      simp [zpow_ofNat]
      rfl
    · rw [Rat.ofScientific_true_def]
      simp [Rat.mkRat_eq_div, div_eq_mul_inv, zpow_ofNat]
      rfl
  · simp
  · cases s
    · simp [zpow_ofNat, NNRat.den_ofNat]
    · simp [zpow_ofNat, -inv_pow]
      rw [← inv_pow, den_pow, Nat.cast_pow, pow_eq_zero_iff', den_inv_of_ne_zero, num_ofNat]
      simp?
      sorry
  · sorry

open OfScientific in
theorem Nonneg.coe_ofScientific {K} [LinearOrderedField K] (m : ℕ) (s : Bool) (e : ℕ) :
    (ofScientific m s e : {x : K // 0 ≤ x}).val = ofScientific m s e := rfl

end NNRat
