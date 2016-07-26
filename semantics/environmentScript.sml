(*Generated by Lem from environment.lem.*)
open HolKernel Parse boolLib bossLib;
open lem_pervasivesTheory astTheory;

val _ = numLib.prefer_num();



val _ = new_theory "environment"

(*open import Pervasives*)
(*open import Ast*)

val _ = type_abbrev((* ( 'k, 'v) *) "alist" , ``: ('k # 'v) list``);

val _ = Hol_datatype `
 environment =
  Bind of ('n, 'v) alist => (modN, (environment)) alist`;


(*val eLookup : forall 'v 'n. Eq 'n => environment 'n 'v -> id 'n -> maybe 'v*)
 val eLookup_defn = Hol_defn "eLookup" `
 (eLookup (Bind v m) (Short n) = (ALOOKUP v n))
    /\ (eLookup (Bind v m) (Long mn id) =      
((case ALOOKUP m mn of
        NONE => NONE
      | SOME env => eLookup env id
      )))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) Defn.save_defn eLookup_defn;

(*val eEmpty : forall 'v 'n. environment 'n 'v*)
val _ = Define `
 (eEmpty = (Bind [] []))`;


(*val eMerge : forall 'v 'n. environment 'n 'v -> environment 'n 'v -> environment 'n 'v*)
val _ = Define `
 (eMerge (Bind v1 m1) (Bind v2 m2) = (Bind (v1 ++ v2) (m1 ++ m2)))`;


(*val eLift : forall 'v 'n. modN -> environment 'n 'v -> environment 'n 'v*)
val _ = Define `
 (eLift mn env = (Bind [] [(mn, env)]))`;


(*val alist_to_env : forall 'v 'n. alist 'n 'v -> environment 'n 'v*)
val _ = Define `
 (alist_to_env a = (Bind a []))`;


(*val eBind : forall 'v 'n. 'n -> 'v -> environment 'n 'v -> environment 'n 'v*)
val _ = Define `
 (eBind k x (Bind v m) = (Bind ((k,x)::v) m))`;


(*val eOptBind : forall 'v 'n. maybe 'n -> 'v -> environment 'n 'v -> environment 'n 'v*)
val _ = Define `
 (eOptBind n x env =  
((case n of
    NONE => env
  | SOME n' => eBind n' x env
  )))`;


(*val eSing : forall 'v 'n. 'n -> 'v -> environment 'n 'v*)
val _ = Define `
 (eSing n x = (Bind ([(n,x)]) []))`;


(*val eSubEnv : forall 'v 'n. Eq 'n, Eq 'v => (id 'n * 'v -> id 'n * 'v -> bool) -> environment 'n 'v -> environment 'n 'v -> bool*)
val _ = Define `
 (eSubEnv r env1 env2 =  
(! id v1.    
(eLookup env1 id = SOME v1)
    ==>    
(? v2. (eLookup env2 id = SOME v2) /\ r (id,v1) (id,v2))))`;


val _ = export_theory()
