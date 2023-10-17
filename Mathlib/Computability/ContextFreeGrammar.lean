/-
Copyright (c) 2023 Martin Dvorak. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Martin Dvorak
-/
import Mathlib.Computability.Language

/-!
# Context-Free Grammar

This file contains the definition of a context-free grammar, which is a grammar that has a single
nonterminal symbol on the left-hand side of each rule.

## Main definitions
* `ContextFreeGrammar`: A context-free grammar.
* `Language.IsContextFree`: A language generated by a context-free grammar.

## Main theorems
* `reverseContextFreeLanguage`: The class of context-free languages is closed under reversal.
-/

universe uT uN in
/-- Rule that rewrites a single nonterminal to any string (a list of symbols). -/
structure ContextFreeRule (T : Type uT) (N : Type uN) where
  /-- Input nonterminal a.k.a. left-hand side. -/
  input : N
  /-- Output string a.k.a. right-hand side. -/
  output : List (Symbol T N)

/-- Context-free grammar that generates words over the alphabet `T` (a type of terminals). -/
structure ContextFreeGrammar.{uN,uT} (T : Type uT) where
  /-- Type of nonterminals. -/
  NT : Type uN
  /-- Initial nonterminal. -/
  initial : NT
  /-- Rewrite rules. -/
  rules : List (ContextFreeRule T NT)

universe uT uN
variable {T : Type uT}

namespace ContextFreeRule
variable {N : Type uN}

/-- Inductive definition of a single application of a given context-free rule `r` to a string `u`;
`r.Rewrites u v` means that the `r` sends `u` to `v` (there may be multiple such strings `v`). -/
inductive Rewrites (r : ContextFreeRule T N) : List (Symbol T N) → List (Symbol T N) → Prop
  /-- The replacement is at the start of the remaining string. -/
  | head (s : List (Symbol T N)) :
      r.Rewrites (Symbol.nonterminal r.input :: s) (r.output ++ s)
  /-- There is a replacement later in the string. -/
  | cons (x : Symbol T N) {s₁ s₂ : List (Symbol T N)} (hrs : Rewrites r s₁ s₂) :
      r.Rewrites (x :: s₁) (x :: s₂)

lemma Rewrites.exists_parts {r : ContextFreeRule T N} {u v : List (Symbol T N)}
    (hyp : r.Rewrites u v) :
    ∃ p q : List (Symbol T N),
      u = p ++ [Symbol.nonterminal r.input] ++ q ∧ v = p ++ r.output ++ q := by
  induction hyp with
  | head xs =>
    use [], xs
    simp
  | cons x _ ih =>
    rcases ih with ⟨p', q', rfl, rfl⟩
    use x :: p', q'
    simp

lemma rewrites_of_exists_parts (r : ContextFreeRule T N) (p q : List (Symbol T N)) :
    r.Rewrites (p ++ [Symbol.nonterminal r.input] ++ q) (p ++ r.output ++ q) := by
  induction p with
  | nil         => exact Rewrites.head q
  | cons d l ih => exact Rewrites.cons d ih

/-- Rule `r` rewrites string `u` is to string `v` iff they share both a prefix `p` and postfix `q`
such that the remaining middle part of `u` is the input of `r` and the remaining middle part
of `u` is the output of `r`. -/
theorem rewrites_iff {r : ContextFreeRule T N} (u v : List (Symbol T N)) :
    r.Rewrites u v ↔ ∃ p q : List (Symbol T N),
      u = p ++ [Symbol.nonterminal r.input] ++ q ∧ v = p ++ r.output ++ q :=
  ⟨Rewrites.exists_parts, by rintro ⟨p, q, rfl, rfl⟩; apply rewrites_of_exists_parts⟩

end ContextFreeRule

namespace ContextFreeGrammar

/-- Given a context-free grammar `g` and strings `u` and `v`
`g.Produces u v` means that one step of a context-free transformation by a rule from `g` sends
`u` to `v`. -/
def Produces (g : ContextFreeGrammar.{uN} T) (u v : List (Symbol T g.NT)) : Prop :=
  ∃ r ∈ g.rules, r.Rewrites u v

/-- Given a context-free grammar `g` and strings `u` and `v`
`g.Derives u v` means that `g` can transform `u` to `v` in some number of rewriting steps. -/
abbrev Derives (g : ContextFreeGrammar.{uN} T) :
    List (Symbol T g.NT) → List (Symbol T g.NT) → Prop :=
  Relation.ReflTransGen g.Produces

/-- Given a context-free grammar `g` and a string `s`
`g.Generates s` means that `g` can transform its initial nonterminal to `s` in some number of
rewriting steps. -/
def Generates (g : ContextFreeGrammar.{uN} T) (s : List (Symbol T g.NT)) : Prop :=
  g.Derives [Symbol.nonterminal g.initial] s

/-- The language (set of words) that can be generated by a given context-free grammar `g`. -/
def language (g : ContextFreeGrammar.{uN} T) : Language T :=
  { w | g.Generates (List.map Symbol.terminal w) }

/-- A given word `w` belongs to the language generated by a given context-free grammar `g` iff
`g` can derive the word `w` (wrapped as a string) from the initial nonterminal of `g` in some
number of steps. -/
@[simp]
lemma mem_language_iff (g : ContextFreeGrammar.{uN} T) (w : List T) :
    w ∈ g.language ↔ g.Derives [Symbol.nonterminal g.initial] (List.map Symbol.terminal w) := by
  rfl

