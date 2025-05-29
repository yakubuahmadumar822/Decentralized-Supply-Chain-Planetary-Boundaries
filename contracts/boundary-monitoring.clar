;; Boundary Monitoring Contract
;; Tracks planetary boundary compliance and thresholds

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u300))
(define-constant err-not-found (err u301))
(define-constant err-invalid-threshold (err u302))

;; Planetary boundary thresholds
(define-map boundary-thresholds
  { boundary-type: uint }
  {
    safe-threshold: uint,
    danger-threshold: uint,
    current-level: uint,
    last-updated: uint,
    measurement-unit: (string-ascii 20)
  }
)

;; Compliance status
(define-map entity-compliance
  { entity-id: uint, boundary-type: uint }
  {
    compliance-status: uint, ;; 0=safe, 1=warning, 2=danger
    last-assessment: uint,
    total-impact: uint
  }
)

;; Set boundary threshold (admin only)
(define-public (set-boundary-threshold
  (boundary-type uint)
  (safe-threshold uint)
  (danger-threshold uint)
  (measurement-unit (string-ascii 20))
)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (< safe-threshold danger-threshold) err-invalid-threshold)

    (map-set boundary-thresholds
      { boundary-type: boundary-type }
      {
        safe-threshold: safe-threshold,
        danger-threshold: danger-threshold,
        current-level: u0,
        last-updated: block-height,
        measurement-unit: measurement-unit
      }
    )
    (ok true)
  )
)

;; Update current planetary boundary level
(define-public (update-boundary-level (boundary-type uint) (current-level uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (match (map-get? boundary-thresholds { boundary-type: boundary-type })
      threshold-data
      (begin
        (map-set boundary-thresholds
          { boundary-type: boundary-type }
          (merge threshold-data { current-level: current-level, last-updated: block-height })
        )
        (ok true)
      )
      err-not-found
    )
  )
)

;; Assess entity compliance
(define-public (assess-compliance (entity-id uint) (boundary-type uint) (entity-impact uint))
  (match (map-get? boundary-thresholds { boundary-type: boundary-type })
    threshold-data
    (let (
      (safe-threshold (get safe-threshold threshold-data))
      (danger-threshold (get danger-threshold threshold-data))
      (compliance-status
        (if (<= entity-impact safe-threshold)
          u0  ;; safe
          (if (<= entity-impact danger-threshold)
            u1  ;; warning
            u2  ;; danger
          )
        )
      )
    )
      (map-set entity-compliance
        { entity-id: entity-id, boundary-type: boundary-type }
        {
          compliance-status: compliance-status,
          last-assessment: block-height,
          total-impact: entity-impact
        }
      )
      (ok compliance-status)
    )
    err-not-found
  )
)

;; Get boundary threshold
(define-read-only (get-boundary-threshold (boundary-type uint))
  (map-get? boundary-thresholds { boundary-type: boundary-type })
)

;; Get entity compliance status
(define-read-only (get-compliance-status (entity-id uint) (boundary-type uint))
  (map-get? entity-compliance { entity-id: entity-id, boundary-type: boundary-type })
)
