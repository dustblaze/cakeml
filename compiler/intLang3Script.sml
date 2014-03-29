(*Generated by Lem from intLang3.lem.*)
open HolKernel Parse boolLib bossLib;
open lem_pervasivesTheory libTheory astTheory semanticPrimitivesTheory lem_list_extraTheory bigStepTheory intLang2Theory;

val _ = numLib.prefer_num();



val _ = new_theory "intLang3"

(* The third intermediate language (IL3). Removes declarations.
 *
 * The AST of IL3 differs from IL2 in that there is no declarations level, the
 * program is represented by a sequence of expressions.
 *
 * The values of IL3 are the same as IL2.
 *
 * The semantics of IL3 differ in that the global environment is now store-like
 * rather than environment-like. The expressions for extending and initialising
 * it modify the global environment (instread of just rasing a type error).
 *
 * The translator to IL3 maps a declaration to an expression that sets of the
 * global environment in the right way.
 *
 *)

(*open import Pervasives*)
(*open import Lib*)
(*open import Ast*)
(*open import SemanticPrimitives*)
(*open import List_extra*)
(*open import BigStep*)
(*open import IntLang2*)

(*val init_globals : nat -> nat -> list (pat_i2 * exp_i2)*)
 val _ = Define `
 (init_globals next 0 = ([]))
/\ (init_globals next num =  
(let var =  (STRCAT"x" (num_to_dec_string num)) in
    (Pvar_i2 var, Uapp_i2 (Init_global_var_i2 (next+num)) (Var_local_i2 var)) :: init_globals next (num -  1)))`;


(*val init_global_funs : nat -> list (varN * varN * exp_i2) -> list exp_i2*)
 val _ = Define `
 (init_global_funs next [] = ([]))
/\ (init_global_funs next ((f,x,e)::funs) =  
(Uapp_i2 (Init_global_var_i2 next) (Fun_i2 x e) :: init_global_funs (next+ 1) funs))`;


(*val decs_to_i3 : nat -> list dec_i2 -> list exp_i2*)
 val _ = Define `
 (decs_to_i3 next [] = ([]))
/\ (decs_to_i3 next (d::ds) =  
((case d of
      Dlet_i2 n e =>
        Mat_i2 e (init_globals next n) :: decs_to_i3 (next+n) ds
    | Dletrec_i2 funs =>
        let n = (LENGTH funs) in
          init_global_funs next funs ++ decs_to_i3 (next+n) ds 
  )))`;


(*val num_defs : list dec_i2 -> nat*)
 val _ = Define `
 (num_defs [] =( 0))
/\ (num_defs (d::ds) =  
((case d of
      Dlet_i2 n e => n + num_defs ds
    | Dletrec_i2 funs => LENGTH funs + num_defs ds
  )))`;


(*val prompt_to_i3 : nat -> prompt_i2 -> nat * list exp_i2*)
val _ = Define `
 (prompt_to_i3 next prompt =  
((case prompt of
      Prompt_i2 ds =>
        let n = (num_defs ds) in
          ((next+n), [Extend_global_i2 n; Handle_i2 (Con_i2 tuple_tag (decs_to_i3 next ds)) [(Pvar_i2 "x", Var_local_i2 "x")]])
  )))`;


