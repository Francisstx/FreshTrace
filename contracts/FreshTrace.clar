;; FreshTrace - Farm-to-Table Supply Chain Tracking Contract with IoT Integration
;; This contract enables transparent tracking of agricultural products from farm to consumer
;; with automated IoT sensor data collection, comprehensive input validation, quality certification system,
;; and consumer verification portal with QR code support

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_INVALID_INPUT (err u400))
(define-constant ERR_ALREADY_EXISTS (err u409))
(define-constant ERR_CERTIFICATION_EXPIRED (err u410))

;; Validation constants
(define-constant MIN_LATITUDE u0)        ;; -90 degrees * 1000000 = 0 (using offset)
(define-constant MAX_LATITUDE u180000000) ;; +90 degrees * 1000000 = 180000000 (using offset +90)
(define-constant MIN_LONGITUDE u0)        ;; -180 degrees * 1000000 = 0 (using offset)
(define-constant MAX_LONGITUDE u360000000) ;; +180 degrees * 1000000 = 360000000 (using offset +180)
(define-constant MIN_TEMPERATURE u0)      ;; -273C * 100 = 0 (using offset +273)
(define-constant MAX_TEMPERATURE u37300)  ;; 100C * 100 = 37300 (using offset +273)
(define-constant MIN_HUMIDITY u0)         ;; 0%
(define-constant MAX_HUMIDITY u10000)     ;; 100% * 100

;; Certification constants
(define-constant MAX_CERTIFICATIONS_PER_BATCH u10)
(define-constant CERTIFICATION_VALIDITY_PERIOD u52560) ;; ~1 year in blocks (assuming 10min blocks)

;; Data Variables
(define-data-var next-batch-id uint u1)
(define-data-var next-producer-id uint u1)
(define-data-var next-certification-id uint u1)

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
    created-at: uint,
    qr-code: (string-ascii 100)
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

;; IoT Sensor data mapping
(define-map sensor-data
  {batch-id: uint, reading-id: uint}
  {
    temperature: uint,  ;; Temperature in centigrade * 100 + 27300 offset (e.g., 29500 = 22.00C)
    humidity: uint,     ;; Humidity percentage * 100 (e.g., 6500 = 65.00%)
    latitude: uint,     ;; Latitude * 1000000 + 90000000 offset for precision
    longitude: uint,    ;; Longitude * 1000000 + 180000000 offset for precision
    timestamp: uint
  }
)

(define-map sensor-data-count uint uint)

;; Quality Certification System Maps
(define-map quality-certifications
  uint
  {
    certification-type: (string-ascii 30),  ;; "organic", "fair-trade", "non-gmo", etc.
    certifying-body: (string-ascii 50),     ;; Name of certification authority
    certificate-id: (string-ascii 50),      ;; Unique certificate identifier
    issue-date: uint,                        ;; Block height when issued
    expiry-date: uint,                       ;; Block height when expires
    verification-status: bool,               ;; Contract owner verification
    issuer: principal,                       ;; Who added this certification
    created-at: uint
  }
)

(define-map batch-certifications
  {batch-id: uint, cert-index: uint}
  uint  ;; certification-id
)

(define-map batch-certification-count uint uint)

;; Consumer Verification System Maps
(define-map consumer-verifications
  {batch-id: uint, verification-id: uint}
  {
    verifier: principal,
    timestamp: uint,
    location: (string-ascii 100)
  }
)

(define-map consumer-verification-count uint uint)

;; QR code to batch-id mapping for quick lookups
(define-map qr-code-lookup (string-ascii 100) uint)

;; Enhanced validation helpers
(define-private (is-valid-string (str (string-ascii 200)))
  (and (> (len str) u0) (<= (len str) u200))
)

(define-private (is-valid-name (name (string-ascii 50)))
  (and (> (len name) u0) (<= (len name) u50))
)

(define-private (is-valid-location (location (string-ascii 100)))
  (and (> (len location) u0) (<= (len location) u100))
)

(define-private (is-valid-certification (cert (string-ascii 30)))
  (and (> (len cert) u0) (<= (len cert) u30))
)

