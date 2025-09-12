;; FreshTrace - Farm-to-Table Supply Chain Tracking Contract with IoT Integration
;; This contract enables transparent tracking of agricultural products from farm to consumer
;; with automated IoT sensor data collection and comprehensive input validation

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_INVALID_INPUT (err u400))
(define-constant ERR_ALREADY_EXISTS (err u409))

;; Validation constants
(define-constant MIN_LATITUDE u0)        ;; -90 degrees * 1000000 = 0 (using offset)
(define-constant MAX_LATITUDE u180000000) ;; +90 degrees * 1000000 = 180000000 (using offset +90)
(define-constant MIN_LONGITUDE u0)        ;; -180 degrees * 1000000 = 0 (using offset)
(define-constant MAX_LONGITUDE u360000000) ;; +180 degrees * 1000000 = 360000000 (using offset +180)
(define-constant MIN_TEMPERATURE u0)      ;; -273C * 100 = 0 (using offset +273)
(define-constant MAX_TEMPERATURE u37300)  ;; 100C * 100 = 37300 (using offset +273)
(define-constant MIN_HUMIDITY u0)         ;; 0%
(define-constant MAX_HUMIDITY u10000)     ;; 100% * 100

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
    (asserts! (is-valid-uint producer-id) ERR_INVALID_INPUT)
    (asserts! (< producer-id (var-get next-producer-id)) ERR_NOT_FOUND)
    (asserts! (is-valid-product-name product-name) ERR_INVALID_INPUT)
    (asserts! (is-valid-quantity quantity) ERR_INVALID_INPUT)
    (asserts! (is-valid-date-range harvest-date expiry-date) ERR_INVALID_INPUT)
    (asserts! (is-valid-location location) ERR_INVALID_INPUT)
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
        (map-set sensor-data-count batch-id u0)
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

;; Get sensor data reading
(define-read-only (get-sensor-data (batch-id uint) (reading-id uint))
  (map-get? sensor-data {batch-id: batch-id, reading-id: reading-id})
)

;; Get total sensor readings for batch
(define-read-only (get-sensor-data-count (batch-id uint))
  (default-to u0 (map-get? sensor-data-count batch-id))
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

;; Additional validation helper functions for external use
(define-read-only (validate-coordinates (latitude uint) (longitude uint))
  (and (is-valid-latitude latitude) (is-valid-longitude longitude))
)

(define-read-only (validate-sensor-reading (temperature uint) (humidity uint))
  (and (is-valid-temperature temperature) (is-valid-humidity humidity))
)