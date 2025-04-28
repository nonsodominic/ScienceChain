;; ScienceChain: Decentralized Scientific Research Funding
;; This contract allows researchers to submit proposals, reviewers to vote, funders to support approved projects, and implement a refund mechanism

;; Define constants
(define-constant CONTRACT_ADMIN tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_CONTRIBUTION (err u101))
(define-constant ERR_RESEARCH_NOT_FOUND (err u102))
(define-constant ERR_ALREADY_FUNDED (err u103))
(define-constant ERR_INVALID_TITLE (err u104))
(define-constant ERR_INVALID_DESCRIPTION (err u105))
(define-constant ERR_INVALID_FUNDING_GOAL (err u106))
(define-constant ERR_INVALID_RESEARCH_ID (err u107))
(define-constant ERR_INVALID_STATUS (err u108))
(define-constant ERR_ALREADY_REVIEWED (err u109))
(define-constant ERR_NOT_REVIEWER (err u110))
(define-constant ERR_INVALID_REVIEWER (err u111))
(define-constant ERR_NOT_CONTRIBUTOR (err u112))
(define-constant ERR_REFUND_NOT_AVAILABLE (err u113))

;; Define research statuses
(define-constant STATUS_SUBMITTED u0)
(define-constant STATUS_UNDER_REVIEW u1)
(define-constant STATUS_APPROVED u2)
(define-constant STATUS_REJECTED u3)
(define-constant STATUS_OPEN u4)
(define-constant STATUS_FUNDED u5)
(define-constant STATUS_COMPLETED u6)
(define-constant STATUS_REFUNDABLE u7)

;; Define review options
(define-constant REVIEW_APPROVE u1)
(define-constant REVIEW_REJECT u0)

;; Define data maps
(define-map research-projects
  { research-id: uint }
  {
    researcher: principal,
    title: (string-ascii 100),
    description: (string-ascii 1000),
    funding-goal: uint,
    current-funding: uint,
    status: uint,
    approve-count: uint,
    reject-count: uint,
    end-date: uint
  }
)

(define-map project-contributions
  { research-id: uint, contributor: principal }
  { amount: uint }
)

(define-map reviewers
  { reviewer: principal }
  { is-active: bool }
)

(define-map reviews
  { research-id: uint, reviewer: principal }
  { verdict: uint }
)

;; Define variables
(define-data-var research-counter uint u0)
(define-data-var minimum-reviews uint u3)
(define-data-var funding-period uint u43200) ;; Default to 30 days (in blocks, assuming 1 block every 60 seconds)

;; Helper functions for input validation
(define-private (is-valid-title (title (string-ascii 100)))
  (and (> (len title) u0) (<= (len title) u100))
)

(define-private (is-valid-description (description (string-ascii 1000)))
  (and (> (len description) u0) (<= (len description) u1000))
)

(define-private (is-valid-funding-goal (funding-goal uint))
  (> funding-goal u0)
)

(define-private (is-valid-research-id (research-id uint))
  (<= research-id (var-get research-counter))
)

(define-private (is-valid-status (status uint))
  (and (>= status STATUS_SUBMITTED) (<= status STATUS_REFUNDABLE))
)

(define-private (is-reviewer (account principal))
  (default-to false (get is-active (map-get? reviewers { reviewer: account })))
)

;; Public functions

;; Submit a new research project
(define-public (submit-research (title (string-ascii 100)) (description (string-ascii 1000)) (funding-goal uint))
  (begin
    (asserts! (is-valid-title title) ERR_INVALID_TITLE)
    (asserts! (is-valid-description description) ERR_INVALID_DESCRIPTION)
    (asserts! (is-valid-funding-goal funding-goal) ERR_INVALID_FUNDING_GOAL)
    (let
      (
        (research-id (+ (var-get research-counter) u1))
        (end-date (+ block-height (var-get funding-period)))
      )
      (map-set research-projects
        { research-id: research-id }
        {
          researcher: tx-sender,
          title: title,
          description: description,
          funding-goal: funding-goal,
          current-funding: u0,
          status: STATUS_SUBMITTED,
          approve-count: u0,
          reject-count: u0,
          end-date: end-date
        }
      )
      (var-set research-counter research-id)
      (ok research-id)
    )
  )
)

;; Vote on a project (only for reviewers)
(define-public (review-research (research-id uint) (verdict uint))
  (begin
    (asserts! (is-reviewer tx-sender) ERR_NOT_REVIEWER)
    (asserts! (is-valid-research-id research-id) ERR_INVALID_RESEARCH_ID)
    (asserts! (or (is-eq verdict REVIEW_APPROVE) (is-eq verdict REVIEW_REJECT)) ERR_INVALID_STATUS)
    (let
      (
        (project (unwrap-panic (map-get? research-projects { research-id: research-id })))
        (existing-review (map-get? reviews { research-id: research-id, reviewer: tx-sender }))
      )
      (asserts! (is-eq (get status project) STATUS_UNDER_REVIEW) ERR_INVALID_STATUS)
      (asserts! (is-none existing-review) ERR_ALREADY_REVIEWED)
      (map-set reviews { research-id: research-id, reviewer: tx-sender } { verdict: verdict })
      (if (is-eq verdict REVIEW_APPROVE)
        (map-set research-projects { research-id: research-id }
          (merge project { approve-count: (+ (get approve-count project) u1) }))
        (map-set research-projects { research-id: research-id }
          (merge project { reject-count: (+ (get reject-count project) u1) }))
      )
      (let
        (
          (updated-project (unwrap-panic (map-get? research-projects { research-id: research-id })))
          (total-reviews (+ (get approve-count updated-project) (get reject-count updated-project)))
        )
        (if (>= total-reviews (var-get minimum-reviews))
          (if (> (get approve-count updated-project) (get reject-count updated-project))
            (map-set research-projects { research-id: research-id }
              (merge updated-project { status: STATUS_APPROVED }))
            (map-set research-projects { research-id: research-id }
              (merge updated-project { status: STATUS_REJECTED }))
          )
          true
        )
      )
      (ok true)
    )
  )
)

;; Fund a research project
(define-public (fund-research (research-id uint) (amount uint))
  (begin
    (asserts! (is-valid-research-id research-id) ERR_INVALID_RESEARCH_ID)
    (asserts! (> amount u0) ERR_INVALID_CONTRIBUTION)
    (let
      (
        (project (unwrap-panic (map-get? research-projects { research-id: research-id })))
        (new-funding (+ (get current-funding project) amount))
      )
      (asserts! (is-eq (get status project) STATUS_OPEN) ERR_INVALID_STATUS)
      (asserts! (<= new-funding (get funding-goal project)) ERR_INVALID_CONTRIBUTION)
      (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
      (map-set research-projects
        { research-id: research-id }
        (merge project {
          current-funding: new-funding,
          status: (if (is-eq new-funding (get funding-goal project)) STATUS_FUNDED STATUS_OPEN)
        })
      )
      (map-set project-contributions
        { research-id: research-id, contributor: tx-sender }
        { amount: (+ amount (default-to u0 (get amount (map-get? project-contributions { research-id: research-id, contributor: tx-sender })))) }
      )
      (ok true)
    )
  )
)

