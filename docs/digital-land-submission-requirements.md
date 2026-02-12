# Digital Land Submission Endpoint — Requirements & Approach

## Context

MHCLG/Digital Land is developing a planning application data specification (`v0.1.57`, alpha phase) that standardises how planning applications are submitted digitally across England. BOPS currently ingests submissions from two sources — **PlanX** (ODP schema v0.7.6) and **Planning Portal** (ZIP + HMAC). We need to add **Digital Land as a third submission source**, enabling any conformant system to submit planning applications to BOPS via the new standard.

---

## 1. Standard Overview — What We Must Accept

### 1.1 Payload Shape

The Digital Land spec uses a **flat, module-based** JSON structure — fundamentally different from ODP's deeply nested camelCase format:

```json
{
  "application": {
    "reference": "550e8400-...",
    "application-types": ["hh"],
    "planning-authority": "local-authority:CMD",
    "submission-date": "2025-09-17",
    "modules": ["site-details", "applicant-details", "..."],
    "documents": [ { "reference": "DOC-001", "file": { "..." } } ],
    "fee": { "..." }
  },
  "site-details": { "..." },
  "applicant-details": { "..." },
  "agent-details": { "..." },
  "proposal-details": { "..." },
  "declaration": { "..." }
}
```

Key characteristics:
- **kebab-case** keys throughout (vs camelCase in ODP)
- **Module-per-key** at root level — no deep nesting hierarchy
- **`additionalProperties: true`** — payloads may include extra data
- **Multi-type applications**: `application-types` is an array; validate against each type's schema
- **25 application type schemas** generated as self-contained JSON Schema Draft-07 files

### 1.2 Application Envelope (Always Required)

| Field | Required | Format | Description |
|---|---|---|---|
| `reference` | MUST | UUID string | Unique application identifier |
| `application-types` | MUST | Array of enum (38 codes) | e.g. `["hh"]`, `["full"]` |
| `planning-authority` | MUST | `{org-type}:{code}` | e.g. `local-authority:CMD` |
| `submission-date` | MUST | `YYYY-MM-DD` | When submitted |
| `modules` | MUST | Array of strings | Module keys present in payload |
| `documents` | MUST | Array of document objects | At least one |
| `fee` | MAY | Object | Fee amount + payment info |

### 1.3 Documents / Attachments

Documents live in `application.documents[]`:

```json
{
  "reference": "DOC-001",
  "name": "Site Location Plan",
  "document-types": ["location-plan"],
  "uploaded-date": "2025-09-17",
  "file": {
    "url": "https://...",
    "base64-content": "...",
    "filename": "location.pdf",
    "mime-type": "application/pdf",
    "checksum": "sha256:...",
    "file-size": 2048576
  }
}
```

Rules:
- Either `url` OR `base64-content`, not both
- `reference` MUST be unique within the application
- `name`, `document-types`, `uploaded-date`, `file.filename` are MUST
- Supporting documents within modules reference docs by `reference` only (no data duplication)
- `document-types` must match the `planning-requirement` codelist

### 1.4 Key Identifiers

| Identifier | Format | Maps to BOPS |
|---|---|---|
| `application.reference` | UUID | `Submission#application_reference` |
| `application.planning-authority` | `{org-type}:{code}` | Local authority lookup |
| `applicant.reference` / `agent.reference` | String | Internal cross-refs |
| `document.reference` | String | Document cross-refs |
| `site-details.site-locations[].uprns[]` | String | `Property` UPRN |

### 1.5 Application Types (38 total, key subset for MVP)

| Code | Name | Modules |
|---|---|---|
| `hh` | Householder | 17 modules |
| `full` | Full planning permission | 28 modules |
| `ldc` | Lawful development certificate | 11 modules |
| `lbc` | Listed building consent | 19 modules |
| `prior-approval` | Prior approval | 8 modules |
| `s73` | Variation of conditions | 13 modules |
| `pip` | Permission in principle | 10 modules |

### 1.6 Versioning Status

- Current version: **v0.1.57** (alpha)
- No version field in payload or schema `$id` — versioning approach is an open question in their docs
- JSON Schema Draft-07
- Expect breaking changes before 1.0

---

## 2. BOPS Current State — What We Already Have

