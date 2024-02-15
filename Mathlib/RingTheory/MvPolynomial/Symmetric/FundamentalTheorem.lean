/-
Copyright (c) 2023 Junyan Xu. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Junyan Xu
-/
import Mathlib.RingTheory.MvPolynomial.Symmetric.Defs
import Mathlib.RingTheory.MvPolynomial.Tower
import Mathlib.Data.Finsupp.Notation
import Mathlib.Data.Finsupp.WellFounded

/-!
# The Fundamental Theorem of Symmetric Polynomials

In a polynomial ring in `n` variables over a commutative ring, the subalgebra of symmetric
polynomials is freely generated by the first `n` elementary symmetric polynomials (excluding
the 0th, which is simply 1). This is expressed as an isomorphism
`MvPolynomial.equiv_symmetricSubalgebra` between `MvPolynomial (Fin n) R` and
the symmetric subalgebra of any polynomial ring `MvPolynomial σ R` with `#σ = n`.
The forward map is called `MvPolynomial.esymmAlgHom`.

## Proof strategy

We follow the alternative proof on the Wikipedia page
https://en.wikipedia.org/wiki/Elementary_symmetric_polynomial#Alternative_proof
It suffices to show `esymmAlgHom` is both injective and surjective.

Endow the Fintype `σ` with a linear order and endow the (monic) monomials in the polynomial ring
`MvPolynomial σ R` with the lexicographic order on `σ →₀ ℕ`, which is a well order.
Then any nonzero polynomial `p : MvPolynomial σ R` has a largest nonzero monomial
(`AddMonoidAlgebra.supDegree toLex p`) and the corresponding coefficient is
`AddMonoidAlgebra.leadingCoeff toLex p`. If `p` is symmetric, any permutation of a nonzero monomial
in `p` must also be a nonzero monomial in `p`, so the largest nonzero monomial must be antitone
as a function `σ → ℕ` (`MvPolynomial.IsSymmetric.antitone_supDegree`). We can then construct a
monomial in `MvPolynomial (Fin n) R` whose image under `esymmAlgHom` has the same `supDegree` and
`leadingCoeff` as `p`: `MvPolynomial.supDegree_esymmAlgHom_monomial` says that the `supDegree` of
the image is given by `Fin.accumulate`, and `Fin.surjective_accumulate` says that
`Fin.inv_accumulate` is inverse to `Fin.accumulate` for antitone monomials.
If we subtract the image from `p`, we are left with a symmetric polynomial of
lower `supDegree`, which we may assume to be in the image by induction,
thanks to the well-orderedness of `Lex (σ →₀ ℕ)`; the surjectivity of `esymmAlgHom`
follows. For injectivity, just notice that the images of different monic monomials in
`MvPolynomial (Fin n) R` have different `supDegree` (`Fin.injective_accumulate`), so if there is
at least one nonzero monomial, the images cannot all cancel out
(`AddMonoidAlgebra.sum_ne_zero_of_injOn_supDegree`).

We actually only define `Fin.accumulate` in the case `σ := Fin m` rather than an arbitrary Fintype
with a linear order; we show that `esymmAlgHom` is in fact surjective whenever `m ≤ n` and
injective whenever `n ≤ m`, and then transfer the results to any Fintype `σ`. See
`MvPolynomial.injective_esymmAlgHom` and `MvPolynomial.surjective_esymmAlgHom`.

-/

variable {σ τ R : Type*} {n m : ℕ}

open BigOperators Finset

namespace Fin

section accumulate

/-- The `j`th entry of `accumulate n m t` is the sum of `t i` over all `i ≥ j`. -/
@[simps] def accumulate (n m : ℕ) : (Fin n → ℕ) →+ (Fin m → ℕ) where
  toFun t j := ∑ i in univ.filter (fun i : Fin n ↦ (j : ℕ) ≤ i), t i
  map_zero' := funext <| fun j ↦ sum_eq_zero <| fun h _ ↦ rfl
  map_add' t₁ t₂ := funext <| fun j ↦ by dsimp only; exact sum_add_distrib

/-- The `i`th entry of `inv_accumulate n m s` is `s i - s (i+1)`, where `s j = 0` if `j ≥ m`. -/
def inv_accumulate (n m : ℕ) (s : Fin m → ℕ) (i : Fin n) : ℕ :=
  (if hi : i < m then s ⟨i, hi⟩ else 0) - (if hi : i + 1 < m then s ⟨i + 1, hi⟩ else 0)

