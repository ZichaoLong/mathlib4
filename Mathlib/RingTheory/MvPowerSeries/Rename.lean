/-
Copyright (c) 2017 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johannes Hölzl, Johan Commelin, Mario Carneiro
-/
import Mathlib.Algebra.Algebra.Hom
import Mathlib.RingTheory.MvPowerSeries.Basic

/-!
# Renaming variables of polynomials

This file establishes the `rename` operation on multivariate polynomials,
which modifies the set of variables.

## Main declarations

* `MvPowerSeries.rename`

## Notation

As in other polynomial files, we typically use the notation:

+ `σ τ α : Type*` (indexing the variables)

+ `R S : Type*` `[CommSemiring R]` `[CommSemiring S]` (the coefficients)

+ `s : σ →₀ ℕ`, a function from `σ` to `ℕ` which is zero away from a finite set.
This will give rise to a monomial in `MvPowerSeries σ R` which mathematicians might call `X^s`

+ `r : R` elements of the coefficient ring

+ `i : σ`, with corresponding monomial `X i`, often denoted `X_i` by mathematicians

+ `p : MvPowerSeries σ α`

  -/


noncomputable section

open BigOperators

open Set Function Finsupp AddMonoidAlgebra

open BigOperators

variable {σ τ υ R S : Type*} [CommSemiring R] [CommSemiring S]

namespace MvPowerSeries

section Rename

variable [DecidableEq σ] [DecidableEq τ] [DecidableEq υ]

lemma coeff_equiv (φ : MvPowerSeries σ R) (n : τ →₀ ℕ) (e : σ ≃ τ) :
  (coeff R n) (φ ∘ Finsupp.mapDomain e.symm) = (coeff R (Finsupp.mapDomain (e.symm) n)) φ := rfl

lemma coeff_equiv' (φ : MvPowerSeries σ R) (n : τ →₀ ℕ) (e : σ ≃ τ) :
  (coeff R n) (φ ∘ Finsupp.equivMapDomain e.symm) = (coeff R (Finsupp.equivMapDomain (e.symm) n)) φ := rfl

/-- Rename all the variables in a multivariable power series. -/
-- def rename' (e : σ ≃ τ) : MvPowerSeries σ R ≃ₐ[R] MvPowerSeries τ R where
--   toFun := fun φ ↦ φ ∘ (Finsupp.equivMapDomain e.symm)
--   invFun := fun φ ↦ φ ∘ (Finsupp.equivMapDomain e)
--   left_inv := by
--     intro x; funext s
--     simp only [comp_apply]
--     congr

--   right_inv := by
--     intro x; funext s
--     simp only [comp_apply, ← mapDomain_comp, Equiv.self_comp_symm, mapDomain_id]
--   map_mul' := by
--     intro x y; ext t; dsimp
--     rw [← apply_eq_coeff, comp_apply, apply_eq_coeff _ (x * y) (Finsupp.mapDomain e.symm t),
--       coeff_mul, coeff_mul, Finset.sum_equiv]
--     · use fun (a, b) ↦ ((Finsupp.mapDomain e) a, (Finsupp.mapDomain e) b)
--       · use fun (a, b) ↦ ((Finsupp.mapDomain e.symm) a, (Finsupp.mapDomain e.symm) b)
--       · intro (a, b)
--         simp only [Prod.mk.injEq]
--         constructor <;> simp only [comp_apply, mapDomain.addMonoidHom_apply, ← mapDomain_comp,
--           Equiv.symm_comp_self, mapDomain_id]
--       · intro (a, b)
--         simp only [Prod.mk.injEq]
--         constructor <;> simp only [comp_apply, mapDomain.addMonoidHom_apply, ← mapDomain_comp,
--           Equiv.self_comp_symm, mapDomain_id]
--     · simp only [Finset.mem_antidiagonal, Equiv.coe_fn_mk, Prod.forall]
--       intro a b
--       constructor
--       · intro h
--         rw [← mapDomain_add, h]
--         simp only [← mapDomain_comp, Equiv.self_comp_symm, mapDomain_id]
--       · intro h
--         rw [← mapDomain_add] at h
--         rw [← h]
--         simp only [← mapDomain_comp, Equiv.symm_comp_self, mapDomain_id]
--     · simp only [Finset.mem_antidiagonal, Equiv.coe_fn_mk, Prod.forall]
--       intro a b _
--       simp only [← apply_eq_coeff, comp_apply, ← mapDomain_comp, Equiv.symm_comp_self, mapDomain_id]
--   map_add' := by
--     intro x y; ext s
--     simp only [map_add]
--     congr
--   commutes' := by
--     intro r; ext t
--     simp only [algebraMap_apply, Algebra.id.map_eq_id, RingHom.id_apply, coeff_equiv, coeff_C,
--       mapDomain_equiv_eq_zero_iff]

