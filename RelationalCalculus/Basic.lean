import Mathlib.Tactic
set_option pp.coercions false

universe u v

-- This is an extensional (set-like) definition of a relation as a subset of the Cartesian product α × β. The goal of many theorems will be to relate the algebraic structure of relational expressions to the semantics based on subsets of pairs.
abbrev Relation.Pairs (α β : Type u) : Type u  := (a:α) → (b:β) → Prop

-- The Relation inductive type gives the syntactic composition structure of relations. This defines the fundamental objects to be manipulated by the relational calculus.
inductive Relation  : (Dom : Type u) → (Cod : Type u) → Type (u+1)
-- atomic forms a relation directly from a set of pairs
| atomic  {α β : Type u} (f:Relation.Pairs α β)  :  Relation α β

-- pair forms a relation as a pair of two values. This is useful for forming higher-order relations from existing relations.
| pair {α β : Type u} (a: α) (b: β) : Relation α β

-- comp stands for composition, and it is the sequential composition operation, which is defined analogously to function composition.
| comp {α β γ : Type u} (R : Relation α β) (S :Relation β γ) : Relation α γ

-- converse is one of the involutions of relations, it reverses the direction of the pairs.
| converse {α β : Type u} (R : Relation α β) : Relation β α

-- complement is the other involution, it consists of the set theoretic complement of pairs relative to a given relation.
| complement {α β : Type u} (R : Relation α β) : Relation α β

-- full is the relation which is the full subset of the Cartersian product of domain and codomain. It's complement is an empty relation.
| full (α β : Type u) : Relation α β

-- product is a monoidal product in the category Rel. It corresponds to one of the conjunction operations in linear logic, usually represented as ⊗.
| product {α β γ δ : Type u} (R : Relation α β) (S : Relation γ δ) : Relation (α × γ) (β × δ)

-- This is the coproduct in the category Rel. It corresponds to one of the disjunction operations in linear logic, usually represented as ⊕. It is interpreted as a disjoint union of domain, codomain, and relational pairs.
| coproduct {α β γ δ : Type u} (R : Relation α β) (S : Relation γ δ) : Relation (Sum α γ ) (Sum β δ)

-- Copy is the diagonal relation, connecting each value in the domain to a pair of identical copies in the codomain. The converse of this is a "merge" relation that sents pairs of identicals to a single copy.
| copy (α : Type u) : Relation α (α × α)

-- Collapse is the categorical dual of copy (a.k.a. cocopy).  It relates every left and right values of a sum type α + α  to equal values in α. This allows us to collapse the disjoint sets of the sum type into a single set. Among other things, this operation allows us to define a union operation compositonally. The converse is a "split" relation that splits a single value into two parallel copies in the disjoint sets.
|   collapse (α: Type u) : Relation (Sum α α) α

-- First is a projection relation from a pair in the domain to the first member of the pair. The converse inserts a value into all pairs where it occurs in first position.
| first (α β : Type u) : Relation (α × β) α

-- Second is a projection relation from a pair in the domain to the second member of the pair. The converse inserts a value into all pairs where it occurs in second position.
| second (α β : Type u) : Relation (α × β) β

-- Left is an injection relation from a value to itself in the left side of a sum type. The converse is a kind of first projection that works with Sum types.
| left (α β : Type u) : Relation α (Sum α β)

-- Right is an injection relation from a value to itself in the right side of a sum type. The converse is a kind of second projection that works with Sum types.
| right (α β : Type u) : Relation α (Sum β α)


open Relation
namespace Relation

postfix: 80 "ᵒ" => converse -- \^o (hat and then letter)
postfix: 80 "⁻" => complement -- \^- (hat dash)
infixl: 70 " ⊗ " => product -- \otimes
infixl: 60 " ⊕ " => coproduct -- \oplus
infixl: 40 " ▹ " => comp -- \trans


def domain (_: Relation α β) := α
def codomain (_: Relation α β) := β

