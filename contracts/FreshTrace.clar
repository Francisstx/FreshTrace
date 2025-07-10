;; FreshTrace - Farm-to-Table Supply Chain Tracking Contract
;; This contract enables transparent tracking of agricultural products from farm to consumer

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_INVALID_BATCH (err u400))
(define-constant ERR_ALREADY_EXISTS (err u409))

;; Data Variables
(define-data-var next-batch-id uint u1)
(define-data-var next-producer-id uint u1)

;; Data Maps
(define-map producers 
  uint 
  {
    name: (string-ascii 50),
    location: (string-ascii 100),
    certification: (string-ascii 30),
    owner: principal,
    verified: bool
  }
)

(define-map batches
  uint
  {
    producer-id: uint,
    product-name: (string-ascii 50),
    quantity: uint,
    harvest-date: uint,
    expiry-date: uint,
    location: (string-ascii 100),
    status: (string-ascii 20),
    created-at: uint
  }
)

(define-map batch-events
  {batch-id: uint, event-id: uint}
  {
    event-type: (string-ascii 30),
    location: (string-ascii 100),
    timestamp: uint,
    notes: (string-ascii 200)
  }
)

(define-map batch-event-count uint uint)

;; Public Functions

;; Register a new producer
(define-public (register-producer (name (string-ascii 50)) (location (string-ascii 100)) (certification (string-ascii 30)))
  (let ((producer-id (var-get next-producer-id)))
    (asserts! (> (len name) u0) ERR_INVALID_BATCH)
    (asserts! (> (len location) u0) ERR_INVALID_BATCH)
    (asserts! (> (len certification) u0) ERR_INVALID_BATCH)
    (map-set producers producer-id {
      name: name,
      location: location,
      certification: certification,
      owner: tx-sender,
      verified: false
    })
    (var-set next-producer-id (+ producer-id u1))
    (ok producer-id)
  )
)

;; Verify a producer (only contract owner)
(define-public (verify-producer (producer-id uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (> producer-id u0) ERR_INVALID_BATCH)
    (match (map-get? producers producer-id)
      producer-data
      (begin
        (map-set producers producer-id (merge producer-data {verified: true}))
        (ok true)
      )
      ERR_NOT_FOUND
    )
  )
)

;; Create a new batch
(define-public (create-batch 
  (producer-id uint)
  (product-name (string-ascii 50))
  (quantity uint)
  (harvest-date uint)
  (expiry-date uint)
  (location (string-ascii 100))
)
  (let ((batch-id (var-get next-batch-id)))
    (asserts! (> producer-id u0) ERR_INVALID_BATCH)
    (asserts! (> (len product-name) u0) ERR_INVALID_BATCH)
    (asserts! (> quantity u0) ERR_INVALID_BATCH)
    (asserts! (> harvest-date u0) ERR_INVALID_BATCH)
    (asserts! (> expiry-date harvest-date) ERR_INVALID_BATCH)
    (asserts! (> (len location) u0) ERR_INVALID_BATCH)
    (match (map-get? producers producer-id)
      producer-data
      (begin
        (asserts! (is-eq (get owner producer-data) tx-sender) ERR_UNAUTHORIZED)
        (asserts! (get verified producer-data) ERR_UNAUTHORIZED)
        (map-set batches batch-id {
          producer-id: producer-id,
          product-name: product-name,
          quantity: quantity,
          harvest-date: harvest-date,
          expiry-date: expiry-date,
          location: location,
          status: "harvested",
          created-at: stacks-block-height
        })
        (map-set batch-event-count batch-id u0)
        (var-set next-batch-id (+ batch-id u1))
        (ok batch-id)
      )
      ERR_NOT_FOUND
    )
  )
)

;; Add tracking event to batch
(define-public (add-batch-event 
  (batch-id uint)
  (event-type (string-ascii 30))
  (location (string-ascii 100))
  (notes (string-ascii 200))
)
  (begin
    (asserts! (> batch-id u0) ERR_INVALID_BATCH)
    (asserts! (> (len event-type) u0) ERR_INVALID_BATCH)
    (asserts! (> (len location) u0) ERR_INVALID_BATCH)
    (asserts! (> (len notes) u0) ERR_INVALID_BATCH)
    (match (map-get? batches batch-id)
      batch-data
      (let ((event-count (default-to u0 (map-get? batch-event-count batch-id)))
            (new-event-id (+ event-count u1)))
        (map-set batch-events 
          {batch-id: batch-id, event-id: new-event-id}
          {
            event-type: event-type,
            location: location,
            timestamp: stacks-block-height,
            notes: notes
          }
        )
        (map-set batch-event-count batch-id new-event-id)
        (ok new-event-id)
      )
      ERR_NOT_FOUND
    )
  )
)

;; Update batch status
(define-public (update-batch-status (batch-id uint) (new-status (string-ascii 20)))
  (begin
    (asserts! (> batch-id u0) ERR_INVALID_BATCH)
    (asserts! (> (len new-status) u0) ERR_INVALID_BATCH)
    (match (map-get? batches batch-id)
      batch-data
      (begin
        (map-set batches batch-id (merge batch-data {status: new-status}))
        (ok true)
      )
      ERR_NOT_FOUND
    )
  )
)

;; Read-only functions

;; Get producer information
(define-read-only (get-producer (producer-id uint))
  (map-get? producers producer-id)
)

;; Get batch information
(define-read-only (get-batch (batch-id uint))
  (map-get? batches batch-id)
)

;; Get batch event
(define-read-only (get-batch-event (batch-id uint) (event-id uint))
  (map-get? batch-events {batch-id: batch-id, event-id: event-id})
)

;; Get total events for batch
(define-read-only (get-batch-event-count (batch-id uint))
  (default-to u0 (map-get? batch-event-count batch-id))
)

;; Get next batch ID
(define-read-only (get-next-batch-id)
  (var-get next-batch-id)
)

;; Get next producer ID
(define-read-only (get-next-producer-id)
  (var-get next-producer-id)
)

;; Check if producer is verified
(define-read-only (is-producer-verified (producer-id uint))
  (match (map-get? producers producer-id)
    producer-data (get verified producer-data)
    false
  )
)