/-- Rename all the variables in a multivariable power series. -/
def rename (e : σ ≃ τ) : MvPowerSeries σ R ≃ₐ[R] MvPowerSeries τ R where
  toFun := fun φ ↦ φ ∘ (Finsupp.mapDomain e.symm)
  invFun := fun φ ↦ φ ∘ (Finsupp.mapDomain e)
  left_inv := by
    intro x; funext s
    simp only [comp_apply, ← mapDomain_comp, Equiv.symm_comp_self, mapDomain_id]
  right_inv := by
    intro x; funext s
    simp only [comp_apply, ← mapDomain_comp, Equiv.self_comp_symm, mapDomain_id]
  map_mul' := by
    intro x y; ext t; dsimp
    rw [← apply_eq_coeff, comp_apply, apply_eq_coeff _ (x * y) (Finsupp.mapDomain e.symm t),
      coeff_mul, coeff_mul, Finset.sum_equiv]
    · use fun (a, b) ↦ ((Finsupp.mapDomain e) a, (Finsupp.mapDomain e) b)
      · use fun (a, b) ↦ ((Finsupp.mapDomain e.symm) a, (Finsupp.mapDomain e.symm) b)
      · intro (a, b)
        simp only [Prod.mk.injEq]
        constructor <;> simp only [comp_apply, mapDomain.addMonoidHom_apply, ← mapDomain_comp,
          Equiv.symm_comp_self, mapDomain_id]
      · intro (a, b)
        simp only [Prod.mk.injEq]
        constructor <;> simp only [comp_apply, mapDomain.addMonoidHom_apply, ← mapDomain_comp,
          Equiv.self_comp_symm, mapDomain_id]
    · simp only [Finset.mem_antidiagonal, Equiv.coe_fn_mk, Prod.forall]
      intro a b
      constructor
      · intro h
        rw [← mapDomain_add, h]
        simp only [← mapDomain_comp, Equiv.self_comp_symm, mapDomain_id]
      · intro h
        rw [← mapDomain_add] at h
        rw [← h]
        simp only [← mapDomain_comp, Equiv.symm_comp_self, mapDomain_id]
    · simp only [Finset.mem_antidiagonal, Equiv.coe_fn_mk, Prod.forall]
      intro a b _
      simp only [← apply_eq_coeff, comp_apply, ← mapDomain_comp, Equiv.symm_comp_self, mapDomain_id]
  map_add' := by
    intro x y; ext s
    simp only [map_add]
    congr
  commutes' := by
    intro r; ext t
    simp only [algebraMap_apply, Algebra.id.map_eq_id, RingHom.id_apply, coeff_equiv, coeff_C,
      mapDomain_equiv_eq_zero_iff]

lemma rename_zero (e : σ ≃ τ) : rename e (0 : MvPowerSeries σ R) = 0 := by
  simp only [rename, map_zero, Equiv.coe_fn_mk, Pi.zero_comp, map_zero]

@[simp]
theorem rename_C (e : σ ≃ τ) (r : R) : rename e (C σ R r) = C τ R r := by
  simp only [rename, Equiv.coe_fn_mk]
  funext t
  have : coeff R (Finsupp.mapDomain (⇑e.symm) t) (C σ R r) = (if t = 0 then r else 0) := by
    simp only [mapDomain_equiv_eq_zero_iff, coeff_C]
  show coeff R (Finsupp.mapDomain (⇑e.symm) t) ((C σ R) r) = coeff R t ((C τ R) r)
  simp only [this, coeff_C]

