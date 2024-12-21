import Mathlib.Combinatorics.SimpleGraph.Clique
import Mathlib.Combinatorics.SimpleGraph.CompletePartite

open Finset
variable {α : Type*}[DecidableEq α]
/-- Useful trivial fact about when |{a,b,c,d}| ≤ 2 given a ≠ b , a ≠ d, b ≠ c  -/
lemma Finset.card_le_two_of_four {a b c d : α} (hab : a ≠ b) (had : a ≠ d) (hbc : b ≠ c)
(hc2: card {a,b,c,d} ≤ 2): c = a ∧ d = b:=by
  by_contra! hf
  apply (card {a, b, c, d}).le_lt_asymm hc2 <| two_lt_card_iff.2 _
  by_cases hac: a = c <;> simp only [mem_insert,mem_singleton]
  · exact ⟨a,b,d,Or.inl rfl, Or.inr <| Or.inl rfl,Or.inr <| Or.inr <| Or.inr rfl,hab,had,
      fun hbd => (hf hac.symm) hbd.symm⟩
  · exact ⟨a,b,c,Or.inl rfl,Or.inr <| Or.inl rfl,Or.inr <| Or.inr <| Or.inl rfl,hab,hac,hbc⟩

namespace SimpleGraph
variable (G : SimpleGraph α) {r : ℕ }
/-- A IsWheel r structure in G is 3 vertices and two r-sets such that... -/
structure IsWheel (r : ℕ) (v w₁ w₂ : α) (s t : Finset α) : Prop where
  IsP2Compl : G.IsP2Compl v w₁ w₂ -- w₁w₂ ∈ E(G) but vw₁,vw₂ ∉ E(G)
  disj : v ∉ s ∧ v ∉ t ∧ w₁ ∉ s ∧ w₂ ∉ t -- v ∉ s,t and w₁ ∉ t and w₂ ∉ s
  cliques : G.IsNClique (r + 1) (insert v s) ∧ G.IsNClique (r + 1) (insert w₁ s)
          ∧ G.IsNClique (r + 1) (insert v t) ∧ G.IsNClique (r + 1) (insert w₂ t)

variable {G}
/-- If G contains a IsP2Compl and is maximal Kᵣ₊₂-free then we have a wheel like graph -/
lemma exists_IsWheel (h : G.MaxCliqueFree (r + 2))  (hnc : ¬ G.IsCompletePartite) :
    ∃ v w₁ w₂ s t, G.IsWheel r v w₁ w₂ s t :=by
  obtain ⟨v,w₁,w₂,h3⟩:=G.IsP2Compl_of_not_completePartite hnc
  obtain ⟨s,hvs,hw1s,hcsv,hcsw1⟩:=h.exists_of_not_adj h3.ne.1 h3.nonedge.1
  obtain ⟨t,hvt,hw2t,hctv,hctw2⟩:=h.exists_of_not_adj h3.ne.2 h3.nonedge.2
  exact ⟨v,w₁,w₂,s,t,h3,⟨hvs,hvt,hw1s,hw2t⟩,⟨hcsv,hcsw1,hctv,hctw2⟩⟩

namespace IsWheel
variable {x v w₁ w₂ : α} {s t : Finset α}
variable (hw : G.IsWheel r v w₁ w₂ s t) include hw
lemma symm :  G.IsWheel r v w₂ w₁ t s := by
  obtain ⟨p2,⟨d1,d2,d3,d4⟩,⟨c1,c2,c3,c4⟩⟩:=hw
  exact ⟨p2.symm,⟨d2,d1,d4,d3⟩,⟨c3,c4,c1,c2⟩⟩

/-- We automatically have w₁ ∉ t and w₂ ∉ s for any wheel -/
lemma disj' : w₁ ∉ t ∧ w₂ ∉ s:=by
  constructor <;> intro hf
  · apply hw.IsP2Compl.nonedge.1 <| hw.cliques.2.2.1.1 (mem_insert_self _ _) ( mem_insert_of_mem hf)
       (hw.IsP2Compl.ne.1)
  · apply hw.IsP2Compl.nonedge.2 <| hw.cliques.1.1 (mem_insert_self _ _) ( mem_insert_of_mem hf)
        (hw.IsP2Compl.ne.2)

