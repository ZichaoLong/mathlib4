/-
Copyright (c) 2022 Antoine Labelle. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Antoine Labelle
-/
import Mathlib.RepresentationTheory.FdRep
import Mathlib.LinearAlgebra.Trace
import Mathlib.RepresentationTheory.Invariants

#align_import representation_theory.character from "leanprover-community/mathlib"@"55b3f8206b8596db8bb1804d8a92814a0b6670c9"

/-!
# Characters of representations

This file introduces characters of representation and proves basic lemmas about how characters
behave under various operations on representations.

A key result is the orthogonality of characters for irreducible representations of finite group
over an algebraically closed field whose characteristic doesn't divide the order of the group. It
is the theorem `char_orthonormal`

# Implementation notes

Irreducible representations are implemented categorically, using the `Simple` class defined in
`Mathlib.CategoryTheory.Simple`

# TODO
* Once we have the monoidal closed structure on `FdRep k G` and a better API for the rigid
structure, `char_dual` and `char_linHom` should probably be stated in terms of `Vᘁ` and `ihom V W`.
-/


noncomputable section

universe u

open CategoryTheory LinearMap CategoryTheory.MonoidalCategory Representation FiniteDimensional

open scoped BigOperators

variable {k : Type u} [Field k]

namespace FdRep
set_option linter.uppercaseLean3 false -- `fdRep`

section Monoid

variable {G : Type u} [Monoid G]

/-- The character of a representation `V : FdRep k G` is the function associating to `g : G` the
trace of the linear map `V.ρ g`. -/
def character (V : FdRep k G) (g : G) :=
  LinearMap.trace k V (V.ρ g)
#align fdRep.character FdRep.character

theorem char_mul_comm (V : FdRep k G) (g : G) (h : G) : V.character (h * g) = V.character (g * h) :=
  by simp only [trace_mul_comm, character, map_mul]
#align fdRep.char_mul_comm FdRep.char_mul_comm

@[simp]
theorem char_one (V : FdRep k G) : V.character 1 = FiniteDimensional.finrank k V := by
  simp only [character, map_one, trace_one]
#align fdRep.char_one FdRep.char_one

/-- The character is multiplicative under the tensor product. -/
theorem char_tensor (V W : FdRep k G) : (V ⊗ W).character = V.character * W.character := by
  ext g; convert trace_tensorProduct' (V.ρ g) (W.ρ g)
#align fdRep.char_tensor FdRep.char_tensor

-- Porting note: adding variant of `char_tensor` to make the simp-set confluent
@[simp]
theorem char_tensor' (V W : FdRep k G) :
    character (Action.FunctorCategoryEquivalence.inverse.obj
    (Action.FunctorCategoryEquivalence.functor.obj V ⊗
     Action.FunctorCategoryEquivalence.functor.obj W)) = V.character * W.character := by
  simp [← char_tensor]