@[simp]
theorem rename_X (e : σ ≃ τ) (i : σ) : rename e (X i : MvPowerSeries σ R) = X (e i) := by
  simp only [rename, Equiv.coe_fn_mk]
  funext t
  have : coeff R (Finsupp.mapDomain (⇑e.symm) t) (X i) =
      (if t = Finsupp.single (e i) 1 then 1 else 0) := by
    have : Finsupp.mapDomain (⇑e.symm) t = Finsupp.single i 1 ↔ t = Finsupp.single (e i) 1 := by
      constructor <;> intro h
      · ext j
        have : t j = Finsupp.mapDomain (e.symm) t (e.symm j) := by
          simp only [mapDomain_equiv_apply, Equiv.symm_symm, Equiv.apply_symm_apply]
        simp only [this, h]
        rw [Finsupp.single_apply, Finsupp.single_apply]
        simp_rw [Equiv.eq_symm_apply e]
      · simp only [h, Finsupp.mapDomain_single, Equiv.symm_apply_apply]
    simp only [this, coeff_X]
  show coeff R (Finsupp.mapDomain (⇑e.symm) t) (X i) = coeff R t (X (e i))
  simp only [this, coeff_X]

theorem map_rename (f : R →+* S) (e : σ ≃ τ) (p : MvPowerSeries σ R) :
    map τ f (rename e p) = rename e (map σ f p) := by
  simp only [map, rename, AlgEquiv.coe_mk, RingHom.coe_mk, MonoidHom.coe_mk, OneHom.coe_mk]
  rfl

@[simp]
theorem rename_rename (e : σ ≃ τ) (f : τ ≃ υ) (p : MvPowerSeries σ R) :
    rename f (rename e p) = rename (Equiv.trans e f) p := by
  funext u
  simp only [rename, AlgEquiv.coe_mk, comp_apply, mapDomain.addMonoidHom_apply, Equiv.coe_trans]
  rw [← mapDomain_comp]
  congr

@[simp]
theorem rename_id (p : MvPowerSeries σ R) : rename (Equiv.refl σ) p = p := by
  funext s
  simp only [rename, Equiv.refl_symm, Equiv.coe_refl, AlgEquiv.coe_mk, comp_apply, mapDomain_id]

-- theorem rename_monomial (f : σ → τ) (d : σ →₀ ℕ) (r : R) :
--     rename f (monomial d r) = monomial (d.mapDomain f) r := by
--   rw [rename, aeval_monomial, monomial_eq (s := Finsupp.mapDomain f d),
--     Finsupp.prod_mapDomain_index]
--   · rfl
--   · exact fun n => pow_zero _
--   · exact fun n i₁ i₂ => pow_add _ _ _
-- #align mv_polynomial.rename_monomial MvPowerSeries.rename_monomial

-- theorem rename_eq (f : σ → τ) (p : MvPowerSeries σ R) :
--     rename f p = Finsupp.mapDomain (Finsupp.mapDomain f) p := by
--   simp only [rename, aeval_def, eval₂, Finsupp.mapDomain, algebraMap_eq, comp_apply,
--     X_pow_eq_monomial, ← monomial_finsupp_sum_index]
--   rfl
-- #align mv_polynomial.rename_eq MvPowerSeries.rename_eq

-- theorem rename_injective (f : σ → τ) (hf : Function.Injective f) :
--     Function.Injective (rename f : MvPowerSeries σ R → MvPowerSeries τ R) := by
--   have :
--     (rename f : MvPowerSeries σ R → MvPowerSeries τ R) = Finsupp.mapDomain (Finsupp.mapDomain f) :=
--     funext (rename_eq f)
--   rw [this]
--   exact Finsupp.mapDomain_injective (Finsupp.mapDomain_injective hf)
-- #align mv_polynomial.rename_injective MvPowerSeries.rename_injective

-- section

-- variable {f : σ → τ} (hf : Function.Injective f)

-- open scoped Classical

-- /-- Given a function between sets of variables `f : σ → τ` that is injective with proof `hf`,
--   `MvPowerSeries.killCompl hf` is the `AlgHom` from `R[τ]` to `R[σ]` that is left inverse to
--   `rename f : R[σ] → R[τ]` and sends the variables in the complement of the range of `f` to `0`. -/
-- def killCompl : MvPowerSeries τ R →ₐ[R] MvPowerSeries σ R :=
--   aeval fun i => if h : i ∈ Set.range f then X <| (Equiv.ofInjective f hf).symm ⟨i, h⟩ else 0
-- #align mv_polynomial.kill_compl MvPowerSeries.killCompl

-- theorem killCompl_C (r : R) : killCompl hf (C r) = C r := algHom_C _ _

-- theorem killCompl_comp_rename : (killCompl hf).comp (rename f) = AlgHom.id R _ :=
--   algHom_ext fun i => by
--     dsimp
--     rw [rename, killCompl, aeval_X, comp_apply, aeval_X, dif_pos, Equiv.ofInjective_symm_apply]
-- #align mv_polynomial.kill_compl_comp_rename MvPowerSeries.killCompl_comp_rename

