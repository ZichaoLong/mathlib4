/-
Copyright (c) 2024 Andrew Yang. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Andrew Yang
-/
import Mathlib.RingTheory.Kaehler.CotangentComplex
import Mathlib.RingTheory.Generators
import Mathlib.Algebra.Module.SnakeLemma

/-!

# The Jacobi-Zariski exact sequence

Given `R → S → T`, the Jacobi-Zariski exact sequence is
```
H¹(L_{T/R}) → H¹(L_{T/S}) → T ⊗[S] Ω[S/R] → Ω[T/R] → Ω[T/S] → 0
```
The maps are
- `Algebra.H1Cotangent.map`
- `Algebra.H1Cotangent.δ`
- `KaehlerDifferential.mapBaseChange`
- `KaehlerDifferential.map`
and the exactness lemmas are
- `Algebra.H1Cotangent.exact_map_δ`
- `Algebra.H1Cotangent.exact_δ_mapBaseChange`
- `KaehlerDifferential.exact_mapBaseChange_map`
- `KaehlerDifferential.map_surjective`
-/

open KaehlerDifferential TensorProduct MvPolynomial

namespace Algebra

universe u₁ u₂ u₃ u₄ w' w u v uT

variable {R : Type u} {S : Type v} [CommRing R] [CommRing S] [Algebra R S] {P : Generators.{w} R S}
variable {T : Type uT} [CommRing T] [Algebra R T] [Algebra S T] [IsScalarTower R S T]
variable (Q : Generators.{w} S T) (P : Generators.{w'} R S)

attribute [local instance] SMulCommClass.of_commMonoid

attribute [local instance 999999] Zero.toOfNat0 SemilinearMapClass.distribMulActionSemiHomClass
  SemilinearEquivClass.instSemilinearMapClass TensorProduct.addZeroClass AddZeroClass.toZero

namespace Generators

/--
Given `R[X] → S` and `S[Y] → T`, this is the lift of an element in `ker(S[Y] → T)`
to `ker(R[X][Y] → S[Y] → T)` constructed from `P.σ`.
-/
noncomputable
def kerCompPreimage (x : Q.ker) :
    (Q.comp P).ker := by
  refine ⟨x.1.sum fun n r ↦ ?_, ?_⟩
  · refine rename ?_ (P.σ r) * monomial ?_ 1
    exacts [Sum.inr, n.mapDomain Sum.inl]
  · simp only [ker_eq_ker_aeval_val, RingHom.mem_ker]
    conv_rhs => rw [← show aeval Q.val x.1 = 0 from x.2, ← x.1.support_sum_monomial_coeff]
    simp only [Finsupp.sum, map_sum, map_mul, aeval_rename, Function.comp_def, comp_val,
      Sum.elim_inr, aeval_monomial, map_one, Finsupp.prod_mapDomain_index_inj Sum.inl_injective,
      Sum.elim_inl, one_mul]
    congr! with v i
    simp_rw [← IsScalarTower.toAlgHom_apply R, ← comp_aeval, AlgHom.comp_apply, P.aeval_val_σ]
    rfl

lemma ofComp_kerCompPreimage (x : Q.ker) :
    (Q.ofComp P).toAlgHom (kerCompPreimage Q P x) = x := by
  conv_rhs => rw [← x.1.support_sum_monomial_coeff]
  rw [kerCompPreimage, map_finsupp_sum, Finsupp.sum]
  refine Finset.sum_congr rfl fun j _ ↦ ?_
  simp only [AlgHom.toLinearMap_apply, _root_.map_mul, Hom.toAlgHom_monomial]
  rw [one_smul, Finsupp.prod_mapDomain_index_inj Sum.inl_injective]
  rw [rename, ← AlgHom.comp_apply, comp_aeval]
  simp only [ofComp_val, Sum.elim_inr, Function.comp_apply, self_val, id_eq,
    Sum.elim_inl, monomial_eq, Hom.toAlgHom_X]
  congr 1
  rw [aeval_def, IsScalarTower.algebraMap_eq R S, ← MvPolynomial.algebraMap_eq,
    ← coe_eval₂Hom, ← map_aeval, P.aeval_val_σ]
  rfl

lemma Cotangent.map_ofComp_ker :
    Submodule.map (Q.ofComp P).toAlgHom.toLinearMap ((Q.comp P).ker.restrictScalars R) =
      Q.ker.restrictScalars R := by
  apply le_antisymm
  · rintro _ ⟨x, hx, rfl⟩
    simp only [ker_eq_ker_aeval_val, Submodule.coe_restrictScalars, SetLike.mem_coe,
      RingHom.mem_ker, AlgHom.toLinearMap_apply, Submodule.restrictScalars_mem] at hx ⊢
    rw [← hx, Hom.algebraMap_toAlgHom]
    rfl
  · intro x hx
    exact ⟨_, (kerCompPreimage Q P ⟨x, hx⟩).2, ofComp_kerCompPreimage Q P ⟨x, hx⟩⟩

lemma Cotangent.surjective_map_ofComp :
    Function.Surjective (Extension.Cotangent.map (Q.ofComp P).toExtensionHom) := by
  intro x
  obtain ⟨⟨x, hx⟩, rfl⟩ := Extension.Cotangent.mk_surjective x
  have : x ∈ Q.ker.restrictScalars R := hx
  rw [← map_ofComp_ker Q P] at this
  obtain ⟨x, hx', rfl⟩ := this
  exact ⟨.mk ⟨x, hx'⟩, Extension.Cotangent.map_mk _ _⟩

lemma map_toComp_ker :
    P.ker.map (Q.toComp P).toAlgHom.toRingHom = RingHom.ker (Q.ofComp P).toAlgHom := by
  letI : DecidableEq (Q.vars →₀ ℕ) := Classical.decEq _
  apply le_antisymm
  · rw [Ideal.map_le_iff_le_comap]
    rintro x (hx : algebraMap P.Ring S x = 0)
    have : ((Q.ofComp P).toAlgHom.comp (Q.toComp P).toAlgHom) = IsScalarTower.toAlgHom R _ _ := by
      ext1; simp
    simp only [comp_vars, AlgHom.toRingHom_eq_coe, Ideal.mem_comap, RingHom.coe_coe,
      RingHom.mem_ker, ← AlgHom.comp_apply, this, IsScalarTower.toAlgHom_apply]
    rw [IsScalarTower.algebraMap_apply P.Ring S, hx, map_zero]
  · rintro x (h₂ : (Q.ofComp P).toAlgHom x = 0)
    let e : ((Q.comp P).vars →₀ ℕ) ≃+ (Q.vars →₀ ℕ) × (P.vars →₀ ℕ) :=
      Finsupp.sumFinsuppAddEquivProdFinsupp
    suffices ∑ v ∈ (support x).map e, (monomial (e.symm v)) (coeff (e.symm v) x) ∈
        Ideal.map (Q.toComp P).toAlgHom.toRingHom P.ker by
      simpa only [AlgHom.toRingHom_eq_coe, Finset.sum_map, Equiv.coe_toEmbedding,
        EquivLike.coe_coe, AddEquiv.symm_apply_apply, support_sum_monomial_coeff] using this
    rw [← Finset.sum_fiberwise_of_maps_to (fun i ↦ Finset.mem_image_of_mem Prod.fst)]
    refine sum_mem fun i hi ↦ ?_
    convert_to monomial (e.symm (i, 0)) 1 * (Q.toComp P).toAlgHom.toRingHom
      (∑ j ∈ ((support x).map e.toEmbedding).filter (fun x ↦ x.1 = i),
        monomial j.2 (coeff (e.symm j) x)) ∈ _
    · rw [map_sum, Finset.mul_sum]
      refine Finset.sum_congr rfl fun j hj ↦ ?_
      obtain rfl := (Finset.mem_filter.mp hj).2
      obtain ⟨i, j⟩ := j
      clear hj hi
      have : (Q.toComp P).toAlgHom (monomial j (coeff (e.symm (i, j)) x)) =
          monomial (e.symm (0, j)) (coeff (e.symm (i, j)) x) := by
        convert rename_monomial _ _ _
        ext (i₁ | i₂) <;>
          simp only [Finsupp.sumFinsuppAddEquivProdFinsupp_symm_apply, comp_vars,
            Finsupp.coe_sumElim, Finsupp.coe_zero, Sum.elim_inl, Sum.elim_inr, Pi.zero_apply, e,
            Set.mem_range, exists_false, not_false_eq_true, Finsupp.mapDomain_notin_range,
            Finsupp.mapDomain_apply Sum.inr_injective, reduceCtorEq, ↓reduceIte]
      simp only [AlgHom.toRingHom_eq_coe, monomial_zero', RingHom.coe_coe, algHom_C,
          MvPolynomial.algebraMap_eq, this]
      rw [monomial_mul, ← map_add, Prod.mk_add_mk, add_zero, zero_add, one_mul]
    · apply Ideal.mul_mem_left
      refine Ideal.mem_map_of_mem _ ?_
      simp only [ker_eq_ker_aeval_val, AddEquiv.toEquiv_eq_coe, RingHom.mem_ker, map_sum]
      rw [← coeff_zero i, ← h₂]
      clear h₂ hi
      have (x : (Q.comp P).Ring) : (Function.support fun a ↦ if a.1 = i then aeval P.val
          (monomial a.2 (coeff (e.symm a) x)) else 0) ⊆ ((support x).map e).toSet := by
        rw [← Set.compl_subset_compl]
        intro j
        obtain ⟨j, rfl⟩ := e.surjective j
        simp_all
      rw [Finset.sum_filter, ← finsum_eq_sum_of_support_subset _ (this x)]
      induction x using MvPolynomial.induction_on' with
      | h1 v a =>
        rw [finsum_eq_sum_of_support_subset _ (this _), ← Finset.sum_filter]
        obtain ⟨v, rfl⟩ := e.symm.surjective v
        erw [ofComp_toAlgHom_monomial_sumElim]
        classical
        simp only [comp_vars, coeff_monomial, ← e.injective.eq_iff,
          map_zero, AddEquiv.apply_symm_apply, apply_ite]
        rw [← apply_ite, Finset.sum_ite_eq]
        simp only [Finset.mem_filter, Finset.mem_map_equiv, AddEquiv.coe_toEquiv_symm, comp_vars,
          mem_support_iff, coeff_monomial, ↓reduceIte, ne_eq, ite_and, ite_not]
        split
        · simp only [zero_smul, coeff_zero, *, map_zero, ite_self]
        · congr
      | h2 p q hp hq =>
        simp only [coeff_add, map_add, ite_add_zero]
        rw [finsum_add_distrib, hp, hq]
        · refine (((support p).map e).finite_toSet.subset ?_)
          convert this p
        · refine (((support q).map e).finite_toSet.subset ?_)
          convert this q

open Extension.Cotangent in
lemma Cotangent.exact :
    Function.Exact
      ((Extension.Cotangent.map (Q.toComp P).toExtensionHom).liftBaseChange T)
      (Extension.Cotangent.map (Q.ofComp P).toExtensionHom) := by
  apply LinearMap.exact_of_comp_of_mem_range
  · rw [LinearMap.liftBaseChange_comp, ← Extension.Cotangent.map_comp,
      EmbeddingLike.map_eq_zero_iff]
    ext x
    obtain ⟨⟨x, hx⟩, rfl⟩ := Extension.Cotangent.mk_surjective x
    simp only [map_mk, Hom.toAlgHom_comp_apply, val_mk, LinearMap.zero_apply, val_zero]
    convert Q.ker.toCotangent.map_zero
    trans ((IsScalarTower.toAlgHom R _ _).comp (IsScalarTower.toAlgHom R P.Ring S)) x
    · congr
      refine MvPolynomial.algHom_ext fun i ↦ ?_
      show (Q.ofComp P).toAlgHom ((Q.toComp P).toAlgHom (X i)) = _
      simp
    · simp [-self_vars, show aeval P.val x = 0 from hx]
  · intro x hx
    obtain ⟨⟨x : (Q.comp P).Ring, hx'⟩, rfl⟩ := Extension.Cotangent.mk_surjective x
    replace hx : (Q.ofComp P).toAlgHom x ∈ Q.ker ^ 2 := by
      simpa only [map_mk, val_mk, val_zero, Ideal.toCotangent_eq_zero] using congr(($hx).val)
    rw [← Submodule.restrictScalars_mem R, pow_two, Submodule.restrictScalars_mul,
      ← map_ofComp_ker (P := P), ← Submodule.map_mul, ← Submodule.restrictScalars_mul] at hx
    obtain ⟨y, hy, e⟩ := hx
    rw [AlgHom.toLinearMap_apply, eq_comm, ← sub_eq_zero, ← map_sub, ← RingHom.mem_ker,
      ← map_toComp_ker] at e
    rw [LinearMap.range_liftBaseChange]
    let z : (Q.comp P).ker := ⟨x - y, Ideal.sub_mem _ hx' (Ideal.mul_le_left hy)⟩
    have hz : z.1 ∈ P.ker.map (Q.toComp P).toAlgHom.toRingHom := e
    have : Extension.Cotangent.mk ⟨x, hx'⟩ = Extension.Cotangent.mk z := by
      ext; simpa only [comp_vars, val_mk, Ideal.toCotangent_eq, sub_sub_cancel, pow_two]
    rw [this, ← Submodule.restrictScalars_mem (Q.comp P).Ring, ← Submodule.mem_comap,
      ← Submodule.span_singleton_le_iff_mem, ← Submodule.map_le_map_iff_of_injective
      (f := Submodule.subtype _) Subtype.val_injective, Submodule.map_subtype_span_singleton,
      Submodule.span_singleton_le_iff_mem]
    refine (show Ideal.map (Q.toComp P).toAlgHom.toRingHom P.ker ≤ _ from ?_) hz
    rw [Ideal.map_le_iff_le_comap]
    rintro w hw
    simp only [AlgHom.toRingHom_eq_coe, Ideal.mem_comap, RingHom.coe_coe,
      Submodule.mem_map, Submodule.mem_comap, Submodule.restrictScalars_mem, Submodule.coe_subtype,
      Subtype.exists, exists_and_right, exists_eq_right,
      toExtension_Ring, toExtension_commRing, toExtension_algebra₂]
    refine ⟨?_, Submodule.subset_span ⟨Extension.Cotangent.mk ⟨w, hw⟩, ?_⟩⟩
    · simp only [ker_eq_ker_aeval_val, RingHom.mem_ker, Hom.algebraMap_toAlgHom]
      rw [show aeval P.val w = 0 from hw, map_zero]
    · rw [map_mk]
      rfl

/-- Given `R[X] → S` and `S[Y] → T`, the cotangent space of `R[X][Y] → T` is isomorphic
to the direct product of the cotangent space of `S[Y] → T` and `R[X] → S` (base changed to `T`). -/
noncomputable
def CotangentSpace.compEquiv (Q : Generators.{w} S T) (P : Generators.{w'} R S) :
    (Q.comp P).toExtension.CotangentSpace ≃ₗ[T]
      Q.toExtension.CotangentSpace × (T ⊗[S] P.toExtension.CotangentSpace) :=
  (Q.comp P).cotangentSpaceBasis.repr.trans
    (Q.cotangentSpaceBasis.prod (P.cotangentSpaceBasis.baseChange T)).repr.symm

lemma CotangentSpace.compEquiv_symm_inr :
    (compEquiv Q P).symm.toLinearMap ∘ₗ
      LinearMap.inr T Q.toExtension.CotangentSpace (T ⊗[S] P.toExtension.CotangentSpace) =
        (Extension.CotangentSpace.map (Q.toComp P).toExtensionHom).liftBaseChange T := by
  classical
  apply (P.cotangentSpaceBasis.baseChange T).ext
  intro i
  apply (Q.comp P).cotangentSpaceBasis.repr.injective
  ext j
  simp only [compEquiv, LinearEquiv.trans_symm, LinearEquiv.symm_symm,
    Basis.baseChange_apply, LinearMap.coe_comp, LinearEquiv.coe_coe, LinearMap.coe_inr,
    Function.comp_apply, LinearEquiv.trans_apply, Basis.repr_symm_apply, pderiv_X, toComp_val,
    Basis.repr_linearCombination, LinearMap.liftBaseChange_tmul, one_smul, repr_CotangentSpaceMap]
  obtain (j | j) := j <;>
    simp only [comp_vars, Basis.prod_repr_inr, Basis.baseChange_repr_tmul,
      Basis.repr_self, Basis.prod_repr_inl, map_zero, Finsupp.coe_zero,
      Pi.zero_apply, ne_eq, not_false_eq_true, Pi.single_eq_of_ne, Pi.single_apply,
      Finsupp.single_apply, ite_smul, one_smul, zero_smul, Sum.inr.injEq,
        RingHom.map_ite_one_zero, reduceCtorEq, ↓reduceIte]

lemma CotangentSpace.compEquiv_symm_zero (x) :
    (compEquiv Q P).symm (0, x) =
        (Extension.CotangentSpace.map (Q.toComp P).toExtensionHom).liftBaseChange T x :=
  DFunLike.congr_fun (compEquiv_symm_inr Q P) x

lemma CotangentSpace.fst_compEquiv :
    LinearMap.fst T Q.toExtension.CotangentSpace (T ⊗[S] P.toExtension.CotangentSpace) ∘ₗ
      (compEquiv Q P).toLinearMap = Extension.CotangentSpace.map (Q.ofComp P).toExtensionHom := by
  classical
  apply (Q.comp P).cotangentSpaceBasis.ext
  intro i
  apply Q.cotangentSpaceBasis.repr.injective
  ext j
  simp only [compEquiv, LinearMap.coe_comp, LinearEquiv.coe_coe, Function.comp_apply, ofComp_val,
    LinearEquiv.trans_apply, Basis.repr_self, LinearMap.fst_apply, repr_CotangentSpaceMap]
  obtain (i | i) := i <;>
    simp only [comp_vars, Basis.repr_symm_apply, Finsupp.linearCombination_single, Basis.prod_apply,
      LinearMap.coe_inl, LinearMap.coe_inr, Sum.elim_inl, Function.comp_apply, one_smul,
      Basis.repr_self, Finsupp.single_apply, pderiv_X, Pi.single_apply, RingHom.map_ite_one_zero,
      Sum.elim_inr, Function.comp_apply, Basis.baseChange_apply, one_smul,
      map_zero, Finsupp.coe_zero, Pi.zero_apply, derivation_C]

lemma CotangentSpace.fst_compEquiv_apply (x) :
    (compEquiv Q P x).1 = Extension.CotangentSpace.map (Q.ofComp P).toExtensionHom x :=
  DFunLike.congr_fun (fst_compEquiv Q P) x

lemma CotangentSpace.map_toComp_injective :
    Function.Injective
      ((Extension.CotangentSpace.map (Q.toComp P).toExtensionHom).liftBaseChange T) := by
  rw [← compEquiv_symm_inr]
  apply (compEquiv Q P).symm.injective.comp
  exact Prod.mk.inj_left _

lemma CotangentSpace.map_ofComp_surjective :
    Function.Surjective (Extension.CotangentSpace.map (Q.ofComp P).toExtensionHom) := by
  rw [← fst_compEquiv]
  exact (Prod.fst_surjective).comp (compEquiv Q P).surjective

lemma CotangentSpace.exact :
    Function.Exact ((Extension.CotangentSpace.map (Q.toComp P).toExtensionHom).liftBaseChange T)
      (Extension.CotangentSpace.map (Q.ofComp P).toExtensionHom) := by
  rw [← fst_compEquiv, ← compEquiv_symm_inr]
  conv_rhs => rw [← LinearEquiv.symm_symm (compEquiv Q P)]
  rw [LinearEquiv.conj_exact_iff_exact]
  exact Function.Exact.inr_fst

variable (R) in
/--
Given `0 → I → S[Y] → T → 0`, this is an auxiliary map from `S[Y]` to `T ⊗[S] Ω[S⁄R]` whose
restriction to `ker(I/I² → ⊕ S dyᵢ)` is the connecting homomorphism in the Jacobi-Zariski sequence.
-/
noncomputable
def H1Cotangent.δAux :
    Q.Ring →ₗ[R] T ⊗[S] Ω[S⁄R] :=
  Finsupp.lsum R (R := R) fun f ↦
    (TensorProduct.mk S T _ (f.prod (Q.val · ^ ·))).restrictScalars R ∘ₗ (D R S).toLinearMap

lemma H1Cotangent.δAux_monomial (n r) :
    δAux R Q (monomial n r) = (n.prod (Q.val · ^ ·)) ⊗ₜ D R S r :=
  Finsupp.lsum_single _ _ _ _

@[simp]
lemma H1Cotangent.δAux_X (i) :
    δAux R Q (X i) = 0 := by
  rw [X, δAux_monomial]
  simp only [Derivation.map_one_eq_zero, tmul_zero]

lemma H1Cotangent.δAux_mul (x y) :
    δAux R Q (x * y) = x • (δAux R Q y) + y • (δAux R Q x) := by
  induction' x using MvPolynomial.induction_on' with n r x₁ x₂ hx₁ hx₂
  · induction' y using MvPolynomial.induction_on' with m s y₁ y₂ hy₁ hy₂
    · simp only [monomial_mul, δAux_monomial, Derivation.leibniz, tmul_add, tmul_smul,
        smul_tmul', smul_eq_mul, Algebra.smul_def, algebraMap_apply, aeval_monomial, mul_assoc]
      rw [mul_comm (m.prod _) (n.prod _)]
      simp only [pow_zero, implies_true, pow_add, Finsupp.prod_add_index']
    · simp only [map_add, smul_add, hy₁, hy₂, mul_add, add_smul]; abel
  · simp only [add_mul, map_add, hx₁, hx₂, add_smul, smul_add]; abel

lemma H1Cotangent.δAux_C (r) :
    δAux R Q (C r) = 1 ⊗ₜ D R S r := by
  rw [← monomial_zero', δAux_monomial, Finsupp.prod_zero_index]

lemma H1Cotangent.δAux_toAlgHom {Q : Generators.{u₁} S T}
    {Q' : Generators.{u₃} S T} (f : Hom Q Q') (x) :
    δAux R Q' (f.toAlgHom x) = δAux R Q x + Finsupp.linearCombination _ (δAux R Q' ∘ f.val)
      (Q.cotangentSpaceBasis.repr ((1 : T) ⊗ₜ[Q.Ring] D S Q.Ring x : _)) := by
  letI : AddCommGroup (T ⊗[S] Ω[S⁄R]) := inferInstance
  have : IsScalarTower Q.Ring Q.Ring T := IsScalarTower.left _
  induction' x using MvPolynomial.induction_on with s x₁ x₂ hx₁ hx₂ p n IH
  · simp [MvPolynomial.algebraMap_eq, δAux_C]
  · simp only [map_add, hx₁, hx₂, tmul_add]
    rw [add_add_add_comm]
  · simp only [map_mul, Hom.toAlgHom_X, δAux_mul, algebraMap_apply, Hom.algebraMap_toAlgHom,
      ← @IsScalarTower.algebraMap_smul Q'.Ring T, id.map_eq_id, δAux_X, RingHomCompTriple.comp_eq,
      RingHom.id_apply, coe_eval₂Hom, IH, Hom.aeval_val, smul_add, map_aeval, tmul_add, tmul_smul,
      ← @IsScalarTower.algebraMap_smul Q.Ring T, smul_zero, aeval_X, zero_add, Derivation.leibniz,
      LinearEquiv.map_add, LinearEquiv.map_smul, Basis.repr_self, LinearMap.map_add, one_smul,
      LinearMap.map_smul, Finsupp.linearCombination_single,
      Function.comp_apply, ← cotangentSpaceBasis_apply]
    rw [add_left_comm]
    rfl

lemma H1Cotangent.δAux_ofComp (x : (Q.comp P).Ring) :
    δAux R Q ((Q.ofComp P).toAlgHom x) =
      P.toExtension.toKaehler.baseChange T (CotangentSpace.compEquiv Q P
        (1 ⊗ₜ[(Q.comp P).Ring] (D R (Q.comp P).Ring) x : _)).2 := by
  letI : AddCommGroup (T ⊗[S] Ω[S⁄R]) := inferInstance
  have : IsScalarTower (Q.comp P).Ring (Q.comp P).Ring T := IsScalarTower.left _
  induction' x using MvPolynomial.induction_on with s x₁ x₂ hx₁ hx₂ p n IH
  · simp only [algHom_C, δAux_C, sub_self, derivation_C, Derivation.map_algebraMap,
      tmul_zero, map_zero, add_zero, MvPolynomial.algebraMap_apply, Prod.snd_zero]
  · simp only [map_add, hx₁, hx₂, tmul_add, Prod.snd_add]
  · simp only [map_mul, Hom.toAlgHom_X, ofComp_val, δAux_mul,
      ← @IsScalarTower.algebraMap_smul Q.Ring T, algebraMap_apply, Hom.algebraMap_toAlgHom,
      id.map_eq_id, map_aeval, RingHomCompTriple.comp_eq, comp_val, RingHom.id_apply, coe_eval₂Hom,
      IH, Derivation.leibniz, tmul_add, tmul_smul, ← cotangentSpaceBasis_apply,
      ← @IsScalarTower.algebraMap_smul (Q.comp P).Ring T, aeval_X, LinearEquiv.map_add,
      LinearMapClass.map_smul, Prod.snd_add, Prod.smul_snd, LinearMap.map_add]
    obtain (n | n) := n
    · simp only [comp_vars, Sum.elim_inl, δAux_X, smul_zero, aeval_X,
        CotangentSpace.compEquiv, LinearEquiv.trans_apply, Basis.repr_symm_apply, zero_add,
        Basis.repr_self, Finsupp.linearCombination_single, Basis.prod_apply, LinearMap.coe_inl,
        LinearMap.coe_inr, Function.comp_apply, one_smul, map_zero]
    · simp only [comp_vars, Sum.elim_inr, Function.comp_apply, algHom_C, δAux_C,
        CotangentSpace.compEquiv, LinearEquiv.trans_apply, Basis.repr_symm_apply,
        algebraMap_smul, Basis.repr_self, Finsupp.linearCombination_single, Basis.prod_apply,
        LinearMap.coe_inr, Basis.baseChange_apply, one_smul, LinearMap.baseChange_tmul,
        toKaehler_cotangentSpaceBasis, add_left_inj, LinearMap.coe_inl]
      rfl

open Generators in
/--
The connecting homomorphism in the Jacobi-Zariski sequence for given presentations.
Given representations `0 → I → R[X] → S → 0` and `0 → K → S[Y] → T → 0`,
we may consider the induced representation `0 → J → R[X, Y] → T → 0`,
and this map is obtained by applying snake lemma to the following diagram
```
    T ⊗[S] Ω[S/R]    →          Ω[T/R]        →   Ω[T/S]  → 0
        ↑                         ↑                 ↑
0 → T ⊗[S] (⨁ₓ S dx) → (⨁ₓ T dx) ⊕ (⨁ᵧ T dy) →  ⨁ᵧ T dy → 0
        ↑                         ↑                 ↑
    T ⊗[S] (I/I²)    →           J/J²         →    K/K²   → 0
                                  ↑                 ↑
                             H¹(L_{T/R})      → H¹(L_{T/S})

```
This is independent from the presentations chosen. See `H1Cotangent.δ_comp_equiv`.
-/
noncomputable
def H1Cotangent.δ :
    Q.toExtension.H1Cotangent →ₗ[T] T ⊗[S] Ω[S⁄R] :=
  SnakeLemma.δ'
    (P.toExtension.cotangentComplex.baseChange T)
    (Q.comp P).toExtension.cotangentComplex
    Q.toExtension.cotangentComplex
    ((Extension.Cotangent.map (toComp Q P).toExtensionHom).liftBaseChange T)
    (Extension.Cotangent.map (ofComp Q P).toExtensionHom)
    (Cotangent.exact Q P)
    ((Extension.CotangentSpace.map (toComp Q P).toExtensionHom).liftBaseChange T)
    (Extension.CotangentSpace.map (ofComp Q P).toExtensionHom)
    (CotangentSpace.exact Q P)
    (by ext x; simp [Extension.CotangentSpace.map_cotangentComplex])
    (by ext; exact Extension.CotangentSpace.map_cotangentComplex (ofComp Q P).toExtensionHom _)
    Q.toExtension.h1Cotangentι
    (LinearMap.exact_subtype_ker_map _)
    (P.toExtension.toKaehler.baseChange T)
    (lTensor_exact T P.toExtension.exact_cotangentComplex_toKaehler
      P.toExtension.toKaehler_surjective)
    (Cotangent.surjective_map_ofComp Q P)
    (CotangentSpace.map_toComp_injective Q P)

lemma H1Cotangent.exact_δ_map :
    Function.Exact (H1Cotangent.δ Q P) (mapBaseChange R S T) := by
  apply SnakeLemma.exact_δ_left (π₂ := (Q.comp P).toExtension.toKaehler)
    (hπ₂ := (Q.comp P).toExtension.exact_cotangentComplex_toKaehler)
  · apply (P.cotangentSpaceBasis.baseChange T).ext
    intro i
    simp only [Basis.baseChange_apply, LinearMap.coe_comp, Function.comp_apply,
      LinearMap.baseChange_tmul, toKaehler_cotangentSpaceBasis, mapBaseChange_tmul, map_D,
      one_smul, comp_vars, LinearMap.liftBaseChange_tmul]
    rw [cotangentSpaceBasis_apply]
    conv_rhs => enter [2]; tactic => exact Extension.CotangentSpace.map_tmul ..
    simp only [map_one, mapBaseChange_tmul, map_D, one_smul]
    simp [Extension.Hom.toAlgHom]
  · exact LinearMap.lTensor_surjective T P.toExtension.toKaehler_surjective

lemma H1Cotangent.δ_eq (x : Q.toExtension.H1Cotangent) (y)
    (hy : Extension.Cotangent.map (ofComp Q P).toExtensionHom y = x.1) (z)
    (hz : (Extension.CotangentSpace.map (toComp Q P).toExtensionHom).liftBaseChange T z =
      (Q.comp P).toExtension.cotangentComplex y) :
    H1Cotangent.δ Q P x = P.toExtension.toKaehler.baseChange T z := by
  apply SnakeLemma.δ_eq
  exacts [hy, hz]

lemma H1Cotangent.δ_eq_δAux (x : Q.ker) (hx) :
    H1Cotangent.δ Q P ⟨.mk x, hx⟩ = H1Cotangent.δAux R Q x.1 := by
  let y := Extension.Cotangent.mk (P := (Q.comp P).toExtension) (Q.kerCompPreimage P x)
  have hy : (Extension.Cotangent.map (Q.ofComp P).toExtensionHom) y = Extension.Cotangent.mk x := by
    simp only [y, Extension.Cotangent.map_mk]
    congr
    exact ofComp_kerCompPreimage Q P x
  let z := (CotangentSpace.compEquiv Q P ((Q.comp P).toExtension.cotangentComplex y)).2
  rw [H1Cotangent.δ_eq (y := y) (z := z)]
  · rw [← ofComp_kerCompPreimage Q P x, δAux_ofComp]
    rfl
  · exact hy
  · rw [← CotangentSpace.compEquiv_symm_inr]
    apply (CotangentSpace.compEquiv Q P).injective
    simp only [LinearMap.coe_comp, LinearEquiv.coe_coe, LinearMap.coe_inr, Function.comp_apply,
      LinearEquiv.apply_symm_apply, z]
    ext
    swap; · rfl
    show 0 = (LinearMap.fst T Q.toExtension.CotangentSpace (T ⊗[S] P.toExtension.CotangentSpace) ∘ₗ
      (CotangentSpace.compEquiv Q P).toLinearMap) ((Q.comp P).toExtension.cotangentComplex y)
    rw [CotangentSpace.fst_compEquiv, Extension.CotangentSpace.map_cotangentComplex, hy, hx]

lemma H1Cotangent.δ_eq_δ (Q : Generators.{u₁} S T) (P : Generators.{u₂} R S)
    (P' : Generators.{u₃} R S) :
    H1Cotangent.δ Q P = H1Cotangent.δ Q P' := by
  ext ⟨x, hx⟩
  obtain ⟨x, rfl⟩ := Extension.Cotangent.mk_surjective x
  rw [δ_eq_δAux, δ_eq_δAux]

lemma H1Cotangent.exact_map_δ :
    Function.Exact (Extension.H1Cotangent.map (Q.ofComp P).toExtensionHom) (H1Cotangent.δ Q P) := by
  apply SnakeLemma.exact_δ_right
    (ι₂ := (Q.comp P).toExtension.h1Cotangentι)
    (hι₂ := LinearMap.exact_subtype_ker_map _)
  · ext x; rfl
  · exact Subtype.val_injective

lemma H1Cotangent.δ_map
    (Q : Generators.{u₁} S T) (P : Generators.{u₂} R S)
    (Q' : Generators.{u₃} S T) (P' : Generators.{u₄} R S) (f : Hom Q' Q) (x) :
    H1Cotangent.δ Q P (Extension.H1Cotangent.map f.toExtensionHom x) = H1Cotangent.δ Q' P' x := by
  letI : AddCommGroup (T ⊗[S] Ω[S⁄R]) := inferInstance
  obtain ⟨x, hx⟩ := x
  obtain ⟨⟨y, hy⟩, rfl⟩ := Extension.Cotangent.mk_surjective x
  show δ _ _ ⟨_, _⟩ = δ _ _ _
  replace hx : (1 : T) ⊗ₜ[Q'.Ring] (D S Q'.Ring) y = 0 := by
    simpa only [LinearMap.mem_ker, Extension.cotangentComplex_mk, ker, RingHom.mem_ker] using hx
  simp only [LinearMap.domRestrict_apply, Extension.Cotangent.map_mk, δ_eq_δAux]
  refine (δAux_toAlgHom f _).trans ?_
  rw [hx, map_zero, map_zero, add_zero]

lemma H1Cotangent.δ_comp_equiv
    (Q : Generators.{u₁} S T) (P : Generators.{u₂} R S)
    (Q' : Generators.{u₃} S T) (P' : Generators.{u₄} R S) :
    H1Cotangent.δ Q P ∘ₗ (H1Cotangent.equiv _ _).toLinearMap = H1Cotangent.δ Q' P' := by
  ext x
  exact δ_map Q P Q' P' _ _

/-- A variant of `exact_map_δ` that takes in an arbitrary map between generators. -/
lemma H1Cotangent.exact_map_δ'
    (Q : Generators.{u₁} S T) (P : Generators.{u₂} R S) (P' : Generators.{u₃} R T) (f : Hom P' Q) :
    Function.Exact (Extension.H1Cotangent.map f.toExtensionHom) (H1Cotangent.δ Q P) := by
  refine (H1Cotangent.equiv (Q.comp P) P').surjective.comp_exact_iff_exact.mp ?_
  show Function.Exact ((Extension.H1Cotangent.map f.toExtensionHom).restrictScalars T ∘ₗ
    (Extension.H1Cotangent.map _)) (δ Q P)
  rw [← Extension.H1Cotangent.map_comp, Extension.H1Cotangent.map_eq _ (Q.ofComp P).toExtensionHom]
  exact exact_map_δ Q P

end Generators

variable {T : Type w} [CommRing T] [Algebra R T] [Algebra S T] [IsScalarTower R S T]

variable (R S T)

/-- The connecting homomorphism in the Jacobi-Zariski sequence. -/
noncomputable
def H1Cotangent.δ : H1Cotangent S T →ₗ[T] T ⊗[S] Ω[S⁄R] :=
  Generators.H1Cotangent.δ (Generators.self S T) (Generators.self R S)

lemma H1Cotangent.exact_map_δ : Function.Exact (map R S T T) (δ R S T) :=
  Generators.H1Cotangent.exact_map_δ' (Generators.self S T)
    (Generators.self R S) (Generators.self R T) (Generators.defaultHom _ _)

lemma H1Cotangent.exact_δ_mapBaseChange : Function.Exact (δ R S T) (mapBaseChange R S T) :=
  Generators.H1Cotangent.exact_δ_map (Generators.self S T) (Generators.self R S)

end Algebra