-- *** Eval - Semantics for Relations ***
-- eval defines the semantic domain of the Relation inductive type. It allows us to prove that different syntactic Relation expressions are extensionally equal.


def eval (R : Relation α β) : Relation.Pairs α β :=
match R with
-- For atomic relations, we simply return the pair function
| atomic f => f

-- Pair relations consist of the single pair of elements used in their definition
| pair a b => fun (a': α ) (b': β) => a = a' ∧ b = b'

-- A sequential composition of relations yeilds pair if there exists a common element in the middle Codomain/Domain. Note that for relations which have the structure of a function (i.e., relations with the properties of totality and determinism) this definition specializes to the standard definition of function composition.
| comp R S => fun (a : R.domain) (c : S.codomain) =>
  ∃ (b : S.domain), Relation.eval R a b ∧ Relation.eval S b c

-- A full relation has all pairs so returns a constant True proposition.
| full α β => fun _ _ => True

-- Converse returns an evaluation with the order of the arguments switched.
| converse R => fun a b => (Relation.eval R b a)

-- Complement returns the negation of evaluated proposition for each pair.
| complement R => fun a b => ¬(Relation.eval R a b)

-- Product returns true iff the first element of the domain is related by R to the first element of the codomain AND the second element of domain is related by S to the second element of the codomain.
| product R S => fun (a: (product R S).domain) (b: (product R S).codomain) => (Relation.eval R a.1 b.1) ∧ (Relation.eval S a.2 b.2)

-- Coproduct returns true iff a left element of the domain is related by R to a left element of the codomain OR a right element of the domain is related by S to the right element of the codomain.
| coproduct R S => fun (a: (coproduct R S).domain) (b: (coproduct R S).codomain) =>
  match a, b with
  | Sum.inl a', Sum.inl b' => Relation.eval R a' b'
  | Sum.inr a', Sum.inr b' => Relation.eval S a' b'
  | _, _ => False

| copy α => fun a (a1, a2) => a = a1 ∧ a = a2

| collapse α => fun (aa) a =>
  match aa with
  | Sum.inl a' => a' = a
  | Sum.inr a' => a' = a

-- First and second relate the first (second) elements of a pair in domain to itself in codomain.
| first α β  => fun pair a => pair.1 = a
| second α β => fun pair b => pair.2 = b

-- Left and right relate an element of the domain to the corresponding left (right) elements of the codomain.
| left α β => fun a ab =>
  match ab with
  | Sum.inl a' => a = a'
  | _ => False
| right α β => fun a ba =>
  match ba with
  | Sum.inr a' => a = a'
  | _ => False


-- Expresses the evaluation function as a relation
def evalRel {α β : Type u} : Relation (Relation α β) (PLift (Pairs α β)) :=
  atomic fun (R : Relation α β) (f: PLift (Pairs α β) ) =>
    let evaluatedR := PLift.up (eval R)
  evaluatedR = f

-- **DEFINED RELATION OPERATIONS** --

-- Merge is the converse of copy
def merge (α) := converse (copy α)

-- Sends each a in α to left a and right a
def split  (α : Type u) := converse (collapse α)


-- This is a notion from Peirce/Tarski of a second sequential composition operation that is the logical dual of ordinary composition. It replaces the  existential quantifier (∃) in the definition of composition with a universal quantifier (∀) and replaces conjunction (∧) with disjunction (∨). It can be defined by a De Morgan equivalence.
-- TODO: Add a proof that this compositional definition is equal to the direct logical definition.
def relativeComp (R : Relation α β) (S :Relation β γ) := complement (comp (complement R) (complement S))

-- The converse complement of a relation is often refered to as the relative or linear negation of the relation. Note, that this is order invariant, i.e. complement converse = converse complemetn (proof below).
def negation (R : Relation α β) := converse (complement R)
abbrev neg (R : Relation α β) :=  R.negation
postfix: 80 "ᗮ" => Relation.negation -- \^bot

