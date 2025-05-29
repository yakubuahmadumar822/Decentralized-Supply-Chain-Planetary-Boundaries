;; Entity Verification Contract
;; Validates and manages supply chain participants

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))

;; Entity status types
(define-constant status-pending u0)
(define-constant status-verified u1)
(define-constant status-suspended u2)
(define-constant status-revoked u3)

;; Entity data structure
(define-map entities
  { entity-id: uint }
  {
    owner: principal,
    name: (string-ascii 100),
    entity-type: (string-ascii 50),
    status: uint,
    verification-date: uint,
    certifications: (list 10 (string-ascii 50))
  }
)

(define-data-var next-entity-id uint u1)

;; Register new entity
(define-public (register-entity (name (string-ascii 100)) (entity-type (string-ascii 50)) (certifications (list 10 (string-ascii 50))))
  (let ((entity-id (var-get next-entity-id)))
    (map-set entities
      { entity-id: entity-id }
      {
        owner: tx-sender,
        name: name,
        entity-type: entity-type,
        status: status-pending,
        verification-date: u0,
        certifications: certifications
      }
    )
    (var-set next-entity-id (+ entity-id u1))
    (ok entity-id)
  )
)

;; Verify entity (admin only)
(define-public (verify-entity (entity-id uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (match (map-get? entities { entity-id: entity-id })
      entity-data
      (begin
        (map-set entities
          { entity-id: entity-id }
          (merge entity-data { status: status-verified, verification-date: block-height })
        )
        (ok true)
      )
      err-not-found
    )
  )
)

;; Get entity details
(define-read-only (get-entity (entity-id uint))
  (map-get? entities { entity-id: entity-id })
)

;; Check if entity is verified
(define-read-only (is-verified (entity-id uint))
  (match (map-get? entities { entity-id: entity-id })
    entity-data (is-eq (get status entity-data) status-verified)
    false
  )
)