lemma accumulate_rec {i n m : ℕ} (hin : i < n) (him : i + 1 < m) (t : Fin n → ℕ) :
    accumulate n m t ⟨i, Nat.lt_of_succ_lt him⟩ = t ⟨i, hin⟩ + accumulate n m t ⟨i + 1, him⟩ := by
  simp_rw [accumulate_apply]
  convert (add_sum_erase _ _ _).symm
  · ext; rw [mem_erase]
    simp_rw [mem_filter, mem_univ, true_and, i.succ_le_iff, lt_iff_le_and_ne]
    rw [and_comm, ne_comm, ← Fin.val_ne_iff]
  · exact mem_filter.2 ⟨mem_univ _, le_rfl⟩

lemma accumulate_last {i n m : ℕ} (hin : i < n) (hmi : m = i + 1) (t : Fin n → ℕ)
    (ht : ∀ j : Fin n, m ≤ j → t j = 0) :
    accumulate n m t ⟨i, i.lt_succ_self.trans_eq hmi.symm⟩ = t ⟨i, hin⟩ := by
  rw [accumulate_apply]
  apply sum_eq_single_of_mem
  · rw [mem_filter]; exact ⟨mem_univ _, le_rfl⟩
  refine fun j hij hji ↦ ht j ?_
  simp_rw [mem_filter, mem_univ, true_and] at hij
  exact hmi.trans_le (hij.lt_of_ne (Fin.val_ne_iff.2 hji).symm).nat_succ_le

lemma injective_accumulate {n m} (hnm : n ≤ m) : Function.Injective (accumulate n m) := by
  refine fun t s he ↦ funext fun i ↦ ?_
  obtain h|h := lt_or_le (i.1 + 1) m
  · have := accumulate_rec i.2 h s
    rwa [← he, accumulate_rec i.2 h t, add_right_cancel_iff] at this
  · have := h.antisymm (i.2.nat_succ_le.trans hnm)
    rw [← accumulate_last i.2 this t, ← accumulate_last i.2 this s, he]
    iterate 2 { intro j hj; exact ((j.2.trans_le hnm).not_le hj).elim }

lemma surjective_accumulate {n m} (hmn : m ≤ n) {s : Fin m → ℕ} (hs : Antitone s) :
    accumulate n m (inv_accumulate n m s) = s := funext <| fun ⟨i, hi⟩ ↦ by
  have := Nat.le_pred_of_lt hi
  revert hi
  refine Nat.decreasingInduction' (fun i hi _ ih him ↦ ?_) this fun hm ↦ ?_
  · rw [Nat.lt_pred_iff] at hi
    rw [accumulate_rec (him.trans_le hmn) hi, ih hi, inv_accumulate, dif_pos him, dif_pos hi]
    exact Nat.sub_add_cancel (hs i.le_succ)
  · have := (Nat.succ_pred <| Nat.not_eq_zero_of_lt hm).symm
    rw [accumulate_last (hm.trans_le hmn) this, inv_accumulate, dif_pos hm, dif_neg, Nat.sub_zero]
    · exact this.not_gt
    intro j hj
    rw [inv_accumulate, dif_neg hj.not_lt, Nat.zero_sub]

end accumulate

end Fin

namespace MvPolynomial

open Fin

section CommSemiring

variable (σ R n) [CommSemiring R]

/-- The `R`-algebra homomorphism from $R[x_1,\dots,x_n]$ to the symmetric subalgebra of
  $R[\{x_i \mid i ∈ σ\}]$ sending $x_i$ to the $i$-th elementary symmetric polynomial. -/
noncomputable def esymmAlgHom [Fintype σ] :
    MvPolynomial (Fin n) R →ₐ[R] symmetricSubalgebra σ R :=
  aeval (fun i ↦ ⟨esymm σ R (i + 1), esymm_isSymmetric σ R _⟩)

variable {σ R n}

lemma esymmAlgHom_apply [Fintype σ] (p : MvPolynomial (Fin n) R) :
    (esymmAlgHom σ R n p).val = aeval (fun i : Fin n ↦ esymm σ R (i + 1)) p :=
  (Subalgebra.mvPolynomial_aeval_coe _ _ _).symm

lemma rename_esymmAlgHom [Fintype σ] [Fintype τ] (e : σ ≃ τ) :
    (rename_symmetricSubalgebra e).toAlgHom.comp (esymmAlgHom σ R n) = esymmAlgHom τ R n := by
  refine algHom_ext (fun i ↦ Subtype.ext ?_)
  simp_rw [AlgHom.comp_apply, esymmAlgHom, aeval_X]
  exact rename_esymm σ R _ e

