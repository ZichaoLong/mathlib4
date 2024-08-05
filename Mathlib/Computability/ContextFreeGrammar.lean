/-
Copyright (c) 2023 Martin Dvorak. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Martin Dvorak
-/
import Mathlib.Computability.Language

/-!
# Context-Free Grammars

This file contains the definition of a context-free grammar, which is a grammar that has a single
nonterminal symbol on the left-hand side of each rule. Then we prove some closure properties.

## Main definitions
* `ContextFreeGrammar`: A context-free grammar.
* `ContextFreeGrammar.language`: A language generated by a given context-free grammar.

## Main theorems
* `Language.IsContextFree.reverse`: The class of context-free languages is closed under reversal.
* `Language.IsContextFree.union`: The class of context-free languages is closed under union.
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
    (hr : r.Rewrites u v) :
    ∃ p q : List (Symbol T N),
      u = p ++ [Symbol.nonterminal r.input] ++ q ∧ v = p ++ r.output ++ q := by
  induction hr with
  | head s =>
    use [], s
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

/-- Add extra prefix to context-free rewriting. -/
lemma Rewrites.append_left {r : ContextFreeRule T N} {v w : List (Symbol T N)}
    (hvw : r.Rewrites v w) (p : List (Symbol T N)) : r.Rewrites (p ++ v) (p ++ w) := by
  rw [rewrites_iff] at *
  rcases hvw with ⟨x, y, hxy⟩
  use p ++ x, y
  simp_all

/-- Add extra postfix to context-free rewriting. -/
lemma Rewrites.append_right {r : ContextFreeRule T N} {v w : List (Symbol T N)}
    (hvw : r.Rewrites v w) (p : List (Symbol T N)) : r.Rewrites (v ++ p) (w ++ p) := by
  rw [rewrites_iff] at *
  rcases hvw with ⟨x, y, hxy⟩
  use x, y ++ p
  simp_all

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

/-- Add extra prefix to context-free producing. -/
lemma Produces.append_left {v w : List (Symbol T g.NT)}
    (hvw : g.Produces v w) (p : List (Symbol T g.NT)) :
    g.Produces (p ++ v) (p ++ w) :=
  match hvw with | ⟨r, hrmem, hrvw⟩ => ⟨r, hrmem, hrvw.append_left p⟩

/-- Add extra postfix to context-free producing. -/
lemma Produces.append_right {v w : List (Symbol T g.NT)}
    (hvw : g.Produces v w) (p : List (Symbol T g.NT)) :
    g.Produces (v ++ p) (w ++ p) :=
  match hvw with | ⟨r, hrmem, hrvw⟩ => ⟨r, hrmem, hrvw.append_right p⟩

/-- Add extra prefix to context-free deriving. -/
lemma Derives.append_left {v w : List (Symbol T g.NT)}
    (hvw : g.Derives v w) (p : List (Symbol T g.NT)) :
    g.Derives (p ++ v) (p ++ w) := by
  induction hvw with
  | refl => rfl
  | tail _ last ih => exact ih.trans_produces <| last.append_left p

/-- Add extra postfix to context-free deriving. -/
lemma Derives.append_right {v w : List (Symbol T g.NT)}
    (hvw : g.Derives v w) (p : List (Symbol T g.NT)) :
    g.Derives (v ++ p) (w ++ p) := by
  induction hvw with
  | refl => rfl
  | tail _ last ih => exact ih.trans_produces <| last.append_right p

end ContextFreeGrammar

/-- Context-free languages are defined by context-free grammars. -/
def Language.IsContextFree (L : Language T) : Prop :=
  ∃ g : ContextFreeGrammar.{uT} T, g.language = L

section closure_reversal

/-- Rules for a grammar for a reversed language. -/
def ContextFreeRule.reverse {N : Type uN} (r : ContextFreeRule T N) : ContextFreeRule T N :=
  ⟨r.input, r.output.reverse⟩

/-- Grammar for a reversed language. -/
def ContextFreeGrammar.reverse (g : ContextFreeGrammar T) : ContextFreeGrammar T :=
  ⟨g.NT, g.initial, g.rules.map .reverse⟩