lemma card_cliques : s.card = r ∧ t.card = r:=by
  constructor
  · have :=hw.cliques.1.2
    rwa [card_insert_of_not_mem hw.disj.1,Nat.succ_inj] at this
  · have :=hw.cliques.2.2.1.2
    rwa [card_insert_of_not_mem hw.disj.2.1,Nat.succ_inj] at this

/-- The vertex set of the Wheel -/
@[reducible]
def verts (_hw : G.IsWheel r v w₁ w₂ s t) : Finset α := (insert v (insert w₁ (insert w₂ (s ∪ t))))

/-- Helper lemma to show x ∈ W -/
lemma mem_verts : x ∈ insert w₁ s ∨ x ∈ insert w₂ t ∨ x ∈ insert v s ∨ x ∈ insert v t ↔ x ∈ hw.verts
  :=by aesop

/-- vertices of IsP2Compl are in W -/
lemma mem_verts_IsP2Compl  : v ∈ hw.verts ∧ w₁ ∈ hw.verts ∧ w₂ ∈ hw.verts:=by
  simp only [←mem_verts,mem_insert]; tauto

/-- A wheel consists of the 3 vertices v, w₁, w₂, and the r-sets s , t but the size will vary
depending on how large |s ∩ t| is, so a useful identity is
#verts in Wheel =  |s ∪ t| + 3 = 2r + 3 - |s ∩ t|, which we express without subtraction -/
lemma card_verts_add_inter  : card hw.verts + card (s ∩ t) = 2 * r + 3:=by
  rw [verts, card_insert_of_not_mem, add_comm, card_insert_of_not_mem,card_insert_of_not_mem]
  · simp only [←add_assoc,card_inter_add_card_union,two_mul,hw.card_cliques.1,hw.card_cliques.2]
  · rw [mem_union,not_or]
    exact ⟨hw.disj'.2, hw.disj.2.2.2⟩
  · rw [mem_insert,mem_union,not_or,not_or]
    exact ⟨hw.IsP2Compl.edge.ne ,hw.disj.2.2.1,hw.disj'.1 ⟩
  · rw [mem_insert,mem_insert,mem_union]
    push_neg
    exact ⟨hw.IsP2Compl.ne.1,hw.IsP2Compl.ne.2, hw.disj.1,hw.disj.2.1⟩

/-- Every wheel contains at least 3 vertices: v w₁ w₂-/
lemma three_le_card_verts : 3 ≤ hw.verts.card := two_lt_card.2
  ⟨v,hw.mem_verts_IsP2Compl.1,w₁,hw.mem_verts_IsP2Compl.2.1,w₂,
  hw.mem_verts_IsP2Compl.2.2,hw.IsP2Compl.ne.1,hw.IsP2Compl.ne.2,hw.IsP2Compl.edge.ne⟩

