import Mathlib.Order.CompleteSublattice
import Mathlib.Order.CompleteLattice
import Mathlib.Tactic
variable (α : Type*) [Order.Frame α]

abbrev Subframe := @CompleteSublattice α _


#synth SetLike (CompleteSublattice α) α
variable (x : CompleteSublattice α)
#check CompleteLattice x

variable {α}
variable (S : Subframe α)

#check S

#synth Order.Frame.MinimalAxioms α


lemma minAx :  ∀ (a : ↥S) (s : Set ↥S), a ⊓ sSup s ≤ ⨆ b ∈ s, a ⊓ b := by
  intro a s
  have h : a.val ⊓ sSup (Subtype.val '' s) ≤ ⨆ b ∈ (Subtype.val '' s), a.val ⊓ b := by
    apply Order.Frame.inf_sSup_le_iSup_inf





def x : Order.Frame.MinimalAxioms (Subframe α) := @Order.Frame.MinimalAxioms.mk (Subframe α) (by ) sorry

instance instFrame : Order.Frame S :=
  Order.Frame.ofMinimalAxioms ⟨sorry⟩
