;; FuelChain Contract

;; Define fuel token
(define-fungible-token fuel-token)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-quality (err u101))
(define-constant err-insufficient-balance (err u102))
(define-constant err-invalid-batch (err u103))
(define-constant err-unauthorized (err u104))
(define-constant err-paused (err u105))

;; Data structures
(define-map batches
  { batch-id: uint }
  {
    fuel-type: (string-ascii 20),
    quality: uint,
    quantity: uint,
    producer: principal,
    status: (string-ascii 10),
    timestamp: uint
  }
)

(define-data-var batch-nonce uint u0)
(define-data-var contract-paused bool false)

;; Events
(define-data-var last-event-id uint u0)

(define-map events
  { event-id: uint }
  {
    event-type: (string-ascii 20),
    batch-id: uint,
    data: (string-ascii 50),
    timestamp: uint
  }
)

;; Administrative functions
(define-public (pause-contract)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set contract-paused true)
    (ok true)))

(define-public (unpause-contract)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set contract-paused false)
    (ok true)))

;; Event logging
(define-private (log-event (event-type (string-ascii 20)) (batch-id uint) (data (string-ascii 50)))
  (let ((event-id (var-get last-event-id)))
    (map-set events
      { event-id: event-id }
      {
        event-type: event-type,
        batch-id: batch-id,
        data: data,
        timestamp: block-height
      }
    )
    (var-set last-event-id (+ event-id u1))
    (ok event-id)))

;; Create new fuel batch
(define-public (create-batch (quantity uint) (fuel-type (string-ascii 20)) (quality uint))
  (let
    ((batch-id (var-get batch-nonce)))
    (asserts! (not (var-get contract-paused)) err-paused)
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (try! (ft-mint? fuel-token quantity tx-sender))
    (map-set batches
      { batch-id: batch-id }
      {
        fuel-type: fuel-type,
        quality: quality,
        quantity: quantity,
        producer: tx-sender,
        status: "ACTIVE",
        timestamp: block-height
      }
    )
    (var-set batch-nonce (+ batch-id u1))
    (try! (log-event "BATCH_CREATED" batch-id fuel-type))
    (ok batch-id)))

;; Update batch status
(define-public (update-batch-status (batch-id uint) (new-status (string-ascii 10)))
  (let ((batch (unwrap! (map-get? batches { batch-id: batch-id }) err-invalid-batch)))
    (asserts! (not (var-get contract-paused)) err-paused)
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set batches
      { batch-id: batch-id }
      (merge batch { status: new-status })
    )
    (try! (log-event "STATUS_UPDATED" batch-id new-status))
    (ok true)))

;; Transfer fuel tokens
(define-public (transfer-fuel (amount uint) (sender principal) (recipient principal))
  (let ((sender-balance (ft-get-balance fuel-token sender)))
    (asserts! (not (var-get contract-paused)) err-paused)
    (asserts! (>= sender-balance amount) err-insufficient-balance)
    (try! (ft-transfer? fuel-token amount sender recipient))
    (try! (log-event "TRANSFER" u0 (concat (concat (to-ascii amount) "-FROM-") (to-ascii sender))))
    (ok true)))

;; Get batch details
(define-read-only (get-batch-info (batch-id uint))
  (ok (map-get? batches { batch-id: batch-id })))

;; Get fuel inventory
(define-read-only (get-inventory (account principal))
  (ok (ft-get-balance fuel-token account)))

;; Verify fuel quality
(define-public (verify-quality (batch-id uint) (actual-quality uint))
  (let ((batch (unwrap! (map-get? batches { batch-id: batch-id }) err-invalid-quality)))
    (asserts! (not (var-get contract-paused)) err-paused)
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (if (>= actual-quality (get quality batch))
      (begin
        (try! (log-event "QUALITY_VERIFIED" batch-id (concat "QUALITY-" (to-ascii actual-quality))))
        (ok true))
      err-invalid-quality)))

;; Get event details
(define-read-only (get-event (event-id uint))
  (ok (map-get? events { event-id: event-id })))