-- In linear logic, ar (upside down &) is the DeMorgan dual of product.
def par (R : Relation α β) (S : Relation γ δ) : Relation (α × γ) (β × δ) := neg (product (neg R) (neg S))

-- In linear logic, the operation with (&) is the DeMorgan dual of coproduct.
def withR (R : Relation α β) (S : Relation γ δ) :=  neg (coproduct (neg R) (neg S))

-- An empty relation is the complement of the full relation.
def empty (α β : Type u) := complement (full α β)

-- The identity relation is the composition of copy and merge
def IdRel (α : Type u) := comp (copy α) (merge α)

-- The complement of identity is a relation consisting of all pairs of elements that are not identical.
def nonId (α : Type u) := complement (IdRel α)

--The (linear) negation of copy is a "different" relation that relates pairs in α × α of non-equal elements to every element in α. This is useful for compositionally removing reflexive pairs from a relation.
def different (α: Type u) := neg (copy α)


-- Residuation / Linear Implication
def linImp (R S : Relation α β) := (Rᵒ▹S⁻)⁻
abbrev linImpRight (R S : Relation α β) := linImp R S
def linImpLeft (R S : Relation α β) := (S⁻▹Rᵒ)⁻

namespace Relation
--NOTATION FOR Linear Implication
  infixr : 50 "⊸" => linImp -- \multi
  infixl : 50 "⟜" => linImpLeft

end Relation

-- *** Simplification Theorems ***

-- Double converse equals original relation
@[simp]
theorem double_converse (R : Relation α β) : eval (converse (converse R)) = eval R := by
  apply funext; intro a; apply funext; intro b
  simp [eval, converse]

-- Double complement equals original relation
@[simp]
theorem double_complement (R : Relation α β) : eval (complement (complement R)) = eval R := by
  apply funext; intro a; apply funext; intro b
  simp [eval, complement]

-- Double negation (converse complement) equals original relation
@[simp]
theorem double_neg (R : Relation α β) : eval (neg (neg R)) = eval R := by
  apply funext; intro a; apply funext; intro b
  simp [eval, neg,  complement, converse]

-- complement-converse equals converse-complement. We simply to the later.
@[simp]
theorem converse_complement_sym (R : Relation α β) : eval (complement (converse R)) =  eval (converse ( complement  R))  := by
  apply funext; intro b; apply funext; intro a;
  simp [eval]

-- Complement-converse simplifies to negation. This is really trival but it helps display the expressions in a more readable way.
@[simp]
theorem complement_converse_to_neg (R : Relation α β) : eval (complement (converse R)) = eval (neg R) := by
  apply funext; intro b; apply funext; intro a;
  simp [eval, neg]


-- Converse distributes over composition
@[simp]
theorem converse_comp (R : Relation α β) (S : Relation β γ) :
  eval (converse (comp R S)) = eval (comp (converse S) (converse R)) := by
  apply funext; intro c; apply funext; intro a
  simp [Relation.eval, Relation.comp, Relation.converse]
  apply Iff.intro
  . intro ⟨b, hab, hbc⟩
    exact ⟨b, hbc, hab⟩
  . intro ⟨b, hcb, hba⟩
    exact ⟨b, hba, hcb⟩

-- TODO:
  -- Complement distributes over composition?
  -- Negation distributes over composition?

-- Converse distributes across product
@[simp]
theorem converse_product (R : Relation α β) (S : Relation γ δ) :
  eval (converse (product R S)) = eval (product (converse R) (converse S)) := by
  apply funext; intro ⟨b, d⟩; apply funext; intro ⟨a, c⟩
  simp [Relation.eval, Relation.product, Relation.converse]

-- Complement distributes across product
@[simp]
theorem complement_product (R : Relation α β) (S : Relation γ δ) :
  eval (complement (product R S)) = eval (par (complement R) (complement S)) := by
  apply funext; intro ⟨a, c⟩; apply funext; intro ⟨b, d⟩
  simp [Relation.eval]

