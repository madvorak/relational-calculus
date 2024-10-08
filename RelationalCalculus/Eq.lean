import RelationalCalculus.Basic
import RelationalCalculus.Order
open Relation


-- Define custom equality for Relation based on union order (inclusion)
def Relation.eq (R S : Relation α β) : Prop :=
  R ≤ S ∧ S ≤ R

-- Notation for extensional equality
infix:50 " ≃ " => Relation.eq


theorem Relation.eval_eq_iff_eq {R S : Relation α β} : (eval R = eval S) ↔ (R ≃ S) := by
  constructor
  · intro h
    constructor <;> rw [le_rel_iff_le_eval, h]
  · intro h
    unfold eq at h
    apply funext
    intro a
    apply funext
    intro b
    apply propext
    constructor
    · exact (le_rel_iff_le_eval.mp h.left) a b
    · exact (le_rel_iff_le_eval.mp h.right) a b




-- Prove reflexivity
@[refl]
theorem Relation.eq_refl (R : Relation α β) : R ≃ R :=
  ⟨le_refl R, le_refl R⟩

-- Prove symmetry
@[symm]
theorem Relation.eq_symm {R S : Relation α β} (h : R ≃ S) : S ≃ R :=
  ⟨h.2, h.1⟩

-- Prove transitivity
@[trans]
theorem Relation.eq_trans {R S T : Relation α β} (h₁ : R ≃ S) (h₂ : S ≃ T) : R ≃ T :=
  ⟨le_trans h₁.1 h₂.1, le_trans h₂.2 h₁.2⟩

theorem Relation.eq_iff_eval_eq {R S : Relation α β} :
    R ≃ S ↔ (∀ a b, eval R a b ↔ eval S a b) := by
  constructor
  · intro h
    intro a b
    exact ⟨fun hr => h.1 a b hr, fun hs => h.2 a b hs⟩
  · intro h
    constructor
    · intro a b hr
      exact (h a b).1 hr
    · intro a b hs
      exact (h a b).2 hs

-- Extentional equality implies evaluation equality

theorem Relation.eq_to_eval {R S : Relation α β} (h : R ≃ S) :
    eval R = eval S := by
  funext a b
  exact propext (Relation.eq_iff_eval_eq.1 h a b)

theorem Relation.eval_to_eq {R S : Relation α β} (h: eval R = eval S) : R ≃ S := by
  unfold eq
  constructor
  · intro a b hR
    rw [←h]
    exact hR
  · intro a b hS
    rw [h]
    exact hS

-- Create Setoid instance
-- A Setoid is a set together with an equivalence relation
instance : Setoid (Relation α β) where
  r :=  Relation.eq
  iseqv := {
    refl := Relation.eq_refl
    symm := Relation.eq_symm
    trans := Relation.eq_trans
  }

instance : HasEquiv (Relation α β) where
Equiv := Relation.eq

def Relation.Setoid := @instSetoidRelation
def Relation.HasEquiv := @instHasEquivRelation