/-- If s ∩ t contains an r-set then together with w₁ and w₂ it contains a copy of K_r + 2.
This implies a bound on k for any W_r,k in a K_r + 2 - free graph -/
lemma card_clique_free (h : G.CliqueFree (r + 2)) : card (s ∩ t) < r:=by
  contrapose! h
  have hs : s ∩ t = s :=eq_of_subset_of_card_le inter_subset_left (hw.card_cliques.1 ▸ h)
  have ht : s ∩ t = t :=eq_of_subset_of_card_le inter_subset_right (hw.card_cliques.2 ▸ h)
  exact (hw.cliques.2.1.insert_insert  (hs ▸ ht.symm ▸ hw.cliques.2.2.2)
    hw.disj'.2 hw.IsP2Compl.edge).not_cliqueFree

omit hw in
/-- If G is maximally Kᵣ₊₂-free and not complete partite then it contains a maximal wheel -/
lemma _root_.SimpleGraph.exists_max_wheel (h: G.MaxCliqueFree (r + 2)) (hnc : ¬ G.IsCompletePartite)
: ∃ v w₁ w₂ s t, G.IsWheel r v w₁ w₂ s t ∧ ∀ s' t', G.IsWheel r v w₁ w₂ s' t' →
  (card (s' ∩ t')) ≤ card (s ∩ t):= by
  classical
  obtain ⟨v,w₁,w₂,s,t,hw⟩:=exists_IsWheel h hnc
  let P : ℕ → Prop := fun k => ∃ s t, G.IsWheel r v w₁ w₂ s t ∧ card (s ∩ t) = k
  have : P (card (s ∩ t)) := by use s,t
  have nler := (hw.card_clique_free h.1).le
  obtain ⟨s,t,hw⟩:= Nat.findGreatest_spec nler this
  use v,w₁,w₂,s,t,hw.1
  intro s' t' hw'
  apply (Nat.le_findGreatest (hw'.card_clique_free h.1).le (by use s',t')).trans (hw.2.symm.le)

/- If x ∈ V(G) there exist a b c d non-neighbours of x such that ...  -/
lemma exist_non_adj (h: G.CliqueFree (r + 2)) (x : α): ∃ a b c d, a ∈ insert w₁ s ∧ ¬G.Adj x a ∧
    b ∈ insert w₂ t ∧ ¬G.Adj x b ∧ c ∈ insert v s ∧ ¬G.Adj x c ∧ d ∈ insert v t ∧ ¬G.Adj x d:=by
  obtain ⟨a,ha1,ha2⟩:=hw.cliques.2.1.exists_non_adj_of_cliqueFree_succ h x
  obtain ⟨b,hb1,hb2⟩:=hw.cliques.2.2.2.exists_non_adj_of_cliqueFree_succ h x
  obtain ⟨c,hc1,hc2⟩:=hw.cliques.1.exists_non_adj_of_cliqueFree_succ h x
  obtain ⟨d,hd1,hd2⟩:=hw.cliques.2.2.1.exists_non_adj_of_cliqueFree_succ h x
  exact ⟨a,b,c,d,ha1,ha2,hb1,hb2,hc1,hc2,hd1,hd2⟩

/--This is a warmup for the main lemma `bigger_wheel` where we use it with `card_eq_two_of_four`
to help build a bigger wheel -/
lemma exist_non_adj_core (h: G.CliqueFree (r + 2)) (hWc: ∀ {y}, y ∈ s ∩ t → G.Adj x y ) :
    ∃ a b c d, a ∈ insert w₁ s ∧ ¬G.Adj x a ∧ b ∈ insert w₂ t ∧ ¬G.Adj x b ∧ c ∈ insert v s ∧
      ¬G.Adj x c ∧ d ∈ insert v t ∧ ¬G.Adj x d ∧ a ≠ b  ∧ a ≠ d ∧ b ≠ c ∧ a ∉ t ∧ b ∉ s := by
  obtain ⟨a,b,c,d,ha,haj,hb,hbj,hc,hcj,hd,hdj⟩ := hw.exist_non_adj h  x
  refine ⟨a,b,c,d,ha,haj,hb,hbj,hc,hcj,hd,hdj,?_,?_,?_,?_,?_⟩
    <;> simp only [mem_insert] at ha hb hc hd;
  · rintro rfl;
    obtain (rfl | ha) := ha;
    · obtain (rfl | hb ):= hb
      · exfalso; apply  hw.IsP2Compl.edge.ne rfl
      · apply hw.disj'.1  hb
    · obtain (rfl | hb ):= hb
      ·  apply hw.disj'.2 ha
      ·  apply haj <| hWc  <| mem_inter.2 ⟨ha,hb⟩
  · rintro rfl;
    obtain (rfl | ha) := ha;
    · obtain (rfl | hd ):= hd
      · exfalso; apply  hw.IsP2Compl.ne.1 rfl
      · apply hw.disj'.1  hd
    · obtain (rfl | hd ):= hd
      ·  apply hw.disj.1 ha
      ·  apply haj <| hWc  <| mem_inter.2 ⟨ha,hd⟩
  · rintro rfl;
    obtain (rfl | hb) := hb;
    · obtain (rfl | hc ):= hc
      · exfalso; apply  hw.IsP2Compl.ne.2 rfl
      · apply hw.disj'.2  hc
    · obtain (rfl | hc ):= hc
      ·  apply hw.disj.2.1 hb
      ·  apply hbj <| hWc  <| mem_inter.2 ⟨hc,hb⟩
  · intro hat
    by_cases haw1: a = w₁
    · apply hw.disj'.1 (haw1 ▸ hat)
    · apply haj <|  hWc <| mem_inter.2  ⟨ha.resolve_left haw1,hat⟩
  · intro hbs
    by_cases hbw2: b = w₂
    · apply hw.disj'.2 (hbw2 ▸ hbs)
    · apply hbj <| hWc <| mem_inter.2 ⟨hbs,hb.resolve_left hbw2⟩

open Classical
/-- We can build a wheel with a larger common clique set if there is a core vertex that is
 adjacent to all but at most 2 of the vertices of the wheel -/
lemma bigger_wheel (h: G.CliqueFree (r + 2)) (hWc: ∀ {y}, y ∈ s ∩ t → G.Adj x y)
(hsmall : card (hw.verts.filter (fun z => ¬ G.Adj  x z)) ≤ 2) : ∃ a b,  a ∉ t ∧ b ∉ s ∧
    (G.IsWheel r v w₁ w₂ (insert x (s.erase a)) (insert x (t.erase b))) :=by
  obtain ⟨a,b,c,d,ha,haj,hb,hbj,hc,hcj,hd,hdj,hab, had,hbc,hat,hbs⟩:= hw.exist_non_adj_core h hWc
  have ac_bd : c = a ∧ d = b:= by
    apply card_le_two_of_four hab had hbc
    apply le_trans (card_le_card _) hsmall
    intro z; simp_rw [mem_filter,← mem_verts,mem_insert,mem_singleton] at *
    rintro (rfl|rfl|rfl|rfl)
    · exact ⟨Or.inl ha, haj⟩
    · exact ⟨Or.inr <| Or.inl hb,hbj⟩
    · exact ⟨Or.inr <| Or.inr <| Or.inl hc,hcj⟩
    · exact ⟨Or.inr <| Or.inr <| Or.inr hd,hdj⟩
  simp only [ac_bd.1,ac_bd.2,mem_insert] at ha hb hc hd;
  have has: a ∈ s:= by
    obtain (rfl|ha) := ha;
    · obtain (rfl|hc) := hc
      · exfalso; apply hw.IsP2Compl.ne.1 rfl
      · exact hc
    · exact ha
  have hbt: b ∈ t :=by
    obtain (rfl|hb) := hb;
    · obtain (rfl|hd) := hd
      · exfalso; apply hw.IsP2Compl.ne.2 rfl
      · exact hd
    · exact hb
  have habv: v ≠ a ∧ v ≠ b := ⟨fun hf => hw.disj.1 (hf ▸ has),fun hf => hw.disj.2.1 (hf ▸ hbt)⟩
  have haw2: a ≠ w₂ := fun hf => hw.disj'.2 (hf ▸ has)
  have hbw1: b ≠ w₁ := fun hf => hw.disj'.1 (hf ▸ hbt)
  have hxvw12 : x ≠ v ∧ x ≠ w₁ ∧ x ≠ w₂:=by
    refine ⟨?_,?_,?_⟩
    · by_cases hax : x = a <;> rintro rfl
      · apply hw.disj.1 (hax ▸ has)
      · apply haj; apply hw.cliques.1.1; apply mem_insert_self
        apply mem_insert_of_mem has ; exact hax
    · by_cases hax : x = a <;> rintro rfl
      · apply hw.disj.2.2.1 (hax ▸ has)
      · apply haj; apply hw.cliques.2.1.1; apply mem_insert_self
        apply mem_insert_of_mem has ; exact hax
    · by_cases hbx : x = b <;> rintro rfl
      · apply hw.disj.2.2.2 (hbx ▸ hbt)
      · apply hbj; apply hw.cliques.2.2.2.1; apply mem_insert_self
        apply mem_insert_of_mem hbt; exact hbx
  have wadj: ∀ w ∈ hw.verts, w ≠ a → w ≠ b → G.Adj w x:=by
    intro z hz haz hbz
    by_contra hf; push_neg at hf
    have gt2: 2 < card (hw.verts.filter (fun z => ¬ G.Adj x z)):=by
      refine  two_lt_card.2 ⟨a,?_,b ,?_ ,z ,?_ ,hab, haz.symm, hbz.symm⟩ <;> rw [mem_filter]
      · refine ⟨?_,haj⟩
        apply hw.mem_verts.1; left
        apply mem_insert.2 <| Or.inr has
      · refine ⟨?_,hbj⟩
        apply hw.mem_verts.1;right; left
        apply mem_insert.2 <| Or.inr hbt
      · rw [adj_comm] at hf
        exact ⟨hz,hf⟩
    apply Nat.lt_le_asymm gt2 hsmall
-- Below we prove that the new wheel is indeed a wheel by showing disjointedness and that
-- the 4 cliques exist
  refine ⟨a,b,hat,hbs,⟨hw.IsP2Compl,?_,?_⟩⟩
-- We first prove disj-ointedness,i.e. v w₁ w₂ are not in the various new cliques
  · simp only [mem_insert, not_or]
    exact ⟨⟨hxvw12.1.symm,fun hv => hw.disj.1 (mem_erase.1 hv).2 ⟩,
           ⟨hxvw12.1.symm,fun hv => hw.disj.2.1 (mem_erase.1 hv).2⟩,
           ⟨hxvw12.2.1.symm,fun hw1 => hw.disj.2.2.1 (mem_erase.1 hw1).2⟩,
           ⟨hxvw12.2.2.symm,fun hv => hw.disj.2.2.2 (mem_erase.1 hv).2⟩⟩
-- Next we prove that the new cliques are indeed (r + 1)-cliques
  · refine ⟨?_,?_,?_,?_⟩
    · apply hw.cliques.1.insert_insert_erase has hw.disj.1
      intro z hz hza; symm
      apply wadj z _ hza
      · rintro rfl;
        cases mem_insert.1 hz with
        | inl hz => exact habv.2 hz.symm
        | inr hz => exact hbs hz
      · apply  hw.mem_verts.1 (Or.inr <| Or.inr <| Or.inl hz);
    · apply hw.cliques.2.1.insert_insert_erase has hw.disj.2.2.1
      intro z hz hza; symm
      apply wadj z _ hza
      · rintro rfl;
        cases mem_insert.1 hz with
        | inl hz => exact hbw1 hz
        | inr hz => exact hbs hz
      · apply  hw.mem_verts.1 (Or.inl hz);
    · apply hw.cliques.2.2.1.insert_insert_erase hbt hw.disj.2.1
      intro z hz hzb; symm
      apply wadj z  _ _ hzb
      · apply  hw.mem_verts.1 (Or.inr <| Or.inr <| Or.inr hz);
      · rintro rfl;
        cases mem_insert.1 hz with
        | inl hz => exact habv.1 hz.symm
        | inr hz => exact hat hz
    · apply hw.cliques.2.2.2.insert_insert_erase hbt hw.disj.2.2.2
      intro z hz hzb; symm
      apply wadj z  _ _ hzb
      · apply  hw.mem_verts.1 (Or.inr <| Or.inl hz);
      · rintro rfl;
        cases mem_insert.1 hz with
        | inl hz => exact haw2 hz
        | inr hz => exact hat hz

/-- For any x there is a wheelvertex that is not adjacent to x (in fact there is one in s+w₁) -/
lemma one_le_non_adj  (hcf: G.CliqueFree (r + 2)) (x : α) :
    1 ≤ card (hw.verts.filter (fun z => ¬ G.Adj  x z)):=by
  apply card_pos.2
  obtain ⟨_,hz⟩:=hw.cliques.2.1.exists_non_adj_of_cliqueFree_succ hcf x
  exact ⟨_,mem_filter.2 ⟨hw.mem_verts.1 (Or.inl hz.1),hz.2⟩⟩

/-- If G is Kᵣ₊₂-free contains a MaxWheel W then every vertex that is adjacent to all of the common
clique vertices is not adjacent to at least 3 vertices in W -/
lemma three_le_nonadj (hmcf : G.MaxCliqueFree (r + 2)) (hWc: ∀ {y}, y ∈ s ∩ t → G.Adj x y)
(hmax: ∀ s' t', G.IsWheel r v w₁ w₂ s' t' → card (s' ∩ t') ≤ card (s ∩ t)) :
    3 ≤ card (hw.verts.filter fun z => ¬ G.Adj  x z) :=by
  by_contra! hc; change _ + 1 ≤ _ + 1 at hc
  simp only [Nat.reduceLeDiff] at hc
  obtain ⟨c,d,hw1,hw2,hbW⟩:= hw.bigger_wheel hmcf.1 hWc hc
  apply Nat.not_succ_le_self (card (s ∩ t))
  rw [Nat.succ_eq_add_one, ← card_insert_of_not_mem fun hx => G.loopless x <| hWc hx] at *
  convert (hmax _ _ hbW) using 2
  rw [← insert_inter_distrib]
  congr! 1
  rw [erase_inter,inter_erase,erase_eq_of_not_mem,erase_eq_of_not_mem]
  · apply not_mem_mono inter_subset_left hw2
  · apply not_mem_mono <| erase_subset _ _
    apply not_mem_mono <| inter_subset_right
    exact hw1

end IsWheel
end SimpleGraph