lemma ContextFreeRule.reverse_involutive {N : Type uN} :
    Function.Involutive (@ContextFreeRule.reverse T N) := by
  intro x
  simp [ContextFreeRule.reverse]

lemma ContextFreeGrammar.reverse_involutive :
    Function.Involutive (@ContextFreeGrammar.reverse T) := by
  intro x
  simp [ContextFreeGrammar.reverse, ContextFreeRule.reverse_involutive]

lemma ContextFreeGrammar.reverse_derives (g : ContextFreeGrammar T) {s : List (Symbol T g.NT)}
    (hgs : g.reverse.Derives [Symbol.nonterminal g.reverse.initial] s) :
    g.Derives [Symbol.nonterminal g.initial] s.reverse := by
  induction hgs with
  | refl =>
    rw [List.reverse_singleton]
    apply ContextFreeGrammar.Derives.refl
  | tail _ orig ih =>
    apply ContextFreeGrammar.Derives.trans_produces ih
    obtain ⟨r, rin, rewr⟩ := orig
    simp only [ContextFreeGrammar.reverse, List.mem_map] at rin
    obtain ⟨r₀, rin₀, rfl⟩ := rin
    refine ⟨r₀, rin₀, ?_⟩
    rw [ContextFreeRule.rewrites_iff] at rewr ⊢
    rcases rewr with ⟨p, q, rfl, rfl⟩
    use q.reverse, p.reverse
    simp [ContextFreeRule.reverse]

lemma ContextFreeGrammar.reverse_mem_language_of_mem_reverse_language (g : ContextFreeGrammar T)
    {w : List T} (hgw : w ∈ g.reverse.language) :
    w.reverse ∈ g.language := by
  convert g.reverse_derives hgw
  simp [List.map_reverse]

lemma ContextFreeGrammar.mem_reverse_language_iff_reverse_mem_language (g : ContextFreeGrammar T)
    (w : List T) :
    w ∈ g.reverse.language ↔ w.reverse ∈ g.language := by
  refine ⟨reverse_mem_language_of_mem_reverse_language _, fun hw => ?_⟩
  rw [← ContextFreeGrammar.reverse_involutive g] at hw
  rw [← List.reverse_reverse w]
  exact g.reverse.reverse_mem_language_of_mem_reverse_language hw

/-- The class of context-free languages is closed under reversal. -/
theorem Language.IsContextFree.reverse (L : Language T) :
    L.IsContextFree → L.reverse.IsContextFree :=
  fun ⟨g, hg⟩ => ⟨g.reverse, hg ▸ Set.ext g.mem_reverse_language_iff_reverse_mem_language⟩

end closure_reversal

section lift_sink

/- This section contains only auxilliary constructions that will shorten upcoming proofs of
closure properties. When combining several grammars together, we usually want to take a sum type of
their nonterminal types and lift respective nonterminals to this sum type. We subsequently show
that the resulting grammar preserves derivations of those strings that may contain any terminals but
only the proper nonterminals. The lifting operation must be injective. The sinking operation must be
injective on those symbols where it is defined. -/

/-- Lifting `Symbol` to a larger nonterminal type. -/
def liftSymbol {N₀ N : Type*} (liftN : N₀ → N) : Symbol T N₀ → Symbol T N
  | Symbol.terminal t => Symbol.terminal t
  | Symbol.nonterminal n => Symbol.nonterminal (liftN n)

/-- Sinking `Symbol` from a larger nonterminal type; may return `none`. -/
def sinkSymbol {N₀ N : Type*} (sinkN : N → Option N₀) : Symbol T N → Option (Symbol T N₀)
  | Symbol.terminal t => some (Symbol.terminal t)
  | Symbol.nonterminal n => Option.map Symbol.nonterminal (sinkN n)

/-- Lifting `List Symbol` to a larger nonterminal type. -/
def Symbol.liftString {N₀ N : Type*} (liftN : N₀ → N) :
    List (Symbol T N₀) → List (Symbol T N) :=
  List.map (liftSymbol liftN)

lemma Symbol.liftString_all_terminals {N₀ N : Type*} (liftN : N₀ → N) (w : List T) :
    Symbol.liftString liftN (w.map Symbol.terminal) = w.map Symbol.terminal := by
  induction w with
  | nil => rfl
  | cons t _ ih => exact congr_arg (Symbol.terminal t :: ·) ih