-- Negation distribtes across product
@[simp]
theorem neg_product (R : Relation α β) (S : Relation γ δ) :
  eval (neg (product R S)) = eval (par (neg R) (neg S)) := by
  apply funext; intro ⟨a, c⟩; apply funext; intro ⟨b, d⟩
  simp [Relation.eval]

-- Converse distributes across coproduct
@[simp]
theorem converse_coproduct (R : Relation α β) (S : Relation γ δ) :
  eval (converse (coproduct R S)) = eval (coproduct (converse R) (converse S)) := by
  apply funext; intro ab; apply funext; intro cd
  cases ab <;> cases cd
  . simp [Relation.eval]
  . simp [Relation.eval]
  . simp [Relation.eval]
  . simp [Relation.eval]

--  Complement distributes across coproduct
@[simp]
theorem complement_coproduct (R : Relation α β) (S : Relation γ δ) :
eval (complement (coproduct R S)) = eval (withR (complement R) (complement S)) := by
apply funext; intro ab; apply funext; intro cd
cases ab <;> cases cd
. simp [Relation.eval]
. simp [Relation.eval]
. simp [Relation.eval]
. simp [Relation.eval]

-- Composition is associative.
@[simp]
theorem assoc_comp (R : Relation α β) (S : Relation β γ) (T: Relation γ δ) :
  eval (comp (comp R S) T) = eval (comp R (comp S T)) := by
  apply funext; intro a; apply funext; intro d
  simp [Relation.eval, Relation.comp]
  apply Iff.intro
  . intro ⟨c, ⟨b, hab, hbc⟩, hcd⟩
    exact ⟨b, hab, ⟨c, hbc, hcd⟩⟩
  . intro ⟨b, hab, ⟨c, hbc, hcd⟩⟩
    exact ⟨c, ⟨b, hab, hbc⟩, hcd⟩




abbrev EndoRelation (α: Type U) := Relation α α

end Relation



-- *** Odds and Ends (Very Rough WIP) ***
-- Helper for getArityType. Note that arity' is arity - 1.
def getProduct (α : Type u) (arity': Nat) : Type u :=
  match arity' with
    | n+1 => α × (getProduct α n)
    | _ => α

-- Returns PUnit for arity 0, returns α for arity 1, α × α for arity 2, etc.
def getArityType (α : Type u) (arity: Nat) : Type u :=
if arity == 0 then PUnit else  getProduct α (arity-1)




-- theorem Relation.product_coproduct__dist (R : Relation α α) (S : Relation α α) (T: Relation α α) :
--   eval (product (coproduct R S) T) = eval (coproduct (product R T) (product S T)) := sorry

-- theorem Relation.coproduct_product_dist (R : Relation α β) (S : Relation γ δ) (T: Relation ε ζ) :
-- eval (product (coproduct R S) T) = eval (coproduct (product R T) (product S T))  := by sorry

--  Equiv.sumProdDistrib is the distributivity equivalence for Sum and Product types. We need to apply this so the types match on either side of the eqution.
-- (R⊕S)⊗T ≅ (R⊗T)⊕(S⊗T)
theorem Relation.coproduct_product_dist (R : Relation α β) (S : Relation γ δ) (T: Relation ε ζ) :
  eval (product (coproduct R S) T) =
    fun (a:(α ⊕ γ) × ε) (b: (β ⊕ δ) × ζ) =>
      let prodPlusProd := eval (coproduct (product R T) (product S T))
      let isoDomain := (Equiv.sumProdDistrib α γ ε)
      let isoCodomain := (Equiv.sumProdDistrib β δ ζ)
      prodPlusProd (isoDomain a) (isoCodomain b) := by
  apply funext; intro a; apply funext; intro b
  dsimp [Relation.eval, Equiv.sumProdDistrib]
  cases a.1 <;> cases b.1
  . simp
  . simp
  . simp
  . simp


-- -- T⊕(R⊗S) = (T⊕R) ⊗ (T⊕S)
-- theorem Relation.product_coproduct_dist (R : Relation α β) (S : Relation γ δ) (T: Relation ε ζ) :