/-- The character of isomorphic representations is the same. -/
theorem char_iso {V W : FdRep k G} (i : V ≅ W) : V.character = W.character := by
  ext g; simp only [character, FdRep.Iso.conj_ρ i]; exact (trace_conj' (V.ρ g) _).symm
#align fdRep.char_iso FdRep.char_iso

/-- The character of a representation `V : FdRep k G`,
seen as k-linear map from MonoidAlgebra k G. -/
def character' (V : FdRep k G) : MonoidAlgebra k G →ₗ[k] k := Finsupp.lift k k G V.character

lemma lift_eq (f : G → k) (g : G) : Finsupp.lift k k G f (MonoidAlgebra.single g 1) = f g := by
  rw [Finsupp.lift_apply, Finsupp.sum_single_index, one_smul]
  simp only [smul_eq_mul, zero_mul]

theorem character_eq_character' (V : FdRep k G) (g : G) :
    character' V (MonoidAlgebra.single g 1) = V.character g := by
  rw [character']
  exact lift_eq V.character g

end Monoid

section Group

variable {G : Type u} [Group G]

/-- The character of a representation is constant on conjugacy classes. -/
@[simp]
theorem char_conj (V : FdRep k G) (g : G) (h : G) : V.character (h * g * h⁻¹) = V.character g := by
  rw [char_mul_comm, inv_mul_cancel_left]
#align fdRep.char_conj FdRep.char_conj

@[simp]
theorem char_dual (V : FdRep k G) (g : G) : (of (dual V.ρ)).character g = V.character g⁻¹ :=
  trace_transpose' (V.ρ g⁻¹)
#align fdRep.char_dual FdRep.char_dual

@[simp]
theorem char_linHom (V W : FdRep k G) (g : G) :
    (of (linHom V.ρ W.ρ)).character g = V.character g⁻¹ * W.character g := by
  rw [← char_iso (dualTensorIsoLinHom _ _), char_tensor, Pi.mul_apply, char_dual]
#align fdRep.char_lin_hom FdRep.char_linHom

variable [Fintype G] [Invertible (Fintype.card G : k)]

theorem average_char_eq_finrank_invariants (V : FdRep k G) :
    ⅟ (Fintype.card G : k) • ∑ g : G, V.character g = finrank k (invariants V.ρ) := by
  erw [← (isProj_averageMap V.ρ).trace] -- Porting note: Changed `rw` to `erw`
  simp [character, GroupAlgebra.average, _root_.map_sum]
#align fdRep.average_char_eq_finrank_invariants FdRep.average_char_eq_finrank_invariants

end Group

namespace MonoidAlgebra

universe u₁ u₂

instance {k : Type u₁} {G : Type u₂} [Semiring k] :
    Coe G (MonoidAlgebra k G) where
  coe g := MonoidAlgebra.single g 1

-- def std_basis (k : Type u₁) (G : Type u₂) [Semiring k] :
--     Basis G k (MonoidAlgebra k G) :=
--   .ofRepr (LinearEquiv.refl _ _)

-- instance my_inst {k : Type u₁} {G : Type u₂} [Semiring k] :
--     CoeDep (Type u₂) G (Basis G k (MonoidAlgebra k G)) where
--   coe := std_basis k G

-- instance {k : Type u₁} {G : Type u₂} [Semiring k] :
--     Inhabited (Basis G k (MonoidAlgebra k G)) :=
--   ⟨std_basis k G⟩

-- instance {k : Type u₁} {G : Type u₂} [Semiring k] :
--     Module.Free k (MonoidAlgebra k G) where
--   exists_basis := ⟨G, std_basis k G⟩

end MonoidAlgebra


-- def is_conj_inv (f : MonoidAlgebra k G →ₗ[k] k) := ∀ g h : G, f (h * g * h⁻¹) = f g

-- def ClassFuntion := {f : MonoidAlgebra k G →ₗ[k] k // is_conj_inv f}

-- lemma char_is_class_func (V : FdRep k G) :
--     is_conj_inv (Basis.constr (MonoidAlgebra.my_inst.coe : Basis G k (MonoidAlgebra k G)) k V.character) := by
--   intro g h
--   have foo := Basis.constr_basis G k V.character h
--   have (g : G) : B g = MonoidAlgebra.single g 1 := B.repr_self g
--   repeat rw [← this]
--   sorry

section ClassFunction

variable {G : Type u} [Group G]

def IsClassFunction (f : G → k) : Prop := ∀ (g h : G), f (h * g * h⁻¹) = f g

def IsClassFunction' (f : MonoidAlgebra k G →ₗ[k] k) : Prop := ∀ (g h : G), f (h * g * h⁻¹) = f g

def ClassFunction := { f : G → k // IsClassFunction f }

def ClassFunction' := { f : MonoidAlgebra k G →ₗ[k] k // IsClassFunction' f }

theorem isClassFunction_iff (f : G → k) : IsClassFunction f ↔
    IsClassFunction' (Finsupp.lift k k G f) := by
  simp only [IsClassFunction, IsClassFunction']
  have (g h : G): (MonoidAlgebra.single h 1) * (MonoidAlgebra.single g 1) *
      (MonoidAlgebra.single h⁻¹ 1) = MonoidAlgebra.single (h * g * h⁻¹) (1 : k) := by
    simp only [MonoidAlgebra.single_mul_single, mul_one]
  simp_rw [this]
  constructor
  · intro conj_inv g h
    calc
      Finsupp.lift k k G f (MonoidAlgebra.single (h * g * h⁻¹) 1) = f (h * g * h⁻¹) :=
        lift_eq f (h * g * h⁻¹)
      _ = f g := conj_inv g h
      _ = Finsupp.lift k k G f (MonoidAlgebra.single g 1) := (lift_eq f g).symm
  · intro conj_inv g h
    calc
      f (h * g * h⁻¹) = Finsupp.lift k k G f (MonoidAlgebra.single (h * g * h⁻¹) 1) :=
        (lift_eq f (h * g * h⁻¹)).symm
      _ = Finsupp.lift k k G f (MonoidAlgebra.single g 1) := conj_inv g h
      _ = f g := lift_eq f g

theorem char_isClassFunction (V : FdRep k G) : IsClassFunction V.character := by
  intro g h
  rw [char_conj]

theorem char_isClassFunction' (V : FdRep k G) : IsClassFunction' V.character' := by
  rw [character', ← isClassFunction_iff]
  exact char_isClassFunction V

end ClassFunction

section Orthogonality

variable {G : GroupCat.{u}} [IsAlgClosed k]

open scoped Classical

variable [Fintype G] [Invertible (Fintype.card G : k)]

def scalarProduct (φ ψ : G → k) := ⅟ (Fintype.card G : k) • ∑ g : G, φ g * ψ g⁻¹

lemma scalarProduct_symmetric : ∀ φ ψ : G → k, scalarProduct φ ψ = scalarProduct ψ φ := by
  intro φ ψ
  simp only
    [scalarProduct, mul_comm, invOf_eq_inv, smul_eq_mul
    , mul_eq_mul_left_iff, inv_eq_zero]
  apply Or.inl
  have : (fun g => ψ g * φ g⁻¹) = (fun g => (fun g => φ g * ψ g⁻¹) g⁻¹) := by
    simp only [inv_inv, mul_comm]
  rw [this]
  symm
  -- There should be a lemma for this, e.g. MulAction.toPerm
  let σ : Equiv.Perm G := by
    use (fun g => g⁻¹)
    use (fun g => g⁻¹)
    sorry
    sorry
  apply Equiv.Perm.sum_comp σ Fintype.elems (fun g => φ g * ψ g⁻¹) (fun a _ => Fintype.complete a)

/-- Orthogonality of characters for irreducible representations of finite group over an
algebraically closed field whose characteristic doesn't divide the order of the group. -/
theorem char_orthonormal (V W : FdRep k G) [Simple V] [Simple W] :
    scalarProduct V.character W.character =
      if Nonempty (V ≅ W) then ↑1 else ↑0 := by
  -- We expand the definition of scalar product.
  rw [scalarProduct]
  -- First, we can rewrite the summand `V.character g * W.character g⁻¹` as the character
  -- of the representation `V ⊗ W* ≅ Hom(W, V)` applied to `g`.
  -- Porting note: Originally `conv in V.character _ * W.character _ =>`
  conv_lhs =>
    enter [2, 2, g]
    rw [mul_comm, ← char_dual, ← Pi.mul_apply, ← char_tensor]
    rw [char_iso (FdRep.dualTensorIsoLinHom W.ρ V)]
  -- The average over the group of the character of a representation equals the dimension of the
  -- space of invariants.
  rw [average_char_eq_finrank_invariants]
  rw [show (of (linHom W.ρ V.ρ)).ρ = linHom W.ρ V.ρ from FdRep.of_ρ (linHom W.ρ V.ρ)]
  -- The space of invariants of `Hom(W, V)` is the subspace of `G`-equivariant linear maps,
  -- `Hom_G(W, V)`.
  erw [(linHom.invariantsEquivFdRepHom W V).finrank_eq] -- Porting note: Changed `rw` to `erw`
  -- By Schur's Lemma, the dimension of `Hom_G(W, V)` is `1` is `V ≅ W` and `0` otherwise.
  rw_mod_cast [finrank_hom_simple_simple W V, Iso.nonempty_iso_symm]
#align fdRep.char_orthonormal FdRep.char_orthonormal

theorem simple_iff_norm_one : ∀ V : FdRep k G, Simple V ↔ scalarProduct V.character V.character = 1 := by
  intro V
  constructor
  · intro h
    rw [char_orthonormal V V]
    simp only [ite_eq_left_iff, not_nonempty_iff, not_isEmpty_of_nonempty, zero_ne_one,
      IsEmpty.forall_iff]
  · intro h
    sorry

lemma simple_iff_dual_simple : ∀ V : FdRep k G, Simple V ↔ Simple (of (dual V.ρ)) := by
  intro V
  constructor
  · intro h
    rw [simple_iff_norm_one] at h
    simp_rw [simple_iff_norm_one, scalarProduct, char_dual, inv_inv, mul_comm]
    exact h
  · intro h
    rw [simple_iff_norm_one]
    simp_rw [simple_iff_norm_one, scalarProduct, char_dual, inv_inv, mul_comm] at h
    exact h

def averageFunction (α : G → k) (V : FdRep k G) : (V.V →ₗ[k] V.V) := ⅟ (Fintype.card G : k) • ∑ g : G, (α g) • (V.ρ g)

def averageClassFunction (α : G → k) (h : IsClassFunction α) (V : FdRep k G) : (V ⟶  V) := by
  use averageFunction α V
  intro g
  rw [averageFunction]
  sorry

end Orthogonality

section RegularRepresentation

variable {G : GroupCat.{u}} [IsAlgClosed k]
variable [Fintype G] [DecidableEq G] [Invertible (Fintype.card G : k)]

variable (k G)

def RegularRep : FdRep k G := FdRep.of (Representation.ofMulAction k G G)

def stdBasis : Basis G k (RegularRep k G) :=
  Basis.ofRepr (LinearEquiv.refl _ _)

lemma RegularRep_character_one : (RegularRep k G).character (1 : G) = (Fintype.card G : k) := by
  rw [character, LinearMap.trace_eq_matrix_trace k (stdBasis k G)]
  simp only [map_one, toMatrix_one, Matrix.trace_one]

lemma RegularRep_character_ne_one (g : G) (h : g ≠ 1) : (RegularRep k G).character g = (0 : k) := by
  rw [character, LinearMap.trace_eq_matrix_trace k (stdBasis k G)]
  apply Fintype.sum_eq_zero
  intro g'
  simp only [toMatrix, LinearEquiv.trans_apply, Matrix.diag_apply, toMatrix'_apply,
    LinearEquiv.arrowCongr_apply, Basis.equivFun_symm_apply, ite_smul, one_smul, zero_smul,
    Finset.sum_ite_eq', Finset.mem_univ, ↓reduceIte, Basis.equivFun_apply]
  erw [ofMulAction_single]
  apply Finsupp.single_eq_of_ne
  simp only [smul_eq_mul, ne_eq, mul_left_eq_self]
  exact h

lemma RegularRep_character : (RegularRep k G).character =
    fun (g : G) ↦ if g = 1 then (Fintype.card G : k) else 0 := by
  ext g
  if h : g = 1 then
    simp [h, RegularRep_character_one k G]
  else
    simp [h, RegularRep_character_ne_one k G]

lemma scalarProduct_RegularRep_eq_dimension (V : FdRep k G) :
    scalarProduct (RegularRep k G).character V.character = (FiniteDimensional.finrank k V : k) := by
  simp only
    [ RegularRep_character, scalarProduct, invOf_eq_inv, ite_mul
    , zero_mul, Finset.sum_ite_eq', Finset.mem_univ, ↓reduceIte, inv_one
    , char_one, smul_eq_mul, ← mul_assoc, inv_mul_cancel_of_invertible, one_mul
    ]

/-- Irreducbile characters are a basis of ClassFunction G -/
lemma orthogonal_to_all_characters_implies_zero (f : G → k) (hf : IsClassFunction f) (h : ∀ V : FdRep k G, Simple V → scalarProduct f V.character = (0 : k)) : f = fun _ ↦ (0 : k) := by
  let f' : (G → k) := fun g => f g⁻¹
  have hf' : IsClassFunction f' := by
    intro g h
    simp [f']
    rw [← mul_assoc]
    exact hf g⁻¹ h
  have h' : ∀ V : FdRep k G, Simple V → scalarProduct f' V.character = (0 : k) := by
    intro V hV
    simp_rw [scalarProduct_symmetric, scalarProduct, ← char_dual V, f']

    -- apply h (of (dual V.ρ)) (simple_iff_dual_simple hV)
  have (V : FdRep k G) (hV : Simple V) : averageClassFunction f' hf' V = (0 : V ⟶  V) := by
    have : finrank k (V ⟶  V) = 1 := by
      rw [finrank_hom_simple_simple V V]
      simp only [ite_eq_left_iff, not_nonempty_iff, not_isEmpty_of_nonempty, zero_ne_one,
        IsEmpty.forall_iff]
    have nonzero : (Action.Hom.id V) ≠ (0 : V ⟶  V) := by sorry
    let mul_id := exists_smul_eq_of_finrank_eq_one this nonzero (averageClassFunction f' hf' V)
    obtain ⟨c, hc⟩ := mul_id
    rw [← hc]
    have tr : LinearMap.trace k V (averageClassFunction f' hf' V).hom = 0 := by
      calc
        LinearMap.trace k V (averageClassFunction f' hf' V).hom = ⅟ (Fintype.card G : k) • ∑ g : G, f' g * V.character g := by
          simp_rw [character, averageClassFunction, averageFunction]
          simp only [invOf_eq_inv, map_smul, map_sum, smul_eq_mul]
        _ = ⅟ (Fintype.card G : k) • ∑ g : G, f' g * (of (dual V.ρ)).character g⁻¹ := by
          simp_rw [char_dual, inv_inv]
        _ = 0 := by
          apply h (of (dual V.ρ)) ?_
          rw [← simple_iff_dual_simple]
          exact hV
    rw [← hc] at tr
    have : LinearMap.trace k V (c • (Action.Hom.id V).hom) = c * finrank k V := by
      simp only [map_smul, smul_eq_mul, mul_eq_mul_left_iff]
      left
      exact LinearMap.trace_id k _
    by_cases hc : c = 0
    · rw [hc]
      simp only [zero_smul]
    · simp only [Action.smul_hom, Action.Hom.id_hom, map_smul, smul_eq_mul, mul_eq_zero, hc,
      false_or] at tr
      simp only [Action.Hom.id_hom, map_smul, smul_eq_mul, mul_eq_mul_left_iff, hc, or_false, tr] at this
      symm at this
      have : (finrank k V : k) ≠ (0 : k) := by
        sorry --exact nonzero_of_invertible (finrank k V)
      contradiction

  sorry -- Needs Maschke's theorem!

end RegularRepresentation

end FdRep