/-- Sinking `List Symbol` from a larger nonterminal type; may skip some elements. -/
def Symbol.sinkString {N₀ N : Type*} (sinkN : N → Option N₀) :
    List (Symbol T N) → List (Symbol T N₀) :=
  List.filterMap (sinkSymbol sinkN)

lemma Symbol.sinkString_all_terminals {N₀ N : Type*} (sinkN : N → Option N₀) (w : List T) :
    Symbol.sinkString sinkN (w.map Symbol.terminal) = w.map Symbol.terminal := by
  induction w with
  | nil => rfl
  | cons t _ ih => exact congr_arg (Symbol.terminal t :: ·) ih

/-- Lifting `ContextFreeRule` to a larger nonterminal type. -/
def ContextFreeRule.lift {N₀ N : Type*} (r : ContextFreeRule T N₀) (liftN : N₀ → N) :
    ContextFreeRule T N :=
  ⟨liftN r.input, Symbol.liftString liftN r.output⟩

/-- Lifting `ContextFreeGrammar` to a larger nonterminal type. -/
structure LiftedContextFreeGrammar (T : Type uT) where
  /-- The smaller grammar. -/
  g₀: ContextFreeGrammar.{uN} T
  /-- The bigger grammar. -/
  g : ContextFreeGrammar.{uN} T
  /-- Mapping nonterminals from the smaller type to the bigger type. -/
  liftNT : g₀.NT → g.NT
  /-- Mapping nonterminals from the bigger type to the smaller type. -/
  sinkNT : g.NT → Option g₀.NT
  /-- The former map is injective. -/
  lift_inj : Function.Injective liftNT
  /-- The latter map is injective where defined. -/
  sink_inj : ∀ x y, sinkNT x = sinkNT y → x = y ∨ sinkNT x = none
  /-- The two mappings are essentially inverses. -/
  sinkNT_liftNT : ∀ n₀ : g₀.NT, sinkNT (liftNT n₀) = some n₀
  /-- Each rule of the smaller grammar has a corresponding rule in the bigger grammar. -/
  corresponding_rules : ∀ r : ContextFreeRule T g₀.NT, r ∈ g₀.rules → r.lift liftNT ∈ g.rules
  /-- Each rule of the bigger grammar whose input nonterminal the smaller grammar recognizes
      has a corresponding rule in the smaller grammar. -/
  preimage_of_rules :
    ∀ r : ContextFreeRule T g.NT,
      (r ∈ g.rules ∧ ∃ n₀ : g₀.NT, liftNT n₀ = r.input) →
        (∃ r₀ ∈ g₀.rules, r₀.lift liftNT = r)