/-- The image of a monomial under `esymmAlgHom`. -/
noncomputable def esymmAlgHom_monomial (σ) [Fintype σ] (t : Fin n →₀ ℕ) (r : R) :
    MvPolynomial σ R := (esymmAlgHom σ R n <| monomial t r).val

variable {m k : ℕ} {i : Fin n} {j : Fin m} {r : R} (hr : r ≠ 0)

lemma isSymmetric_esymmAlgHom_monomial [Fintype σ] (t : Fin n →₀ ℕ) (r : R) :
    (esymmAlgHom_monomial σ t r).IsSymmetric := (esymmAlgHom _ _ _ _).2

lemma esymmAlgHom_monomial_single [Fintype σ] :
    esymmAlgHom_monomial σ (Finsupp.single i k) r = C r * esymm σ R (i + 1) ^ k := by
  rw [esymmAlgHom_monomial, esymmAlgHom_apply, aeval_monomial, algebraMap_eq,
      Finsupp.prod_single_index]; apply pow_zero

lemma esymmAlgHom_monomial_single_one [Fintype σ] :
    esymmAlgHom_monomial σ (Finsupp.single i k) 1 = esymm σ R (i + 1) ^ k := by
  rw [esymmAlgHom_monomial_single]; apply one_mul

lemma esymmAlgHom_monomial_add [Fintype σ] {t s : Fin n →₀ ℕ} :
    esymmAlgHom_monomial σ (t + s) r = esymmAlgHom_monomial σ t r * esymmAlgHom_monomial σ s 1 := by
  simp_rw [esymmAlgHom_monomial, esymmAlgHom_apply, ← map_mul, monomial_mul, mul_one]