### 2.1 Submissions Engine Architecture

```
POST /api/v2/submissions(?schema=odp|planning-portal)
  |
  AuthenticatedController (Bearer token or HMAC)
  |
  Schema validation (ODP only, synchronous)
  |
  CreationService -> persist raw payload as Submission record
  |  (request_headers, request_body, schema, external_uuid)
  |
  Return UUID immediately -> async processing begins
  |
  SubmissionProcessorJob
  |
  +-- PlanX path -> PlanxCreationService -> PlanningApplication
  +-- Planning Portal path -> ZipExtractionService -> PlanningPortalCreationService
  +-- Enforcement path -> Enforcement::CreationService
```

### 2.2 Key Existing Components

| Component | Path | Reusable? |
|---|---|---|
| `Submission` model | `app/models/submission.rb` | Yes — add `"digital-land"` schema value |
| `CreationService` | `engines/bops_submissions/app/services/bops_submissions/creation_service.rb` | Yes — already schema-agnostic |
| `SubmissionProcessorJob` | `engines/bops_submissions/app/jobs/bops_submissions/submission_processor_job.rb` | Yes — add Digital Land dispatch branch |
| `SchemaValidation` concern | `engines/bops_api/app/controllers/concerns/bops_api/schema_validation.rb` | Extend — add DL schema host recognition |
| `CaseRecord` (delegated_type) | `app/models/case_record.rb` | Yes — already supports PlanningApplication + Enforcement |
| `BaseParser` + parsers | `engines/bops_submissions/app/services/bops_submissions/parsers/` | Extend — add `"digital-land"` source to each parser's `FIELD_MAP` |
| `DocumentsService` | `engines/bops_submissions/app/services/bops_submissions/documents_service.rb` | Extend — add base64 support |
| `FileDownloaders` | `app/models/file_downloaders.rb` | Yes — URL downloads already work |
| Auth (Bearer token) | `engines/bops_submissions/app/controllers/bops_submissions/v2/authenticated_controller.rb` | Yes — reuse Bearer token auth |
| JSON Schema infrastructure | `engines/bops_api/lib/bops_api/schemas.rb` | Extend — register DL schemas alongside ODP |

### 2.3 Source-Aware Parser Pattern

Every parser has a `FIELD_MAP` hash keyed by source:

```ruby
FIELD_MAP = {
  "PlanX" => { first_name: %w[applicant name first], ... },
  "Planning Portal" => { first_name: %w[Applicant Name FirstName], ... }
}
```

Adding Digital Land means adding a third entry to each parser mapping the new kebab-case paths.

---

## 3. Gap List — What We Need to Build/Decide

### 3.1 Must Build

| # | Gap | Effort | Notes |
|---|---|---|---|
| G1 | **DL JSON schemas vendored into BOPS** | S | Copy generated schemas from spec repo into `engines/bops_api/schemas/digital-land/v0.1.x/` |
| G2 | **Schema detection for DL payloads** | S | Extend `SchemaValidation#schema_name_and_version` to handle DL schema identification (no `metadata.schema` URL — need different approach) |
| G3 | **Multi-schema validation** | M | DL requires validating against *each* declared `application-types` schema. Current BOPS validates against one schema only |
| G4 | **Application type code mapping** | M | Map DL's 38 kebab-case type codes (e.g. `hh`, `full`) to BOPS `ApplicationType::Config` codes (e.g. `pp.full.householder`). Similar to PP's `planning-portal.en.rb` I18n lookup |
| G5 | **Parser field maps for "digital-land" source** | L | Add `"digital-land"` entries to all 9 parsers: Applicant, Agent, Address, ApplicationType, Fee, Proposal, ProposalDetails, PreAssessment, Submission |
| G6 | **Base64 document handling** | M | Current `DocumentsService` only downloads from URLs. DL allows inline `base64-content`. Need to decode + attach via Active Storage |
| G7 | **Planning authority -> local authority resolution** | S | Map DL's `local-authority:CMD` format to BOPS local authority records |
| G8 | **`?schema=digital-land` query parameter** | S | Add to submissions endpoint alongside `odp` and `planning-portal` |
| G9 | **DL-specific creation service** | M | `BopsSubmissions::Application::DigitalLandCreationService` — orchestrate parsers + create `PlanningApplication` via `CaseRecord` |
| G10 | **Address/coordinate handling** | S | DL uses WKT for geometry (vs GeoJSON in ODP). Need WKT->GeoJSON conversion for `boundary_geojson` |