(define-private (is-valid-product-name (name (string-ascii 50)))
  (and (> (len name) u0) (<= (len name) u50))
)

(define-private (is-valid-event-type (event-type (string-ascii 30)))
  (and (> (len event-type) u0) (<= (len event-type) u30))
)

(define-private (is-valid-status (status (string-ascii 20)))
  (and (> (len status) u0) (<= (len status) u20))
)

(define-private (is-valid-notes (notes (string-ascii 200)))
  (<= (len notes) u200)
)

(define-private (is-valid-uint (value uint))
  (> value u0)
)

(define-private (is-valid-quantity (quantity uint))
  (and (> quantity u0) (<= quantity u4294967295)) ;; Max uint32
)

(define-private (is-valid-temperature (temp uint))
  (and (>= temp MIN_TEMPERATURE) (<= temp MAX_TEMPERATURE))
)

(define-private (is-valid-humidity (humidity uint))
  (and (>= humidity MIN_HUMIDITY) (<= humidity MAX_HUMIDITY))
)

(define-private (is-valid-latitude (lat uint))
  (and (>= lat MIN_LATITUDE) (<= lat MAX_LATITUDE))
)

(define-private (is-valid-longitude (lng uint))
  (and (>= lng MIN_LONGITUDE) (<= lng MAX_LONGITUDE))
)

(define-private (is-valid-timestamp (timestamp uint))
  (and (> timestamp u0) (<= timestamp stacks-block-height))
)

(define-private (is-valid-date-range (harvest-date uint) (expiry-date uint))
  (and 
    (> harvest-date u0)
    (> expiry-date harvest-date)
    (<= harvest-date stacks-block-height)
  )
)

(define-private (is-valid-cert-date-range (issue-date uint) (expiry-date uint))
  (and 
    (> issue-date u0)
    (> expiry-date issue-date)
    (<= issue-date stacks-block-height)
    (<= (- expiry-date issue-date) CERTIFICATION_VALIDITY_PERIOD)
  )
)

(define-private (is-certification-active (cert-id uint))
  (match (map-get? quality-certifications cert-id)
    cert-data
    (and 
      (get verification-status cert-data)
      (> (get expiry-date cert-data) stacks-block-height)
    )
    false
  )
)

(define-private (is-valid-certificate-id (cert-id (string-ascii 50)))
  (and (> (len cert-id) u0) (<= (len cert-id) u50))
)

(define-private (is-valid-certifying-body (body (string-ascii 50)))
  (and (> (len body) u0) (<= (len body) u50))
)

(define-private (is-valid-qr-code (qr-code (string-ascii 100)))
  (and (> (len qr-code) u0) (<= (len qr-code) u100))
)

;; Public Functions

;; Register a new producer
(define-public (register-producer (name (string-ascii 50)) (location (string-ascii 100)) (certification (string-ascii 30)))
  (let ((producer-id (var-get next-producer-id)))
    (asserts! (is-valid-name name) ERR_INVALID_INPUT)
    (asserts! (is-valid-location location) ERR_INVALID_INPUT)
    (asserts! (is-valid-certification certification) ERR_INVALID_INPUT)
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
    (asserts! (is-valid-uint producer-id) ERR_INVALID_INPUT)
    (asserts! (< producer-id (var-get next-producer-id)) ERR_NOT_FOUND)
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

;; Create a new batch with QR code
(define-public (create-batch 
  (producer-id uint)
  (product-name (string-ascii 50))
  (quantity uint)
  (harvest-date uint)
  (expiry-date uint)
  (location (string-ascii 100))
  (qr-code (string-ascii 100))
)
  (let ((batch-id (var-get next-batch-id)))
    (asserts! (is-valid-uint producer-id) ERR_INVALID_INPUT)
    (asserts! (< producer-id (var-get next-producer-id)) ERR_NOT_FOUND)
    (asserts! (is-valid-product-name product-name) ERR_INVALID_INPUT)
    (asserts! (is-valid-quantity quantity) ERR_INVALID_INPUT)
    (asserts! (is-valid-date-range harvest-date expiry-date) ERR_INVALID_INPUT)
    (asserts! (is-valid-location location) ERR_INVALID_INPUT)
    (asserts! (is-valid-qr-code qr-code) ERR_INVALID_INPUT)
    (asserts! (is-none (map-get? qr-code-lookup qr-code)) ERR_ALREADY_EXISTS)
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
          created-at: stacks-block-height,
          qr-code: qr-code
        })
        (map-set qr-code-lookup qr-code batch-id)
        (map-set batch-event-count batch-id u0)
        (map-set sensor-data-count batch-id u0)
        (map-set batch-certification-count batch-id u0)
        (map-set consumer-verification-count batch-id u0)
        (var-set next-batch-id (+ batch-id u1))
        (ok batch-id)
      )
      ERR_NOT_FOUND
    )
  )
)