lemma esymmAlgHom_zero [Fintype σ] : esymmAlgHom_monomial σ (0 : Fin n →₀ ℕ) r = C r := by
  rw [esymmAlgHom_monomial, monomial_zero', esymmAlgHom_apply, aeval_C]; rfl

open AddMonoidAlgebra
lemma supDegree_monic_esymm [Nontrivial R] {i : ℕ} (him : i < m) :
    supDegree toLex (esymm (Fin m) R (i + 1)) =
      toLex (Finsupp.indicator (Iic ⟨i, him⟩) fun _ _ ↦ 1) ∧
    Monic toLex (esymm (Fin m) R (i + 1)) := by
  have := supDegree_leadingCoeff_sum_eq (D := toLex) (s := univ.powersetCard (i + 1))
    (i := Iic (⟨i, him⟩ : Fin m)) ?_ (f := fun s ↦ monomial (∑ j in s, fun₀ | j => 1) (1 : R)) ?_
  · rwa [← esymm_eq_sum_monomial, ← Finsupp.indicator_eq_sum_single, ← single_eq_monomial,
         supDegree_single_ne_zero _ one_ne_zero, leadingCoeff_single toLex.injective] at this
  · exact mem_powersetCard.2 ⟨subset_univ _, Fin.card_Iic _⟩
  intro t ht hne
  simp_rw [← single_eq_monomial, supDegree_single_ne_zero _ one_ne_zero,
           ← Finsupp.indicator_eq_sum_single]
  rw [Ne, eq_comm, ← subset_iff_eq_of_card_le, not_subset] at hne
  · simp_rw [← mem_sdiff] at hne
    let hkm := mem_sdiff.1 (min'_mem _ hne)
    refine ⟨min' _ hne, fun k hk ↦ ?_, ?_⟩
    all_goals simp only [Pi.toLex_apply, ofLex_toLex, Finsupp.indicator_apply]
    · have hki := mem_Iic.2 (hk.le.trans <| mem_Iic.1 hkm.1)
      rw [dif_pos hki, dif_pos]
      exact not_not.1 (fun h ↦ lt_irrefl k <| ((lt_min'_iff _ _).1 hk) _ <| mem_sdiff.2 ⟨hki, h⟩)
    · rw [dif_neg hkm.2, dif_pos hkm.1]; exact Nat.zero_lt_one
  · rw [(mem_powersetCard.1 ht).2, Fin.card_Iic]

lemma supDegree_esymm [Nontrivial R] (him : i < m) :
    ofLex (supDegree toLex <| esymm (Fin m) R (i + 1)) = accumulate n m (Finsupp.single i 1) := by
  rw [(supDegree_monic_esymm him).1, ofLex_toLex]
  ext j; simp_rw [Finsupp.indicator_apply, mem_Iic, accumulate_apply, Finsupp.single_apply,
    sum_ite_eq, mem_filter, mem_univ, true_and]; rfl

lemma monic_esymm {i : ℕ} (him : i ≤ m) : Monic toLex (esymm (Fin m) R i) := by
  cases' i with i; rw [esymm_zero]; exact monic_one toLex.injective
  cases subsingleton_or_nontrivial R
  · rw [Monic]; apply Subsingleton.elim
  · exact (supDegree_monic_esymm him).2

lemma leadingCoeff_esymmAlgHom_monomial (t : Fin n →₀ ℕ) (hnm : n ≤ m) :
    leadingCoeff toLex (esymmAlgHom_monomial (Fin m) t r) = r := by
  apply t.induction₂
  · rw [esymmAlgHom_zero, leadingCoeff_toLex_C]
  intro i _ _ _ _ ih
  rw [esymmAlgHom_monomial_add, esymmAlgHom_monomial_single_one,
      ((monic_esymm <| i.2.trans_le hnm).pow toLex_add toLex.injective).leadingCoeff_mul, ih]
  exacts [toLex.injective, toLex_add]

lemma supDegree_esymmAlgHom_monomial (t : Fin n →₀ ℕ) (hnm : n ≤ m) :
    ofLex (supDegree toLex <| esymmAlgHom_monomial (Fin m) t r) = accumulate n m t := by
  nontriviality R
  apply t.induction₂
  · simp_rw [esymmAlgHom_zero, supDegree_toLex_C, Finsupp.coe_zero, map_zero]; rfl
  intro i _ _ _ _ ih
  have := i.2.trans_le hnm
  rw [esymmAlgHom_monomial_add, esymmAlgHom_monomial_single_one,
      Monic.supDegree_mul_of_ne_zero toLex.injective toLex_add, ofLex_add, Finsupp.coe_add, ih,
      Finsupp.coe_add, map_add, Monic.supDegree_pow rfl toLex_add toLex.injective, ofLex_smul,
      Finsupp.coe_smul, supDegree_esymm, ← map_nsmul, ← Finsupp.coe_smul, Finsupp.smul_single,
      nsmul_one]; rfl
  · exact this
  · exact monic_esymm this
  · exact (monic_esymm this).pow toLex_add toLex.injective
  · rwa [Ne, ← leadingCoeff_eq_zero toLex.injective, leadingCoeff_esymmAlgHom_monomial _ hnm]

lemma IsSymmetric.antitone_supDegree [LinearOrder σ] {p : MvPolynomial σ R} (hp : p.IsSymmetric) :
    Antitone ↑(ofLex <| p.supDegree toLex) := by
  obtain rfl | h0 := eq_or_ne p 0
  · rw [supDegree_zero]; exact fun _ _ _ ↦ le_rfl
  rw [Antitone]; by_contra! h
  obtain ⟨i, j, hle, hlt⟩ := h
  apply (le_sup (s := p.support) (f := toLex) _).not_lt
  pick_goal 3
  · rw [← hp (Equiv.swap i j), mem_support_iff, coeff_rename_mapDomain]
    · rwa [Ne, ← leadingCoeff_eq_zero toLex.injective, leadingCoeff_eq] at h0
    · apply Equiv.injective
  refine ⟨i, fun k hk ↦ ?_, ?_⟩
  all_goals dsimp only [Pi.toLex_apply, ofLex_toLex]
  · conv_rhs => rw [← Equiv.swap_apply_of_ne_of_ne hk.ne (hk.trans_le hle).ne]
    rw [Finsupp.mapDomain_apply (Equiv.injective _)]; rfl
  · apply hlt.trans_eq
    convert ← (Finsupp.mapDomain_apply (Equiv.injective _) _ _).symm
    exact Equiv.swap_apply_right i j

end CommSemiring

section CommRing

variable (R) [Fintype σ] [CommRing R]

-- shortcut instance necessary to avoid timeout
instance {K} [CommRing K] : AddCommMonoid K := inferInstance

open AddMonoidAlgebra

/- Also holds for a cancellative CommSemiring. -/
lemma injective_esymmAlgHom_fin (h : n ≤ m) :
    Function.Injective (esymmAlgHom (Fin m) R n) := by
  rw [injective_iff_map_eq_zero]
  refine fun p ↦ (fun hp ↦ ?_).mtr
  rw [p.as_sum, map_sum (esymmAlgHom (Fin m) R n), ← Subalgebra.coe_eq_zero,
      AddSubmonoidClass.coe_finset_sum]
  refine sum_ne_zero_of_injOn_supDegree (D := toLex) (support_eq_empty.not.2 hp) (fun t ht ↦ ?_)
    (fun t ht s hs he ↦ DFunLike.ext' <| injective_accumulate h ?_)
  · rw [← esymmAlgHom_monomial, Ne, ← leadingCoeff_eq_zero toLex.injective,
        leadingCoeff_esymmAlgHom_monomial t h]
    rwa [mem_support_iff] at ht
  rw [mem_coe, mem_support_iff] at ht hs
  dsimp only [Function.comp] at he
  rwa [← esymmAlgHom_monomial, ← esymmAlgHom_monomial, ← ofLex_inj, DFunLike.ext'_iff,
       supDegree_esymmAlgHom_monomial ht t h, supDegree_esymmAlgHom_monomial hs s h] at he

lemma injective_esymmAlgHom (hn : n ≤ Fintype.card σ) :
    Function.Injective (esymmAlgHom σ R n) := by
  rw [← rename_esymmAlgHom (Fintype.equivFin σ).symm, AlgHom.coe_comp]
  exact (AlgEquiv.injective _).comp (injective_esymmAlgHom_fin R hn)

lemma bijective_esymmAlgHom_fin (n : ℕ) :
    Function.Bijective (esymmAlgHom (Fin n) R n) := by
  use injective_esymmAlgHom_fin R le_rfl
  rintro ⟨p, hp⟩; rw [← AlgHom.mem_range]
  obtain rfl | h0 := eq_or_ne p 0; apply Subalgebra.zero_mem
  induction' he : p.supDegree toLex using WellFoundedLT.induction with t ih generalizing p; subst he
  let t := Finsupp.equivFunOnFinite.symm (inv_accumulate n n <| ↑(ofLex <| p.supDegree toLex))
  have hd : (esymmAlgHom_monomial _ t <| p.leadingCoeff toLex).supDegree toLex = p.supDegree toLex
  · rw [← ofLex_inj, DFunLike.ext'_iff, supDegree_esymmAlgHom_monomial _ _ le_rfl]
    · exact surjective_accumulate le_rfl hp.antitone_supDegree
    · rwa [Ne, leadingCoeff_eq_zero toLex.injective]
  obtain he | hne := eq_or_ne p (esymmAlgHom_monomial _ t <| p.leadingCoeff toLex)
  · convert AlgHom.mem_range_self _ (monomial t <| p.leadingCoeff toLex); exact he
  have := (supDegree_sub_lt_of_leadingCoeff_eq toLex.injective hd.symm ?_).resolve_right hne
  · specialize ih _ this _ (Subalgebra.sub_mem _ hp <| isSymmetric_esymmAlgHom_monomial _ _) _ rfl
    · rwa [sub_ne_zero]
    convert ← Subalgebra.add_mem _ ih ⟨monomial t (p.leadingCoeff toLex), rfl⟩
    apply sub_add_cancel p
  · rw [leadingCoeff_esymmAlgHom_monomial t le_rfl]

lemma surjective_esymmAlgHom_fin (h : m ≤ n) :
    Function.Surjective (esymmAlgHom (Fin m) R n) := fun p ↦ by
  obtain ⟨q, rfl⟩ := (bijective_esymmAlgHom_fin R m).2 p
  rw [← AlgHom.mem_range]
  apply q.induction_on
  · intro r; rw [← algebraMap_eq, AlgHom.commutes]; apply Subalgebra.algebraMap_mem
  · intro p q hp hq; rw [map_add]; exact Subalgebra.add_mem _ hp hq
  · intro p i hp; rw [map_mul]; apply Subalgebra.mul_mem _ hp
    rw [AlgHom.mem_range]
    refine ⟨X ⟨i, i.2.trans_le h⟩, ?_⟩
    simp_rw [esymmAlgHom, aeval_X]

lemma surjective_esymmAlgHom (hn : Fintype.card σ ≤ n) :
    Function.Surjective (esymmAlgHom σ R n) := by
  rw [← rename_esymmAlgHom (Fintype.equivFin σ).symm, AlgHom.coe_comp]
  exact (AlgEquiv.surjective _).comp (surjective_esymmAlgHom_fin R hn)

/-- If the cardinality of `σ` is `n`, then `esymmAlgHom σ R n` is an isomorphism. -/
noncomputable def equiv_symmetricSubalgebra (hn : Fintype.card σ = n) :
    MvPolynomial (Fin n) R ≃ₐ[R] symmetricSubalgebra σ R :=
  AlgEquiv.ofBijective (esymmAlgHom σ R n)
    ⟨injective_esymmAlgHom R hn.ge, surjective_esymmAlgHom R hn.le⟩

end CommRing

end MvPolynomial
