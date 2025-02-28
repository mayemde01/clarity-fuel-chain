;; FuelChain Contract

;; Define fuel token
(define-fungible-token fuel-token)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-quality (err u101))
(define-constant err-insufficient-balance (err u102))

;; Data structures
(define-map batches
  { batch-id: uint }
  {
    fuel-type: (string-ascii 20),
    quality: uint,
    quantity: uint,
    producer: principal 
  }
)

(define-data-var batch-nonce uint u0)

;; Create new fuel batch
(define-public (create-batch (quantity uint) (fuel-type (string-ascii 20)) (quality uint))
  (let
    ((batch-id (var-get batch-nonce)))
    (if (is-eq tx-sender contract-owner)
      (begin
        (try! (ft-mint? fuel-token quantity tx-sender))
        (map-set batches
          { batch-id: batch-id }
          {
            fuel-type: fuel-type,
            quality: quality,
            quantity: quantity,
            producer: tx-sender
          }
        )
        (var-set batch-nonce (+ batch-id u1))
        (ok batch-id)
      )
      err-owner-only
    )
  )
)

;; Transfer fuel tokens
(define-public (transfer-fuel (amount uint) (sender principal) (recipient principal))
  (let ((sender-balance (ft-get-balance fuel-token sender)))
    (if (>= sender-balance amount)
      (begin
        (try! (ft-transfer? fuel-token amount sender recipient))
        (ok true)
      )
      err-insufficient-balance
    )
  )
)

;; Get batch details
(define-read-only (get-batch-info (batch-id uint))
  (ok (map-get? batches { batch-id: batch-id }))
)

;; Get fuel inventory
(define-read-only (get-inventory (account principal))
  (ok (ft-get-balance fuel-token account))
)

;; Verify fuel quality
(define-public (verify-quality (batch-id uint) (actual-quality uint))
  (let ((batch (unwrap! (map-get? batches { batch-id: batch-id }) err-invalid-quality)))
    (if (is-eq tx-sender contract-owner)
      (if (>= actual-quality (get quality batch))
        (ok true)
        err-invalid-quality
      )
      err-owner-only
    )
  )
)