lemma LiftedContextFreeGrammar.sinkNT_inverse_liftNT (G : LiftedContextFreeGrammar T) :
    ∀ x : G.g.NT, (∃ n₀, G.sinkNT x = some n₀) → (Option.map G.liftNT (G.sinkNT x) = x) := by
  intro x ⟨n₀, hx⟩
  rw [hx, Option.map_some']
  apply congr_arg
  by_contra hnx
  cases (G.sinkNT_liftNT n₀ ▸ G.sink_inj x (G.liftNT n₀)) hx with
  | inl case_valu => exact hnx case_valu.symm
  | inr case_none => exact Option.noConfusion (hx ▸ case_none)

lemma LiftedContextFreeGrammar.lift_produces {G : LiftedContextFreeGrammar T}
    {w₁ w₂ : List (Symbol T G.g₀.NT)} (hG : G.g₀.Produces w₁ w₂) :
    G.g.Produces (Symbol.liftString G.liftNT w₁) (Symbol.liftString G.liftNT w₂) := by
  rcases hG with ⟨r, rin, hr⟩
  rcases hr.exists_parts with ⟨u, v, bef, aft⟩
  refine ⟨r.lift G.liftNT, G.corresponding_rules r rin, ?_⟩
  rw [ContextFreeRule.rewrites_iff]
  use Symbol.liftString G.liftNT u, Symbol.liftString G.liftNT v
  constructor
  · simpa only [Symbol.liftString, List.map_append] using congr_arg (Symbol.liftString G.liftNT) bef
  · simpa only [Symbol.liftString, List.map_append] using congr_arg (Symbol.liftString G.liftNT) aft

/-- Derivation by `G.g₀` can be mirrored by `G.g` derivation. -/
lemma LiftedContextFreeGrammar.lift_derives {G : LiftedContextFreeGrammar T}
    {w₁ w₂ : List (Symbol T G.g₀.NT)} (hG : G.g₀.Derives w₁ w₂) :
    G.g.Derives (Symbol.liftString G.liftNT w₁) (Symbol.liftString G.liftNT w₂) := by
  induction hG with
  | refl => rfl
  | tail _ orig ih => exact ih.trans_produces (lift_produces orig)

/-- A `Symbol` is good iff it is one of those nonterminals that result from sinking or it is any
terminal. -/
def LiftedContextFreeGrammar.GoodLetter {G : LiftedContextFreeGrammar T} : Symbol T G.g.NT → Prop
  | Symbol.terminal _ => True
  | Symbol.nonterminal n => ∃ n₀ : G.g₀.NT, G.sinkNT n = n₀

/-- A string is good iff every `Symbol` in it is good. -/
def LiftedContextFreeGrammar.GoodString {G : LiftedContextFreeGrammar T}
    (s : List (Symbol T G.g.NT)) : Prop :=
  ∀ a ∈ s, GoodLetter a

lemma LiftedContextFreeGrammar.singletonGoodString {G : LiftedContextFreeGrammar T}
    {s : Symbol T G.g.NT} (hs : G.GoodLetter s) : G.GoodString [s] := by
  simpa [GoodString] using hs

lemma LiftedContextFreeGrammar.sink_produces {G : LiftedContextFreeGrammar T}
    {w₁ w₂ : List (Symbol T G.g.NT)} (hG : G.g.Produces w₁ w₂) (hw₁ : GoodString w₁) :
    G.g₀.Produces (Symbol.sinkString G.sinkNT w₁) (Symbol.sinkString G.sinkNT w₂) ∧
      GoodString w₂ := by
  rcases hG with ⟨r, rin, hr⟩
  rcases hr.exists_parts with ⟨u, v, bef, aft⟩
  rw [bef] at hw₁
  rcases G.preimage_of_rules r (by
      obtain ⟨n₀, hn₀⟩ : GoodLetter (Symbol.nonterminal r.input) := by apply hw₁; simp
      refine ⟨rin, n₀, ?_⟩
      simpa [G.sinkNT_inverse_liftNT r.input ⟨n₀, hn₀⟩, Option.map_some'] using
        congr_arg (Option.map G.liftNT) hn₀.symm)
    with ⟨r₀, hr₀, hrr₀⟩
  constructor
  · refine ⟨r₀, hr₀, ?_⟩
    rw [ContextFreeRule.rewrites_iff]
    use Symbol.sinkString G.sinkNT u, Symbol.sinkString G.sinkNT v
    have correct_inverse : sinkSymbol (T := T) G.sinkNT ∘ liftSymbol G.liftNT = Option.some := by
      ext1 x
      cases x
      · rfl
      rw [Function.comp_apply]
      simp only [sinkSymbol, liftSymbol, Option.map_eq_some', Symbol.nonterminal.injEq]
      rw [exists_eq_right]
      apply G.sinkNT_liftNT
    constructor
    · have middle :
        List.filterMap (sinkSymbol (T := T) G.sinkNT) [Symbol.nonterminal (G.liftNT r₀.input)] =
          [Symbol.nonterminal r₀.input] := by
        simp [sinkSymbol, G.sinkNT_liftNT]
      simpa only [Symbol.sinkString, List.filterMap_append, ContextFreeRule.lift,
        ← hrr₀, middle] using congr_arg (Symbol.sinkString G.sinkNT) bef
    · simpa only [Symbol.sinkString, List.filterMap_append, ContextFreeRule.lift,
        Symbol.liftString, List.filterMap_map, List.filterMap_some,
        ← hrr₀, correct_inverse] using congr_arg (Symbol.sinkString G.sinkNT) aft
  · rw [aft, ← hrr₀]
    simp only [GoodString, List.forall_mem_append] at hw₁ ⊢
    refine ⟨⟨hw₁.left.left, ?_⟩, hw₁.right⟩
    intro a ha
    cases a
    · simp [GoodLetter]
    dsimp only [ContextFreeRule.lift, Symbol.liftString] at ha
    rw [List.mem_map] at ha
    rcases ha with ⟨s, -, hs⟩
    rw [← hs]
    cases s with
    | terminal _ => exact False.elim (Symbol.noConfusion hs)
    | nonterminal s' => exact ⟨s', G.sinkNT_liftNT s'⟩

lemma LiftedContextFreeGrammar.sink_derives_aux {G : LiftedContextFreeGrammar T}
    {w₁ w₂ : List (Symbol T G.g.NT)} (hG : G.g.Derives w₁ w₂) (hw₁ : GoodString w₁) :
    G.g₀.Derives (Symbol.sinkString G.sinkNT w₁) (Symbol.sinkString G.sinkNT w₂) ∧
      GoodString w₂ := by
  induction hG with
  | refl => exact ⟨by rfl, hw₁⟩
  | tail _ orig ih =>
    have both := sink_produces orig ih.right
    exact ⟨ContextFreeGrammar.Derives.trans_produces ih.left both.left, both.right⟩

/-- Derivation by `G.g` can be mirrored by `G.g₀` derivation if the starting word does not contain
any nonterminals that `G.g₀` lacks. -/
lemma LiftedContextFreeGrammar.sink_derives (G : LiftedContextFreeGrammar T)
    {w₁ w₂ : List (Symbol T G.g.NT)} (hG : G.g.Derives w₁ w₂) (hw₁ : GoodString w₁) :
    G.g₀.Derives (Symbol.sinkString G.sinkNT w₁) (Symbol.sinkString G.sinkNT w₂) :=
  (sink_derives_aux hG hw₁).left

end lift_sink

section closure_union

/-- Grammar for a union of two context-free languages. -/
def ContextFreeGrammar.union (g₁ g₂ : ContextFreeGrammar T) : ContextFreeGrammar T :=
  ContextFreeGrammar.mk (Option (g₁.NT ⊕ g₂.NT)) none (
    ⟨none, [Symbol.nonterminal (some (Sum.inl g₁.initial))]⟩ :: (
    ⟨none, [Symbol.nonterminal (some (Sum.inr g₂.initial))]⟩ :: (
    List.map (ContextFreeRule.lift · (Option.some ∘ Sum.inl)) g₁.rules ++
    List.map (ContextFreeRule.lift · (Option.some ∘ Sum.inr)) g₂.rules)))

section union_aux

/-- The only interesting declaration in this subsection is the lemma
`ContextFreeGrammar.mem_union_language_iff_mem_or_mem` towards which the whole section builds.
Ignore everything else. -/

private lemma both_empty {u v : List T} {a b : T} (ha : [a] = u ++ [b] ++ v) :
    u = [] ∧ v = [] := by
  cases u <;> cases v <;> simp at ha; trivial

variable {g₁ g₂ : ContextFreeGrammar.{uT} T}

private def oN₁_of_N : (g₁.union g₂).NT → Option g₁.NT
  | none => none
  | some (Sum.inl n) => some n
  | some (Sum.inr _) => none

private def oN₂_of_N : (g₁.union g₂).NT → Option g₂.NT
  | none => none
  | some (Sum.inl _) => none
  | some (Sum.inr n) => some n

private def g₁g : LiftedContextFreeGrammar T :=
  ⟨g₁, g₁.union g₂, some ∘ Sum.inl, oN₁_of_N,
    (fun x y hxy => Sum.inl_injective (Option.some_injective _ hxy)),
    (by
      intro x y hxy
      cases x with
      | none => right; rfl;
      | some x₀ =>
        cases y with
        | none => right; exact hxy
        | some y₀ =>
          cases x₀ with
          | inl =>
            cases y₀ with
            | inl =>
              simp only [oN₁_of_N, Option.some.injEq] at hxy
              left
              rw [hxy]
            | inr =>
              exfalso
              simp [oN₁_of_N] at hxy
          | inr =>
            cases y₀ with
            | inl =>
              exfalso
              simp [oN₁_of_N] at hxy
            | inr =>
              right
              rfl),
    (fun _ => rfl),
    (by
      intro r _
      apply List.mem_cons_of_mem
      apply List.mem_cons_of_mem
      apply List.mem_append_left
      rw [List.mem_map]
      use r),
    (by
      intro r ⟨hr, ⟨n₀, imposs⟩⟩
      cases hr with
      | head =>
        exfalso
        exact Option.noConfusion imposs
      | tail _ hr =>
        cases hr with
        | head =>
          exfalso
          exact Option.noConfusion imposs
        | tail _ hr =>
          change r ∈ List.map _ g₁.rules ++ List.map _ g₂.rules at hr
          rw [List.mem_append] at hr
          cases hr with
          | inl hr =>
            rw [List.mem_map] at hr
            exact hr
          | inr hr =>
            exfalso
            rw [List.mem_map] at hr
            rcases hr with ⟨_, -, rfl⟩
            simp only [ContextFreeRule.lift, Function.comp_apply] at imposs
            rw [Option.some_inj] at imposs
            exact Sum.noConfusion imposs)⟩

private def g₂g : LiftedContextFreeGrammar T :=
  ⟨g₂, g₁.union g₂, some ∘ Sum.inr, oN₂_of_N,
    (fun x y hxy => Sum.inr_injective (Option.some_injective _ hxy)),
    (by
      intro x y hxy
      cases x with
      | none => right; rfl;
      | some x₀ =>
        cases y with
        | none => right; exact hxy
        | some y₀ =>
          cases x₀ with
          | inl =>
            cases y₀ with
            | inl =>
              right
              rfl
            | inr =>
              exfalso
              simp [oN₂_of_N] at hxy
          | inr =>
            cases y₀ with
            | inl =>
              exfalso
              simp [oN₂_of_N] at hxy
            | inr =>
              simp only [oN₂_of_N, Option.some.injEq] at hxy
              left
              rw [hxy]),
    (fun _ => rfl),
    (by
      intro r _
      apply List.mem_cons_of_mem
      apply List.mem_cons_of_mem
      apply List.mem_append_right
      rw [List.mem_map]
      use r),
    (by
      intro r ⟨hr, ⟨n₀, imposs⟩⟩
      cases hr with
      | head =>
        exfalso
        exact Option.noConfusion imposs
      | tail _ hr =>
        cases hr with
        | head =>
          exfalso
          exact Option.noConfusion imposs
        | tail _ hr =>
          change r ∈ List.map _ g₁.rules ++ List.map _ g₂.rules at hr
          rw [List.mem_append] at hr
          cases hr with
          | inl hr =>
            exfalso
            rw [List.mem_map] at hr
            rcases hr with ⟨_, -, rfl⟩
            simp only [ContextFreeRule.lift, Function.comp_apply] at imposs
            rw [Option.some_inj] at imposs
            exact Sum.noConfusion imposs
          | inr hr =>
            rw [List.mem_map] at hr
            exact hr)⟩

variable {w : List T}

private lemma in_union_of_in_left (hw : w ∈ g₁.language) :
    w ∈ (g₁.union g₂).language :=
  have derives_left_initial : (g₁.union g₂).Derives [Symbol.nonterminal none]
      [Symbol.nonterminal (some (Sum.inl g₁.initial))] := by
    refine ContextFreeGrammar.Produces.single
      ⟨⟨none, [Symbol.nonterminal (some (Sum.inl g₁.initial))]⟩, List.mem_cons_self .., ?_⟩
    rw [ContextFreeRule.rewrites_iff]
    use [], []
    simp
  derives_left_initial.trans (Symbol.liftString_all_terminals g₁g.liftNT w ▸ g₁g.lift_derives hw)

private lemma in_union_of_in_right (hw : w ∈ g₂.language) :
    w ∈ (g₁.union g₂).language :=
  have derives_right_initial :
    (g₁.union g₂).Derives [Symbol.nonterminal none]
      [Symbol.nonterminal (some (Sum.inr g₂.initial))] := by
    refine ContextFreeGrammar.Produces.single
      ⟨⟨none, [Symbol.nonterminal (some (Sum.inr g₂.initial))]⟩,
        List.mem_cons_of_mem _ (List.mem_cons_self ..), ?_⟩
    rw [ContextFreeRule.rewrites_iff]
    use [], []
    simp
  derives_right_initial.trans (Symbol.liftString_all_terminals g₂g.liftNT w ▸ g₂g.lift_derives hw)

private lemma in_left_of_in_union (hw :
    (g₁.union g₂).Derives
      [Symbol.nonterminal (some (Sum.inl g₁.initial))]
      (List.map Symbol.terminal w)) :
    w ∈ g₁.language := by
  apply Symbol.sinkString_all_terminals g₁g.sinkNT w ▸ g₁g.sink_derives hw
  apply LiftedContextFreeGrammar.singletonGoodString
  constructor
  rfl

private lemma in_right_of_in_union (hw :
    (g₁.union g₂).Derives
      [Symbol.nonterminal (some (Sum.inr g₂.initial))]
      (List.map Symbol.terminal w)) :
    w ∈ g₂.language := by
  apply Symbol.sinkString_all_terminals g₂g.sinkNT w ▸ g₂g.sink_derives hw
  apply LiftedContextFreeGrammar.singletonGoodString
  constructor
  rfl

private lemma impossible_rule {r : ContextFreeRule T (g₁.union g₂).NT}
    (hg : [Symbol.nonterminal (g₁.union g₂).initial] =
      ([] : List (Symbol T (g₁.union g₂).NT)) ++ [Symbol.nonterminal r.input] ++
      ([] : List (Symbol T (g₁.union g₂).NT)))
    (hr : r ∈
      List.map (ContextFreeRule.lift · (Option.some ∘ Sum.inl)) g₁.rules ++
      List.map (ContextFreeRule.lift · (Option.some ∘ Sum.inr)) g₂.rules) :
    False := by
  have rule_root : none = r.input := Symbol.nonterminal.inj (List.head_eq_of_cons_eq hg)
  rw [List.mem_append] at hr
  cases hr with
  | inl hr' =>
    rw [List.mem_map] at hr'
    rcases hr' with ⟨_, -, rfl⟩
    exact Option.noConfusion rule_root
  | inr hr' =>
    rw [List.mem_map] at hr'
    rcases hr' with ⟨_, -, rfl⟩
    exact Option.noConfusion rule_root

private lemma in_language_of_in_union (hw : w ∈ (g₁.union g₂).language) :
    w ∈ g₁.language ∨ w ∈ g₂.language := by
  cases hw.eq_or_head with
  | inl impossible =>
    exfalso
    have h0 := congr_arg (List.get? · 0) impossible
    simp only [List.get?_map] at h0
    cases hw0 : w.get? 0 with
    | none => exact Option.noConfusion (hw0 ▸ h0)
    | some => exact Symbol.noConfusion (Option.some.inj (hw0 ▸ h0))
  | inr hv =>
    rcases hv with ⟨_, ⟨r, hr, hrr⟩, hg⟩
    rcases hrr.exists_parts with ⟨u, v, huv, rfl⟩
    rcases both_empty huv with ⟨rfl, rfl⟩
    cases hr with
    | head =>
      left
      exact in_left_of_in_union hg
    | tail _ hr' =>
      cases hr' with
      | head =>
        right
        exact in_right_of_in_union hg
      | tail _ hr'' =>
        exfalso
        exact impossible_rule huv hr''

lemma ContextFreeGrammar.mem_union_language_iff_mem_or_mem :
    w ∈ (g₁.union g₂).language ↔ w ∈ g₁.language ∨ w ∈ g₂.language :=
  ⟨in_language_of_in_union, fun hw => hw.elim in_union_of_in_left in_union_of_in_right⟩

end union_aux

/-- The class of context-free languages is closed under union. -/
theorem Language.IsContextFree.union {L₁ L₂ : Language T} :
    L₁.IsContextFree → L₂.IsContextFree → (L₁ + L₂).IsContextFree := by
  rintro ⟨g₁, rfl⟩ ⟨g₂, rfl⟩
  exact ⟨g₁.union g₂, Set.ext (fun _ =>
    ContextFreeGrammar.mem_union_language_iff_mem_or_mem)⟩

end closure_union
