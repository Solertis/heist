; Any built-in functions that we can implement directly
; in Scheme should go here. If at all possible, write
; builtins in Scheme rather than Ruby.


; (newline)
; prints a new-line character
(define (newline)
  (display "\n"))

; (force)
; Extracts the value of a promise created using (delay)
(define (force promise) (promise))

; (call/cc)
; Alias for (call-with-current-continuation)
(define call/cc call-with-current-continuation)

; (eq? x y)
; Currently an alias for (eqv? x y). TODO implement properly
(define eq? eqv?)

; (not x)
; Boolean inverse of x
(define (not x)
  (if x #f #t))

; (negate x)
; Returns a negated form of x, like (not) but also
; works on functions
(define (negate proc)
  (if (procedure? proc)
      (lambda args (not (apply proc args)))
      (not proc)))

; Longhand aliases for boolean constants
(define true #t)
(define false #f)

; (boolean? x)
; Returns true iff x is a boolean value
(define (boolean? x)
  (or (eqv? x #t) (eqv? x #f)))

;----------------------------------------------------------------

; Numerical functions

; (number? x)
; Returns true iff x is any type of number
(define number? complex?)

; (inexact? x)
; Returns true iff x is not an exact number
(define inexact? (negate exact?))

; Returns true iff all arguments are numerically equal
(define (= . args)
  (define (iter x rest)
    (if (null? rest)
        #t
        (let ([y (car rest)])
          (if (or (not (number? x))
                  (not (number? y))
                  (not (equal? x y)))
              #f
              (iter x (cdr rest))))))
  (iter (car args) (cdr args)))

; (zero? x)
; Returns true iff x is zero
(define (zero? x)
  (eqv? x 0))

; (positive? x)
; Returns true iff x > 0
(define (positive? x)
  (> x 0))

; (negative? x)
; Returns true iff x < 0
(define (negative? x)
  (< x 0))

; (odd? x)
; Returns true iff x is odd
(define (odd? x)
  (= 1 (remainder x 2)))

; (even? x)
; Returns true iff x is even
(define (even? x)
  (zero? (remainder x 2)))

; (max arg1 arg2 ...)
; Returns the maximum value in the list of arguments
(define (max . values)
  (foldr (lambda (a b) (if (>= a b) a b))
         (car values)
         (cdr values)))

; (min arg1 arg2 ...)
; Returns the minimum value in the list of arguments
(define (min . values)
  (foldr (lambda (a b) (if (<= a b) a b))
         (car values)
         (cdr values)))

; (abs x)
; Returns the absolute value of a number
(define (abs x)
  (if (negative? x)
      (- x)
      x))

; (quotient) and (remainder) satisfy
; 
; (= n1 (+ (* n2 (quotient n1 n2))
;          (remainder n1 n2)))

; (quotient x y)
; Returns the quotient of two numbers, i.e. performs n1/n2
; and rounds toward zero.
(define (quotient x y)
  (let ([result (/ x y)])
    ((if (positive? result)
         floor
         ceiling)
     result)))

; (remainder x y)
; Returns the remainder after dividing the first operand
; by the second
(define (remainder x y)
  (- (round x)
     (* (round y)
        (quotient x y))))

; (modulo x y)
; Returns the first operand modulo the second
(define (modulo x y)
  (+ (remainder x y)
     (if (negative? (* x y))
         (round y)
         0)))

; (gcd x y)
; Returns the greatest common divisor of two numbers
; http://en.wikipedia.org/wiki/Euclidean_algorithm
; TODO take >2 arguments
(define (gcd x y)
  (if (zero? y)
      (abs x)
      (gcd y (remainder x y))))

; (lcm x y)
; Returns the lowest common multiple of two numbers
; http://en.wikipedia.org/wiki/Least_common_multiple
; TODO take >2 arguments
(define (lcm x y)
  (/ (abs (* x y))
     (gcd x y)))

(define ceiling ceil)

; (make-polar magnitude angle)
; Returns a new complex number with the given
; magnitude and angle
(define (make-polar magnitude angle)
  (let ([re (* magnitude (cos angle))]
        [im (* magnitude (sin angle))])
    (make-rectangular re im)))

; (magnitude z)
; Returns the magnitude of a complex number
(define (magnitude z)
  (let ([re (real-part z)]
        [im (imag-part z)])
    (sqrt (+ (* re re) (* im im)))))

; (angle z)
; Returns the angle a complex number makes with the
; real axis when plotted in the complex plane
(define (angle z)
  (let ([re (real-part z)]
        [im (imag-part z)])
    (atan im re)))

; (factorial x)
; Returns factorial of x
(define (factorial x)
  (define (iter y acc)
    (if (zero? y)
        acc
        (iter (- y 1) (* y acc))))
  (iter x 1))

;----------------------------------------------------------------

; List/pair functions

; (null? object)
; Returns true iff object is the empty list
(define (null? object)
  (eqv? '() object))

; (list? object)
; Returns true iff object is a proper list
(define (list? object)
  (or (null? object)
      (and (pair? object)
           (list? (cdr object)))))

; (list arg ...)
; Allocates and returns a new list from its arguments
(define (list . args) args)

; (length object)
; Returns the length of a proper list
(define (length object)
  (define (iter list acc)
    (if (null? list)
        acc
        (iter (cdr list) (+ 1 acc))))
  (iter object 0))

; (append list ...)
; Returns a new list formed by concatenating the arguments.
; The final argument is not copied and the return value of
; (append) shares structure with it.
(define (append first . rest)
  (if (null? rest)
      first
      (if (null? first)
          (apply append rest)
          (let ([copy (apply list first)])
            (do ([pair copy (cdr pair)])
                ((null? (cdr pair))
                  (set-cdr! pair (apply append rest))))
            copy))))

; (reverse list)
; Returns a newly allocated list consisting of the
; elements of list in reverse order.
(define (reverse object)
  (if (null? object)
      object
      (append (reverse (cdr object))
              (list (car object)))))

; (list-tail list k)
; Returns the sublist of list obtained by omitting the
; first k elements.
(define (list-tail list k)
  (do ([pair list (cdr pair)]
       [i k (- i 1)])
      ((zero? i) pair)))

; (list-ref list k)
; Returns the kth element of list.
(define (list-ref list k)
  (car (list-tail list k)))

; (memq obj list)
; (memv obj list)
; (member obj list)
; These procedures return the first sublist of list whose
; car is obj, where the sublists of list are the non-empty
; lists returned by (list-tail list k) for k less than the
; length of list. If obj does not occur in list, then #f
; (not the empty list) is returned. Memq uses eq? to compare
; obj with the elements of list, while memv uses eqv? and
; member uses equal?.

(define (list-transform-search transform)
  (lambda (predicate)
    (lambda (object list)
      (do ([pair list (cdr pair)])
          ((or (null? pair)
               (predicate (car (transform pair)) object))
           (if (null? pair)
               #f
               (transform pair)))))))

(define list-search (list-transform-search (lambda (x) x)))
(define memq   (list-search eq?))
(define memv   (list-search eqv?))
(define member (list-search equal?))

; (assq obj alist)
; (assv obj alist)
; (assoc obj alist)
; Alist (for "association list") must be a list of pairs.
; These procedures find the first pair in alist whose car
; field is obj, and returns that pair. If no pair in alist
; has obj as its car, then #f (not the empty list) is
; returned. Assq uses eq? to compare obj with the car fields
; of the pairs in alist, while assv uses eqv? and assoc
; uses equal?.

(define assoc-list-search (list-transform-search car))
(define assq  (assoc-list-search eq?))
(define assv  (assoc-list-search eqv?))
(define assoc (assoc-list-search equal?))

; (map proc list1 list2 ...)
; Returns a new list formed by applying proc to each member
; (or set of members) of the given list(s).
(define (map proc list1 . list2)
  (if (null? list1)
      list1
      (if (null? list2)
          (cons (proc (car list1))
                (map proc (cdr list1)))
          (let* ([all (cons list1 list2)]
                 [args (map car all)]
                 [rest (map cdr all)])
            (cons (apply proc args)
                  (apply map (cons proc rest)))))))

; (for-each proc list1 list2 ...)
; Calls proc once for each member of list1, passing each
; member (or set of members if more than one list given)
; as arguments to proc.
(define (for-each proc list1 . list2)
  (do ([pair list1 (cdr pair)]
       [others list2 (map cdr others)])
      ((null? pair) '())
    (apply proc (cons (car pair)
                      (map car others)))))

; (foldr proc value list)
(define (foldr proc value list)
  (if (null? list)
      value
      (proc (car list)
            (foldr proc value (cdr list)))))

;----------------------------------------------------------------

; Character functions

; (char-upper-case? letter)
; Returns true iff letter is an uppercase letter
(define (char-upper-case? letter)
  (and (char? letter)
       (let ([code (char->integer letter)])
         (and (>= code 65)
              (<= code 90)))))

; (char-lower-case? letter)
; Returns true iff letter is a lowercase letter
(define (char-lower-case? letter)
  (and (char? letter)
       (let ([code (char->integer letter)])
         (and (>= code 97)
              (<= code 122)))))

; (char-alphabetic? char)
; Returns true iff char is an alphabetic character
(define (char-alphabetic? char)
  (or (char-upper-case? char)
      (char-lower-case? char)))

; (char-numeric? char)
; Returns true iff char is a numeric character
(define (char-numeric? char)
  (and (char? char)
       (let ([code (char->integer char)])
         (and (>= code 48)
              (<= code 57)))))

; (char-whitespace? char)
; Returns true iff char is a whitespace character
(define (char-whitespace? char)
  (and (char? char)
       (if (member (char->integer char)
                  '(9 10 32))
           #t
           #f)))

; (char-upcase char)
; Returns an uppercase copy of char
(define (char-upcase char)
  (let ([code (char->integer char)])
    (if (and (>= code 97) (<= code 122))
        (integer->char (- code 32))
        (integer->char code))))

; (char-downcase char)
; Returns a lowercase copy of char
(define (char-downcase char)
  (let ([code (char->integer char)])
    (if (and (>= code 65) (<= code 90))
        (integer->char (+ code 32))
        (integer->char code))))

(define (char-compare-ci operator)
  (lambda (x y)
    (operator (char-downcase x)
              (char-downcase y))))

(define char-ci=?  (char-compare-ci char=?))
(define char-ci<?  (char-compare-ci char<?))
(define char-ci>?  (char-compare-ci char>?))
(define char-ci<=? (char-compare-ci char<=?))
(define char-ci>=? (char-compare-ci char>=?))

;----------------------------------------------------------------

; String functions

; (string char ...)
; Returns a new string formed by combining the given characters
(define (string . chars) (list->string chars))

; (string=? x y)
; Returns true iff x and y are equal strings
(define (string=? x y)
  (string-equal? x y char=?))

; (string-ci=? x y)
; Returns true iff x and y are equal strings, ignoring case
(define (string-ci=? x y)
  (string-equal? x y char-ci=?))

(define (string-equal? x y comparator)
  (and (string? x)
       (string? y)
       (let ([l1 (string-length x)]
             [l2 (string-length y)])
         (and (= l1 l2)
              (do ([i 0 (+ i 1)]
                   [result #t (comparator (string-ref x i)
                                          (string-ref y i))])
                  ((or (= i l1)
                       (not result))
                   result))))))

; (substring string start end)
; Returns a string composed of the characters from start (inclusive)
; to end (exclusive) in string
(define (substring string start end)
  (let ([size (string-length string)])
    (cond [(< start 0)   (error "start index must be positive")]
          [(> end size)  (error "end index must be <= the length of string")]
          [(> start end) (error "start must be <= end index")]
          [else
            (let* ([subsize (- end start)]
                   [substr (make-string subsize)])
              (do ([i 0 (+ i 1)])
                  ((= i subsize) substr)
                (string-set! substr i (string-ref string (+ start i)))))])))

; (list->string chars)
; Returns a new string formed by combining the list
(define (list->string chars)
  (let* ([size (length chars)]
         [str (make-string size)])
    (do ([list chars (cdr list)]
         [i 0 (+ i 1)])
        ((= i size) str)
      (string-set! str i (car list)))))

; (string->list string)
; Returns a newly allocated list of the characters in the string
(define (string->list string)
  (let ([size (string-length string)])
    (do ([i size (- i 1)]
         [list '() (cons (string-ref string (- i 1)) list)])
        ((zero? i) list))))

; (string-copy string)
; Returns a newly allocated copy of the string
(define (string-copy string)
  (list->string (string->list string)))

; (string-fill! string char)
; Replaces every character of string with char
(define (string-fill! string char)
  (let ([size (string-length string)])
    (do ([i size (- i 1)])
        ((zero? i) string)
      (string-set! string (- i 1) char))))

; (string-append string ...)
; Returns a new string formed by concatenating the arguments
(define (string-append . strings)
  (list->string (apply append (map string->list strings))))

;----------------------------------------------------------------

; Vector functions

; (vector object ...)
; Returns a newly allocated vector from its arguments
(define (vector . args) (list->vector args))

; (list->vector list)
; Returns a newly allocated vector from a list
(define (list->vector list)
  (let* ([size (length list)]
         [new-vector (make-vector size)])
    (do ([i 0 (+ i 1)]
         [pair list (cdr pair)])
        ((= i size) new-vector)
      (vector-set! new-vector i (car pair)))))

; (vector->list vector)
; Returns a newly allocated proper list from a vector
(define (vector->list vector)
  (do ([i (vector-length vector) (- i 1)]
       [pair '() (cons (vector-ref vector (- i 1)) pair)])
      ((zero? i) pair)))

; (vector-fill! vector fill)
; Sets every element of vector to fill
(define (vector-fill! vector fill)
  (do ([i (vector-length vector) (- i 1)])
      ((zero? i) vector)
    (vector-set! vector (- i 1) fill)))