variable {g : ContextFreeGrammar.{uN} T}

@[refl]
lemma Derives.refl (w : List (Symbol T g.NT)) : g.Derives w w :=
  Relation.ReflTransGen.refl

lemma Produces.single {v w : List (Symbol T g.NT)} (hvw : g.Produces v w) : g.Derives v w :=
  Relation.ReflTransGen.single hvw

@[trans]
lemma Derives.trans {u v w : List (Symbol T g.NT)} (huv : g.Derives u v) (hvw : g.Derives v w) :
    g.Derives u w :=
  Relation.ReflTransGen.trans huv hvw

lemma Derives.trans_produces {u v w : List (Symbol T g.NT)}
    (huv : g.Derives u v) (hvw : g.Produces v w) :
    g.Derives u w :=
  huv.trans hvw.single

lemma Produces.trans_derives {u v w : List (Symbol T g.NT)}
    (huv : g.Produces u v) (hvw : g.Derives v w) :
    g.Derives u w :=
  huv.single.trans hvw

lemma Derives.eq_or_head {u w : List (Symbol T g.NT)} (huw : g.Derives u w) :
    u = w ∨ ∃ v : List (Symbol T g.NT), g.Produces u v ∧ g.Derives v w :=
  Relation.ReflTransGen.cases_head huw

lemma Derives.eq_or_tail {u w : List (Symbol T g.NT)} (huw : g.Derives u w) :
    u = w ∨ ∃ v : List (Symbol T g.NT), g.Derives u v ∧ g.Produces v w :=
  (Relation.ReflTransGen.cases_tail huw).casesOn (Or.inl ∘ Eq.symm) Or.inr

end ContextFreeGrammar

/-- Context-free languages are defined by context-free grammars. -/
def Language.IsContextFree (L : Language T) : Prop :=
  ∃ g : ContextFreeGrammar.{uT} T, g.language = L

/-- `L.reverse` is a language that contains exactly all words from `L` backwards. -/
def Language.reverse (L : Language T) : Language T := { w : List T | w.reverse ∈ L }

private def reverseRule {N : Type uN} (r : ContextFreeRule T N) : ContextFreeRule T N :=
  ⟨r.input, r.output.reverse⟩

private def reverseGrammar (g : ContextFreeGrammar T) : ContextFreeGrammar T :=
  ⟨g.NT, g.initial, g.rules.map reverseRule⟩

private lemma reverseRule_reverseRule {N : Type uN} (r : ContextFreeRule T N) :
    reverseRule (reverseRule r) = r := by
  simp [reverseRule]

private lemma dual_reverseRule {N : Type uN} : reverseRule ∘ @reverseRule T N = id := by
  ext
  apply reverseRule_reverseRule

private lemma reverseGrammar_reverseGrammar (g : ContextFreeGrammar T) :
    reverseGrammar (reverseGrammar g) = g := by
  cases g with
  | mk => simp [reverseGrammar, dual_reverseRule, List.map_map, List.map_id]

private lemma derives_reverse {g : ContextFreeGrammar T} {s : List (Symbol T g.NT)}
    (hgs : (reverseGrammar g).Derives [Symbol.nonterminal (reverseGrammar g).initial] s) :
    g.Derives [Symbol.nonterminal g.initial] s.reverse := by
  induction hgs with
  | refl =>
    rw [List.reverse_singleton]
    apply ContextFreeGrammar.Derives.refl
  | @tail u v _ orig ih =>
    apply ContextFreeGrammar.Derives.trans_produces ih
    rcases orig with ⟨r, rin, rewr⟩
    simp only [reverseGrammar, List.mem_map] at rin
    rcases rin with ⟨r₀, rin₀, r_of_r₀⟩
    use r₀
    constructor
    · exact rin₀
    rw [ContextFreeRule.rewrites_iff] at rewr ⊢
    rcases rewr with ⟨p, q, rfl, rfl⟩
    use q.reverse, p.reverse
    rw [← r_of_r₀]
    simp [reverseRule]

private lemma reversed_word_in_original_language {g : ContextFreeGrammar T} {w : List T}
    (hgw : w ∈ (reverseGrammar g).language) :
    w.reverse ∈ g.language := by
  convert derives_reverse hgw
  simp [List.map_reverse]

/-- The class of context-free languages is closed under reversal. -/
theorem Language.IsContextFree.reverse {L : Language T} (CFL : L.IsContextFree) :
    L.reverse.IsContextFree := by
  cases CFL with
  | intro g hgL =>
    rw [← hgL]
    use reverseGrammar g
    apply Set.eq_of_subset_of_subset
    · intro w hwg
      exact reversed_word_in_original_language hwg
    · intro w hwg
      have pre_reversal : ∃ g₀, g = reverseGrammar g₀
      · use reverseGrammar g
        rw [reverseGrammar_reverseGrammar]
      cases' pre_reversal with g₀ pre_rev
      rw [pre_rev] at hwg ⊢
      have finished_modulo_reverses := reversed_word_in_original_language hwg
      rw [reverseGrammar_reverseGrammar]
      rw [List.reverse_reverse] at finished_modulo_reverses
      exact finished_modulo_reverses
