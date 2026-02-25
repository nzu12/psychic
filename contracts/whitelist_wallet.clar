;; Whitelist Wallet Smart Contract
;; Only whitelisted users can deposit/withdraw funds

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_WHITELISTED (err u101))
(define-constant ERR_INSUFFICIENT_BALANCE (err u102))
(define-constant ERR_INVALID_AMOUNT (err u103))

;; Data Variables
(define-data-var total-supply uint u0)

;; Data Maps
(define-map whitelist principal bool)
(define-map balances principal uint)

;; Private Functions
(define-private (is-contract-owner)
  (is-eq tx-sender CONTRACT_OWNER))

(define-private (is-whitelisted (user principal))
  (default-to false (map-get? whitelist user)))

;; Public Functions

;; Add user to whitelist (only contract owner)
(define-public (add-to-whitelist (user principal))
  (begin
    (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
    (ok (map-set whitelist user true))))

;; Remove user from whitelist (only contract owner)
(define-public (remove-from-whitelist (user principal))
  (begin
    (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
    (ok (map-delete whitelist user))))

;; Deposit STX tokens (only whitelisted users)
(define-public (deposit (amount uint))
  (let ((sender tx-sender)
        (current-balance (get-balance sender)))
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (is-whitelisted sender) ERR_NOT_WHITELISTED)
    (try! (stx-transfer? amount sender (as-contract tx-sender)))
    (map-set balances sender (+ current-balance amount))
    (var-set total-supply (+ (var-get total-supply) amount))
    (ok amount)))

;; Withdraw STX tokens (only whitelisted users)
(define-public (withdraw (amount uint))
  (let ((sender tx-sender)
        (current-balance (get-balance sender)))
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (is-whitelisted sender) ERR_NOT_WHITELISTED)
    (asserts! (>= current-balance amount) ERR_INSUFFICIENT_BALANCE)
    (try! (as-contract (stx-transfer? amount tx-sender sender)))
    (map-set balances sender (- current-balance amount))
    (var-set total-supply (- (var-get total-supply) amount))
    (ok amount)))

;; Transfer between whitelisted users
(define-public (transfer (recipient principal) (amount uint))
  (let ((sender tx-sender)
        (sender-balance (get-balance sender))
        (recipient-balance (get-balance recipient)))
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (is-whitelisted sender) ERR_NOT_WHITELISTED)
    (asserts! (is-whitelisted recipient) ERR_NOT_WHITELISTED)
    (asserts! (>= sender-balance amount) ERR_INSUFFICIENT_BALANCE)
    (map-set balances sender (- sender-balance amount))
    (map-set balances recipient (+ recipient-balance amount))
    (ok amount)))

;; Read-only Functions

;; Check if user is whitelisted
(define-read-only (check-whitelist (user principal))
  (is-whitelisted user))

;; Get user balance
(define-read-only (get-balance (user principal))
  (default-to u0 (map-get? balances user)))

;; Get total supply
(define-read-only (get-total-supply)
  (var-get total-supply))

;; Get contract owner
(define-read-only (get-contract-owner)
  CONTRACT_OWNER)

;; Get contract's STX balance
(define-read-only (get-contract-balance)
  (stx-get-balance (as-contract tx-sender)))