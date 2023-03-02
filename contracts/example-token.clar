(impl-trait .sip-010-trait-approve.sip-010-trait-approve)

(define-fungible-token example-token)

(define-map allowances { owner: principal, spender: principal } uint)

;; get the token balance of owner
(define-read-only (get-balance (owner principal))
  (begin
    (ok (ft-get-balance example-token owner))))

;; returns the total number of tokens
(define-read-only (get-total-supply)
  (ok (ft-get-supply example-token)))

;; returns the token name
(define-read-only (get-name)
  (ok "Example Token"))

;; the symbol or "ticker" for this token
(define-read-only (get-symbol)
  (ok "EXAMPLE"))

;; the number of decimals used
(define-read-only (get-decimals)
  (ok u8))

(define-public (get-token-uri)
  (ok (some u"https://example.com")))

;; Transfers tokens to a recipient
(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (begin
    (if (is-eq tx-sender sender)
      (try! (ft-transfer? example-token amount sender recipient))
      (begin
        (try! (spend-allowance sender tx-sender amount))
        (try! (ft-transfer? example-token amount sender recipient))
      )
    )
    (print memo)
    (ok true)
  )
  
)

(define-public (mint (recipient principal) (amount uint))
  (ft-mint? example-token amount recipient)
)

(define-public (burn (owner principal) (amount uint))
  (ft-burn? example-token amount owner)
)

;; -- approval

(define-private (spend-allowance (owner principal) (spender principal) (amount uint))
  (let ( (amount-allowed (unwrap-panic (allowance tx-sender spender))) )
    (asserts! (>= amount-allowed amount) (err u5))
    (ok (approve_ owner spender (- amount-allowed amount)))
  )
)

(define-private (approve_ (owner principal) (spender principal) (amount uint))
  (map-set allowances { owner: tx-sender, spender: spender } amount)
)

(define-public (increase-allowance (spender principal) (amount uint))
  (let ( (amount-allowed (unwrap-panic (allowance tx-sender spender))) )
    (ok (approve_ tx-sender spender (+ amount-allowed amount)) )
  )
)

(define-public (decrease-allowance (spender principal) (amount uint))
  (let ( (amount-allowed (unwrap-panic (allowance tx-sender spender))) )
    (asserts! (>= amount-allowed amount) (err u3))
    (ok (approve_ tx-sender spender (- amount-allowed amount)) )
  )
)

(define-public (allowance (owner principal) (spender principal))
  (ok (default-to u0 (map-get? allowances { owner: owner, spender: spender })))
)

(define-public (approve (spender principal) (amount uint))
  (ok (approve_ tx-sender spender amount))
)
