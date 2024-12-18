compiler: compiler.s
	cc $^ -o $@ 

test: compiler compiler.lisp
	./compiler < compiler.lisp > compiler.s
	git diff compiler.s

%: %.lisp compiler
	./compiler < $^ > $@.s
	cc $@.s -o $@
