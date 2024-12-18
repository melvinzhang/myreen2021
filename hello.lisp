(defun print (s)
   (if (= s '0) '0 (let (a (write (head s))) (print (tail s)))))

(print (list 'H 'e 'l 'l 'o '33 '10))