;; Add quality certification
(define-public (add-quality-certification
  (certification-type (string-ascii 30))
  (certifying-body (string-ascii 50))
  (certificate-id (string-ascii 50))
  (issue-date uint)
  (expiry-date uint)
)
  (let ((cert-id (var-get next-certification-id)))
    (asserts! (is-valid-certification certification-type) ERR_INVALID_INPUT)
    (asserts! (is-valid-certifying-body certifying-body) ERR_INVALID_INPUT)
    (asserts! (is-valid-certificate-id certificate-id) ERR_INVALID_INPUT)
    (asserts! (is-valid-cert-date-range issue-date expiry-date) ERR_INVALID_INPUT)
    (map-set quality-certifications cert-id {
      certification-type: certification-type,
      certifying-body: certifying-body,
      certificate-id: certificate-id,
      issue-date: issue-date,
      expiry-date: expiry-date,
      verification-status: false,
      issuer: tx-sender,
      created-at: stacks-block-height
    })
    (var-set next-certification-id (+ cert-id u1))
    (ok cert-id)
  )
)

;; Verify quality certification (only contract owner)
(define-public (verify-quality-certification (cert-id uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-valid-uint cert-id) ERR_INVALID_INPUT)
    (asserts! (< cert-id (var-get next-certification-id)) ERR_NOT_FOUND)
    (match (map-get? quality-certifications cert-id)
      cert-data
      (begin
        (asserts! (> (get expiry-date cert-data) stacks-block-height) ERR_CERTIFICATION_EXPIRED)
        (map-set quality-certifications cert-id (merge cert-data {verification-status: true}))
        (ok true)
      )
      ERR_NOT_FOUND
    )
  )
)

