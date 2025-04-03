;; Certification Authority Contract
;; This contract validates legitimate issuing organizations

;; Define data variables
(define-data-var contract-owner principal tx-sender)
(define-map authorities
  { authority-id: (string-ascii 64) }
  {
    name: (string-ascii 256),
    website: (string-ascii 256),
    active: bool,
    created-at: uint,
    updated-at: uint
  }
)

;; Define error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_ALREADY_EXISTS u2)
(define-constant ERR_NOT_FOUND u3)

;; Check if caller is contract owner
(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner))
)

;; Register a new certification authority
(define-public (register-authority
    (authority-id (string-ascii 64))
    (name (string-ascii 256))
    (website (string-ascii 256)))
  (begin
    (asserts! (is-contract-owner) (err ERR_UNAUTHORIZED))
    (asserts! (is-none (map-get? authorities { authority-id: authority-id })) (err ERR_ALREADY_EXISTS))

    (map-set authorities
      { authority-id: authority-id }
      {
        name: name,
        website: website,
        active: true,
        created-at: block-height,
        updated-at: block-height
      }
    )
    (ok true)
  )
)

;; Update an existing authority
(define-public (update-authority
    (authority-id (string-ascii 64))
    (name (string-ascii 256))
    (website (string-ascii 256)))
  (begin
    (asserts! (is-contract-owner) (err ERR_UNAUTHORIZED))
    (asserts! (is-some (map-get? authorities { authority-id: authority-id })) (err ERR_NOT_FOUND))

    (map-set authorities
      { authority-id: authority-id }
      {
        name: name,
        website: website,
        active: true,
        created-at: (get created-at (unwrap-panic (map-get? authorities { authority-id: authority-id }))),
        updated-at: block-height
      }
    )
    (ok true)
  )
)

;; Deactivate an authority
(define-public (deactivate-authority (authority-id (string-ascii 64)))
  (begin
    (asserts! (is-contract-owner) (err ERR_UNAUTHORIZED))
    (asserts! (is-some (map-get? authorities { authority-id: authority-id })) (err ERR_NOT_FOUND))

    (let ((authority (unwrap-panic (map-get? authorities { authority-id: authority-id }))))
      (map-set authorities
        { authority-id: authority-id }
        {
          name: (get name authority),
          website: (get website authority),
          active: false,
          created-at: (get created-at authority),
          updated-at: block-height
        }
      )
    )
    (ok true)
  )
)

;; Check if an authority is active
(define-read-only (is-authority-active (authority-id (string-ascii 64)))
  (match (map-get? authorities { authority-id: authority-id })
    authority (ok (get active authority))
    (err ERR_NOT_FOUND)
  )
)

;; Get authority details
(define-read-only (get-authority (authority-id (string-ascii 64)))
  (map-get? authorities { authority-id: authority-id })
)

;; Transfer contract ownership
(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-contract-owner) (err ERR_UNAUTHORIZED))
    (var-set contract-owner new-owner)
    (ok true)
  )
)
