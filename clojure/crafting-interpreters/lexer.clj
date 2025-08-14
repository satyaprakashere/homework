(ns lexer)

(def TokenType #{
 ; Single-character tokens.
                 :LEFT_PAREN, :RIGHT_PAREN, :LEFT_BRACE, :RIGHT_BRACE,
                 :COMMA, :DOT, :MINUS, :PLUS, :SEMICOLON, :SLASH, :STAR,

 ; One or two character tokens.
                 :BANG, :BANG_EQUAL,
                 :EQUAL, :EQUAL_EQUAL,
                 :GREATER, :GREATER_EQUAL,
                 :LESS, :LESS_EQUAL,

 ; Literals.
                 :IDENTIFIER, :STRING, :NUMBER,

 ; Keywords.
                 :AND, :CLASS, :ELSE, :FALSE, :FUN, :FOR, :IF, :NIL, :OR,
                 :PRINT, :RETURN, :SUPER, :THIS, :TRUE, :VAR, :WHILE,

                 :EOF})

(deftype Token
  [type lexeme literal line])

(deftype Scanner
  [source tokens])

(defn addToken
  ([tokens type text] (addToken tokens text type nil))
  ([tokens type text literal] (conj tokens (Token. type text literal 0))))

(defn scanToken [source start current line tokens]
  (let [c (.charAt source current)
        text (.substring source start (inc current))]
    (cond
      (= c \() (addToken tokens text :LEFT_PAREN)
      (= c \)) (addToken tokens text :RIGHT_PAREN)
      (= c \{) (addToken tokens text :LEFT_BRACE)
      (= c \}) (addToken tokens text :RIGHT_BRACE)
      :else (throw (Exception. "Something went wrong")))))

(defn scanTokens
  ([source] (scanTokens source 0 1 (count source) []))
  ([source current line slen tokens]
   (if (>= current slen)
     (conj tokens (Token. :EOF "" nil line))
     (let [uTokens (scanToken source current current line tokens)]
       (recur source (inc current) line slen uTokens)))))

;; (defn tokenize [input]
;;   (let [tokens (re-seq #"\w+" input)]
;;     (map #(hash-map :type :word :value %) tokens)))