### 3.2 Must Decide

| # | Decision | Options |
|---|---|---|
| D1 | **Schema version pinning** | DL has no version in payload. Do we: (a) pin to a vendored version, (b) accept a version query param, (c) use `application-types` to infer? |
| D2 | **Auth model for DL submitters** | Reuse existing Bearer token? (Recommended — simplest, already proven) |
| D3 | **Idempotency strategy** | `application.reference` is a UUID — use it for deduplication like we use `metadata.id` for ODP. Reject duplicates or return existing UUID? |
| D4 | **Which application types for MVP** | Start with `hh` only? Or `hh` + `full` + `ldc`? |
| D5 | **Base64 payload size limits** | Documents can be inline. What max request body size? (Current Nginx/Puma limits may need adjusting) |
| D6 | **Conditional field validation** | DL uses `required-if` / `applies-if`. The generated JSON schemas handle this via `if/then`. Is JSONSchemer sufficient or do we need custom validation? |

---

## 4. MVP Proposal — Smallest Viable Endpoint

### 4.1 Scope

- **One endpoint**: `POST /api/v2/submissions?schema=digital-land`
- **One application type**: `hh` (householder) — 17 modules, most common type
- **Auth**: Existing Bearer token (`ApiUser` with `planning_application:write`)
- **Documents**: URL-based only for MVP (defer base64 to fast-follow)
- **No new API version** — extend existing v2 submissions endpoint

### 4.2 Request/Response

**Request:**
```
POST /api/v2/submissions?schema=digital-land
Authorization: Bearer bops_xxxxx
Content-Type: application/json

{ "application": { ... }, "site-details": { ... }, ... }
```

**Response (201):**
```json
{
  "uuid": "01912345-...",
  "message": "Submission was successfully created for application with reference: HH/2025/001"
}
```

**Error (422):**
```json
{
  "error": {
    "code": 422,
    "message": "Unprocessable Entity",
    "detail": "Validation failed: application-types 'hh' schema validation errors: ..."
  }
}
```

### 4.3 Implementation Flow

```
1. POST /api/v2/submissions?schema=digital-land
2. Bearer token auth (existing)
3. Detect schema=digital-land -> load DL JSON schema for each application-types[] entry
4. Validate payload against all applicable schemas
5. CreationService.call -> persist Submission (schema: "digital-land")
6. Return UUID
7. SubmissionProcessorJob picks up submission
8. Dispatch to DigitalLandCreationService:
   a. Parse application envelope -> extract type, authority, reference
   b. Resolve planning-authority -> local_authority
   c. Run parsers (applicant, agent, address, proposal, etc.) with "digital-land" field maps
   d. Create PlanningApplication via CaseRecord
9. PlanningApplicationDependencyJob:
   a. Download documents from URLs
   b. Create Document records with type tags
   c. Fetch planning constraints/designations
   d. Mark as accepted, send receipt
```

### 4.4 Files to Create/Modify

**New files:**

| File | Purpose |
|---|---|
| `engines/bops_api/schemas/digital-land/v0.1.57/hh.json` | Vendored HH JSON schema |
| `engines/bops_submissions/app/services/bops_submissions/application/digital_land_creation_service.rb` | Creation service for DL submissions |
| `config/locales/digital-land.en.rb` | Application type code mapping (DL -> BOPS) |
| `engines/bops_submissions/spec/fixtures/examples/digital-land/v0.1.57/hh.json` | Test fixture |

**Modified files:**

| File | Change |
|---|---|
| `engines/bops_submissions/app/jobs/bops_submissions/submission_processor_job.rb` | Add `digital-land` dispatch branch |
| `engines/bops_api/app/controllers/concerns/bops_api/schema_validation.rb` | Add DL schema detection logic |
| `engines/bops_api/lib/bops_api/schemas.rb` | Register DL schemas |
| All 9 parsers in `engines/bops_submissions/app/services/bops_submissions/parsers/` | Add `"digital-land"` to each `FIELD_MAP` |
| `engines/bops_submissions/app/controllers/bops_submissions/v2/submissions_controller.rb` | Allow `"digital-land"` as schema param |
| `app/models/submission.rb` | Handle DL `application.reference` in `#application_reference` |
| `engines/bops_submissions/swagger/v2/submissions/swagger_doc.yaml` | Document new schema option |

