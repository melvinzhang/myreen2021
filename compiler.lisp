
# This file is generated from the HOL4 theorem prover.

# The code in this file implements a verified bootstrapped compiler
# for a small Lisp-inspired language. The compiler consists of:
#
#  - a code generator (codegen)
#  - a lexer and a parser
#  - a printer that outputs GNU assmebler for Ubuntu x86-64
#
# Lines beginning with # are comments.


# Definition of the codegen function

(defun append (v l)
   (if (= v '0) l (cons (head v) (append (tail v) l))))

(defun flatten (v acc)
   (case v ((List xs) (append xs acc))
      ((Append l1 l2) (flatten l1 (flatten l2 acc)))))

(defun init (k)
   (list (Const RAX '0) (Const R12 '16)
      (Const R13 '9223372036854775807) (Call k)
      (Const RDI '0) (Exit)
      (Comment (list 'c 'o 'n 's))
      (Jump (Equal R14 R15) '14) (Store RDI R14 '0)
      (Store RAX R14 '8) (Mov RAX R14) (Add R14 R12)
      (Ret) (Comment (list 'e 'x 'i 't '32 '49))
      (Push R15) (Const RDI '1) (Exit)))

(defun even_len (v) (if (= v '0) '1 (odd_len (tail v))))

(defun odd_len (v) (if (= v '0) '0 (even_len (tail v))))

(defun give_up (b) (if (= b '1) '14 '15))

(defun c_const (l n vs)
   (if (< '9223372036854775807 n)
      (cons
         (List (list (Jump (Always) (give_up (odd_len vs)))))
         (+ l '1))
      (cons (List (list (Push RAX) (Const RAX n))) (+ l '2))))

(defun find (n v k)
   (if (= v '0) k
      (if (= (head v) '0) (find n (tail v) (+ k '1))
         (let (x (head (head v)))
            (if (= x n) k (find n (tail v) (+ k '1)))))))

(defun c_var (l n vs)
   (let (k (find n vs '0))
      (if (= k '0)
         (cons (List (list (Push RAX))) (+ l '1))
         (cons (List (list (Push RAX) (Load_RSP RAX k))) (+ l '2)))))

(defun c_add (vs)
   (list (Pop RDI) (Add RAX RDI)
      (Jump (Less R13 RAX) (give_up (even_len vs)))))

(defun c_sub (l)
   (list (Pop RDI) (Jump (Less RAX RDI) (+ l '3))
      (Mov RAX RDI) (Sub RDI RAX) (Mov RAX RDI)))

(defun c_div 0
   (list (Mov RDI RAX) (Pop RAX) (Const RDX '0) (Div RDI)))

(defun c_cons (vs)
   (if (= (even_len vs) '1)
      (list (Load_RSP RDI '0) (Call '7) (Pop RDI))
      (list (Pop RDI) (Call '7))))

(defun c_head 0 (list (Load RAX RAX '0)))

(defun c_tail 0 (list (Load RAX RAX '8)))

(defun align (b cs)
   (if (= b '1)
      (append (append (list (Push RAX)) cs) (list (Pop RDI)))
      cs))

(defun c_read (vs) (align (even_len vs) (list (Push RAX) (GetChar))))

(defun c_write (vs)
   (align (even_len vs) (list (Mov RDI RAX) (PutChar) (Const RAX '0))))

(defun c_op (v vs l)
   (case v (Add (c_add vs)) (Sub (c_sub l))
      (Div (c_div)) (Cons (c_cons vs)) (Head (c_head))
      (Tail (c_tail)) (Read (c_read vs))
      (Write (c_write vs))))

(defun c_test (c target)
   (let
      (cond (case c (Less (Less RDI RBX)) (Equal (Equal RDI RBX))))
      (list (Mov RBX RAX) (Pop RDI) (Pop RAX) (Jump cond target))))

(defun c_if (t cmp x1 x2 x3)
   (cons
      (Append (head x1)
         (Append
            (List (c_test cmp (+ (tail x2) (if (= t '1) '0 '1))))
            (Append (head x2)
               (Append
                  (List (if (= t '1) '0 (list (Jump (Always) (tail x3)))))
                  (head x3)))))
      (tail x3)))

(defun length (v) (if (= v '0) '0 (+ (length (tail v)) '1)))

(defun call_env (v acc)
   (if (= v '0) acc (call_env (tail v) (cons (list (head v)) acc))))

(defun c_pushes (vs l)
   (let (k (length vs)) (e (call_env vs '0))
      (case k (0 (cons (List '0) (list '0) l))
         (1 (cons (List '0) e l))
         (2 (cons (List (list (Push RDI))) e (+ l '1)))
         (3 (cons (List (list (Push RDX) (Push RDI))) e (+ l '2)))
         (4
            (cons (List (list (Push RBX) (Push RDX) (Push RDI))) e (+ l '3)))
         (_
            (cons
               (List (list (Push RBP) (Push RBX) (Push RDX) (Push RDI)))
               e (+ l '4))))))

(defun c_pops (xs vs)
   (let (k (length xs))
      (case k (0 (list (Push RAX))) (1 '0)
         (2 (list (Pop RDI)))
         (3 (list (Pop RDI) (Pop RDX)))
         (4 (list (Pop RDI) (Pop RDX) (Pop RBX)))
         (5 (list (Pop RDI) (Pop RDX) (Pop RBX) (Pop RBP)))
         (_
            (list
               (Jump (Always)
                  (give_up (- '1 (if (= (odd_len xs) (odd_len vs)) '1 '0)))))))))

(defun c_call (t vs target xs v)
   (let (ys (c_pops xs vs))
      (if (= t '1)
         (cons
            (Append (head v)
               (Append (List ys)
                  (List (list (Add_RSP (length vs)) (Jump (Always) target)))))
            (+ (+ (tail v) (length ys)) '2))
         (let
            (cs (align (even_len vs) (list (Call target))))
            (cons
               (Append (head v) (Append (List ys) (List cs)))
               (+ (+ (tail v) (length ys)) (length cs)))))))

(defun lookup (n v)
   (if (= v '0) '0
      (if (= (head (head v)) n) (tail (head v)) (lookup n (tail v)))))

(defun make_ret (vs v)
   (cons
      (Append (head v) (List (list (Add_RSP (length vs)) (Ret))))
      (+ (tail v) '2)))

(defun c_exp (t l vs fs z)
   (if (= t '1)
      (case z
         ((Const v13) (make_ret vs (c_exp '0 l vs fs z)))
         ((Var v14) (make_ret vs (c_exp '0 l vs fs z)))
         ((Op v15 v16) (make_ret vs (c_exp '0 l vs fs z)))
         ((If v17 v18 v19 v20)
            (let (r1 (c_exps l vs fs v18))
               (r2 (c_exp '1 (+ (tail r1) '4) vs fs v20))
               (r3 (c_exp '1 (tail r2) vs fs v19))
               (c_if '1 v17 r1 r2 r3)))
         ((Let n x y)
            (let (r1 (c_exp '0 l vs fs x))
               (r2 (c_exp '1 (tail r1) (cons (list n) vs) fs y))
               (cons (Append (head r1) (Append (head r2) (List '0))) (tail r2))))
         ((Call n xs) (c_call '1 vs (lookup n fs) xs (c_exps l vs fs xs))))
      (case z ((Const n) (c_const l n vs))
         ((Var n) (c_var l n vs))
         ((Op op xs)
            (let (r1 (c_exps l vs fs xs))
               (insts (c_op op vs (tail r1)))
               (cons (Append (head r1) (List insts))
                  (+ (tail r1) (length insts)))))
         ((If cmp xs y x)
            (let (r1 (c_exps l vs fs xs))
               (r2 (c_exp '0 (+ (tail r1) '4) vs fs x))
               (r3 (c_exp '0 (+ (tail r2) '1) vs fs y))
               (c_if '0 cmp r1 r2 r3)))
         ((Let n x y)
            (let (r1 (c_exp '0 l vs fs x))
               (r2 (c_exp '0 (tail r1) (cons (list n) vs) fs y))
               (cons
                  (Append (head r1)
                     (Append (head r2) (List (list (Add_RSP '1)))))
                  (+ (tail r2) '1))))
         ((Call n xs) (c_call '0 vs (lookup n fs) xs (c_exps l vs fs xs))))))

(defun c_exps (l vs fs zs)
   (if (= zs '0) (cons (List '0) l)
      (let (res1 (c_exp '0 l vs fs (head zs)))
         (res2 (c_exps (tail res1) (cons '0 vs) fs (tail zs)))
         (cons (Append (head res1) (head res2)) (tail res2)))))

(defun c_defun (l fs v)
   (case v
      ((Defun n vs body)
         (let (r1 (c_pushes vs l))
            (r2 (c_exp '1 (tail (tail r1)) (head (tail r1)) fs body))
            (cons (Append (head r1) (head r2)) (tail r2))))))

(defun name_of (v) (case v ((Defun n v0 v1) n)))

(defun mul256 (n)
   (let (x (+ n n)) (y (+ x x)) (z (+ y y)) (s (+ z z))
      (t (+ s s)) (v (+ t t)) (w (+ v v)) (+ w w)))

(defun name2str (n acc)
   (if (= n '0) acc
      (let (d (div n '256)) (m (- n (mul256 d)))
         (name2str d (cons m acc)))))

(defun c_decs (l fs v)
   (if (= v '0) (cons (List '0) '0 l)
      (let (fname (name_of (head v)))
         (comment (List (list (Comment (name2str fname '0)))))
         (r1 (c_defun (+ l '1) fs (head v)))
         (r2 (c_decs (tail r1) fs (tail v)))
         (cons
            (Append comment (Append (head r1) (head r2)))
            (cons (cons fname (+ l '1)) (head (tail r2)))
            (tail (tail r2))))))

(defun codegen (v)
   (case v
      ((Program decs main)
         (let (r1 (c_decs '17 '0 decs))
            (r2
               (c_decs '17 (head (tail r1))
                  (append decs (list (Defun 'main '0 main)))))
            (flatten
               (Append (List (init (+ (tail (tail r1)) '1))) (head r2))
               '0)))))


# Definition of the lexer that reads from stdin

(defun mul10 (n)
   (let (n2 (+ n n)) (n4 (+ n2 n2)) (n5 (+ n4 n)) (+ n5 n5)))

(defun read_num (acc next)
   (if (< next ':)
      (if (< next '48) (cons acc next)
         (read_num (+ (mul10 acc) (- next '48)) (read)))
      (cons acc next)))

(defun read_str (acc next)
   (if (< next '123)
      (if (< next '*) (cons acc next)
         (read_str (+ (mul256 acc) next) (read)))
      (cons acc next)))

(defun read_any (next)
   (if (< next ':)
      (if (< next '48) (read_str '0 next) (read_num '0 next))
      (read_str '0 next)))

(defun end_line (next)
   (if (< next '256) (if (= next '10) (read) (end_line (read))) next))

(defun lex (q next acc)
   (if (< next '*)
      (let (n (read))
         (if (= next '40) (lex '0 n (cons (OPEN) acc))
            (if (= next '41) (lex '0 n (cons (CLOSE) acc))
               (if (= next '39) (lex '1 n acc)
                  (if (= next '35) (lex '0 (end_line n) acc) (lex '0 n acc))))))
      (if (= next '46) (lex '0 (read) (cons (DOT) acc))
         (if (< 'z next)
            (if (< next '256) (lex '0 (read) acc) acc)
            (let (r (read_any next))
               (lex '0 (tail r)
                  (if (= q '0) (cons (NUM (head r)) acc)
                     (cons (QUOTE (head r)) acc))))))))

(defun lexer 0 (lex '0 (read) '0))


# Definition of the parser

(defun quote (n) (list '0 (cons '1 '39) '0 (cons '1 n) '1))

(defun parse (input x s)
   (if (= input '0) x
      (case (head input)
         ((OPEN)
            (if (= s '0) (parse (tail input) x s)
               (parse (tail input) (cons '0 x (head s)) (tail s))))
         ((CLOSE) (parse (tail input) (list '1) (cons x s)))
         ((DOT) (parse (tail input) (h x) s))
         ((NUM n) (parse (tail input) (cons '0 (cons '1 n) x) s))
         ((QUOTE n) (parse (tail input) (cons '0 (quote n) x) s)))))

(defun v2list (v)
   (if (= (head v) '1) '0 (cons (h v) (v2list (t v)))))

(defun conses (v)
   (if (= v '0) (Op Cons '0)
      (if (= (tail v) '0) (Op Cons (list (head v)))
         (if (= (tail (tail v)) '0)
            (Op Cons (list (head v) (head (tail v))))
            (Op Cons
               (list (head v)
                  (conses
                     (cons (head (tail v)) (head (tail (tail v)))
                        (tail (tail (tail v)))))))))))

(defun v2test (v)
   (if (= (if (= (head v) '0) '0 (tail v)) '<) Less Equal))

(defun h (x) (if (= (head x) '1) x (head (tail x))))

(defun t (x) (if (= (head x) '1) x (tail (tail x))))

(defun el1 (v) (h (t v)))

(defun el2 (v) (el1 (t v)))

(defun el3 (v) (el2 (t v)))

(defun vs2args (v)
   (if (= v '0) '0
      (cons
         (if (= (head (el1 (head v))) '0) '0 (tail (el1 (head v))))
         (vs2args (tail v)))))

(defun is_upper (n)
   (if (< n '256) (if (< n A) '0 (if (< n '[) '1 '0))
      (is_upper (div n '256))))

(defun pat_lets (x v rhs)
   (if (= (head v) '1) rhs
      (let
         (var (if (= (head (h v)) '0) '0 (tail (h v))))
         (Let var (Op Head (list x))
            (pat_lets (Op Tail (list x)) (t v) rhs)))))

(defun num2exp (n) (if (= (is_upper n) '1) (Const n) (Var n)))

(defun v2exp (v)
   (if (= (head v) '1)
      (num2exp (if (= (head v) '0) '0 (tail v)))
      (let
         (n (if (= (head (h v)) '0) '0 (tail (h v))))
         (case n
            (39 (Const (if (= (head (el1 v)) '0) '0 (tail (el1 v)))))
            (+ (Op Add (v2exps (t v))))
            (- (Op Sub (v2exps (t v))))
            (div (Op Div (v2exps (t v))))
            (cons (conses (v2exps (t v))))
            (cons* (Op Cons (v2exps (t v))))
            (list (conses (append (v2exps (t v)) (list (Const '0)))))
            (head (Op Head (v2exps (t v))))
            (tail (Op Tail (v2exps (t v))))
            (read (Op Read (v2exps (t v))))
            (case (v2case (v2exp (el1 v)) (t (t v))))
            (write (Op Write (v2exps (t v))))
            (if
               (If (v2test (h (el1 v))) (v2exps (t (el1 v)))
                  (v2exp (el2 v)) (v2exp (el3 v))))
            (let (v2lets (t v)))
            (var (Var (if (= (head (h (t v))) '0) '0 (tail (h (t v))))))
            (call
               (Call
                  (if (= (head (el1 v)) '0) '0 (tail (el1 v)))
                  (v2exps (t (t v)))))
            (_
               (if (= (is_upper n) '1)
                  (conses
                     (cons (Const n) (append (v2exps (t v)) (list (Const '0)))))
                  (Call (if (= (head (h v)) '0) '0 (tail (h v))) (v2exps (t v)))))))))

(defun v2exps (v)
   (if (= (head v) '1) '0 (cons (v2exp (h v)) (v2exps (t v)))))

(defun v2lets (v)
   (if (= (head v) '1) (Const '0)
      (Let
         (if (= (head (h (h v))) '0) '0 (tail (h (h v))))
         (v2exp (el1 (h v)))
         (if (= (head (t (t v))) '1) (v2exp (el1 v)) (v2lets (t v))))))

(defun v2case (x v)
   (if (= (head v) '1) (Const '0)
      (let (row (h v)) (pat (h row)) (rhs (el1 row))
         (if (= (head pat) '1)
            (if
               (= (if (= (head pat) '0) '0 (tail pat)) '_)
               (If Less (list (Const '0) (Const '1))
                  (v2exp rhs) (v2case x (t v)))
               (If Equal
                  (list x (Const (if (= (head pat) '0) '0 (tail pat))))
                  (v2exp rhs) (v2case x (t v))))
            (If Equal
               (list
                  (Const (if (= (head (h pat)) '0) '0 (tail (h pat))))
                  (Op Head (list x)))
               (pat_lets (Op Tail (list x)) (t pat) (v2exp rhs))
               (v2case x (t v)))))))

(defun v2dec (v)
   (Defun
      (if (= (head (el1 v)) '0) '0 (tail (el1 v)))
      (vs2args (v2list (el2 v))) (v2exp (el3 v))))

(defun vs2prog (vs)
   (if (= vs '0) (Program '0 (Const '0))
      (if (= (tail vs) '0)
         (Program '0 (v2exp (head vs)))
         (let (p (vs2prog (tail vs)))
            (case p ((Program ds m) (Program (cons (v2dec (head vs)) ds) m)))))))

(defun parser (tokens)
   (vs2prog (v2list (parse tokens (list '1) '0))))


# Functions for converting assembly to strings

(defun reg (v s)
   (case v (RAX (cons '37 'r 'a 'x s))
      (RDI (cons '37 'r 'd 'i s))
      (RBX (cons '37 'r 'b 'x s))
      (RBP (cons '37 'r 'b 'p s))
      (R12 (cons '37 'r '49 '50 s))
      (R13 (cons '37 'r '49 '51 s))
      (R14 (cons '37 'r '49 '52 s))
      (R15 (cons '37 'r '49 '53 s))
      (RDX (cons '37 'r 'd 'x s))))

(defun num (n s)
   (if (< n '10) (cons (+ '48 n) s)
      (let (d (div n '10)) (m (- n (mul10 d)))
         (num d (cons (+ '48 m) s)))))

(defun lab (n s) (cons L (num n s)))

(defun clean (v acc)
   (if (= v '0) acc
      (if (< (head v) '+) (clean (tail v) acc)
         (cons (head v) (clean (tail v) acc)))))

(defun mul8 (n) (let (x (+ n n)) (y (+ x x)) (+ y y)))

(defun inst (v s)
   (case v
      ((Const r imm)
         (cons 'm 'o 'v 'q '32 '36 (num imm (cons ', '32 (reg r s)))))
      ((Mov dst src)
         (cons 'm 'o 'v 'q '32 (reg src (cons ', '32 (reg dst s)))))
      ((Add dst src)
         (cons 'a 'd 'd 'q '32 (reg src (cons ', '32 (reg dst s)))))
      ((Sub dst src)
         (cons 's 'u 'b 'q '32 (reg src (cons ', '32 (reg dst s)))))
      ((Div r) (cons 'd 'i 'v 'q '32 (reg r s)))
      ((Jump v9 n)
         (case v9
            ((Always) (cons 'j 'm 'p '32 (lab n s)))
            ((Less r1 r2)
               (cons 'c 'm 'p 'q '32
                  (reg r2
                     (cons ', '32 (reg r1 (cons '32 '; '32 'j 'b '32 (lab n s)))))))
            ((Equal r1 r2)
               (cons 'c 'm 'p 'q '32
                  (reg r2
                     (cons ', '32 (reg r1 (cons '32 '; '32 'j 'e '32 (lab n s)))))))))
      ((Call n) (cons 'c 'a 'l 'l '32 (lab n s)))
      ((Ret) (cons 'r 'e 't s))
      ((Pop r) (cons 'p 'o 'p 'q '32 (reg r s)))
      ((Push r) (cons 'p 'u 's 'h 'q '32 (reg r s)))
      ((Add_RSP n)
         (cons 'a 'd 'd 'q '32 '36
            (num (mul8 n) (cons ', '32 '37 'r 's 'p s))))
      ((Load_RSP r n)
         (cons 'm 'o 'v 'q '32
            (num (mul8 n) (cons '40 '37 'r 's 'p '41 ', '32 (reg r s)))))
      ((Load dst a w)
         (cons 'm 'o 'v 'q '32
            (num w (cons '40 (reg a (cons '41 ', '32 (reg dst s)))))))
      ((Store src a w)
         (cons 'm 'o 'v 'q '32
            (reg src (cons ', '32 (num w (cons '40 (reg a (cons '41 s))))))))
      ((GetChar)
         (cons 'm 'o 'v 'q '32 's 't 'd 'i 'n '40 '37 'r 'i 'p '41 ', '32
            '37 'r 'd 'i '32 '; '32 'c 'a 'l 'l '32 '_ I O '_ 'g 'e 't 'c '@ P
            L T s))
      ((PutChar)
         (cons 'm 'o 'v 'q '32 's 't 'd 'o 'u 't '40 '37 'r 'i 'p '41 ',
            '32 '37 'r 's 'i '32 '; '32 'c 'a 'l 'l '32 '_ I O '_ 'p 'u 't 'c
            '@ P L T s))
      ((Exit) (cons 'c 'a 'l 'l '32 'e 'x 'i 't '@ P L T s))
      ((Comment c)
         (cons '10 '10 '9 '/ '* '32 (clean c (cons '32 '* '/ s))))))

(defun insts (n v)
   (if (= v '0) '0
      (lab n
         (cons ': '9 (inst (head v) (cons '10 (insts (+ n '1) (tail v))))))))

(defun asm2str (xs)
   (append
      (list '9 '46 'b 's 's '10 '9 '46 'p '50 'a 'l 'i 'g 'n '32 '51
         '32 '32 '32 '32 '32 '32 '32 '32 '32 '32 '/ '* '32 '56 '- 'b 'y
         't 'e '32 'a 'l 'i 'g 'n '32 '32 '32 '32 '32 '32 '32 '32 '* '/
         '10 'h 'e 'a 'p S ': '10 '9 '46 's 'p 'a 'c 'e '32 '56 '* '49 '48
         '50 '52 '* '49 '48 '50 '52 '32 '32 '/ '* '32 'b 'y 't 'e 's '32
         'o 'f '32 'h 'e 'a 'p '32 's 'p 'a 'c 'e '32 '* '/ '10 '9 '46 'p
         '50 'a 'l 'i 'g 'n '32 '51 '32 '32 '32 '32 '32 '32 '32 '32 '32
         '32 '/ '* '32 '56 '- 'b 'y 't 'e '32 'a 'l 'i 'g 'n '32 '32 '32
         '32 '32 '32 '32 '32 '* '/ '10 'h 'e 'a 'p E ': '10 '10 '9 '46 't
         'e 'x 't '10 '9 '46 'g 'l 'o 'b 'l '32 'm 'a 'i 'n '10 'm 'a 'i 'n
         ': '10 '9 's 'u 'b 'q '32 '36 '56 ', '32 '37 'r 's 'p '32 '32
         '32 '32 '32 '32 '32 '32 '/ '* '32 '49 '54 '- 'b 'y 't 'e '32 'a
         'l 'i 'g 'n '32 '37 'r 's 'p '32 '* '/ '10 '9 'm 'o 'v 'a 'b 's
         '32 '36 'h 'e 'a 'p S ', '32 '37 'r '49 '52 '32 '32 '/ '* '32 'r
         '49 '52 '32 ': '= '32 'h 'e 'a 'p '32 's 't 'a 'r 't '32 '32 '*
         '/ '10 '9 'm 'o 'v 'a 'b 's '32 '36 'h 'e 'a 'p E ', '32 '37 'r
         '49 '53 '32 '32 '/ '* '32 'r '49 '53 '32 ': '= '32 'h 'e 'a 'p
         '32 'e 'n 'd '32 '32 '32 '32 '* '/ '10 '10)
      (insts '0 xs)))


# A function for printing a list of characters to stdout

(defun print (s)
   (if (= s '0) '0 (let (a (write (head s))) (print (tail s)))))


# The main expression

(print (asm2str (codegen (parser (lexer)))))