-- @[simp]
-- theorem killCompl_rename_app (p : MvPowerSeries σ R) : killCompl hf (rename f p) = p :=
--   AlgHom.congr_fun (killCompl_comp_rename hf) p
-- #align mv_polynomial.kill_compl_rename_app MvPowerSeries.killCompl_rename_app

-- end

-- section

-- variable (R)

-- /-- `MvPowerSeries.rename e` is an equivalence when `e` is. -/
-- @[simps apply]
-- def renameEquiv (f : σ ≃ τ) : MvPowerSeries σ R ≃ₐ[R] MvPowerSeries τ R :=
--   { rename f with
--     toFun := rename f
--     invFun := rename f.symm
--     left_inv := fun p => by rw [rename_rename, f.symm_comp_self, rename_id]
--     right_inv := fun p => by rw [rename_rename, f.self_comp_symm, rename_id] }
-- #align mv_polynomial.rename_equiv MvPowerSeries.renameEquiv

-- @[simp]
-- theorem renameEquiv_refl : renameEquiv R (Equiv.refl σ) = AlgEquiv.refl :=
--   AlgEquiv.ext rename_id
-- #align mv_polynomial.rename_equiv_refl MvPowerSeries.renameEquiv_refl

-- @[simp]
-- theorem renameEquiv_symm (f : σ ≃ τ) : (renameEquiv R f).symm = renameEquiv R f.symm :=
--   rfl
-- #align mv_polynomial.rename_equiv_symm MvPowerSeries.renameEquiv_symm

-- @[simp]
-- theorem renameEquiv_trans (e : σ ≃ τ) (f : τ ≃ α) :
--     (renameEquiv R e).trans (renameEquiv R f) = renameEquiv R (e.trans f) :=
--   AlgEquiv.ext (rename_rename e f)
-- #align mv_polynomial.rename_equiv_trans MvPowerSeries.renameEquiv_trans

-- end

-- section

-- variable (f : R →+* S) (k : σ → τ) (g : τ → S) (p : MvPowerSeries σ R)

-- theorem eval₂_rename : (rename k p).eval₂ f g = p.eval₂ f (g ∘ k) := by
--   apply MvPowerSeries.induction_on p <;>
--     · intros
--       simp [*]
-- #align mv_polynomial.eval₂_rename MvPowerSeries.eval₂_rename

-- theorem eval_rename (g : τ → R) (p : MvPowerSeries σ R) : eval g (rename k p) = eval (g ∘ k) p :=
--   eval₂_rename _ _ _ _

-- theorem eval₂Hom_rename : eval₂Hom f g (rename k p) = eval₂Hom f (g ∘ k) p :=
--   eval₂_rename _ _ _ _
-- #align mv_polynomial.eval₂_hom_rename MvPowerSeries.eval₂Hom_rename

-- theorem aeval_rename [Algebra R S] : aeval g (rename k p) = aeval (g ∘ k) p :=
--   eval₂Hom_rename _ _ _ _
-- #align mv_polynomial.aeval_rename MvPowerSeries.aeval_rename

-- theorem rename_eval₂ (g : τ → MvPowerSeries σ R) :
--     rename k (p.eval₂ C (g ∘ k)) = (rename k p).eval₂ C (rename k ∘ g) := by
--   apply MvPowerSeries.induction_on p <;>
--     · intros
--       simp [*]
-- #align mv_polynomial.rename_eval₂ MvPowerSeries.rename_eval₂

-- theorem rename_prod_mk_eval₂ (j : τ) (g : σ → MvPowerSeries σ R) :
--     rename (Prod.mk j) (p.eval₂ C g) = p.eval₂ C fun x => rename (Prod.mk j) (g x) := by
--   apply MvPowerSeries.induction_on p <;>
--     · intros
--       simp [*]
-- #align mv_polynomial.rename_prodmk_eval₂ MvPowerSeries.rename_prod_mk_eval₂

-- theorem eval₂_rename_prod_mk (g : σ × τ → S) (i : σ) (p : MvPowerSeries τ R) :
--     (rename (Prod.mk i) p).eval₂ f g = eval₂ f (fun j => g (i, j)) p := by
--   apply MvPowerSeries.induction_on p <;>
--     · intros
--       simp [*]
-- #align mv_polynomial.eval₂_rename_prodmk MvPowerSeries.eval₂_rename_prod_mk