(*val prog_to_i3 : nat -> list prompt_i2 -> nat * list exp_i2*)
 val prog_to_i3_defn = Hol_defn "prog_to_i3" `
 
(prog_to_i3 next [] = (next, []))
/\ 
(prog_to_i3 next (p::ps) =  
 (let (next',p') = (prompt_to_i3 next p) in
  let (next'',ps') = (prog_to_i3 next' ps) in
    (next'',(p'++ps'))))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) Defn.save_defn prog_to_i3_defn;

(*val do_uapp_i3 : store v_i2 * list (maybe v_i2) -> uop_i2 -> v_i2 -> maybe ((store v_i2 * list (maybe v_i2)) * v_i2)*)
val _ = Define `
 (do_uapp_i3 (s,genv) uop v =  
((case uop of
      Opderef_i2 =>
        (case v of
            Loc_i2 n =>
              (case store_lookup n s of
                  SOME v => SOME ((s,genv),v)
                | NONE => NONE
              )
          | _ => NONE
        )
    | Opref_i2 =>
        let (s',n) = (store_alloc v s) in
          SOME ((s',genv), Loc_i2 n)
    | Init_global_var_i2 idx =>
        if idx < LENGTH genv then
          (case EL idx genv of
              NONE => SOME ((s, LUPDATE (SOME v) idx genv), Litv_i2 Unit)
            | SOME x => NONE
          )
        else
          NONE
  )))`;


val _ = type_abbrev( "count_store_genv" , ``: v_i2 count_store # ( v_i2 option) list``);

val _ = Hol_reln ` (! ck env l s.
T
==>
evaluate_i3 ck env s (Lit_i2 l) (s, Rval (Litv_i2 l)))

/\ (! ck env e s1 s2 v.
(evaluate_i3 ck s1 env e (s2, Rval v))
==>
evaluate_i3 ck s1 env (Raise_i2 e) (s2, Rerr (Rraise v)))

/\ (! ck env e s1 s2 err.
(evaluate_i3 ck s1 env e (s2, Rerr err))
==>
evaluate_i3 ck s1 env (Raise_i2 e) (s2, Rerr err))

/\ (! ck s1 s2 env e v pes.
(evaluate_i3 ck s1 env e (s2, Rval v))
==>
evaluate_i3 ck s1 env (Handle_i2 e pes) (s2, Rval v))

/\ (! ck s1 s2 env e pes v bv.
(evaluate_i3 ck env s1 e (s2, Rerr (Rraise v)) /\
evaluate_match_i3 ck env s2 v pes v bv)
==>
evaluate_i3 ck env s1 (Handle_i2 e pes) bv)

/\ (! ck s1 s2 env e pes err.
(evaluate_i3 ck env s1 e (s2, Rerr err) /\
((err = Rtimeout_error) \/ (err = Rtype_error)))
==>
evaluate_i3 ck env s1 (Handle_i2 e pes) (s2, Rerr err))

/\ (! ck env tag es vs s s'.
(evaluate_list_i3 ck env s es (s', Rval vs))
==>
evaluate_i3 ck env s (Con_i2 tag es) (s', Rval (Conv_i2 tag vs)))

/\ (! ck env tag es err s s'.
(evaluate_list_i3 ck env s es (s', Rerr err))
==>
evaluate_i3 ck env s (Con_i2 tag es) (s', Rerr err))

/\ (! ck env n v s.
(lookup n env = SOME v)
==>
evaluate_i3 ck env s (Var_local_i2 n) (s, Rval v))

/\ (! ck env n s.
(lookup n env = NONE)
==>
evaluate_i3 ck env s (Var_local_i2 n) (s, Rerr Rtype_error))

/\ (! ck env n v s genv.
((LENGTH genv > n) /\
(EL n genv = SOME v))
==>
evaluate_i3 ck env (s,genv) (Var_global_i2 n) ((s,genv), Rval v))

/\ (! ck env n s genv.
((LENGTH genv > n) /\
(EL n genv = NONE))
==>
evaluate_i3 ck env (s,genv) (Var_global_i2 n) ((s,genv), Rerr Rtype_error))

/\ (! ck env n s genv.
(~ (LENGTH genv > n))
==>
evaluate_i3 ck env (s,genv) (Var_global_i2 n) ((s,genv), Rerr Rtype_error))

/\ (! ck env n e s.
T
==>
evaluate_i3 ck env s (Fun_i2 n e) (s, Rval (Closure_i2 env n e)))

/\ (! ck env uop e v v' s1 s2 count s3 genv2 genv3.
(evaluate_i3 ck env s1 e (((count,s2),genv2), Rval v) /\
(do_uapp_i3 (s2,genv2) uop v = SOME ((s3,genv3),v')))
==>
evaluate_i3 ck env s1 (Uapp_i2 uop e) (((count,s3),genv3), Rval v'))

/\ (! ck env uop e v s1 s2 count genv2.
(evaluate_i3 ck env s1 e (((count,s2),genv2), Rval v) /\
(do_uapp_i3 (s2,genv2) uop v = NONE))
==>
evaluate_i3 ck env s1 (Uapp_i2 uop e) (((count,s2),genv2), Rerr Rtype_error))

/\ (! ck env uop e err s s'.
(evaluate_i3 ck env s e (s', Rerr err))
==>
evaluate_i3 ck env s (Uapp_i2 uop e) (s', Rerr err))

/\ (! ck env op e1 e2 v1 v2 env' e3 bv s1 s2 s3 count s4 genv3.
(evaluate_i3 ck env s1 e1 (s2, Rval v1) /\
(evaluate_i3 ck env s2 e2 (((count,s3),genv3), Rval v2) /\
((do_app_i2 env s3 op v1 v2 = SOME (env', s4, e3)) /\
(((ck /\ (op = Opapp)) ==> ~ (count =( 0))) /\
evaluate_i3 ck env' (((if ck then dec_count op count else count),s4),genv3) e3 bv))))
==>
evaluate_i3 ck env s1 (App_i2 op e1 e2) bv)

/\ (! ck env op e1 e2 v1 v2 env' e3 s1 s2 s3 count s4 genv3.
(evaluate_i3 ck env s1 e1 (s2, Rval v1) /\
(evaluate_i3 ck env s2 e2 (((count,s3),genv3), Rval v2) /\
((do_app_i2 env s3 op v1 v2 = SOME (env', s4, e3)) /\
((count = 0) /\
((op = Opapp) /\
ck)))))
==>
evaluate_i3 ck env s1 (App_i2 op e1 e2) ((( 0,s4),genv3),Rerr Rtimeout_error))

/\ (! ck env op e1 e2 v1 v2 s1 s2 s3 count genv3.
(evaluate_i3 ck env s1 e1 (s2, Rval v1) /\
(evaluate_i3 ck env s2 e2 (((count,s3),genv3),Rval v2) /\
(do_app_i2 env s3 op v1 v2 = NONE)))
==>
evaluate_i3 ck env s1 (App_i2 op e1 e2) (((count,s3),genv3), Rerr Rtype_error))

/\ (! ck env op e1 e2 v1 err s1 s2 s3.
(evaluate_i3 ck env s1 e1 (s2, Rval v1) /\
evaluate_i3 ck env s2 e2 (s3, Rerr err))
==>
evaluate_i3 ck env s1 (App_i2 op e1 e2) (s3, Rerr err))

/\ (! ck env op e1 e2 err s s'.
(evaluate_i3 ck env s e1 (s', Rerr err))
==>
evaluate_i3 ck env s (App_i2 op e1 e2) (s', Rerr err))

/\ (! ck env e1 e2 e3 v e' bv s1 s2.
(evaluate_i3 ck env s1 e1 (s2, Rval v) /\
((do_if_i2 v e2 e3 = SOME e') /\
evaluate_i3 ck env s2 e' bv))
==>
evaluate_i3 ck env s1 (If_i2 e1 e2 e3) bv)

/\ (! ck env e1 e2 e3 v s1 s2.
(evaluate_i3 ck env s1 e1 (s2, Rval v) /\
(do_if_i2 v e2 e3 = NONE))
==>
evaluate_i3 ck env s1 (If_i2 e1 e2 e3) (s2, Rerr Rtype_error))

/\ (! ck env e1 e2 e3 err s s'.
(evaluate_i3 ck env s e1 (s', Rerr err))
==>
evaluate_i3 ck env s (If_i2 e1 e2 e3) (s', Rerr err))

/\ (! ck env e pes v bv s1 s2.
(evaluate_i3 ck env s1 e (s2, Rval v) /\
evaluate_match_i3 ck env s2 v pes (Conv_i2 bind_tag []) bv)
==>
evaluate_i3 ck env s1 (Mat_i2 e pes) bv)

/\ (! ck env e pes err s s'.
(evaluate_i3 ck env s e (s', Rerr err))
==>
evaluate_i3 ck env s (Mat_i2 e pes) (s', Rerr err))

/\ (! ck env n e1 e2 v bv s1 s2.
(evaluate_i3 ck env s1 e1 (s2, Rval v) /\
evaluate_i3 ck (bind n v env) s2 e2 bv)
==>
evaluate_i3 ck env s1 (Let_i2 n e1 e2) bv)

/\ (! ck env n e1 e2 err s s'.
(evaluate_i3 ck env s e1 (s', Rerr err))
==>
evaluate_i3 ck env s (Let_i2 n e1 e2) (s', Rerr err))

/\ (! ck env funs e bv s.
(ALL_DISTINCT (MAP (\ (x,y,z) .  x) funs) /\
evaluate_i3 ck (build_rec_env_i2 funs env env) s e bv)
==>
evaluate_i3 ck env s (Letrec_i2 funs e) bv)

/\ (! ck env funs e s.
(~ (ALL_DISTINCT (MAP (\ (x,y,z) .  x) funs)))
==>
evaluate_i3 ck env s (Letrec_i2 funs e) (s, Rerr Rtype_error))

/\ (! ck env n s genv.
T
==>
evaluate_i3 ck env (s,genv) (Extend_global_i2 n) ((s,(genv++GENLIST (\ x .  NONE) n)), Rval (Litv_i2 Unit)))

/\ (! ck env s.
T
==>
evaluate_list_i3 ck env s [] (s, Rval []))

/\ (! ck env e es v vs s1 s2 s3.
(evaluate_i3 ck env s1 e (s2, Rval v) /\
evaluate_list_i3 ck env s2 es (s3, Rval vs))
==>
evaluate_list_i3 ck env s1 (e::es) (s3, Rval (v::vs)))

/\ (! ck env e es err s s'.
(evaluate_i3 ck env s e (s', Rerr err))
==>
evaluate_list_i3 ck env s (e::es) (s', Rerr err))

/\ (! ck env e es v err s1 s2 s3.
(evaluate_i3 ck env s1 e (s2, Rval v) /\
evaluate_list_i3 ck env s2 es (s3, Rerr err))
==>
evaluate_list_i3 ck env s1 (e::es) (s3, Rerr err))

/\ (! ck env v err_v s.
T
==>
evaluate_match_i3 ck env s v [] err_v (s, Rerr (Rraise err_v)))

/\ (! ck env env' v p pes e bv err_v s count genv.
(ALL_DISTINCT (pat_bindings_i2 p []) /\
((pmatch_i2 s p v env = Match env') /\
evaluate_i3 ck env' ((count,s),genv) e bv))
==>
evaluate_match_i3 ck env ((count,s),genv) v ((p,e)::pes) err_v bv)

/\ (! ck genv env v p e pes bv s count err_v.
(ALL_DISTINCT (pat_bindings_i2 p []) /\
((pmatch_i2 s p v env = No_match) /\
evaluate_match_i3 ck env ((count,s),genv) v pes err_v bv))
==>
evaluate_match_i3 ck env ((count,s),genv) v ((p,e)::pes) err_v bv)

/\ (! ck genv env v p e pes s count err_v.
(pmatch_i2 s p v env = Match_type_error)
==>
evaluate_match_i3 ck env ((count,s),genv) v ((p,e)::pes) err_v (((count,s),genv), Rerr Rtype_error))

/\ (! ck env v p e pes s err_v.
(~ (ALL_DISTINCT (pat_bindings_i2 p [])))
==>
evaluate_match_i3 ck env s v ((p,e)::pes) err_v (s, Rerr Rtype_error))`;
val _ = export_theory()