;; Assign certification to batch
(define-public (assign-certification-to-batch (batch-id uint) (cert-id uint))
  (begin
    (asserts! (is-valid-uint batch-id) ERR_INVALID_INPUT)
    (asserts! (< batch-id (var-get next-batch-id)) ERR_NOT_FOUND)
    (asserts! (is-valid-uint cert-id) ERR_INVALID_INPUT)
    (asserts! (< cert-id (var-get next-certification-id)) ERR_NOT_FOUND)
    (asserts! (is-certification-active cert-id) ERR_CERTIFICATION_EXPIRED)
    (match (map-get? batches batch-id)
      batch-data
      (match (map-get? producers (get producer-id batch-data))
        producer-data
        (let ((cert-count (default-to u0 (map-get? batch-certification-count batch-id)))
              (new-cert-index (+ cert-count u1)))
          (asserts! (is-eq (get owner producer-data) tx-sender) ERR_UNAUTHORIZED)
          (asserts! (<= new-cert-index MAX_CERTIFICATIONS_PER_BATCH) ERR_INVALID_INPUT)
          (map-set batch-certifications
            {batch-id: batch-id, cert-index: new-cert-index}
            cert-id
          )
          (map-set batch-certification-count batch-id new-cert-index)
          (ok new-cert-index)
        )
        ERR_NOT_FOUND
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
    (asserts! (is-valid-uint batch-id) ERR_INVALID_INPUT)
    (asserts! (< batch-id (var-get next-batch-id)) ERR_NOT_FOUND)
    (asserts! (is-valid-event-type event-type) ERR_INVALID_INPUT)
    (asserts! (is-valid-location location) ERR_INVALID_INPUT)
    (asserts! (is-valid-notes notes) ERR_INVALID_INPUT)
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

;; Record IoT sensor data with comprehensive validation
(define-public (record-sensor-data 
  (batch-id uint)
  (temperature uint)
  (humidity uint)
  (latitude uint)
  (longitude uint)
)
  (begin
    (asserts! (is-valid-uint batch-id) ERR_INVALID_INPUT)
    (asserts! (< batch-id (var-get next-batch-id)) ERR_NOT_FOUND)
    (asserts! (is-valid-temperature temperature) ERR_INVALID_INPUT)
    (asserts! (is-valid-humidity humidity) ERR_INVALID_INPUT)
    (asserts! (is-valid-latitude latitude) ERR_INVALID_INPUT)
    (asserts! (is-valid-longitude longitude) ERR_INVALID_INPUT)
    (match (map-get? batches batch-id)
      batch-data
      (let ((reading-count (default-to u0 (map-get? sensor-data-count batch-id)))
            (new-reading-id (+ reading-count u1)))
        (map-set sensor-data
          {batch-id: batch-id, reading-id: new-reading-id}
          {
            temperature: temperature,
            humidity: humidity,
            latitude: latitude,
            longitude: longitude,
            timestamp: stacks-block-height
          }
        )
        (map-set sensor-data-count batch-id new-reading-id)
        (ok new-reading-id)
      )
      ERR_NOT_FOUND
    )
  )
)

;; Update batch status with validation
(define-public (update-batch-status (batch-id uint) (new-status (string-ascii 20)))
  (begin
    (asserts! (is-valid-uint batch-id) ERR_INVALID_INPUT)
    (asserts! (< batch-id (var-get next-batch-id)) ERR_NOT_FOUND)
    (asserts! (is-valid-status new-status) ERR_INVALID_INPUT)
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

;; Consumer verification via QR code scan
(define-public (verify-product-by-qr (qr-code (string-ascii 100)) (scan-location (string-ascii 100)))
  (begin
    (asserts! (is-valid-qr-code qr-code) ERR_INVALID_INPUT)
    (asserts! (is-valid-location scan-location) ERR_INVALID_INPUT)
    (match (map-get? qr-code-lookup qr-code)
      batch-id
      (let ((verification-count (default-to u0 (map-get? consumer-verification-count batch-id)))
            (new-verification-id (+ verification-count u1)))
        (map-set consumer-verifications
          {batch-id: batch-id, verification-id: new-verification-id}
          {
            verifier: tx-sender,
            timestamp: stacks-block-height,
            location: scan-location
          }
        )
        (map-set consumer-verification-count batch-id new-verification-id)
        (ok batch-id)
      )
      ERR_NOT_FOUND
    )
  )
)

;; Consumer verification via batch ID
(define-public (verify-product-by-batch (batch-id uint) (scan-location (string-ascii 100)))
  (begin
    (asserts! (is-valid-uint batch-id) ERR_INVALID_INPUT)
    (asserts! (< batch-id (var-get next-batch-id)) ERR_NOT_FOUND)
    (asserts! (is-valid-location scan-location) ERR_INVALID_INPUT)
    (match (map-get? batches batch-id)
      batch-data
      (let ((verification-count (default-to u0 (map-get? consumer-verification-count batch-id)))
            (new-verification-id (+ verification-count u1)))
        (map-set consumer-verifications
          {batch-id: batch-id, verification-id: new-verification-id}
          {
            verifier: tx-sender,
            timestamp: stacks-block-height,
            location: scan-location
          }
        )
        (map-set consumer-verification-count batch-id new-verification-id)
        (ok new-verification-id)
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

;; Get batch by QR code
(define-read-only (get-batch-by-qr (qr-code (string-ascii 100)))
  (match (map-get? qr-code-lookup qr-code)
    batch-id (map-get? batches batch-id)
    none
  )
)

;; Get batch ID from QR code
(define-read-only (get-batch-id-by-qr (qr-code (string-ascii 100)))
  (map-get? qr-code-lookup qr-code)
)

;; Get batch event
(define-read-only (get-batch-event (batch-id uint) (event-id uint))
  (map-get? batch-events {batch-id: batch-id, event-id: event-id})
)

;; Get total events for batch
(define-read-only (get-batch-event-count (batch-id uint))
  (default-to u0 (map-get? batch-event-count batch-id))
)

;; Get sensor data reading
(define-read-only (get-sensor-data (batch-id uint) (reading-id uint))
  (map-get? sensor-data {batch-id: batch-id, reading-id: reading-id})
)

;; Get total sensor readings for batch
(define-read-only (get-sensor-data-count (batch-id uint))
  (default-to u0 (map-get? sensor-data-count batch-id))
)

;; Get quality certification
(define-read-only (get-quality-certification (cert-id uint))
  (map-get? quality-certifications cert-id)
)

;; Get batch certification
(define-read-only (get-batch-certification (batch-id uint) (cert-index uint))
  (match (map-get? batch-certifications {batch-id: batch-id, cert-index: cert-index})
    cert-id (map-get? quality-certifications cert-id)
    none
  )
)

;; Get total certifications for batch
(define-read-only (get-batch-certification-count (batch-id uint))
  (default-to u0 (map-get? batch-certification-count batch-id))
)

;; Get consumer verification
(define-read-only (get-consumer-verification (batch-id uint) (verification-id uint))
  (map-get? consumer-verifications {batch-id: batch-id, verification-id: verification-id})
)

;; Get total consumer verifications for batch
(define-read-only (get-consumer-verification-count (batch-id uint))
  (default-to u0 (map-get? consumer-verification-count batch-id))
)

;; Get complete verification data for consumers
(define-read-only (get-complete-verification-data (batch-id uint))
  (match (map-get? batches batch-id)
    batch-data
    (match (map-get? producers (get producer-id batch-data))
      producer-data
      (ok {
        batch: batch-data,
        producer: producer-data,
        event-count: (default-to u0 (map-get? batch-event-count batch-id)),
        sensor-count: (default-to u0 (map-get? sensor-data-count batch-id)),
        cert-count: (default-to u0 (map-get? batch-certification-count batch-id)),
        verification-count: (default-to u0 (map-get? consumer-verification-count batch-id))
      })
      ERR_NOT_FOUND
    )
    ERR_NOT_FOUND
  )
)

;; Get complete verification data by QR code
(define-read-only (get-complete-verification-data-by-qr (qr-code (string-ascii 100)))
  (match (map-get? qr-code-lookup qr-code)
    batch-id (get-complete-verification-data batch-id)
    ERR_NOT_FOUND
  )
)

;; Check if certification is active
(define-read-only (is-certification-active-public (cert-id uint))
  (is-certification-active cert-id)
)

;; Get next batch ID
(define-read-only (get-next-batch-id)
  (var-get next-batch-id)
)

;; Get next producer ID
(define-read-only (get-next-producer-id)
  (var-get next-producer-id)
)

;; Get next certification ID
(define-read-only (get-next-certification-id)
  (var-get next-certification-id)
)

;; Check if producer is verified
(define-read-only (is-producer-verified (producer-id uint))
  (match (map-get? producers producer-id)
    producer-data (get verified producer-data)
    false
  )
)

;; Check if batch has expired
(define-read-only (is-batch-expired (batch-id uint))
  (match (map-get? batches batch-id)
    batch-data (>= stacks-block-height (get expiry-date batch-data))
    false
  )
)

;; Validate QR code exists
(define-read-only (is-qr-code-valid (qr-code (string-ascii 100)))
  (is-some (map-get? qr-code-lookup qr-code))
)

;; Additional validation helper functions for external use
(define-read-only (validate-coordinates (latitude uint) (longitude uint))
  (and (is-valid-latitude latitude) (is-valid-longitude longitude))
)

(define-read-only (validate-sensor-reading (temperature uint) (humidity uint))
  (and (is-valid-temperature temperature) (is-valid-humidity humidity))
)

(define-read-only (validate-certification-dates (issue-date uint) (expiry-date uint))
  (is-valid-cert-date-range issue-date expiry-date)
)