-- theorem eval_rename_prod_mk (g : σ × τ → R) (i : σ) (p : MvPowerSeries τ R) :
--     eval g (rename (Prod.mk i) p) = eval (fun j => g (i, j)) p :=
--   eval₂_rename_prod_mk (RingHom.id _) _ _ _
-- #align mv_polynomial.eval_rename_prodmk MvPowerSeries.eval_rename_prod_mk

-- end

-- /-- Every polynomial is a polynomial in finitely many variables. -/
-- theorem exists_finset_rename (p : MvPowerSeries σ R) :
--     ∃ (s : Finset σ) (q : MvPowerSeries { x // x ∈ s } R), p = rename (↑) q := by
--   classical
--   apply induction_on p
--   · intro r
--     exact ⟨∅, C r, by rw [rename_C]⟩
--   · rintro p q ⟨s, p, rfl⟩ ⟨t, q, rfl⟩
--     refine' ⟨s ∪ t, ⟨_, _⟩⟩
--     · refine' rename (Subtype.map id _) p + rename (Subtype.map id _) q <;>
--         simp (config := { contextual := true }) only [id.def, true_or_iff, or_true_iff,
--           Finset.mem_union, forall_true_iff]
--     · simp only [rename_rename, AlgHom.map_add]
--       rfl
--   · rintro p n ⟨s, p, rfl⟩
--     refine' ⟨insert n s, ⟨_, _⟩⟩
--     · refine' rename (Subtype.map id _) p * X ⟨n, s.mem_insert_self n⟩
--       simp (config := { contextual := true }) only [id.def, or_true_iff, Finset.mem_insert,
--         forall_true_iff]
--     · simp only [rename_rename, rename_X, Subtype.coe_mk, AlgHom.map_mul]
--       rfl
-- #align mv_polynomial.exists_finset_rename MvPowerSeries.exists_finset_rename

-- /-- `exists_finset_rename` for two polynomials at once: for any two polynomials `p₁`, `p₂` in a
--   polynomial semiring `R[σ]` of possibly infinitely many variables, `exists_finset_rename₂` yields
--   a finite subset `s` of `σ` such that both `p₁` and `p₂` are contained in the polynomial semiring
--   `R[s]` of finitely many variables. -/
-- theorem exists_finset_rename₂ (p₁ p₂ : MvPowerSeries σ R) :
--     ∃ (s : Finset σ) (q₁ q₂ : MvPowerSeries s R), p₁ = rename (↑) q₁ ∧ p₂ = rename (↑) q₂ := by
--   obtain ⟨s₁, q₁, rfl⟩ := exists_finset_rename p₁
--   obtain ⟨s₂, q₂, rfl⟩ := exists_finset_rename p₂
--   classical
--     use s₁ ∪ s₂
--     use rename (Set.inclusion <| s₁.subset_union_left s₂) q₁
--     use rename (Set.inclusion <| s₁.subset_union_right s₂) q₂
--     constructor -- Porting note: was `<;> simp <;> rfl` but Lean couldn't infer the arguments
--     · -- This used to be `rw`, but we need `erw` after leanprover/lean4#2644
--       erw [rename_rename (Set.inclusion <| s₁.subset_union_left s₂)]
--       rfl
--     · -- This used to be `rw`, but we need `erw` after leanprover/lean4#2644
--       erw [rename_rename (Set.inclusion <| s₁.subset_union_right s₂)]
--       rfl
-- #align mv_polynomial.exists_finset_rename₂ MvPowerSeries.exists_finset_rename₂

-- /-- Every polynomial is a polynomial in finitely many variables. -/
-- theorem exists_fin_rename (p : MvPowerSeries σ R) :
--     ∃ (n : ℕ) (f : Fin n → σ) (_hf : Injective f) (q : MvPowerSeries (Fin n) R), p = rename f q := by
--   obtain ⟨s, q, rfl⟩ := exists_finset_rename p
--   let n := Fintype.card { x // x ∈ s }
--   let e := Fintype.equivFin { x // x ∈ s }
--   refine' ⟨n, (↑) ∘ e.symm, Subtype.val_injective.comp e.symm.injective, rename e q, _⟩
--   rw [← rename_rename, rename_rename e]
--   simp only [Function.comp, Equiv.symm_apply_apply, rename_rename]
-- #align mv_polynomial.exists_fin_rename MvPowerSeries.exists_fin_rename

end Rename

-- theorem eval₂_cast_comp (f : σ → τ) (c : ℤ →+* R) (g : τ → R) (p : MvPowerSeries σ ℤ) :
--     eval₂ c (g ∘ f) p = eval₂ c g (rename f p) := by
--   apply MvPowerSeries.induction_on p (fun n => by simp only [eval₂_C, rename_C])
--     (fun p q hp hq => by simp only [hp, hq, rename, eval₂_add, AlgHom.map_add])
--     fun p n hp => by simp only [eval₂_mul, hp, eval₂_X, comp_apply, map_mul, rename_X, eval₂_mul]
-- #align mv_polynomial.eval₂_cast_comp MvPowerSeries.eval₂_cast_comp

-- section Coeff

-- @[simp]
-- theorem coeff_rename_mapDomain (f : σ → τ) (hf : Injective f) (φ : MvPowerSeries σ R) (d : σ →₀ ℕ) :
--     (rename f φ).coeff (d.mapDomain f) = φ.coeff d := by
--   classical
--   apply φ.induction_on' (P := fun ψ => coeff (Finsupp.mapDomain f d) ((rename f) ψ) = coeff d ψ)
--   -- Lean could no longer infer the motive
--   · intro u r
--     rw [rename_monomial, coeff_monomial, coeff_monomial]
--     simp only [(Finsupp.mapDomain_injective hf).eq_iff]
--   · intros
--     simp only [*, AlgHom.map_add, coeff_add]
-- #align mv_polynomial.coeff_rename_map_domain MvPowerSeries.coeff_rename_mapDomain

-- @[simp]
-- theorem coeff_rename_embDomain (f : σ ↪ τ) (φ : MvPowerSeries σ R) (d : σ →₀ ℕ) :
--     (rename f φ).coeff (d.embDomain f) = φ.coeff d := by
--   rw [Finsupp.embDomain_eq_mapDomain f, coeff_rename_mapDomain f f.injective]

-- theorem coeff_rename_eq_zero (f : σ → τ) (φ : MvPowerSeries σ R) (d : τ →₀ ℕ)
--     (h : ∀ u : σ →₀ ℕ, u.mapDomain f = d → φ.coeff u = 0) : (rename f φ).coeff d = 0 := by
--   classical
--   rw [rename_eq, ← not_mem_support_iff]
--   intro H
--   replace H := mapDomain_support H
--   rw [Finset.mem_image] at H
--   obtain ⟨u, hu, rfl⟩ := H
--   specialize h u rfl
--   simp? at h hu says simp only [Finsupp.mem_support_iff, ne_eq] at h hu
--   contradiction
-- #align mv_polynomial.coeff_rename_eq_zero MvPowerSeries.coeff_rename_eq_zero

-- theorem coeff_rename_ne_zero (f : σ → τ) (φ : MvPowerSeries σ R) (d : τ →₀ ℕ)
--     (h : (rename f φ).coeff d ≠ 0) : ∃ u : σ →₀ ℕ, u.mapDomain f = d ∧ φ.coeff u ≠ 0 := by
--   contrapose! h
--   apply coeff_rename_eq_zero _ _ _ h
-- #align mv_polynomial.coeff_rename_ne_zero MvPowerSeries.coeff_rename_ne_zero

-- @[simp]
-- theorem constantCoeff_rename {τ : Type*} (f : σ → τ) (φ : MvPowerSeries σ R) :
--     constantCoeff (rename f φ) = constantCoeff φ := by
--   apply φ.induction_on
--   · intro a
--     simp only [constantCoeff_C, rename_C]
--   · intro p q hp hq
--     simp only [hp, hq, RingHom.map_add, AlgHom.map_add]
--   · intro p n hp
--     simp only [hp, rename_X, constantCoeff_X, RingHom.map_mul, AlgHom.map_mul]
-- #align mv_polynomial.constant_coeff_rename MvPowerSeries.constantCoeff_rename

-- end Coeff

-- section Support

-- theorem support_rename_of_injective {p : MvPowerSeries σ R} {f : σ → τ} [DecidableEq τ]
--     (h : Function.Injective f) :
--     (rename f p).support = Finset.image (Finsupp.mapDomain f) p.support := by
--   rw [rename_eq]
--   exact Finsupp.mapDomain_support_of_injective (mapDomain_injective h) _
-- #align mv_polynomial.support_rename_of_injective MvPowerSeries.support_rename_of_injective

-- end Support

-- theorem degree_rename_eq (e : σ → τ) :
--     (rename f p).degree = φ.degree :=
--   sorry

end MvPowerSeries
