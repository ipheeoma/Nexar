;; Vaultify NFT Marketplace Smart Contract
;; Define response codes
(define-constant unauthorized-access (err u100))
(define-constant insufficient-permissions (err u101))
(define-constant market-entry-missing (err u102))
(define-constant amount-below-minimum (err u103))
(define-constant asset-identifier-invalid (err u104))
(define-constant metadata-format-error (err u105))
(define-constant commission-rate-exceeded (err u106))

;; Define digital collectible asset
(define-non-fungible-token artvault uint)

;; Define storage variables
(define-data-var platform-administrator principal tx-sender)
(define-data-var upcoming-asset-id uint u1)

;; Define storage mappings
(define-map digital-assets
  { asset-id: uint }
  { holder: principal, originator: principal, metadata-link: (string-ascii 256), creator-fee: uint }
)

(define-map marketplace-entries
  { asset-id: uint }
  { asking-amount: uint, vendor: principal }
)

;; Private helper to verify administrative privileges
(define-private (has-admin-rights)
  (is-eq tx-sender (var-get platform-administrator))
)

;; Update platform administration
(define-public (update-admin-role (successor principal))
  (begin
    (asserts! (has-admin-rights) unauthorized-access)
    (asserts! (is-standard successor) metadata-format-error)
    (ok (var-set platform-administrator successor))
  )
)

;; Retrieve current platform administrator
(define-read-only (get-admin-info)
  (ok (var-get platform-administrator))
)

;; Create new digital collectible
(define-public (forge-asset (metadata-link (string-ascii 256)) (creator-fee uint))
  (let
    (
      (current-id (var-get upcoming-asset-id))
    )
    (asserts! (> (len metadata-link) u0) metadata-format-error)
    (asserts! (<= creator-fee u1000) commission-rate-exceeded)
    (try! (nft-mint? artvault current-id tx-sender))
    (map-set digital-assets
      { asset-id: current-id }
      { holder: tx-sender, originator: tx-sender, metadata-link: metadata-link, creator-fee: creator-fee }
    )
    (var-set upcoming-asset-id (+ current-id u1))
    (ok current-id)
  )
)

;; Place asset on marketplace
(define-public (offer-for-trade (asset-id uint) (asking-amount uint))
  (let
    (
      (current-holder (unwrap! (nft-get-owner? artvault asset-id) asset-identifier-invalid))
    )
    (asserts! (> asking-amount u0) amount-below-minimum)
    (asserts! (is-eq tx-sender current-holder) insufficient-permissions)
    (map-set marketplace-entries
      { asset-id: asset-id }
      { asking-amount: asking-amount, vendor: tx-sender }
    )
    (ok true)
  )
)

;; Remove asset from marketplace
(define-public (withdraw-offer (asset-id uint))
  (let
    (
      (market-data (unwrap! (map-get? marketplace-entries { asset-id: asset-id }) market-entry-missing))
    )
    (asserts! (< asset-id (var-get upcoming-asset-id)) asset-identifier-invalid)
    (asserts! (is-eq tx-sender (get vendor market-data)) insufficient-permissions)
    (map-delete marketplace-entries { asset-id: asset-id })
    (ok true)
  )
)

;; Purchase digital asset
(define-public (acquire-asset (asset-id uint))
  (let
    (
      (market-data (unwrap! (map-get? marketplace-entries { asset-id: asset-id }) market-entry-missing))
      (total-cost (get asking-amount market-data))
      (current-vendor (get vendor market-data))
      (asset-info (unwrap! (map-get? digital-assets { asset-id: asset-id }) asset-identifier-invalid))
      (original-creator (get originator asset-info))
      (royalty-percentage (get creator-fee asset-info))
      (creator-payment (/ (* total-cost royalty-percentage) u10000))
      (vendor-payment (- total-cost creator-payment))
    )
    (asserts! (< asset-id (var-get upcoming-asset-id)) asset-identifier-invalid)
    (try! (stx-transfer? creator-payment tx-sender original-creator))
    (try! (stx-transfer? vendor-payment tx-sender current-vendor))
    (try! (nft-transfer? artvault asset-id current-vendor tx-sender))
    (map-set digital-assets
      { asset-id: asset-id }
      (merge asset-info { holder: tx-sender })
    )
    (map-delete marketplace-entries { asset-id: asset-id })
    (ok true)
  )
)

;; Retrieve asset information
(define-read-only (fetch-asset-data (asset-id uint))
  (ok (unwrap! (map-get? digital-assets { asset-id: asset-id }) asset-identifier-invalid))
)

;; Retrieve marketplace information
(define-read-only (fetch-market-data (asset-id uint))
  (ok (unwrap! (map-get? marketplace-entries { asset-id: asset-id }) market-entry-missing))
)