### 4.5 Idempotency

Use `application.reference` (UUID) for deduplication:
- Before creating submission, check if a `Submission` with matching `application_reference` already exists for the local authority
- If found and `completed`: return existing UUID with 200 (idempotent replay)
- If found and `started/submitted`: return existing UUID with 202 (still processing)
- If not found: create new submission, return 201

### 4.6 Operational Needs

- **Audit trail**: Already handled — raw payload stored in `Submission#request_body`, headers in `request_headers`
- **Retries**: `SubmissionProcessorJob` already retries on failure via Sidekiq; `PlanningApplicationDependencyJob` retries 5x
- **Observability**: AppSignal integration already in place for error reporting
- **Rate limiting**: Consider adding per-API-user rate limits (not in MVP)

---

## 5. Open Questions / Risks

### 5.1 Schema Evolution (High Risk)
The DL spec is at v0.1.57 (alpha). Breaking changes are expected. We need a strategy for:
- How to detect which spec version a payload conforms to (no version field in payload)
- How to support multiple DL versions concurrently
- Frequency of schema updates and vendoring cadence

**Recommendation**: Pin to a specific version, accept a `?version=0.1.57` query param, and require explicit opt-in to new versions.

### 5.2 PII / Data Protection
Planning applications contain personal data (names, addresses, emails, phone numbers). The DL spec includes all of these. Considerations:
- Existing BOPS anonymisation in `PlanningApplicationDependencyJob` covers production mirroring to staging
- Base64 documents could contain PII in file content
- Ensure DL submissions go through same data protection controls as ODP

### 5.3 Large Payloads (Medium Risk)
Base64-encoded documents can make payloads very large. A 10MB PDF becomes ~13.3MB base64. Multiple documents could push payloads to 50-100MB+.
- **MVP mitigation**: URL-only documents initially
- **Fast-follow**: Add base64 support with configurable max body size, streaming decode

### 5.4 Application Type Mapping Complexity
DL has 38 application types with subtypes and inheritance. BOPS has its own `ApplicationType::Config` with ODP-style codes. The mapping between `hh` -> `pp.full.householder` is straightforward for common types, but edge cases (e.g. `extraction-oil-gas`, `twao`) may not have BOPS equivalents.
- **MVP**: Map only types BOPS already supports
- **Reject unsupported types** with a clear error message

### 5.5 Geometry Format Difference
DL uses **WKT** (Well-Known Text) for site boundaries. BOPS stores **GeoJSON**. The `RGeo` gem (already in the project) can handle WKT->GeoJSON conversion, but we need to verify coordinate system assumptions (EPSG:4326 vs British National Grid).

### 5.6 No API Contract in the Spec
The DL specification deliberately does not define HTTP methods, paths, or auth. Our endpoint design is our own. This is fine for MVP but means there's no interoperability guarantee with other LPA systems that implement the same spec differently.

### 5.7 Conditional Validation Complexity
DL schemas use `if/then/allOf/anyOf` extensively for conditional requirements. The generated JSON schemas should handle this, but we should verify JSONSchemer handles all these Draft-07 constructs correctly with comprehensive test cases.

---

## 6. Verification Plan

1. **Unit tests**: Parser specs with DL fixture payloads for each parser
2. **Integration tests**: Request spec `POST /api/v2/submissions?schema=digital-land` with HH fixture -> verify Submission created, UUID returned
3. **Async processing test**: Verify `SubmissionProcessorJob` dispatches to `DigitalLandCreationService` and creates `PlanningApplication` with correct attributes
4. **Schema validation test**: Submit payloads with missing required fields -> verify 422 with clear error messages
5. **Idempotency test**: Submit same `application.reference` twice -> verify idempotent response
6. **Document handling test**: Submit with document URLs -> verify documents downloaded and attached
7. **Type mapping test**: Submit each supported `application-types` code -> verify correct `ApplicationType::Config` resolution
